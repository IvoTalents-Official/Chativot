# CLAUDE.md — Guías de Desarrollo Chativot

Este archivo contiene las reglas, convenciones y procedimientos que Claude debe seguir al trabajar en este repositorio. También sirve como referencia para evaluar el cumplimiento del workflow de desarrollo del equipo.

---

## Git Workflow

### Estructura de ramas

| Rama | Propósito |
|------|-----------|
| `main` | Código estable. Refleja el estado de producción (AWS EC2). Solo Andreina puede mergear a esta rama. |
| `dev` | Rama de integración. Refleja el entorno de desarrollo (Hetzner). |
| `desarrollador` | Rama exclusiva de trabajo de Rodrigo González. |
| `feature/*` | Ramas de trabajo para nuevas funcionalidades. |
| `fix/*` | Ramas de trabajo para correcciones de bugs. |

### Reglas de flujo

- Todo trabajo nuevo parte desde `dev` o `desarrollador`, nunca desde `main`.
- Los merges a `main` solo se hacen desde `dev`, una vez validado en el servidor de desarrollo (Hetzner).
- Nunca hacer push directo a `main`.
- Nunca hacer force push a ninguna rama.

### Formato de commits

Usar prefijos convencionales:

```
feat:   nueva funcionalidad
fix:    corrección de bug
docs:   cambios en documentación
chore:  tareas de mantenimiento (limpieza, dependencias)
infra:  cambios de infraestructura o Docker
sec:    cambios de seguridad
```

Ejemplos correctos:
```
feat: agregar soporte multi-cuenta WhatsApp en fZap
fix: corregir timeout en chatwoot-sidekiq
docs: actualizar arquitectura servidor dev Hetzner v2.0
infra: migrar credenciales fZap hardcodeadas a .env
sec: bloquear puerto 5432 via DOCKER-USER iptables
```

### Workflow Específico con Rodrigo

Rodrigo González es el desarrollador del equipo ACM Four. Las siguientes reglas son de cumplimiento obligatorio y su violación es una alerta crítica de proceso:

**Reglas absolutas:**

- Rodrigo trabaja **exclusivamente** en la rama `desarrollador`. Nunca en otra rama sin autorización explícita de Andreina.
- **Rodrigo nunca debe hacer commit directo a `main`**. Cualquier commit en `main` que no provenga de Andreina Marrón es una violación crítica del workflow.
- Todo cambio de Rodrigo debe llegar a `main` únicamente a través de un Pull Request revisado y aprobado por Andreina.
- Rodrigo debe taggear explícitamente a `@AndreinaMarron` en GitHub cuando un PR está listo para revisión. Sin ese tag, el PR no se considera listo.

**Sincronización obligatoria:**

Antes de iniciar trabajo nuevo, Rodrigo debe sincronizar `desarrollador` desde `main` para evitar conflictos de merge:

```bash
git checkout desarrollador
git fetch origin
git merge origin/main
```

Si hay conflictos, resolverlos antes de empezar trabajo nuevo y nunca commitear código con marcadores de conflicto (`<<<<<<<`, `=======`, `>>>>>>>`).

**Cómo Andreina verifica cumplimiento:**

1. En GitHub, ir a `Insights > Network` para ver el grafo de commits y detectar commits directos a `main` no autorizados.
2. Verificar que cada PR en `main` tiene aprobación explícita de Andreina antes del merge.
3. Verificar que los PRs describen claramente el problema que resuelven y la solución elegida.

---

## Seguridad

### Credenciales y secretos

- **Prohibido** incluir contraseñas, tokens, claves o cualquier credencial directamente en el código fuente.
- **Prohibido** commitear el archivo `.env` con valores reales. El `.env` con credenciales vive únicamente en el servidor (`/opt/chativot/.env`).
- Toda credencial debe estar referenciada desde variables de entorno definidas en `.env`.

Variables sensibles del proyecto que **nunca** deben aparecer en el código:

```
POSTGRES_PASSWORD, PGADMIN_PASSWORD
CHATWOOT_SECRET_KEY_BASE, CHATWOOT_DB_PASSWORD
N8N_BASIC_AUTH_PASSWORD, N8N_ENCRYPTION_KEY
FZAP_ADMIN_TOKEN, FZAP_DB_PASSWORD
REDIS_PASSWORD
SMTP_PASSWORD
```

