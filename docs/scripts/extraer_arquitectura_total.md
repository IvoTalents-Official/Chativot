# 📋 `extraer_arquitectura_total.sh`

**Ubicación:** `/opt/chativot/scripts/extraer_arquitectura_total.sh`
**Ejecutar en:** Servidor de **PRODUCCIÓN** como `root`

## ¿Qué hace?
Genera un reporte completo del estado del servidor en `/root/architecture_total.md`:
- Sistema operativo, CPU, memoria, disco
- Red e IPs
- Reglas de firewall (iptables)
- Auditoría de paquetes con actualizaciones pendientes
- Todos los contenedores, redes, volúmenes e imágenes Docker
- Configuración de Apache (Virtual Hosts)
- Archivos docker-compose.yml (sin contraseñas)

## ¿Cuándo ejecutarlo?
- Antes de una migración o cambio importante
- Para documentar el estado actual del servidor
- Para auditoría o diagnóstico

## Cómo ejecutarlo
```bash
bash /opt/chativot/scripts/extraer_arquitectura_total.sh
# El reporte queda en: /root/architecture_total.md
cat /root/architecture_total.md
```
