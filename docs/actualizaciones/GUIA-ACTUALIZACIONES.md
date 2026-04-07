# Guía de Actualización — n8n y Chatwoot
**Plataforma:** Chativot — /opt/chativot  
**Fecha:** 07 de Abril de 2026  
**Responsable:** Rodrigo González  

---

## Scripts disponibles

| Script | Componente | Ubicación en servidor |
|--------|------------|-----------------------|
| `update-n8n.sh` | Motor de automatización n8n | `/opt/chativot/scripts/update-n8n.sh` |
| `update-chatwoot.sh` | Plataforma de atención Chatwoot | `/opt/chativot/scripts/update-chatwoot.sh` |

---

## Instalación (una sola vez)

Copia los scripts al servidor y dales permisos:

```bash
# En el servidor (DEV o PROD)
chmod +x /opt/chativot/scripts/update-n8n.sh
chmod +x /opt/chativot/scripts/update-chatwoot.sh
```

---

## update-n8n.sh

### ¿Qué hace?

1. **Verifica** que el contenedor n8n está corriendo
2. **Determina** la versión objetivo (manual o automática desde GitHub)
3. **Genera backup** del volumen `chativot_n8n_data` en `/opt/backups/n8n/`
4. **Verifica** que el backup tiene contenido real (no está vacío)
5. **Actualiza** la imagen en `docker-compose.yml` y recrea el contenedor
6. **Verifica** que la nueva versión quedó activa
7. **Rollback automático** si la verificación falla

### ¿Cuándo ejecutarlo?

- Cuando n8n publica una nueva versión estable
- Cuando se detecta una vulnerabilidad en la versión activa
- Como parte del mantenimiento mensual planificado
- **No ejecutar** en horario peak (09:00–18:00) sin coordinación previa

### ¿Cómo ejecutarlo?

**Opción A — Versión automática (última estable desde GitHub):**
```bash
bash /opt/chativot/scripts/update-n8n.sh
```

**Opción B — Versión específica:**
```bash
bash /opt/chativot/scripts/update-n8n.sh 2.15.0
```

**El script preguntará confirmación antes de proceder:**
```
  Versión actual : 2.14.2
  Versión nueva  : 2.15.0

  ¿Confirmas la actualización? (s/N):
```

### Backups generados

```
/opt/backups/n8n/
├── n8n_backup_v2.14.2_20260407_030000.tar.gz   ← volumen completo
└── update.log                                    ← historial de actualizaciones
```

### Rollback manual (si es necesario después)

```bash
# Ver backups disponibles
ls -lh /opt/backups/n8n/

# Restaurar volumen desde backup
cd /opt/chativot
docker compose stop n8n
docker run --rm \
  -v chativot_n8n_data:/target \
  -v /opt/backups/n8n:/backup \
  alpine tar xzf /backup/n8n_backup_v2.14.2_FECHA.tar.gz -C /target
docker compose up -d --no-deps n8n
docker exec n8n n8n --version
```

---

## update-chatwoot.sh

### ¿Qué hace?

1. **Verifica** que los contenedores `chatwoot-rails` y `chatwoot-sidekiq` están corriendo
2. **Solicita** la versión objetivo (manual — Chatwoot no tiene API pública de releases)
3. **Genera backup** de 3 elementos:
   - Dump PostgreSQL de la base de datos `chatwoot`
   - Volumen `chativot_chatwoot_storage` (archivos adjuntos, avatares)
   - `docker-compose.yml` y `.env`
4. **Verifica** que cada backup tiene contenido real
5. **Actualiza** la imagen en `docker-compose.yml` y recrea ambos contenedores
6. **Verifica** que la nueva versión quedó activa y el contenedor responde
7. **Reaaplica el branding** automáticamente (si existe `apply-branding.sh`)
8. **Rollback automático** si la verificación falla

### ¿Cuándo ejecutarlo?

- Cuando Chatwoot publica una nueva versión en https://github.com/chatwoot/chatwoot/releases
- Cuando se detecta una vulnerabilidad crítica en la versión activa
- Como parte del mantenimiento mensual planificado
- **Preferiblemente** entre 00:00–06:00 AM para minimizar impacto
- **Siempre en DEV primero** — verificar que funciona antes de aplicar en PROD