- Si Claude detecta una credencial hardcodeada, debe señalarla como bug crítico e indicar la variable de entorno correspondiente del `.env`.
- Las credenciales fZap y `SMTP_PASSWORD` en `docker-compose.yml` están pendientes de migrar a `.env` — deuda técnica conocida de alta prioridad.

### Prácticas prohibidas en código

- No ejecutar código dinámico proveniente de input del usuario (funciones como `exec`, `subprocess` con strings construidos por el usuario, etc.).
- No construir queries SQL por concatenación de strings. Usar siempre queries parametrizadas con placeholders (`?` o `%s`).
- No comparar contraseñas con operadores de igualdad directa (`==`). Usar comparación en tiempo constante (`hmac.compare_digest`).
- No almacenar contraseñas en texto plano en la base de datos.

### Documentación de Variables de Cliente

Cada vez que se agregue una nueva variable de entorno al archivo `.env`, debe documentarse **simultáneamente** en `docs/variables-cliente.md` con los siguientes tres campos obligatorios:

| Campo | Descripción |
|-------|-------------|
| **Nombre** | El nombre exacto de la variable (ej. `FZAP_ADMIN_TOKEN`) |
| **Propósito y descripción** | Para qué sirve y en qué servicio se usa |
| **Valor de ejemplo** | Un valor ilustrativo **nunca el valor real de producción** (ej. `token_abc123_ejemplo`) |

Este archivo es crítico para el proceso de **onboarding de nuevos clientes** en el modelo white-label de Chativot. Cada cliente nuevo necesita configurar su propio `.env` y si `variables-cliente.md` no está actualizado, el proceso de onboarding requiere revisar el código fuente manualmente, lo que genera deuda técnica de documentación y retrasa entregas.

Regla verificable: si se agrega una variable al `.env` y no aparece en `docs/variables-cliente.md` en el mismo commit, es un incumplimiento.

### Logging Seguro

Los logs son útiles para debugging pero **nunca deben exponer secretos**. Está explícitamente prohibido escribir en logs:

- Contraseñas completas (de usuarios, bases de datos, servicios)
- Tokens de API o claves de autenticación completos
- Números de tarjetas de crédito o cualquier dato de pago
- Información personal identificable completa de usuarios finales: emails completos, números de teléfono completos, nombres completos combinados con otros datos sensibles
- Credenciales de base de datos (usuario, contraseña, connection strings)

Si es necesario loguear identificadores para debugging, deben estar **enmascarados o truncados**:

```python
# Correcto — mostrar solo últimos 4 dígitos de teléfono
log.info(f"Mensaje enviado a ****{telefono[-4:]}")

# Correcto — truncar token
log.debug(f"Token usado: {token[:8]}...")

# Incorrecto — nunca hacer esto
log.info(f"Autenticando usuario {email} con password {password}")
```

### Firewall y puertos

Los siguientes puertos están bloqueados desde el exterior mediante `DOCKER-USER` iptables en ambos servidores. No deben exponerse públicamente:

| Puerto | Servicio |
|--------|----------|
| 3000 | Chatwoot Rails |
| 5050 | pgAdmin 4 |
| 5432 | PostgreSQL |
| 5540 | RedisInsight |
| 5678 | n8n |
| 6379 | Redis |
| 8080 | fZap API |
| 8081 | Zabbix Web UI |

Puertos públicamente accesibles (solo estos):

| Puerto | Servicio |
|--------|----------|
| 22 | SSH (acceso administrativo) |
| 80 | Apache HTTP (redirige a HTTPS) |
| 443 | Apache HTTPS (tráfico público) |
| 10051 | Zabbix Server (agentes remotos) |

---

## Docker y Contenedores

### Stack de servicios

El stack completo corre en Docker Compose. El archivo principal es `docker-compose.yml` en la raíz. Los servicios son:

