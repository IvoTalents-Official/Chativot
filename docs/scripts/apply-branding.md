# 🎨 `apply-branding.sh`

**Ubicación:** `/opt/chativot/apply-branding.sh`
**Ejecutar en:** Servidor de **PRODUCCIÓN** como `root`

## ¿Qué hace?
Aplica el branding visual de Chativot sobre los archivos de Chatwoot:

1. Espera a que el contenedor `chatwoot-rails` esté listo
2. Copia el logo `Chativot.png` como brand asset
3. Reemplaza archivos JS compilados con versiones personalizadas (íconos del dashboard)
4. Copia los favicons de Chativot (16, 32, 96, 512px, apple)

Los archivos fuente están en `/opt/chativot/chatwoot-custom/`

## ¿Cuándo ejecutarlo?
- Después de cada `docker compose up -d` o reinicio del contenedor `chatwoot-rails`
  porque los archivos se pierden al recrear el contenedor
- Después de actualizar la versión de Chatwoot
- Si el branding desaparece visualmente en la interfaz

## Cómo ejecutarlo
```bash
bash /opt/chativot/apply-branding.sh
```

## ⚠️ Advertencias
- El script tiene un `sleep 15` inicial + loop de espera — puede tardar 1-2 minutos
- Si se actualiza Chatwoot a una nueva versión, los archivos JS personalizados
  (`DashboardIcon-2tevt9IJ.js`, `v3app-DdPZtMec.js`) pueden cambiar de nombre
  → Verificar nombres actuales en `/app/public/vite/assets/` antes de aplicar
- El log de aplicaciones queda en: `/opt/chativot/branding.log`

## Automatización recomendada
Para que el branding se aplique automáticamente al reiniciar:
```bash
# Agregar al crontab:
@reboot sleep 30 && bash /opt/chativot/apply-branding.sh
```