### ¿Cómo ejecutarlo?

**Paso 1 — Verificar la nueva versión disponible:**
```
https://github.com/chatwoot/chatwoot/releases
```

**Paso 2 — Ejecutar primero en DEV:**
```bash
ssh root@<IP_DEV>
bash /opt/chativot/scripts/update-chatwoot.sh v4.13.0
```

**Paso 3 — Si DEV quedó bien, ejecutar en PROD:**
```bash
ssh root@32.193.7.26
bash /opt/chativot/scripts/update-chatwoot.sh v4.13.0
```

**El script pedirá confirmación y mostrará el resumen de backups antes de proceder:**
```
  Versión actual : v4.12.1
  Versión nueva  : v4.13.0

  ¿Confirmas la actualización? (s/N): s

  Resumen de backups:
  • BD:      4.8 MB
  • Storage: 770 MB
  • Config:  OK
```

### Backups generados

```
/opt/backups/chatwoot/
├── chatwoot_db_v4.12.1_20260407_030000.dump        ← dump PostgreSQL
├── chatwoot_storage_v4.12.1_20260407_030000.tar.gz ← archivos adjuntos
├── config_v4.12.1_20260407_030000.tar.gz           ← compose + .env
└── update.log                                       ← historial de actualizaciones
```

### Rollback manual (si es necesario después)

```bash
# Ver backups disponibles
ls -lh /opt/backups/chatwoot/

# 1. Detener Chatwoot
cd /opt/chativot
docker compose stop chatwoot-rails chatwoot-sidekiq

# 2. Restaurar BD
docker exec postgres psql -U postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='chatwoot';"
docker exec postgres psql -U postgres -c "DROP DATABASE chatwoot;"
docker exec postgres psql -U postgres -c "CREATE DATABASE chatwoot OWNER chatwoot;"
docker cp /opt/backups/chatwoot/chatwoot_db_v4.12.1_FECHA.dump postgres:/tmp/restore.dump
docker exec postgres bash -c \
  "PGPASSWORD='ce43bf12c249' pg_restore -U chatwoot --dbname=chatwoot --no-owner /tmp/restore.dump"

# 3. Restaurar storage
docker run --rm \
  -v chativot_chatwoot_storage:/target \
  -v /opt/backups/chatwoot:/backup \
  alpine sh -c "rm -rf /target/* && tar xzf /backup/chatwoot_storage_v4.12.1_FECHA.tar.gz -C /target"

# 4. Revertir imagen en compose
sed -i 's|chatwoot/chatwoot:.*|chatwoot/chatwoot:v4.12.1|g' docker-compose.yml

# 5. Reiniciar
docker compose up -d --no-deps chatwoot-rails chatwoot-sidekiq
```

---

## Flujo recomendado para ambos scripts

```
1. Revisar releases disponibles
         ↓
2. Ejecutar en DEV
         ↓
3. Verificar funcionalidad en DEV (10-15 min)
         ↓
4. Si DEV OK → Ejecutar en PROD
         ↓
5. Verificar funcionalidad en PROD
         ↓
6. Guardar log de actualización
```

---

## Historial de actualizaciones

Los scripts registran automáticamente cada ejecución en sus respectivos logs:

```bash
# Ver historial n8n
cat /opt/backups/n8n/update.log

# Ver historial Chatwoot
cat /opt/backups/chatwoot/update.log
```

**Ejemplo de entrada en log:**
```
2026-04-07 03:00:00 | ÉXITO | 2.11.4 → 2.14.2 | Backup: /opt/backups/n8n/n8n_backup_v2.11.4_20260407.tar.gz
2026-04-07 03:15:00 | ÉXITO | v4.11.2 → v4.12.1 | DB: /opt/backups/chatwoot/chatwoot_db_v4.11.2_20260407.dump
```

---

**Elaborado por:** Rodrigo González — Administrador de Infraestructura  
**Empresa:** Chativot  
**Fecha:** 07 de Abril de 2026