| Servicio | Imagen | Descripción |
|----------|--------|-------------|
| `postgres` | `pgvector/pgvector:pg16` | BD principal (Chatwoot, n8n, fZap, Zabbix) |
| `redis` | `redis:7-alpine` | Cache y colas de Chatwoot |
| `chatwoot-rails` | `chatwoot/chatwoot:v4.11.2` | Servidor web Chatwoot |
| `chatwoot-sidekiq` | `chatwoot/chatwoot:v4.11.2` | Worker de background |
| `n8n` | `n8nio/n8n:latest` | Automatización de flujos |
| `fzap` | `dncarbonell/fzap:latest` | API WhatsApp |
| `zabbix-server` | `zabbix/zabbix-server-pgsql:latest` | Monitoreo |
| `zabbix-web` | `zabbix/zabbix-web-nginx-pgsql:latest` | UI Zabbix |
| `apache` | `httpd:2.4-alpine` | Proxy inverso + SSL |
| `certbot` | `certbot/certbot:latest` | Certificados SSL Let's Encrypt |
| `redisinsight` | `redis/redisinsight:latest` | UI Redis |
| `pgadmin` | `dpage/pgadmin4:latest` | UI PostgreSQL |

### Reglas Docker

- Nunca cambiar la versión pinneada de Chatwoot (`v4.11.2`) sin validación previa en dev.
- Los volúmenes `chativot_certbot_certs` y `chativot_certbot_html` deben declararse con `external: true` en el servidor dev (Hetzner).
- Después de cualquier cambio en `docker-compose.yml`, documentar el cambio en `docs/arquitectura.md` o `docs/arquitectura-dev.md` según corresponda.
- No dejar imágenes residuales. Después de actualizaciones, limpiar con `docker image prune`.
- No dejar volúmenes anónimos. Limpiar periódicamente con `docker volume prune -f`.
- Mantener imágenes Docker de las **últimas tres versiones estables** de cada servicio crítico para permitir rollbacks rápidos. Esto es obligatorio para Chatwoot, fZap y n8n.

### Comandos estándar

```bash
# Levantar el stack
docker compose up -d

# Ver estado
docker compose ps

# Ver logs de un servicio
docker compose logs -f <servicio>

# Reiniciar un servicio
docker compose restart <servicio>

# Acceder a PostgreSQL
docker exec -it postgres psql -U postgres

# Acceder a Redis
docker exec -it redis redis-cli -a $REDIS_PASSWORD
```

### Sincronización dev → producción

El script `04_sincronizar_dev_a_prod.sh` en la raíz gestiona la sincronización. Flujo obligatorio:

```
1. Exportar en producción (AWS)
2. Transferir al servidor dev (Hetzner) via SCP
3. Importar en dev
```

---

## PostgreSQL y Base de Datos

### Bases de datos del proyecto

Todas las BDs viven en el mismo contenedor `postgres` (`pgvector/pgvector:pg16`):

| Base de datos | Propósito |
|---------------|-----------|
| `chatwoot` | Datos de Chatwoot (conversaciones, contactos, agentes) |
| `fzap` | Datos de fZap (sesiones WhatsApp) |
| `n8n` | Workflows y credenciales de n8n |
| `zabbix` | Métricas y configuración de Zabbix |

### Reglas de base de datos

- **Prohibido** ejecutar `DROP`, `TRUNCATE` o `DELETE` sin `WHERE` en producción sin respaldo previo.
- Toda migración de esquema debe probarse primero en el servidor dev (Hetzner).
- Los scripts de inicialización viven en `scripts/`.
- No conectar directamente a PostgreSQL desde fuera del stack Docker. Usar pgAdmin o `docker exec`.
- El puerto `5432` está bloqueado externamente. Toda conexión es a través de la red interna Docker `chativot_chativot`.

### Volúmenes de datos

| Volumen | Contenido | Tamaño aprox. |
|---------|-----------|----------------|
| `chativot_postgres_data` | Todas las BDs | ~380 MB |
| `chativot_chatwoot_storage` | Media y adjuntos | ~80 MB |
| `chativot_n8n_data` | Workflows n8n | ~30 MB |
| `chativot_redis_data` | Persistencia Redis | ~500 KB |

### Migraciones de Base de Datos

Toda migración de esquema debe cumplir las siguientes condiciones:

**Dos scripts obligatorios por migración:**

```
migrations/
├── YYYYMMDD_descripcion_up.sql    # Aplica el cambio
└── YYYYMMDD_descripcion_down.sql  # Revierte el cambio
```

**Reglas de ejecución:**

- Las migraciones deben ejecutarse dentro de transacciones (`BEGIN` / `COMMIT`) cuando sea posible, para permitir rollback automático si fallan.
- Probar tanto `up` como `down` en el servidor dev antes de aplicar en producción.
- Las migraciones **nunca deben eliminar datos** sin respaldo previo explícito y confirmado.

