# Control de Cambios — Actualización Chatwoot
**Código:** POL-OPS-CCM-2026-002  
**Fecha:** 07 de Abril de 2026  
**Responsable:** Rodrigo González — Administrador de Infraestructura  
**Clasificación:** Interno - Confidencial  

---

## 1. Objetivo
Documentar la actualización de la plataforma de atención al cliente Chatwoot desde la versión **v4.11.2** a la versión **v4.12.1**, ejecutada en los servidores de desarrollo y producción de la plataforma Chativot, garantizando la continuidad operativa y la integridad de los datos.

---

## 2. Información del Cambio

| Parámetro | Detalle |
|-----------|---------|
| Componente | Chatwoot — Plataforma de atención al cliente |
| Imagen Docker | chatwoot/chatwoot |
| Versión anterior | v4.11.2 |
| Versión nueva | v4.12.1 |
| Stack | Docker Compose — /opt/chativot |
| Servicios afectados | chatwoot-rails, chatwoot-sidekiq |
| Volumen de datos | chativot_chatwoot_storage |
| Base de datos | PostgreSQL (chatwoot) |
| Puerto | 127.0.0.1:3000 |
| Fecha ejecución | 07 de Abril de 2026 |

---

## 3. Backup Previo — Producción

Antes de ejecutar la actualización se generaron los siguientes respaldos en el servidor de producción:

```bash
# Dump base de datos chatwoot
docker exec postgres bash -c \
  "PGPASSWORD='***' pg_dump -U chatwoot --format=custom --compress=9 chatwoot" \
  > /opt/backups/chatwoot/chatwoot_db_20260407_025933.dump

# Backup volumen storage
docker run --rm \
  -v chativot_chatwoot_storage:/source:ro \
  -v /opt/backups/chatwoot:/backup \
  alpine tar czf /backup/chatwoot_storage_20260407_025934.tar.gz -C /source .

# Backup configuración
tar czf /opt/backups/chatwoot/config_20260407_030022.tar.gz \
  -C /opt/chativot docker-compose.yml .env
```

| Archivo | Tamaño |
|---------|--------|
| chatwoot_db_20260407_025933.dump | 4.7 MB |
| chatwoot_storage_20260407_025934.tar.gz | 769 MB |
| config_20260407_030022.tar.gz | 2.9 KB |

---

## 4. Procedimiento Ejecutado

### 4.1 Servidor de Desarrollo (root@dev)

**Actualización de imagen:**
```bash
cd /opt/chativot
sed -i 's|chatwoot/chatwoot:v4.11.2|chatwoot/chatwoot:v4.12.1|g' docker-compose.yml
grep "chatwoot/chatwoot" docker-compose.yml
# → image: chatwoot/chatwoot:v4.12.1 (x2)
```

**Aplicar actualización:**
```bash
docker compose pull chatwoot-rails chatwoot-sidekiq
docker compose up -d --no-deps chatwoot-rails chatwoot-sidekiq
```

**Resultado DEV:** ✅ Exitoso — v4.12.1 activa.

---

### 4.2 Servidor de Producción (32.193.7.26)

**Actualización de imagen:**
```bash
cd /opt/chativot
sed -i 's|chatwoot/chatwoot:v4.11.2|chatwoot/chatwoot:v4.12.1|g' docker-compose.yml
```

**Aplicar actualización:**
```bash
docker compose pull chatwoot-rails chatwoot-sidekiq
docker compose up -d --no-deps chatwoot-rails chatwoot-sidekiq
sleep 20
docker compose ps chatwoot-rails chatwoot-sidekiq
docker logs chatwoot-rails --tail=20
```

**Resultado PROD:** ✅ Exitoso — v4.12.1 activa, Rails 7.1.5.2 en producción.

---

## 5. Cambios Adicionales Aplicados

Durante la actualización se aplicaron los siguientes cambios al docker-compose.yml:

| Cambio | Detalle |
|--------|---------|
| Eliminación de variable | `INSTALLATION_ENV: self_hosted` removida de ambos servicios |
| Nuevo volumen | `/root/chatwoot_hub.rb:/app/lib/chatwoot_hub.rb` agregado en chatwoot-rails y chatwoot-sidekiq |

**Motivo:** Adecuación del entorno de ejecución y configuración del hub personalizado de Chativot.

---

## 6. Automatización de Backup

Se instaló script de backup automatizado en producción:

```bash
# Script: /opt/chativot/scripts/backup-chatwoot.sh
# Cron: 0 3 * * * (03:00 AM diario)
# Retención: últimos 7 backups
# Ubicación: /opt/backups/chatwoot/
```

El script realiza automáticamente:
- Dump PostgreSQL base de datos chatwoot
- Backup volumen chatwoot_storage
- Backup docker-compose.yml y .env

---

## 7. Resultado Final

| Entorno | Versión Anterior | Versión Nueva | Estado |
|---------|-----------------|---------------|--------|
| DEV | v4.11.2 | v4.12.1 | ✅ OK |
| PROD | v4.11.2 | v4.12.1 | ✅ OK |

- Backup producción: `/opt/backups/chatwoot/` (774 MB total)
- Datos: íntegros, sin pérdida de conversaciones ni contactos
- Tiempo de inactividad: < 2 minutos por entorno

---

## 8. Observaciones

- El warning `version is obsolete` en docker-compose.yml es cosmético y no afecta la operación.
- Se recomienda eliminar la línea `version:` del compose en próxima mantención planificada.
- El script de backup diario reemplaza al backup_diario.sh previo para el componente Chatwoot.

---

**Elaborado por:** Rodrigo González — Administrador de Infraestructura  
**Empresa:** Chativot  
**Fecha:** 07 de Abril de 2026
