# Control de Cambios — Actualización n8n
**Código:** POL-OPS-CCM-2026-001  
**Fecha:** 07 de Abril de 2026  
**Responsable:** Rodrigo González — Administrador de Infraestructura  
**Clasificación:** Interno - Confidencial  

---

## 1. Objetivo
Documentar la actualización del motor de automatización n8n desde la versión **2.11.4** a la versión **2.14.2**, ejecutada en los servidores de desarrollo y producción de la plataforma Chativot.

---

## 2. Información del Cambio

| Parámetro | Detalle |
|-----------|---------|
| Componente | n8n — Motor de automatización |
| Imagen Docker | n8nio/n8n |
| Versión anterior | 2.11.4 |
| Versión nueva | 2.14.2 |
| Stack | Docker Compose — /opt/chativot |
| Volumen de datos | chativot_n8n_data |
| Base de datos | PostgreSQL |
| Puerto | 127.0.0.1:5678 |
| Fecha ejecución | 07 de Abril de 2026 |

---

## 3. Procedimiento Ejecutado

### 3.1 Servidor de Desarrollo (root@dev)

**Verificación previa:**
```bash
docker ps | grep n8n
docker exec n8n n8n --version   # → 2.11.4
docker inspect n8n | grep "com.docker.compose.project.working_dir"
# → /opt/chativot
```

**Backup del volumen:**
```bash
mkdir -p /opt/backups
docker run --rm \
  -v chativot_n8n_data:/source:ro \
  -v /opt/backups:/backup \
  alpine tar czf /backup/n8n_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /source .
```

**Actualización de imagen:**
```bash
cd /opt/chativot
sed -i 's|n8nio/n8n:latest|n8nio/n8n:2.14.2|g' docker-compose.yml
docker compose pull n8n
docker compose up -d --no-deps n8n
```

**Verificación:**
```bash
docker exec n8n n8n --version   # → 2.14.2
docker compose ps n8n
docker logs n8n --tail=30
```

**Resultado DEV:** ✅ Exitoso — v2.14.2 activa, migraciones aplicadas, workflows intactos.

---

### 3.2 Servidor de Producción (32.193.7.26)

**Verificación previa:**
```bash
docker exec n8n n8n --version   # → 2.11.4
```

**Backup del volumen:**
```bash
mkdir -p /opt/backups
docker run --rm \
  -v chativot_n8n_data:/source:ro \
  -v /opt/backups:/backup \
  alpine tar czf /backup/n8n_prod_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /source .
```

**Actualización:**
```bash
cd /opt/chativot
sed -i 's|n8nio/n8n:latest|n8nio/n8n:2.14.2|g' docker-compose.yml
docker compose pull n8n
docker compose up -d --no-deps n8n
```

**Verificación:**
```bash
docker exec n8n n8n --version   # → 2.14.2
```

**Resultado PROD:** ✅ Exitoso — v2.14.2 activa, migraciones de BD aplicadas automáticamente.

---

## 4. Migraciones de Base de Datos Aplicadas

Las siguientes migraciones fueron ejecutadas automáticamente durante el inicio:

| Migración | Estado |
|-----------|--------|
| AddFilesColumnToChatHubAgents1771500000002 | ✅ Completada |
| AddSuggestedPromptsToAgentTable1772000000000 | ✅ Completada |
| AddRoleColumnToProjectSecretsProviderAccess1772619247761 | ✅ Completada |
| ChangeWorkflowPublishedVersionFKsToRestrict1772619247762 | ✅ Completada |
| AddTypeToChatHubSessions1772700000000 | ✅ Completada |
| CreateCredentialDependencyTable1773000000000 | ✅ Completada |

---

## 5. Resultado Final

| Entorno | Versión Anterior | Versión Nueva | Estado |
|---------|-----------------|---------------|--------|
| DEV | 2.11.4 | 2.14.2 | ✅ OK |
| PROD | 2.11.4 | 2.14.2 | ✅ OK |

- Backup volúmenes: `/opt/backups/`
- Datos: íntegros, sin pérdida de información
- Workflows: conservados en base de datos PostgreSQL
- Tiempo de inactividad: < 1 minuto por entorno

---

## 6. Observaciones

- El warning `version is obsolete` en docker-compose.yml es cosmético y no afecta la operación.
- El aviso de Python 3 missing solo afecta nodos Python — el resto del stack funciona normalmente.
- Se recomienda eliminar la línea `version:` del docker-compose.yml en próxima mantención.

---

**Elaborado por:** Rodrigo González — Administrador de Infraestructura  
**Empresa:** Chativot  
**Fecha:** 07 de Abril de 2026
