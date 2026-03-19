# 🚀 Chativot — Stack de Desarrollo

Entorno de desarrollo completo basado en Docker para la plataforma **Chativot**, clonado desde producción. Incluye todos los servicios necesarios para desarrollar y probar sin afectar el entorno productivo.

---

## 🖥️ Servidor

| Item | Detalle |
|---|---|
| OS | Ubuntu 24.04 LTS |
| IP | 89.167.98.137 |
| Docker | 29.3.0 |
| Docker Compose | v5.1.0 |

---

## 🌐 URLs de Desarrollo

| Servicio | URL | Puerto interno |
|---|---|---|
| Chatwoot | https://chatdev.chativot.com | 3000 |
| n8n | https://n8ndev.chativot.com | 5678 |
| Fzap | https://fzapdev.chativot.com | 8080 |
| Zabbix | https://zabbixdev.chativot.com | 8081 |
| pgAdmin | https://bddev.chativot.com | 5050 |
| RedisInsight | https://redisdev.chativot.com | 5540 |
| Portal | https://dev.chativot.com | 3000 |

---

## 📦 Servicios incluidos

### 🗄️ PostgreSQL (pgvector/pgvector:pg16)
Base de datos principal con soporte para vectores. Contiene:
- `chatwoot` — datos de Chatwoot
- `fzap` — datos de Fzap
- `n8n` — flujos de n8n
- `zabbix` — métricas de Zabbix

### 🔴 Redis (redis:7-alpine)
Cache y cola de mensajes usada por Chatwoot y otros servicios.

### 💬 Chatwoot (chatwoot/chatwoot:v4.11.2)
Plataforma de atención al cliente omnicanal. Dos contenedores:
- `chatwoot-rails` — servidor web (puerto 3000)
- `chatwoot-sidekiq` — procesador de trabajos en background

### ⚡ n8n (n8nio/n8n:latest)
Automatización de flujos de trabajo conectado a PostgreSQL.

### 📱 Fzap (dncarbonell/fzap:latest)
API para gestión de WhatsApp conectada a PostgreSQL.

### 📊 Zabbix
Sistema de monitoreo:
- `zabbix-server` — servidor (puerto 10051)
- `zabbix-web` — interfaz web (puerto 8081)

### 🌐 Apache (httpd:2.4-alpine)
Proxy inverso con SSL para todos los dominios dev.

### 🔒 Certbot (certbot/certbot:latest)
Certificados SSL automáticos con Let's Encrypt, renovación cada 6h.

### 🔍 RedisInsight (redis/redisinsight:latest)
Interfaz visual para administrar Redis.

### 🐘 pgAdmin (dpage/pgadmin4:latest)
Interfaz web para administrar PostgreSQL.

---

## 🗂️ Estructura del proyecto
```
/opt/chativot/
├── docker-compose.yml        # Definición de todos los servicios
├── .env                      # Variables de entorno
├── apache/
│   ├── httpd.conf            # Configuración principal de Apache
│   └── conf/
│       └── vhosts-ssl.conf   # VirtualHosts SSL para dominios dev
└── scripts/
    ├── init-db.sql           # Inicialización de bases de datos
    └── servers.json          # Configuración de servidores pgAdmin
```

---

## 🔧 Variables de entorno (.env)
```env
# PostgreSQL
POSTGRES_USER=
POSTGRES_PASSWORD=

# Chatwoot
DOMAIN_CHAT=chatdev.chativot.com
CHATWOOT_DB=chatwoot
CHATWOOT_DB_USER=
CHATWOOT_DB_PASSWORD=
CHATWOOT_SECRET_KEY_BASE=

# Redis
REDIS_PASSWORD=

# n8n
DOMAIN_N8N=n8ndev.chativot.com
N8N_DB=n8n
N8N_DB_USER=
N8N_DB_PASSWORD=
N8N_BASIC_AUTH_USER=
N8N_BASIC_AUTH_PASSWORD=
N8N_ENCRYPTION_KEY=

# Zabbix
ZABBIX_DB=zabbix
ZABBIX_DB_USER=
ZABBIX_DB_PASSWORD=
ZABBIX_TZ=America/Santiago

# pgAdmin
PGADMIN_EMAIL=
PGADMIN_PASSWORD=

# SMTP
MAILER_SENDER_EMAIL=
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
```

---

## 🚀 Levantar el entorno
```bash
cd /opt/chativot
docker compose up -d

# Ver estado
docker compose ps

# Ver logs
docker compose logs -f chatwoot-rails
```

---

## 🔄 Comandos útiles
```bash
# Reiniciar un servicio
docker compose restart apache

# Detener todo
docker compose down

# Acceder a PostgreSQL
docker exec -it postgres psql -U postgres

# Acceder a Redis
docker exec -it redis redis-cli -a TU_PASSWORD

# Renovar certificados SSL manualmente
docker run --rm -it \
  -p 80:80 \
  -v chativot_certbot_certs:/etc/letsencrypt \
  -v chativot_certbot_html:/var/www/certbot \
  certbot/certbot certonly --standalone \
  -d chatdev.chativot.com \
  -d n8ndev.chativot.com \
  -d fzapdev.chativot.com \
  -d zabbixdev.chativot.com \
  -d bddev.chativot.com \
  -d redisdev.chativot.com \
  -d dev.chativot.com \
  --email admin@chativot.com --agree-tos --non-interactive
```

---

## 🔁 Sincronizar con producción
```bash
# 1. En producción: exportar
bash 01_exportar_produccion.sh

# 2. Transferir al servidor dev
scp -r root@IP_PRODUCCION:/tmp/chativot_export/ /tmp/

# 3. En dev: importar
bash 03_importar_en_dev.sh
```

---

## 📋 Volúmenes Docker

| Volumen | Contenido |
|---|---|
| `chativot_postgres_data` | Datos PostgreSQL |
| `chativot_redis_data` | Datos Redis |
| `chativot_chatwoot_storage` | Adjuntos Chatwoot |
| `chativot_n8n_data` | Flujos n8n |
| `chativot_fzap_data` | Datos Fzap |
| `chativot_fzap_instances` | Instancias WhatsApp |
| `chativot_pgadmin_data` | Config pgAdmin |
| `chativot_zabbix_server_data` | Datos Zabbix |
| `chativot_certbot_certs` | Certificados SSL |
| `chativot_certbot_html` | Challenge Certbot |

---

## 🌍 DNS (Cloudflare)

Todos los subdominios apuntan a `89.167.98.137` con proxy **desactivado** (nube gris).

| Subdominio | IP |
|---|---|
| chatdev.chativot.com | 89.167.98.137 |
| n8ndev.chativot.com | 89.167.98.137 |
| fzapdev.chativot.com | 89.167.98.137 |
| zabbixdev.chativot.com | 89.167.98.137 |
| bddev.chativot.com | 89.167.98.137 |
| redisdev.chativot.com | 89.167.98.137 |
| dev.chativot.com | 89.167.98.137 |

---

## ⚠️ Notas importantes

- Este entorno es una copia de **producción** con datos reales
- No usar para pruebas destructivas sin respaldar primero
- Los certificados SSL expiran en 90 días — certbot los renueva automáticamente
- El `.env` contiene credenciales sensibles — nunca subir a repositorios públicos
