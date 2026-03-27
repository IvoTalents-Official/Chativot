# Chativot — Plataforma White-Label de Atención al Cliente

Stack completo basado en Docker para la plataforma **Chativot**: automatización de CRM, WhatsApp Business, flujos n8n y monitoreo. Diseñado para modelo white-label multi-cliente.

---

## 🌐 Servicios en Producción

| Servicio | URL | Descripción |
|----------|-----|-------------|
| Chatwoot | https://chat.chativot.com | CRM omnicanal de atención al cliente |
| n8n | https://n8n.chativot.com | Automatización de flujos y CRM |
| Fzap | https://fzap.chativot.com | Gestión de instancias WhatsApp |
| Zabbix | https://zabbix.chativot.com | Monitoreo del servidor |
| pgAdmin | https://bd.chativot.com | Administración de base de datos |

## 🌐 Servicios en Desarrollo

| Servicio | URL | Descripción |
|----------|-----|-------------|
| Chatwoot | https://chatdev.chativot.com | CRM omnicanal — entorno dev |
| n8n | https://n8ndev.chativot.com | Automatización de flujos — entorno dev |
| Fzap | https://fzapdev.chativot.com | Gestión de instancias WhatsApp — entorno dev |
| Zabbix | https://zabbixdev.chativot.com | Monitoreo del servidor — entorno dev |
| pgAdmin | https://bddev.chativot.com | Administración de base de datos — entorno dev |

---

## 🏗️ Arquitectura del Stack
```
Internet
   │
   ▼
Apache (80/443) ── SSL via Certbot
   │
   ├── chat.chativot.com   → chatwoot-rails :3000
   ├── n8n.chativot.com    → n8n :5678
   ├── fzap.chativot.com   → fzap :8080
   ├── zabbix.chativot.com → zabbix-web :8081
   └── bd.chativot.com     → pgadmin :5050

Base de datos: PostgreSQL (pgvector:pg16)
  ├── chatwoot
  ├── n8n
  ├── fzap
  └── zabbix

Cache / Colas: Redis 7
```

---

## 📦 Stack Tecnológico

| Componente | Imagen | Versión |
|-----------|--------|---------|
| Chatwoot | chatwoot/chatwoot | v4.11.2 |
| n8n | n8nio/n8n | latest |
| Fzap | dncarbonell/fzap | latest |
| PostgreSQL | pgvector/pgvector | pg16 |
| Redis | redis | 7-alpine |
| Apache | httpd | 2.4-alpine |
| Zabbix Server | zabbix/zabbix-server-pgsql | latest |
| Zabbix Web | zabbix/zabbix-web-nginx-pgsql | latest |
| pgAdmin | dpage/pgadmin4 | latest |
| RedisInsight | redis/redisinsight | latest |
| Certbot | certbot/certbot | latest |

---

## 🗂️ Estructura del Repositorio
```
Chativot/
│
├── docker-compose.yml              # Stack principal de producción
├── docker-compose.prod.yml         # Overrides específicos de producción
├── .env.example                    # Plantilla de variables de entorno
│
├── scripts/                        # Todos los scripts operacionales
│   ├── install.sh                  # Instalación desde cero en servidor nuevo
│   ├── apply-branding.sh           # Aplica branding Chativot sobre Chatwoot
│   ├── backup_diario.sh            # Backup automático diario (cron)
│   ├── sellar_docker.sh            # Sella puertos Docker a 127.0.0.1
│   ├── blindar_firewall.sh         # Configura iptables (solo 22/80/443)
│   ├── 01_exportar_produccion.sh   # Exporta prod completo para clonar a dev
│   ├── 04_sincronizar_dev_a_prod.sh# Sincroniza workflows dev → prod
│   └── extraer_arquitectura_total.sh # Genera reporte completo del servidor
│
├── docs/
│   ├── arquitectura.md             # Documentación técnica de la arquitectura
│   └── scripts/                   # Documentación detallada de cada script
│       ├── install.md
│       ├── apply-branding.md
│       ├── backup_diario.md
│       ├── sellar_docker.md
│       ├── blindar_firewall.md
│       ├── 01_exportar_produccion.md
│       ├── 04_sincronizar_dev_a_prod.md
│       └── extraer_arquitectura_total.md
│
└── clientes/
    └── plantilla/
        ├── onboarding-checklist.md # Checklist completo de activación por cliente
        └── docker-compose.yml      # Plantilla base para nuevos clientes
```

---

## 📋 Scripts — Referencia Rápida

> Documentación completa de cada script en [`/docs/scripts/`](./docs/scripts/)

### 🚀 `install.sh`
Instalación completa del stack en un servidor Ubuntu nuevo desde cero.
Instala Docker, genera claves, configura SSL y levanta todos los servicios.
**→ [Ver documentación completa](./docs/scripts/install.md)**

---

### 🎨 `apply-branding.sh`
Aplica el branding visual de Chativot (logo, favicons, JS personalizados) sobre
el contenedor de Chatwoot. Debe ejecutarse después de cada recreación del contenedor.
**→ [Ver documentación completa](./docs/scripts/apply-branding.md)**

---

### 💾 `backup_diario.sh`
Backup automático diario: dump de PostgreSQL y volúmenes críticos.
Se ejecuta vía cron. También puede ejecutarse manualmente.
**→ [Ver documentación completa](./docs/scripts/backup_diario.md)**

---

### 🔒 `sellar_docker.sh`
Modifica todos los `docker-compose.yml` para que los puertos solo escuchen
en `127.0.0.1` y no queden expuestos públicamente. Idempotente.
**→ [Ver documentación completa](./docs/scripts/sellar_docker.md)**

