#!/bin/bash
# ============================================================
# SCRIPT 4: SINCRONIZAR DESARROLLO → PRODUCCIÓN
# Ejecutar en: servidor DESARROLLO (89.167.98.137)
#
# QUÉ SINCRONIZA (solo datos no críticos, sin pisar prod):
#   ✅ n8n: workflows, credentials, tags, webhooks
#   ✅ Fzap: configuraciones
#
# QUÉ NO TOCA (tablas críticas de producción):
#   ❌ chatwoot: users, conversations, contacts, messages
#   ❌ n8n: execution_entity (historial de ejecuciones)
# ============================================================

set -e

PROD_IP="32.193.7.26"
PROD_USER="root"
DEV_EXPORT="/tmp/dev_to_prod_export"

echo "======================================================"
echo "  SINCRONIZANDO DEV → PRODUCCIÓN - $(date)"
echo "  ⚠️  Solo datos no críticos — producción NO se pisa"
echo "======================================================"

mkdir -p "$DEV_EXPORT"

echo ""
echo "  ✅ Sincronizará: n8n workflows, credentials, tags, webhooks, fzap config"
echo "  ❌ NO tocará:    chatwoot users, conversations, contacts, messages"
echo ""
read -p "¿Confirmas que deseas continuar? (escribe 'si' para confirmar): " CONFIRM
if [ "$CONFIRM" != "si" ]; then
  echo "Operación cancelada."
  exit 0
fi

echo ""
echo "[1/5] Exportando datos no críticos desde DEV..."

docker exec postgres psql -U postgres -c "\COPY (SELECT * FROM n8n.workflow_entity) TO STDOUT WITH CSV HEADER" > "$DEV_EXPORT/n8n_workflows.csv"
docker exec postgres psql -U postgres -c "\COPY (SELECT * FROM n8n.credentials_entity) TO STDOUT WITH CSV HEADER" > "$DEV_EXPORT/n8n_credentials.csv"
docker exec postgres psql -U postgres -c "\COPY (SELECT * FROM n8n.tag_entity) TO STDOUT WITH CSV HEADER" > "$DEV_EXPORT/n8n_tags.csv"
docker exec postgres psql -U postgres -c "\COPY (SELECT * FROM n8n.webhook_entity) TO STDOUT WITH CSV HEADER" > "$DEV_EXPORT/n8n_webhooks.csv"

docker exec postgres pg_dump -U postgres --table=public.instances --table=public.settings --data-only --column-inserts fzap 2>/dev/null > "$DEV_EXPORT/fzap_config.sql" || echo "    ⚠ Fzap: omitiendo"

echo "    ✓ Datos exportados"

echo ""
echo "[2/5] Generando SQL de sincronización segura..."

cat > "$DEV_EXPORT/sync_n8n.sql" << 'SQLEOF'
CREATE TEMP TABLE tmp_workflows AS TABLE n8n.workflow_entity WITH NO DATA;
\COPY tmp_workflows FROM '/tmp/dev_to_prod_export/n8n_workflows.csv' CSV HEADER;
INSERT INTO n8n.workflow_entity SELECT * FROM tmp_workflows ON CONFLICT (id) DO NOTHING;

CREATE TEMP TABLE tmp_credentials AS TABLE n8n.credentials_entity WITH NO DATA;
\COPY tmp_credentials FROM '/tmp/dev_to_prod_export/n8n_credentials.csv' CSV HEADER;
INSERT INTO n8n.credentials_entity SELECT * FROM tmp_credentials ON CONFLICT (id) DO NOTHING;

CREATE TEMP TABLE tmp_tags AS TABLE n8n.tag_entity WITH NO DATA;
\COPY tmp_tags FROM '/tmp/dev_to_prod_export/n8n_tags.csv' CSV HEADER;
INSERT INTO n8n.tag_entity SELECT * FROM tmp_tags ON CONFLICT (id) DO NOTHING;

CREATE TEMP TABLE tmp_webhooks AS TABLE n8n.webhook_entity WITH NO DATA;
\COPY tmp_webhooks FROM '/tmp/dev_to_prod_export/n8n_webhooks.csv' CSV HEADER;
INSERT INTO n8n.webhook_entity SELECT * FROM tmp_webhooks ON CONFLICT (webhook_id) DO NOTHING;

SELECT 'n8n sincronizado exitosamente' AS resultado;
SQLEOF

echo "    ✓ SQL generado"

echo ""
echo "[3/5] Transfiriendo archivos a producción ($PROD_IP)..."
scp -r "$DEV_EXPORT/" "$PROD_USER@$PROD_IP:/tmp/"
echo "    ✓ Transferido"

echo ""
echo "[4/5] Ejecutando sincronización en producción..."
ssh "$PROD_USER@$PROD_IP" bash << 'REMOTE'
  docker exec -i postgres psql -U postgres -f /tmp/dev_to_prod_export/sync_n8n.sql
  [ -s /tmp/dev_to_prod_export/fzap_config.sql ] && \
    docker exec -i postgres psql -U postgres fzap < /tmp/dev_to_prod_export/fzap_config.sql
  echo "✓ Sincronización completada en producción"
REMOTE

echo ""
echo "[5/5] Limpiando temporales..."
rm -rf "$DEV_EXPORT"

echo ""
echo "======================================================"
echo "  ✅ SINCRONIZACIÓN COMPLETADA - $(date)"
echo "======================================================"