**Tablas grandes (más de 100,000 filas):**

Los cambios de esquema en tablas grandes pueden causar locks prolongados que bloquean la aplicación. Para estas tablas:
1. Planificar la migración en horario de bajo tráfico.
2. Usar operaciones `ADD COLUMN` con valor default en lugar de reescribir la tabla cuando sea posible.
3. Notificar en Slack `#backend` antes de ejecutar con anticipación mínima de 24 horas.

**Documentación obligatoria:** Cada migración debe registrarse en el archivo de arquitectura correspondiente (`docs/arquitectura.md` o `docs/arquitectura-dev.md`) con fecha y propósito del cambio.

---

## Scripts Shell

### Scripts existentes

| Script | Ubicación | Propósito |
|--------|-----------|-----------|
| `04_sincronizar_dev_a_prod.sh` | Raíz | Sincronizar datos dev → producción |
| `scripts/nuevo-cliente.sh` | `scripts/` | Provisionamiento de nuevo cliente |

### Reglas para scripts shell

- Todo script nuevo debe tener cabecera con descripción, fecha de creación y autor.
- Usar `set -euo pipefail` al inicio de cada script para fallar de forma explícita.
- Variables con rutas o valores de entorno deben estar entre comillas dobles: `"$VARIABLE"`.
- Nunca hardcodear IPs, contraseñas ni tokens en scripts. Leer desde variables de entorno o argumentos.
- Los scripts que modifican datos en producción deben incluir confirmación interactiva antes de ejecutar.
- Dar permisos explícitos: `chmod +x script.sh` al crear un script nuevo.

---

## Documentación

### Archivos de documentación

| Archivo | Propósito |
|---------|-----------|
| `docs/arquitectura.md` | Arquitectura servidor producción (AWS EC2 t3.large) |
| `docs/arquitectura-dev.md` | Arquitectura servidor desarrollo (Hetzner vServer) |
| `docs/variables-cliente.md` | Referencia de variables de entorno para onboarding de clientes |
| `README.md` | Guía de inicio rápido del stack de desarrollo |

### Reglas de documentación

- Cada cambio significativo de infraestructura debe reflejarse en el documento de arquitectura correspondiente.
- El formato de versión es `vX.Y — Descripción` (ej. `v2.0 — Post Hardening de Seguridad`).
- Los documentos de arquitectura deben incluir fecha de captura y servidor de origen.
- Al documentar variables de entorno, redactar los valores reales (mostrar solo el nombre de la variable).
- Si se agrega o elimina un contenedor, actualizar la tabla de contenedores en el documento correspondiente.
- Si se modifica el firewall (iptables / UFW), actualizar las tablas de puertos en el documento correspondiente.

### Deuda técnica conocida

No crear issues duplicados para estos ítems ya registrados:

**Producción (AWS):**
- Instalar UFW (actualmente solo iptables directo)
- Limpiar 9 volúmenes anónimos pendientes
- Activar Live Restore en Docker daemon
- Migrar credenciales fZap a `.env`
- Migrar `SMTP_PASSWORD` a `.env`
- Restringir SSH por IP (Security Group AWS)
- Configurar snapshots automáticos EBS

**Desarrollo (Hetzner):**
- Activar Live Restore en Docker daemon
- Restringir SSH por IP via UFW
- Configurar snapshots automáticos Hetzner
- Migrar credenciales fZap a `.env`
- Migrar `SMTP_PASSWORD` a `.env`

---

## Testing y Calidad

### Cobertura mínima obligatoria

- Todo código que implemente lógica de negocio crítica debe incluir **al menos una prueba básica** que demuestre funcionamiento correcto con un caso de uso representativo.
- Los cambios en queries de base de datos deben probarse con datos de prueba en el servidor dev **antes del commit**. No commitear una query que no se haya ejecutado manualmente al menos una vez.

### Integraciones con APIs externas

Todo código que consuma una API externa (WhatsApp via fZap, SMTP, Webhooks de Chatwoot, n8n, etc.) debe manejar explícitamente al menos estos tres casos de error:

| Caso | Comportamiento esperado |
|------|------------------------|
| API no responde (timeout) | Reintentar con backoff o retornar error descriptivo, nunca colgar en espera indefinida |
| API responde con error (4xx / 5xx) | Loguear el código de error y mensaje, no propagar excepciones no manejadas |
| Respuesta con formato inesperado | Validar estructura antes de acceder a campos, no asumir que los campos siempre existen |

