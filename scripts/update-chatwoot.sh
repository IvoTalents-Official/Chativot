#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# update-chatwoot.sh — Actualización Chatwoot con backup y rollback
# Uso     : bash update-chatwoot.sh [VERSION]
# Ejemplo : bash update-chatwoot.sh v4.12.1
# Sin arg : solicita la versión interactivamente
# ══════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Configuración ──────────────────────────────────────────────────
COMPOSE_DIR="/opt/chativot"
BACKUP_DIR="/opt/backups/chatwoot"
COMPOSE_FILE="${COMPOSE_DIR}/docker-compose.yml"
ENV_FILE="${COMPOSE_DIR}/.env"
LOG_FILE="${BACKUP_DIR}/update.log"
RAILS_CONTAINER="chatwoot-rails"
SIDEKIQ_CONTAINER="chatwoot-sidekiq"
VOLUME="chativot_chatwoot_storage"

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
echo -e "${BOLD}   Chatwoot Update Script — $(date '+%Y-%m-%d %H:%M:%S')${NC}" | tee -a "$LOG_FILE"
echo -e "${BOLD}══════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"

# ══════════════════════════════════════════════════════════════════
# PASO 1 — Verificar que Chatwoot está corriendo
# ══════════════════════════════════════════════════════════════════
log "PASO 1/7 — Verificando estado de contenedores..."

docker ps --filter "name=${RAILS_CONTAINER}" --filter "status=running" | grep -q "$RAILS_CONTAINER" \
  || fail "${RAILS_CONTAINER} no está corriendo. Verifica con: docker ps"

docker ps --filter "name=${SIDEKIQ_CONTAINER}" --filter "status=running" | grep -q "$SIDEKIQ_CONTAINER" \
  || warn "${SIDEKIQ_CONTAINER} no está corriendo — continuando de todas formas"

CURRENT=$(docker inspect "$RAILS_CONTAINER" --format='{{.Config.Image}}' | cut -d: -f2)
log "Versión actual: ${CURRENT}"

# ══════════════════════════════════════════════════════════════════
# PASO 2 — Obtener versión objetivo
# ══════════════════════════════════════════════════════════════════
log "PASO 2/7 — Determinando versión objetivo..."

if [ -n "${1:-}" ]; then
    TARGET="$1"
else
    echo ""
    read -rp "  Ingresa la versión a instalar (ej: v4.13.0): " TARGET
    [ -z "$TARGET" ] && fail "Debes ingresar una versión"
fi

# Asegurar prefijo v
[[ "$TARGET" == v* ]] || TARGET="v${TARGET}"

if [ "$CURRENT" = "$TARGET" ]; then
    ok "Chatwoot ya está en la versión ${TARGET}. No hay nada que actualizar."
    exit 0
fi

echo ""
echo -e "  ${BOLD}Versión actual : ${RED}${CURRENT}${NC}"
echo -e "  ${BOLD}Versión nueva  : ${GREEN}${TARGET}${NC}"
echo ""
read -rp "  ¿Confirmas la actualización? (s/N): " CONFIRM
[[ "$CONFIRM" =~ ^[sS]$ ]] || { echo "Operación cancelada."; exit 0; }

# ══════════════════════════════════════════════════════════════════
# PASO 3 — Backup BD PostgreSQL
# ══════════════════════════════════════════════════════════════════
log "PASO 3/7 — Generando backup de base de datos PostgreSQL..."

TS=$(date +%Y%m%d_%H%M%S)
CHATWOOT_DB_USER=$(grep "^CHATWOOT_DB_USER=" "$ENV_FILE" | cut -d= -f2)
CHATWOOT_DB_PASSWORD=$(grep "^CHATWOOT_DB_PASSWORD=" "$ENV_FILE" | cut -d= -f2)

DB_DUMP="${BACKUP_DIR}/chatwoot_db_${CURRENT}_${TS}.dump"

docker exec postgres bash -c \
  "PGPASSWORD='${CHATWOOT_DB_PASSWORD}' pg_dump -U ${CHATWOOT_DB_USER} --format=custom --compress=9 chatwoot" \
  > "$DB_DUMP"

[ -f "$DB_DUMP" ] || fail "El dump de BD no fue creado"
[ "$(stat -c%s "$DB_DUMP")" -gt 1024 ] || fail "El dump de BD está vacío"
DB_SIZE=$(du -h "$DB_DUMP" | cut -f1)
ok "Dump BD: ${DB_DUMP} (${DB_SIZE})"

# ══════════════════════════════════════════════════════════════════
# PASO 4 — Backup volumen storage
# ══════════════════════════════════════════════════════════════════
log "PASO 4/7 — Generando backup del volumen storage..."

STORAGE_BACKUP="${BACKUP_DIR}/chatwoot_storage_${CURRENT}_${TS}.tar.gz"

docker run --rm \
  -v "${VOLUME}":/source:ro \
  -v "${BACKUP_DIR}":/backup \
  alpine tar czf "/backup/chatwoot_storage_${CURRENT}_${TS}.tar.gz" -C /source .

