# 🚀 `install.sh`

**Ubicación:** `/opt/chativot/install.sh`
**Ejecutar en:** Servidor **nuevo/limpio** como `root`

## ¿Qué hace?
Instalación completa del stack Chativot desde cero en un servidor Ubuntu:

1. Actualiza el sistema e instala dependencias
2. Instala Docker y Docker Compose
3. Copia los archivos del proyecto a `/opt/chativot`
4. Genera claves secretas automáticamente (`CHATWOOT_SECRET_KEY_BASE`, `N8N_ENCRYPTION_KEY`)
5. Configura firewall UFW (puertos 22, 80, 443, 10051)
6. Levanta Apache temporal para obtener certificados SSL
7. Levanta todos los contenedores Docker
8. Obtiene certificados SSL con Certbot para los 5 dominios
9. Activa Apache con SSL y configura renovación automática (cron 3am diario)

## Dominios que configura
```
bd.chativot.com
chat.chativot.com
n8n.chativot.com
fzap.chativot.com
zabbix.chativot.com
```

## ¿Cuándo ejecutarlo?
- Al instalar Chativot en un servidor nuevo por primera vez
- **NUNCA** en un servidor que ya tiene el stack corriendo (sobreescribe configuración)

## Cómo ejecutarlo
```bash
# Desde la carpeta del repo:
cd /opt/chativot-repo
bash install.sh
```
Tiempo estimado: **10-20 minutos**

## Prerrequisitos
- Servidor Ubuntu 22.04 o 24.04 limpio
- Los 5 subdominios ya deben apuntar a la IP del servidor en Cloudflare (DNS propagado)
  → Verificar: `dig chat.chativot.com +short`
- El archivo `.env` debe estar completo antes de ejecutar
  → Copiar desde `.env.example` y completar todos los valores

## ⚠️ Advertencias
- Si algún dominio no tiene DNS propagado, el certificado SSL fallará (no es crítico, se puede obtener después manualmente)
- Las claves secretas se generan automáticamente y se guardan en `.env` — hacer backup inmediatamente después
- Zabbix usa credenciales por defecto `Admin / zabbix` — cambiar al primer acceso
- Chatwoot requiere crear el primer admin manualmente en https://chat.chativot.com/app/login

## Servicios que quedan corriendo al finalizar
| Servicio | URL |
|----------|-----|
| pgAdmin4 | https://bd.chativot.com |
| Chatwoot | https://chat.chativot.com |
| n8n | https://n8n.chativot.com |
| Fzap | https://fzap.chativot.com |
| Zabbix | https://zabbix.chativot.com |
