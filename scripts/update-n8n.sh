#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# update-n8n.sh — Actualización n8n con backup, verificación y rollback
# Uso     : bash update-n8n.sh [VERSION]
# Ejemplo : bash update-n8n.sh 2.14.2
# Sin arg : toma la última versión estable desde GitHub
# ══════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Configuración ──────────────────────────────────────────────────
COMPOSE_DIR="/opt/chativot"
BACKUP_DIR="/opt/backups/n8n"
COMPOSE_FILE="${COMPOSE_DIR}/docker-compose.yml"
LOG_FILE="${BACKUP_DIR}/update.log"
CONTAINER="n8n"
VOLUME="chativot_n8n_data"

# ── Colores ────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $*" | tee -a "$LOG_FILE"; }
ok()   { echo -e "${GREEN}[✅ OK]${NC} $*"    | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[⚠ WARN]${NC} $*"  | tee -a "$LOG_FILE"; }
fail() { echo -e "${RED}[❌ ERROR]${NC} $*"   | tee -a "$LOG_FILE"; exit 1; }

mkdir -p "$BACKUP_DIR"

echo "" | tee -a "$LOG_FILE"
echo -e "${BOLD}══════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
echo -e "${BOLD}   n8n Update Script — $(date '+%Y-%m-%d %H:%M:%S')${NC}" | tee -a "$LOG_FILE"
echo -e "${BOLD}══════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"

# ══════════════════════════════════════════════════════════════════
# PASO 1 — Verificar que n8n está corriendo
# ══════════════════════════════════════════════════════════════════
log "PASO 1/6 — Verificando estado del contenedor..."

docker ps --filter "name=${CONTAINER}" --filter "status=running" | grep -q "$CONTAINER" \
  || fail "El contenedor ${CONTAINER} no está corriendo. Verifica con: docker ps"

CURRENT=$(docker exec "$CONTAINER" n8n --version 2>/dev/null || echo "unknown")
log "Versión actual: ${CURRENT}"

# ══════════════════════════════════════════════════════════════════
# PASO 2 — Obtener versión objetivo
# ══════════════════════════════════════════════════════════════════
log "PASO 2/6 — Determinando versión objetivo..."

if [ -n "${1:-}" ]; then
    TARGET="$1"
    log "Versión especificada manualmente: ${TARGET}"
else
    TARGET=$(curl -sf https://api.github.com/repos/n8n-io/n8n/releases/latest \
      | grep '"tag_name"' | sed 's/.*"n8n@\([^"]*\)".*/\1/')
    [ -z "$TARGET" ] && fail "No se pudo obtener la versión latest desde GitHub"
    log "Última versión estable: ${TARGET}"
fi

if [ "$CURRENT" = "$TARGET" ]; then
    ok "n8n ya está en la versión ${TARGET}. No hay nada que actualizar."
    exit 0
fi

echo ""
echo -e "  ${BOLD}Versión actual : ${RED}${CURRENT}${NC}"
echo -e "  ${BOLD}Versión nueva  : ${GREEN}${TARGET}${NC}"
echo ""
read -rp "  ¿Confirmas la actualización? (s/N): " CONFIRM
[[ "$CONFIRM" =~ ^[sS]$ ]] || { echo "Operación cancelada."; exit 0; }

# ══════════════════════════════════════════════════════════════════
# PASO 3 — Backup del volumen
# ══════════════════════════════════════════════════════════════════
log "PASO 3/6 — Generando backup del volumen ${VOLUME}..."

TS=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/n8n_backup_v${CURRENT}_${TS}.tar.gz"

docker run --rm \
  -v "${VOLUME}":/source:ro \
  -v "${BACKUP_DIR}":/backup \
  alpine tar czf "/backup/n8n_backup_v${CURRENT}_${TS}.tar.gz" -C /source .

# Verificar que el backup tiene peso real
BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
[ -f "$BACKUP_FILE" ] || fail "El archivo de backup no fue creado"
[ "$(stat -c%s "$BACKUP_FILE")" -gt 1024 ] || fail "El backup está vacío o es inválido"

ok "Backup generado: ${BACKUP_FILE} (${BACKUP_SIZE})"

# ══════════════════════════════════════════════════════════════════
# PASO 4 — Actualizar imagen en docker-compose.yml
# ══════════════════════════════════════════════════════════════════
log "PASO 4/6 — Actualizando docker-compose.yml..."

cd "$COMPOSE_DIR"

# Guardar versión anterior para rollback
sed -n '/image: n8nio\/n8n/p' "$COMPOSE_FILE" | head -1 > "${BACKUP_DIR}/previous_image_${TS}.txt"

sed -i "s|n8nio/n8n:.*|n8nio/n8n:${TARGET}|g" "$COMPOSE_FILE"

VERIFY=$(grep "n8nio/n8n" "$COMPOSE_FILE" | head -1)
log "Imagen en compose: ${VERIFY}"

# ══════════════════════════════════════════════════════════════════
# PASO 5 — Pull y recrear contenedor
# ══════════════════════════════════════════════════════════════════
log "PASO 5/6 — Descargando imagen y recreando contenedor..."

docker compose pull n8n
docker compose up -d --no-deps n8n

log "Esperando inicio del contenedor (30 segundos)..."
sleep 30

# ══════════════════════════════════════════════════════════════════
# PASO 6 — Verificar resultado
# ══════════════════════════════════════════════════════════════════
log "PASO 6/6 — Verificando versión activa..."

NEW_VERSION=$(docker exec "$CONTAINER" n8n --version 2>/dev/null || echo "error")

if [ "$NEW_VERSION" = "$TARGET" ]; then
    ok "Actualización exitosa: n8n v${NEW_VERSION} activo"
    echo ""
    echo -e "${BOLD}${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}   ✅ ACTUALIZACIÓN COMPLETADA EXITOSAMENTE${NC}"
    echo -e "${BOLD}${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "   Versión anterior : ${RED}${CURRENT}${NC}"
    echo -e "   Versión nueva    : ${GREEN}${NEW_VERSION}${NC}"
    echo -e "   Backup           : ${BACKUP_FILE}"
    echo -e "   Log              : ${LOG_FILE}"
    echo -e "${BOLD}${GREEN}══════════════════════════════════════════════${NC}"
    echo ""
    echo "$(date) | ÉXITO | ${CURRENT} → ${TARGET} | Backup: ${BACKUP_FILE}" >> "$LOG_FILE"
else
    warn "La versión activa es '${NEW_VERSION}', se esperaba '${TARGET}'"
    warn "Iniciando ROLLBACK automático a v${CURRENT}..."

    # ── ROLLBACK ──────────────────────────────────────────────────
    sed -i "s|n8nio/n8n:.*|n8nio/n8n:${CURRENT}|g" "$COMPOSE_FILE"
    docker compose up -d --no-deps n8n
    sleep 20

    ROLLBACK_VER=$(docker exec "$CONTAINER" n8n --version 2>/dev/null || echo "error")

    echo ""
    echo -e "${BOLD}${RED}══════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${RED}   ❌ ACTUALIZACIÓN FALLIDA — ROLLBACK EJECUTADO${NC}"
    echo -e "${BOLD}${RED}══════════════════════════════════════════════${NC}"
    echo -e "   Versión revertida : ${ROLLBACK_VER}"
    echo -e "   Backup disponible : ${BACKUP_FILE}"
    echo -e "   Revisa los logs   : docker logs ${CONTAINER} --tail=50"
    echo -e "${BOLD}${RED}══════════════════════════════════════════════${NC}"
    echo ""
    echo "$(date) | FALLO+ROLLBACK | ${CURRENT} → ${TARGET} fallido | Revertido a ${ROLLBACK_VER}" >> "$LOG_FILE"
    exit 1
fi