[ -f "$STORAGE_BACKUP" ] || fail "El backup de storage no fue creado"
[ "$(stat -c%s "$STORAGE_BACKUP")" -gt 1024 ] || fail "El backup de storage está vacío"
STORAGE_SIZE=$(du -h "$STORAGE_BACKUP" | cut -f1)
ok "Storage: ${STORAGE_BACKUP} (${STORAGE_SIZE})"

# ══════════════════════════════════════════════════════════════════
# PASO 5 — Backup configuración
# ══════════════════════════════════════════════════════════════════
log "PASO 5/7 — Backup de configuración..."

CONFIG_BACKUP="${BACKUP_DIR}/config_${CURRENT}_${TS}.tar.gz"
tar czf "$CONFIG_BACKUP" -C "$COMPOSE_DIR" docker-compose.yml .env
ok "Config: ${CONFIG_BACKUP}"

echo ""
echo -e "  ${BOLD}Resumen de backups:${NC}"
echo -e "  • BD:      ${DB_SIZE}"
echo -e "  • Storage: ${STORAGE_SIZE}"
echo -e "  • Config:  OK"
echo ""

# ══════════════════════════════════════════════════════════════════
# PASO 6 — Actualizar imagen y recrear contenedores
# ══════════════════════════════════════════════════════════════════
log "PASO 6/7 — Actualizando docker-compose.yml y recreando contenedores..."

cd "$COMPOSE_DIR"

sed -i "s|chatwoot/chatwoot:.*|chatwoot/chatwoot:${TARGET}|g" "$COMPOSE_FILE"
VERIFY=$(grep "chatwoot/chatwoot" "$COMPOSE_FILE" | head -1)
log "Imagen en compose: ${VERIFY}"

docker compose pull chatwoot-rails chatwoot-sidekiq
docker compose up -d --no-deps chatwoot-rails chatwoot-sidekiq

log "Esperando inicio de contenedores (30 segundos)..."
sleep 30

# ══════════════════════════════════════════════════════════════════
# PASO 7 — Verificar resultado
# ══════════════════════════════════════════════════════════════════
log "PASO 7/7 — Verificando versión activa..."

NEW_VERSION=$(docker inspect "$RAILS_CONTAINER" --format='{{.Config.Image}}' 2>/dev/null | cut -d: -f2 || echo "error")
RAILS_RUNNING=$(docker ps --filter "name=${RAILS_CONTAINER}" --filter "status=running" | grep -c "$RAILS_CONTAINER" || true)

if [ "$NEW_VERSION" = "$TARGET" ] && [ "$RAILS_RUNNING" -gt 0 ]; then
    ok "Actualización exitosa: Chatwoot ${NEW_VERSION} activo"

    # Reaplicar branding si existe el script
    if [ -f "${COMPOSE_DIR}/scripts/apply-branding.sh" ]; then
        log "Reaplicando branding personalizado..."
        bash "${COMPOSE_DIR}/scripts/apply-branding.sh" &
        ok "Branding en proceso (segundo plano)"
    fi

    echo ""
    echo -e "${BOLD}${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}   ✅ ACTUALIZACIÓN COMPLETADA EXITOSAMENTE${NC}"
    echo -e "${BOLD}${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "   Versión anterior : ${RED}${CURRENT}${NC}"
    echo -e "   Versión nueva    : ${GREEN}${NEW_VERSION}${NC}"
    echo -e "   Dump BD          : ${DB_DUMP} (${DB_SIZE})"
    echo -e "   Storage          : ${STORAGE_BACKUP} (${STORAGE_SIZE})"
    echo -e "   Log              : ${LOG_FILE}"
    echo -e "${BOLD}${GREEN}══════════════════════════════════════════════${NC}"
    echo ""
    echo "$(date) | ÉXITO | ${CURRENT} → ${TARGET} | DB: ${DB_DUMP}" >> "$LOG_FILE"
else
    warn "Verificación fallida — versión activa: '${NEW_VERSION}', esperada: '${TARGET}'"
    warn "Iniciando ROLLBACK automático a ${CURRENT}..."

    # ── ROLLBACK ──────────────────────────────────────────────────
    sed -i "s|chatwoot/chatwoot:.*|chatwoot/chatwoot:${CURRENT}|g" "$COMPOSE_FILE"
    docker compose up -d --no-deps chatwoot-rails chatwoot-sidekiq
    sleep 25

    ROLLBACK_VER=$(docker inspect "$RAILS_CONTAINER" --format='{{.Config.Image}}' 2>/dev/null | cut -d: -f2 || echo "error")

    echo ""
    echo -e "${BOLD}${RED}══════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${RED}   ❌ ACTUALIZACIÓN FALLIDA — ROLLBACK EJECUTADO${NC}"
    echo -e "${BOLD}${RED}══════════════════════════════════════════════${NC}"
    echo -e "   Versión revertida : ${ROLLBACK_VER}"
    echo -e "   Backup BD         : ${DB_DUMP}"
    echo -e "   Backup Storage    : ${STORAGE_BACKUP}"
    echo -e "   Revisa los logs   : docker logs ${RAILS_CONTAINER} --tail=50"
    echo -e "${BOLD}${RED}══════════════════════════════════════════════${NC}"
    echo ""
    echo "$(date) | FALLO+ROLLBACK | ${CURRENT} → ${TARGET} fallido | Revertido a ${ROLLBACK_VER}" >> "$LOG_FILE"
    exit 1
fi
