#!/bin/bash
# ============================================================
# SCRIPT 1: EXPORTAR PRODUCCIÓN - Chativot Stack
# Ejecutar en: servidor PRODUCCIÓN como root
# Comando: bash 01_exportar_produccion.sh
# ============================================================

set -e
EXPORT_DIR="/tmp/chativot_export"

echo "======================================================"
echo "  EXPORTANDO STACK CHATIVOT - $(date)"
echo "======================================================"

mkdir -p "$EXPORT_DIR"

# --------------------------------------------------------------
# 1. COPIAR docker-compose.yml y .env
# --------------------------------------------------------------
echo ""
echo "[1/5] Copiando archivos de configuración..."

if [ -f /opt/chativot/docker-compose.yml ]; then
  cp /opt/chativot/docker-compose.yml "$EXPORT_DIR/"
  [ -f /opt/chativot/.env ] && cp /opt/chativot/.env "$EXPORT_DIR/"
elif [ -f /root/chativot/docker-compose.yml ]; then
  cp /root/chativot/docker-compose.yml "$EXPORT_DIR/"
  [ -f /root/chativot/.env ] && cp /root/chativot/.env "$EXPORT_DIR/"
fi

echo "    ✓ Configuración copiada"

# --------------------------------------------------------------
# 2. EXPORTAR IMÁGENES DOCKER
# --------------------------------------------------------------
echo ""
echo "[2/5] Exportando imágenes Docker (~12GB, puede tardar 10-20 min)..."

docker save \
  dncarbonell/fzap:latest \
  chatwoot/chatwoot:v4.11.2 \
  redis/redisinsight:latest \
  httpd:2.4-alpine \
  zabbix/zabbix-web-nginx-pgsql:latest \
  dpage/pgadmin4:latest \
  zabbix/zabbix-server-pgsql:latest \
  n8nio/n8n:latest \
  redis:7-alpine \
  pgvector/pgvector:pg16 \
  certbot/certbot:latest \
  | gzip > "$EXPORT_DIR/imagenes_docker.tar.gz"

echo "    ✓ Imágenes exportadas: $(du -sh $EXPORT_DIR/imagenes_docker.tar.gz | cut -f1)"

# --------------------------------------------------------------
# 3. DUMP DE POSTGRESQL (todas las bases de datos)
# --------------------------------------------------------------
echo ""
echo "[3/5] Haciendo dump de PostgreSQL..."

docker exec postgres pg_dumpall -U postgres | gzip > "$EXPORT_DIR/postgres_dump.sql.gz"

echo "    ✓ Dump PostgreSQL: $(du -sh $EXPORT_DIR/postgres_dump.sql.gz | cut -f1)"

# --------------------------------------------------------------
# 4. EXPORTAR VOLÚMENES DOCKER
# --------------------------------------------------------------
echo ""
echo "[4/5] Exportando volúmenes Docker..."

VOLUMES=(
  chativot_certbot_certs
  chativot_certbot_html
  chativot_chatwoot_storage
  chativot_fzap_data
  chativot_fzap_instances
  chativot_n8n_data
  chativot_pgadmin_data
  chativot_redis_data
  chativot_zabbix_server_data
)

for VOL in "${VOLUMES[@]}"; do
  echo "    Exportando volumen: $VOL ..."
  docker run --rm \
    -v ${VOL}:/data \
    -v $EXPORT_DIR:/backup \
    alpine tar czf /backup/${VOL}.tar.gz -C /data . 2>/dev/null && \
    echo "    ✓ $VOL ($(du -sh $EXPORT_DIR/${VOL}.tar.gz | cut -f1))" || \
    echo "    ⚠ $VOL no encontrado, omitiendo"
done

# --------------------------------------------------------------
# 5. RESUMEN
# --------------------------------------------------------------
echo ""
echo "[5/5] Resumen de exportación:"
du -sh "$EXPORT_DIR"/*
echo ""
echo "======================================================"
echo "  TOTAL: $(du -sh $EXPORT_DIR | cut -f1)"
echo "======================================================"
echo ""
echo "PRÓXIMO PASO - Transferir al servidor de desarrollo:"
echo ""
echo "  # Ejecutar en tu MÁQUINA LOCAL o desde el servidor dev:"
echo "  scp -r root@32.193.7.26:/tmp/chativot_export/ /tmp/"
echo ""
echo "  # O comprimir todo en un solo archivo primero:"
echo "  tar czf /tmp/chativot_export_completo.tar.gz -C /tmp chativot_export/"
echo ""
