#!/bin/bash
FECHA=$(date +"%Y-%m-%d")
DIR_BACKUP="/opt/backups"
LOG_FILE="$DIR_BACKUP/backup_log.txt"
mkdir -p $DIR_BACKUP

echo "--- Iniciando respaldo: $FECHA ---" >> $LOG_FILE
docker exec postgres pg_dumpall -U postgres > $DIR_BACKUP/db_completa_$FECHA.sql
tar -czf $DIR_BACKUP/volumenes_docker_$FECHA.tar.gz /var/lib/docker/volumes/
find $DIR_BACKUP -type f -name "*.sql" -mtime +7 -delete
find $DIR_BACKUP -type f -name "*.tar.gz" -mtime +7 -delete
echo "Respaldo y limpieza completados." >> $LOG_FILE