### Legibilidad del código

El código debe ser legible por una persona que no lo escribió:

- **Nombres de variables y funciones descriptivos**: `obtener_historial_conversacion(cliente_id)` es correcto; `get_data(id)` no lo es.
- **Comentarios en secciones complejas**: Si la lógica no es obvia leyendo el código, agregar un comentario explicando el *por qué*, no el *qué*.
- **Sin código muerto**: No commitear funciones, variables o imports que no se usan.
- **Sin números mágicos**: Los valores constantes deben tener nombre (`MAX_INTENTOS_LOGIN = 5`, no `if intentos > 5`).

---

## Comunicación y Coordinación

### Canales y responsabilidades

| Canal Slack | Propósito |
|-------------|-----------|
| `#desarrollo` | Discusión técnica general, decisiones de arquitectura, revisión de cambios mayores |
| `#backend` | Alertas de bugs críticos en producción, coordinación de deploys, postmortems |

### Reglas de comunicación

**Antes de implementar:**
- Cambios mayores de arquitectura o modificaciones al `docker-compose.yml` deben discutirse en `#desarrollo` **antes de implementarse**, no después.

**Al encontrar un bug crítico en producción:**
- Reportar **inmediatamente** en `#backend` con etiqueta `@channel`.
- El reporte debe incluir: qué servicio está afectado, síntomas observados, y si ya se identificó la causa.

**En Pull Requests:**
- El PR debe incluir un mensaje claro de: qué problema resuelve y por qué se eligió esa solución sobre otras alternativas.
- Rodrigo debe taggear explícitamente a `@AndreinaMarron` en GitHub cuando el PR está listo para revisión.
- Un PR sin descripción o sin el tag de revisión no se considera listo para merge.

**Cambios con downtime:**
- Cualquier cambio que requiera detener servicios en producción debe coordinarse con **anticipación mínima de 24 horas** en `#backend`, especificando la ventana de mantenimiento propuesta.

---

## Rollback y Recuperación ante Desastres

### Procedimiento de emergencia — deploy a producción fallido

Si un deploy a producción causa problemas, seguir estos pasos en orden:

**Paso 1 — Identificar el contenedor problemático**
```bash
docker compose ps
docker compose logs --tail=100 <servicio>
```

**Paso 2 — Revertir a la versión anterior**
```bash
# Detener el contenedor afectado
docker compose stop <servicio>

# Actualizar docker-compose.yml con la imagen de la versión anterior
# y levantar nuevamente
docker compose up -d <servicio>
```

Esto requiere que la imagen de la versión anterior esté disponible en el registro Docker. **Mantener imágenes de las últimas 3 versiones estables es obligatorio** para Chatwoot, fZap, n8n y PostgreSQL.

**Paso 3 — Notificar en Slack**
Publicar en `#backend` con `@channel`:
- Qué se revirtió y a qué versión
- Por qué se revirtió (síntoma observado)
- Estado actual del servicio

**Paso 4 — Documentar el incidente**
Crear un archivo de postmortem en `docs/incidentes/` con el formato:

```
docs/incidentes/YYYYMMDD_nombre-del-incidente.md
```

El archivo debe incluir: fecha y hora, servicios afectados, causa raíz identificada, impacto (tiempo de downtime, clientes afectados), y acciones tomadas.

**Paso 5 — Programar el fix en dev**
No reintentar el deploy hasta haber reproducido y corregido el problema en el servidor de desarrollo (Hetzner) y validado por al menos 24 horas.

---

## Gestión de Dependencias y Actualizaciones

### Proceso obligatorio para actualizaciones críticas

Las dependencias críticas del stack son: **PostgreSQL, Redis, n8n, fZap, Chatwoot, Apache**. Actualizar cualquiera de ellas requiere seguir este proceso completo:

| Paso | Acción | Obligatorio |
|------|--------|-------------|
| 1 | Revisar las release notes oficiales de la nueva versión buscando breaking changes | Sí |
| 2 | Probar la actualización en Hetzner (dev) durante **mínimo 48 horas** monitoreando logs y rendimiento | Sí |
| 3 | Documentar cualquier cambio de configuración necesario (nuevas variables, parámetros deprecados) | Sí |
| 4 | Hacer backup completo de volúmenes Docker antes de aplicar en producción | Sí |
| 5 | Aplicar en producción en **horario de bajo tráfico** con monitoreo activo durante las 2 horas posteriores | Sí |

