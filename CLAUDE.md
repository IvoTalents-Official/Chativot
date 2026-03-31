# CLAUDE.md - Contexto del Proyecto Chativot

## 📋 Información General

**Proyecto:** Chativot - Sistema de Gestión de Relaciones con el Cliente (CRM) y Chat Centralizado  
**Empresa:** ACM Four Company S.A. (Panamá)  
**Repositorio:** `IvoTalents-Official/Chativot` (privado)  
**Última actualización:** 2026-03-30

---

## 👥 Equipo

- **Andreina Marrón** - CEO/Founder (`andreina@ivotalents.com`)
- **Yunai Castillo** - COO (relaciones comerciales y clientes)
- **Rodrigo González** - Desarrollador/Programador (`devlocal2026` en GitHub)

---

## 🏗️ Arquitectura Técnica

### Stack Tecnológico Principal
- **Backend:** Chatwoot + n8n + PostgreSQL (con extensión pgvector)
- **Infraestructura:** Docker (12 contenedores)
- **Control de Versiones:** Git + GitHub
- **Automatización:** n8n workflows
- **Base de Datos:** PostgreSQL con pgvector (embeddings)
- **Cache:** Redis
- **Proxy Reverso:** Apache
- **Certificados SSL:** Let's Encrypt (Certbot)
- **Monitoreo:** Zabbix

### Contenedores Docker (12 total)
1. Chatwoot (app principal)
2. Chatwoot-sidekiq (workers)
3. n8n (automatización)
4. PostgreSQL (base de datos)
5. Redis (cache)
6. fzap (WhatsApp Business API)
7. Apache (proxy reverso)
8. Certbot (certificados SSL)
9. pgAdmin (administración PostgreSQL)
10. RedisInsight (administración Redis)
11. Zabbix-server (monitoreo)
12. Zabbix-web (interfaz monitoreo)

---

## 🖥️ Infraestructura de Servidores

### Servidor de Producción
- **Proveedor:** AWS Lightsail
- **IP:** `32.193.7.26`
- **Acceso SSH:** `ssh -i ~/.ssh/andreina.pem ubuntu@32.193.7.26`
- **Alias SSH:** `chativot-produccion` (en `~/.ssh/config`)
- **Snapshots:** Diarios a las 3AM UTC-5, retención 7 días

### Servidor de Desarrollo
- **Proveedor:** Hetzner
- **Plan:** CX33
- **IP:** `89.167.98.137`
- **Hostname:** `chativotdev`
- **Specs:** Ubuntu 24.04, 16 CPU AMD EPYC, 30GB RAM, 75GB disco
- **UFW activo:** Puertos 22/80/443 públicos; 5050/5678/5540/8081/3000/10051 restringidos a VPN IP `190.153.6.33`

### Dominios y Subdominios
- **chat.chativot.com** - Chatwoot SuperAdmin
- **fzap.chativot.com** - WhatsApp Business API
- **n8n.chativot.com** - n8n (producción)
- **n8n DEV:** Puerto 5678 en Hetzner (dominio HTTPS pendiente)

---

## 📁 Estructura del Repositorio
```
Chativot/
├── clientes/
│   └── plantilla/          # Template para nuevos clientes
├── documentos/             # Documentación técnica y specs
├── guiones/               # Scripts de shell (bash)
├── scripts/               # Scripts centralizados
├── docs/                  # Documentación adicional
├── .env.ejemplo           # Template de variables de entorno
├── .gitignore
├── CLAUDE.md             # Este archivo
├── LÉAME.md              # README principal
├── docker-compose.yml    # Desarrollo
└── docker-compose.prod.yml # Producción
```

**Ubicación en servidor:** `/opt/chativot/`

---

## 🔄 Flujo de Trabajo Git

### Estructura de Ramas
- **`main`** - Rama principal protegida (producción)
- **`dev`** - Rama de desarrollo (Rodrigo trabaja aquí)

### Workflow de Desarrollo
1. Rodrigo trabaja en rama `dev`
2. Commits con mensajes descriptivos siguiendo convenciones
3. Pull Request de `dev` → `main`
4. Andreina revisa y aprueba PR
5. Merge a `main`
6. Deploy a producción

**⚠️ Rodrigo NUNCA debe hacer commit directo a `main`**

### Configuración Git de Andreina
```bash
git config user.name "Andreina Marron"
git config user.email "andreina@ivotalents.com"
```

---

## 🔐 Seguridad y Credenciales

### Gestor de Contraseñas
- **Sistema:** 1Password (cuenta activa)
- **Incluye:** Credenciales de servidores, bases de datos, APIs, servicios

### Hallazgos de Seguridad Activos
- **C-01 (CRÍTICO):** Password compartido en 6 servicios DB - pendiente remediar
- **C-02:** Credenciales Zabbix por defecto - remediado
- **C-03:** RedisInsight expuesto públicamente - remediado