---

### 🛡️ `blindar_firewall.sh`
Configura `iptables` dejando accesibles únicamente los puertos 22, 80 y 443.
Usa `netfilter-persistent` para que las reglas sobrevivan reinicios.
**→ [Ver documentación completa](./docs/scripts/blindar_firewall.md)**

---

### 📦 `01_exportar_produccion.sh`
Exporta el stack completo de producción: imágenes Docker, dump de PostgreSQL
y volúmenes. Genera un directorio listo para transferir a desarrollo.
**→ [Ver documentación completa](./docs/scripts/01_exportar_produccion.md)**

---

### 🔄 `04_sincronizar_dev_a_prod.sh`
Copia datos no críticos (workflows n8n, config Fzap) desde el servidor de
desarrollo hacia producción. No toca conversaciones ni datos de clientes.
**→ [Ver documentación completa](./docs/scripts/04_sincronizar_dev_a_prod.md)**

---

### 📋 `extraer_arquitectura_total.sh`
Genera un reporte Markdown completo del estado del servidor: hardware, red,
firewall, Docker, Apache y configuraciones. Útil para auditoría y documentación.
**→ [Ver documentación completa](./docs/scripts/extraer_arquitectura_total.md)**

---

## 👥 Onboarding de Nuevos Clientes

El proceso completo de activación de un nuevo cliente está documentado en:

**[`/clientes/plantilla/onboarding-checklist.md`](./clientes/plantilla/onboarding-checklist.md)**

Cubre las siguientes fases:
1. **Chatwoot** — Crear cuenta y usuario administrador vía Super Admin
2. **Fzap** — Crear carpeta, token e instancia QR de WhatsApp
3. **n8n** — Crear carpeta y workflows de automatización CRM
4. **PostgreSQL** — Crear base de datos `n8n_[cliente]` con tablas requeridas
5. **WhatsApp Meta Business API** — Pasos para certificación y conexión oficial (opcional)
6. **Verificación y entrega** — Checklist final y credenciales al cliente

---

## ⚙️ Variables de Entorno

Copiar `.env.example` a `.env` y completar todos los valores antes de instalar:
```bash
cp .env.example .env
nano .env
```

Variables requeridas:
- `POSTGRES_USER` / `POSTGRES_PASSWORD`
- `CHATWOOT_SECRET_KEY_BASE` — generada automáticamente por `install.sh`
- `DOMAIN_CHAT` / `DOMAIN_N8N` / etc.
- `N8N_ENCRYPTION_KEY` — generada automáticamente por `install.sh`
- `REDIS_PASSWORD`
- Credenciales SMTP para emails de Chatwoot

> ⚠️ Nunca subir el archivo `.env` al repositorio. Está en `.gitignore`.

---

## 🚀 Instalación en Servidor Nuevo
```bash
# 1. Clonar el repositorio
git clone https://github.com/IvoTalents-Official/Chativot.git /opt/chativot
cd /opt/chativot

# 2. Configurar variables de entorno
cp .env.example .env
nano .env

# 3. Ejecutar instalación
bash scripts/install.sh
```

> Prerrequisito: Los DNS de todos los subdominios deben apuntar a la IP del servidor antes de ejecutar.

---

## 🔧 Comandos Útiles
```bash
# Ver estado de todos los contenedores
docker compose ps

# Ver logs de un servicio
docker compose logs -f chatwoot-rails

# Reiniciar un servicio
docker compose restart apache

# Acceder a PostgreSQL
docker exec -it postgres psql -U postgres

# Aplicar branding después de reiniciar Chatwoot
bash /opt/chativot/scripts/apply-branding.sh
```

---

## 📊 Volúmenes Docker

| Volumen | Contenido |
|---------|-----------|
| `postgres_data` | Datos PostgreSQL (todos los clientes) |
| `redis_data` | Datos Redis |
| `chatwoot_storage` | Adjuntos y archivos de Chatwoot |
| `n8n_data` | Flujos y configuración n8n |
| `fzap_data` | Datos de Fzap |
| `fzap_instances` | Instancias WhatsApp activas |
| `pgadmin_data` | Configuración pgAdmin |
| `zabbix_server_data` | Datos Zabbix |
| `certbot_certs` | Certificados SSL |
| `certbot_html` | Challenge Certbot |

---

## 🌍 DNS Requeridos (Cloudflare)

### Producción — Proxy Cloudflare **Activado** 🟠

| Subdominio | Tipo | Proxy |
|-----------|------|-------|
| chat.chativot.com | A → IP servidor | 🟠 Activado |
| n8n.chativot.com | A → IP servidor | 🟠 Activado |
| fzap.chativot.com | A → IP servidor | 🟠 Activado |
| zabbix.chativot.com | A → IP servidor | 🟠 Activado |
| bd.chativot.com | A → IP servidor | 🟠 Activado |

### Desarrollo — Proxy Cloudflare **Activado** 🟠

| Subdominio | Tipo | Proxy |
|-----------|------|-------|
| chatdev.chativot.com | A → IP servidor dev | 🟠 Activado |
| n8ndev.chativot.com | A → IP servidor dev | 🟠 Activado |
| fzapdev.chativot.com | A → IP servidor dev | 🟠 Activado |
| zabbixdev.chativot.com | A → IP servidor dev | 🟠 Activado |
| bddev.chativot.com | A → IP servidor dev | 🟠 Activado |

---

*Chativot — Plataforma White-Label · IvoTalents*