### Regla de actualización única

**Nunca actualizar múltiples dependencias críticas simultáneamente.** Si se actualizan PostgreSQL y Chatwoot en el mismo deploy y algo falla, es imposible determinar cuál de las dos causó el problema. Actualizar una dependencia por deploy.

### Versionado

- Siempre especificar la versión exacta al actualizar (ej. `chatwoot/chatwoot:v4.12.0`), nunca usar `latest` en servicios críticos de producción.
- `latest` es aceptable solo en servicios de monitoreo (Zabbix, RedisInsight, pgAdmin) donde un fallo no afecta a clientes directamente.

---

## Monitoreo y Observabilidad

### Checks mínimos obligatorios en Zabbix

Todo nuevo servicio agregado al stack Docker debe configurarse en Zabbix con **los siguientes 3 checks como mínimo antes de considerarse listo para producción**:

| Check | Descripción | Umbral de alerta |
|-------|-------------|-----------------|
| Estado del contenedor | Verifica que el contenedor está en estado `running` | Alerta si no está `running` por más de 2 minutos |
| Uso de memoria | Porcentaje de memoria usada respecto al límite asignado | Alerta si supera el 80% |
| Disponibilidad del servicio | Verifica que el servicio responde en su puerto designado | Alerta si no responde por más de 2 minutos |

### Alertas críticas para clientes

Los servicios críticos para clientes (**Chatwoot, fZap, n8n**) deben tener alertas configuradas para notificar a Andreina vía email si están caídos por más de **5 minutos continuos**.

Sin monitoreo proactivo, los problemas solo se descubren cuando un cliente reporta que algo no funciona — lo que deteriora la confianza y aumenta el tiempo de resolución. El monitoreo reactivo no es suficiente.

### Al agregar un nuevo cliente (modelo white-label)

Cuando se aprovisiona un nuevo cliente en el modelo white-label de Chativot:
1. Crear los checks de Zabbix correspondientes para los servicios del cliente.
2. Verificar que las alertas de email están configuradas y llegan correctamente.
3. Documentar en `scripts/nuevo-cliente.sh` cualquier paso nuevo que se haya requerido durante el provisionamiento.

---

## Convenciones de Nomenclatura y Estilo de Código

Código legible es código mantenible. Estas convenciones son verificables visualmente en cualquier PR.

### Nomenclatura en Python

| Elemento | Convención | Correcto | Incorrecto |
|----------|-----------|---------|-----------|
| Archivos | `snake_case` | `procesar_pagos.py` | `ProcesarPagos.py` |
| Clases | `PascalCase` | `ClienteManager` | `cliente_manager` |
| Funciones y métodos | `snake_case` descriptivo | `validar_credenciales_usuario()` | `validar()` o `check()` |
| Variables booleanas | Prefijo `is_`, `has_`, `should_` | `is_activo`, `has_permisos` | `activo`, `permisos` |
| Constantes | `MAYUSCULAS_CON_GUIONES` | `MAX_INTENTOS_LOGIN` | `maxIntentos` |

### Funciones complejas

Las funciones cuya lógica no es inmediatamente obvia deben incluir un docstring con:

```python
def sincronizar_conversaciones(cliente_id: int, desde: datetime) -> list:
    """
    Sincroniza conversaciones de Chatwoot con la base de datos local.

    Args:
        cliente_id: ID del cliente en el modelo white-label.
        desde: Timestamp desde el cual traer conversaciones nuevas.

    Returns:
        Lista de IDs de conversaciones sincronizadas exitosamente.

    Raises:
        ConexionChatwootError: Si la API de Chatwoot no responde.
    """
```

"Función compleja" significa: más de 20 líneas, lógica condicional anidada, o propósito que no es evidente por el nombre.

### Lo que hace un PR fácil de revisar para Andreina

Un PR cumple los estándares de legibilidad cuando:
- Los nombres de variables y funciones explican qué hacen sin necesidad de leer el cuerpo.
- Los comentarios en el código explican el *por qué* de decisiones no obvias.
- No hay bloques de código comentado (`# código viejo`) — si se eliminó, eliminarlo limpiamente.
- El diff del PR muestra cambios enfocados y relacionados entre sí, no cambios dispersos en múltiples archivos sin relación.