### Buenas Prácticas
- IPs de servidores en 1Password y Obsidian únicamente
- No commitear credenciales reales al repo
- Usar placeholders tipo `[IP_SERVIDOR_DEV]` en docs públicas
- UFW configurado en DEV, pendiente replicar en producción

---

## 🤖 Integraciones n8n

### Instancias Activas
1. **n8n Chativot (Producción):** `n8n.chativot.com`
   - Workflows: `Sub | Escalar Agente`, `Agente IA Ventas Imagen`, `ErrorChatIvot`
2. **n8n Ivomation (Naity9 - Legacy):** `ivomation.naity9.com`
   - Sistema heredado de Ivo Talents
   - Plan: Migrar a Chativot white-label

### MCP Servers Configurados
- `n8n-mcp` → `n8n.chativot.com`
- `n8n-ivotalents-naity9` → `ivomation.naity9.com` (JWT token en 1Password)

---

## 👤 Clientes Activos

### TuentradaWeb (Cliente #1)
- **Estado:** Presale activa
- **Integración:** WhatsApp Business API + OCR + Laravel webhook
- **Funcionalidad:** Bot de confirmación de pagos Zelle/Binance
- **Webhook producción:** `32.193.7.26` (AWS Lightsail)
- **Spec técnica:** `integration-whatsapp-chatwoot-chativot.md`

### ChatIvo (Próximo Cliente)
- **Empresa:** Ivo Talents
- **Tipo:** White-label Chativot
- **Estado:** Pendiente provisionar

---

## 🛠️ Desarrollo Local (Claude Code)

### Configuración Claude Code
- **Cuenta:** `amarron69@gmail.com` (Claude Pro)
- **VPN requerida:** Hide.me (servidor US/Europe) para acceder a `api.anthropic.com`
- **Skills instalados:** Ver `~/.agents/skills/` y `~/Visual Studis/.agents/skills/`
- **Vault Obsidian:** `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Brain/`

### Skills Activos
- `double-shot-latte`, `superpowers`, `episodic-memory`, `superpowers-chrome`
- `customer-escalation` (formateo de escalaciones P0-P3)
- `excalidraw-diagram-skill`
- Firecrawl skills (7 aprobados, `firecrawl-browser` deshabilitado por Snyk)

---

## 📝 Convenciones y Estándares

### Commits
- Formato: `tipo: descripción breve`
- Tipos: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `security`
- Ejemplo: `feat: agregar integración WhatsApp para TuentradaWeb`

### Documentación
- Usar Markdown para toda la documentación
- Incluir diagramas en Miro cuando aplique
- Especificaciones técnicas en carpeta `documentos/`

### Scripts
- Scripts de shell en carpeta `guiones/`
- Comentarios de cabecera internos con propósito y autor
- Permisos ejecutables: `chmod +x script.sh`

---

## 🚀 Despliegue y Mantenimiento

### Actualizaciones de Seguridad
- **DEV (Hetzner):** `apt update && apt upgrade` aplicado, reiniciado, snapshots OK
- **PRODUCCIÓN (AWS):** Pendiente aplicar mismo proceso

### Backups
- **Hetzner:** Snapshots automáticos activos (~$1.20/mes adicional)
- **AWS:** Snapshots diarios configurados

### Monitoreo
- Zabbix operativo (propósito original: monitoreo proxy Webshare para QR WhatsApp - ahora obsoleto con API oficial)

---

## 🔗 Enlaces Importantes

- **Repo GitHub:** `https://github.com/IvoTalents-Official/Chativot`
- **Obsidian Vault:** `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Brain/`
- **Proyectos locales:** `~/proyectos/`

---

## 📞 Canales de Comunicación

- **Email trabajo:** `andreina@ivotalents.com`
- **Email personal/Claude:** `amarron69@gmail.com`
- **Slack:** Canal `#desarrollo` (C0AKYTDL7T4), `#backend` (C0AL489N494)
- **GitHub:** Notificaciones integradas a Slack

---

## ⚠️ Recordatorios Pendientes

- [x] Replicar configuración UFW en AWS Lightsail producción
- [x] Rodrigo: Configurar dominio + HTTPS para n8n Hetzner DEV
- [x] Rodrigo: Crear `variables-cliente.md` No aplica: gestión de clientes es 100% vía GUI`
- [x] Rodrigo: Agregar headers de comentarios internos en scripts `guiones/`
- [ ] Andreina: Template de Change Management en Obsidian
- [x] Activar backups automáticos en Hetzner DEV
- [ ] Remediar hallazgo C-01 (password compartido en 6 servicios) - Pendiente 

---

**Última revisión:** 2026-03-30 por Andreina Marrón
