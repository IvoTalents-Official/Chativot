#!/bin/bash
set -e

# ============================================================
#   CHATIVOT.COM — Instalación Docker con Apache
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}"
echo "============================================================"
echo "   CHATIVOT.COM — Instalación Docker completa"
echo "============================================================"
echo -e "${NC}"

INSTALL_DIR="/opt/chativot"
DOMAINS=(
    "bd.chativot.com"
    "chat.chativot.com"
    "n8n.chativot.com"
    "fzap.chativot.com"
    "zabbix.chativot.com"
)

# --- 1. Actualizar sistema ---
echo -e "${YELLOW}[1/8] Actualizando sistema...${NC}"
apt update && apt upgrade -y
apt install -y curl git apt-transport-https ca-certificates gnupg lsb-release ufw

# --- 2. Instalar Docker ---
echo -e "${YELLOW}[2/8] Instalando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker
    systemctl start docker
else
    echo -e "${GREEN}Docker ya está instalado.${NC}"
fi

if ! docker compose version &> /dev/null; then
    apt install -y docker-compose-plugin
fi

echo -e "${GREEN}Docker $(docker --version)${NC}"
echo -e "${GREEN}Docker Compose $(docker compose version)${NC}"

# --- 3. Preparar archivos ---
echo -e "${YELLOW}[3/8] Preparando archivos...${NC}"
mkdir -p ${INSTALL_DIR}
cp -r . ${INSTALL_DIR}/
cd ${INSTALL_DIR}

# --- 4. Generar claves secretas ---
echo -e "${YELLOW}[4/8] Generando claves secretas...${NC}"
CHATWOOT_KEY=$(openssl rand -hex 64)
N8N_KEY=$(openssl rand -hex 32)
sed -i "s|CHATWOOT_SECRET_KEY_BASE=.*|CHATWOOT_SECRET_KEY_BASE=${CHATWOOT_KEY}|" .env
sed -i "s|N8N_ENCRYPTION_KEY=.*|N8N_ENCRYPTION_KEY=${N8N_KEY}|" .env
echo -e "${GREEN}Claves generadas.${NC}"

# --- 5. Firewall ---
echo -e "${YELLOW}[5/8] Configurando firewall...${NC}"
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 10051/tcp
ufw --force enable
echo -e "${GREEN}Firewall configurado.${NC}"

# --- 6. Configurar Apache temporal (solo HTTP para certbot) ---
echo -e "${YELLOW}[6/8] Iniciando Apache temporal para SSL...${NC}"

# Guardar config SSL para después
cp ${INSTALL_DIR}/apache/conf/vhosts-ssl.conf ${INSTALL_DIR}/apache/conf/vhosts-ssl.conf.bak

# Usar solo config temporal HTTP
rm -f ${INSTALL_DIR}/apache/conf/vhosts-ssl.conf

# --- 7. Levantar servicios ---
echo -e "${YELLOW}[7/8] Levantando contenedores...${NC}"
docker compose up -d

echo -e "${YELLOW}Esperando que PostgreSQL esté listo...${NC}"
sleep 20

# Verificar bases de datos
echo -e "${YELLOW}Verificando bases de datos...${NC}"
docker exec postgres psql -U postgres -c "\l" | grep -E "chatwoot|n8n|fzap|zabbix"

# Preparar DB de Chatwoot
echo -e "${YELLOW}Preparando base de datos de Chatwoot...${NC}"
docker exec chatwoot-rails bundle exec rails db:chatwoot_prepare || true
sleep 5

# --- 8. Obtener certificados SSL ---
echo -e "${YELLOW}[8/8] Obteniendo certificados SSL...${NC}"

CERTBOT_EMAIL=$(grep CERTBOT_EMAIL .env | cut -d= -f2)

for domain in "${DOMAINS[@]}"; do
    echo -e "${YELLOW}  → Certificado para ${domain}...${NC}"
    docker compose run --rm certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email ${CERTBOT_EMAIL} \
        --agree-tos \
        --no-eff-email \
        -d ${domain} && echo -e "${GREEN}  ✓ ${domain} OK${NC}" || echo -e "${RED}  ✗ Error con ${domain} — verifica DNS${NC}"
done

# Restaurar config SSL y reiniciar Apache
echo -e "${YELLOW}Activando SSL en Apache...${NC}"
rm -f ${INSTALL_DIR}/apache/conf/vhosts-temp.conf
cp ${INSTALL_DIR}/apache/conf/vhosts-ssl.conf.bak ${INSTALL_DIR}/apache/conf/vhosts-ssl.conf
docker compose restart apache

# Cron para renovar SSL
(crontab -l 2>/dev/null; echo "0 3 * * * cd ${INSTALL_DIR} && docker compose run --rm certbot renew --quiet && docker compose restart apache") | crontab -

# ============================================================
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}   ✅ INSTALACIÓN COMPLETADA${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo -e "${YELLOW}Servicios:${NC}"
echo -e "  📊 pgAdmin4:         https://bd.chativot.com"
echo -e "  💬 Chatwoot:         https://chat.chativot.com"
echo -e "  🔄 n8n:              https://n8n.chativot.com"
echo -e "  📱 fzap (Evolution): https://fzap.chativot.com"
echo -e "  📈 Zabbix:           https://zabbix.chativot.com"
echo ""
echo -e "${YELLOW}Bases de datos en PostgreSQL:${NC}"
echo -e "  • chatwoot"
echo -e "  • n8n"
echo -e "  • n8n_chativot"
echo -e "  • n8n_tuentradaweb"
echo -e "  • fzap"
echo -e "  • zabbix"
echo ""
echo -e "${YELLOW}Credenciales:${NC}"
echo -e "  pgAdmin:  admin@chativot.com / (ver .env)"
echo -e "  Zabbix:   Admin / zabbix"
echo -e "  n8n:      admin / (ver .env)"
echo -e "  Chatwoot: Crear admin en https://chat.chativot.com/app/login"
echo ""
echo -e "${YELLOW}Directorio: ${INSTALL_DIR}${NC}"
echo -e "${YELLOW}Logs: docker compose -f ${INSTALL_DIR}/docker-compose.yml logs -f [servicio]${NC}"
echo ""
echo -e "${RED}⚠️  Asegúrate de que los DNS de los 5 subdominios${NC}"
echo -e "${RED}   apunten a la IP de este servidor.${NC}"
echo ""
