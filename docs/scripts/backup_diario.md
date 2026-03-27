# 💾 `backup_diario.sh`

**Ubicación:** `/opt/chativot/scripts/backup_diario.sh`
**Ejecutar en:** Servidor de **PRODUCCIÓN** como `root`

## ¿Qué hace?
Realiza backup automático diario del stack Chativot:
dump de PostgreSQL y volúmenes críticos. Se ejecuta vía cron.

## ¿Cuándo ejecutarlo?
- Se ejecuta automáticamente vía cron (ver configuración en el script)
- Se puede ejecutar manualmente si se necesita un backup puntual

## Cómo ejecutarlo manualmente
```bash
bash /opt/chativot/scripts/backup_diario.sh
```

## ⚠️ Advertencias
- Verificar espacio disponible antes de ejecutar: `df -h`
- Los backups contienen datos reales de clientes — manejar con confidencialidad
