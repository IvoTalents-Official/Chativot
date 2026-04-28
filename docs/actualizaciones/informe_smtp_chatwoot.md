# Resolución de Incidencia — Configuración SMTP Chatwoot

**Código:** INC-OPS-SMTP-2026-001  
**Fecha:** 07 de Abril de 2026  
**Responsable:** Rodrigo González Cerpa — Analista de Infraestructura  
**Clasificación:** Interno — Confidencial  

---

## 1. Objetivo

Documentar la resolución de la incidencia relacionada con el no envío de correos electrónicos transaccionales (invitación de agentes, recuperación de contraseña, etc.) en la plataforma Chatwoot, incluyendo las causas identificadas, la solución aplicada y el procedimiento a seguir ante futuras incidencias.

---

## 2. Información de la Incidencia

| Parámetro              | Detalle                                          |
|------------------------|--------------------------------------------------|
| Sistema afectado       | Chatwoot — Servicio de correo SMTP               |
| Versión inicial        | v4.11.2                                          |
| Versión final          | v4.12.1                                          |
| Proveedor SMTP         | Gmail Workspace                                  |
| Cuenta SMTP            | admin@chativot.com                               |
| Servidores             | chat.chativot.com / chatdev.chativot.com         |
| Stack                  | Docker Compose — `/opt/chativot`                 |
| Horario de intervención| Fuera de horario laboral                         |
| Fecha de resolución    | 07 de Abril de 2026                              |

---

## 3. Descripción del Problema

Al crear un nuevo agente desde el panel de administración de Chatwoot (**Settings → Agents → Invite Agent**), el correo de invitación y confirmación de cuenta no era enviado al destinatario. El agente quedaba creado en el sistema pero nunca recibía el enlace de activación.

**Síntomas observados:**

- El agente no recibía correo de confirmación ni invitación.
- No se presentaban errores visibles en la interfaz de Chatwoot.
- Los logs de Sidekiq no mostraban errores de autenticación SMTP al momento de la creación del agente.

---

## 4. Análisis de Causa Raíz

### 4.1 Variables SMTP vacías en el archivo `.env`

El archivo `/opt/chativot/.env` tenía las variables de autenticación SMTP definidas pero sin valores:

```env
SMTP_USERNAME=
SMTP_PASSWORD=
```

### 4.2 Contraseña SMTP inválida para Gmail

En el `docker-compose.yml` existía una contraseña convencional de Gmail configurada directamente. Desde mayo de 2022, Google eliminó el soporte para autenticación SMTP con contraseñas normales. Para acceso SMTP desde aplicaciones de terceros es obligatorio el uso de **App Passwords** (tokens de 16 caracteres generados desde la cuenta de Google).

### 4.3 MAILER_SENDER_EMAIL no coincide con la cuenta autenticada

El remitente estaba configurado como `noreply@chativot.com`, mientras que la cuenta autenticada en SMTP era `admin@chativot.com`. Gmail únicamente permite enviar desde la misma cuenta que se autentica.

> ⚠️ **Importante:** Desde mayo de 2022 Google deshabilitó el acceso de aplicaciones menos seguras. Para usar Gmail como servidor SMTP es obligatorio generar un App Password desde [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords).

---

## 5. Solución Aplicada

### 5.1 Generación del App Password de Google

Se generó un App Password independiente por cada servidor desde la cuenta `admin@chativot.com`:

1. Ingresar a [myaccount.google.com](https://myaccount.google.com) con `admin@chativot.com`.
2. Navegar a **Seguridad → Verificación en dos pasos** (debe estar activa).
3. Navegar a **Seguridad → Contraseñas de aplicaciones**.
4. Crear una nueva contraseña con el nombre `Chatwoot`.
5. Copiar la clave de 16 caracteres generada (sin espacios).

> 🔐 **Seguridad:** Los App Passwords generados no se documentan en este repositorio. Para consultar, revocar o regenerar las credenciales, acceder a [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords) con la cuenta `admin@chativot.com`. Cada servidor tiene su propio App Password independiente.

### 5.2 Corrección del archivo `.env`

Se actualizaron las variables SMTP en `/opt/chativot/.env` en ambos servidores:

```env
MAILER_SENDER_EMAIL=admin@chativot.com
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=admin@chativot.com
SMTP_PASSWORD=[APP_PASSWORD_GENERADO_POR_GOOGLE]
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
```

Comandos utilizados para actualizar sin editar manualmente el archivo:

```bash
sed -i 's|MAILER_SENDER_EMAIL=.*|MAILER_SENDER_EMAIL=admin@chativot.com|' /opt/chativot/.env
sed -i 's|SMTP_USERNAME=.*|SMTP_USERNAME=admin@chativot.com|' /opt/chativot/.env
sed -i 's|SMTP_PASSWORD=.*|SMTP_PASSWORD=[APP_PASSWORD]|' /opt/chativot/.env
```

### 5.3 Actualización de imagen Chatwoot

Se actualizó la versión de Chatwoot de `v4.11.2` a `v4.12.1`:

```bash
sed -i 's|chatwoot/chatwoot:v4.11.2|chatwoot/chatwoot:v4.12.1|g' /opt/chativot/docker-compose.yml
cd /opt/chativot && docker compose pull chatwoot-rails chatwoot-sidekiq
docker compose up -d --force-recreate chatwoot-rails chatwoot-sidekiq
```

### 5.4 Verificación del funcionamiento

Prueba de envío directo desde el contenedor:

```bash
docker exec -it chatwoot-rails bundle exec rails runner \
"ActionMailer::Base.mail(from: 'admin@chativot.com', to: 'admin@chativot.com', subject: 'Test SMTP', body: 'Funciona').deliver_now"
```

El correo fue recibido exitosamente. Se creó un agente de prueba desde el panel de Chatwoot confirmando la recepción del correo de invitación.

---

## 6. Configuración SMTP Resultante

| Parámetro                  | Valor                                        |
|----------------------------|----------------------------------------------|
| `MAILER_SENDER_EMAIL`      | admin@chativot.com                           |
| `SMTP_ADDRESS`             | smtp.gmail.com                               |
| `SMTP_PORT`                | 587                                          |
| `SMTP_USERNAME`            | admin@chativot.com                           |
| `SMTP_PASSWORD`            | [App Password — no documentado por seguridad]|
| `SMTP_AUTHENTICATION`      | plain                                        |
| `SMTP_ENABLE_STARTTLS_AUTO`| true                                         |

---

## 7. Resultado Final

| Servidor       | Versión Anterior | Versión Final | Estado     |
|----------------|-----------------|---------------|------------|
| chat.chativot.com (PROD) | v4.11.2 | v4.12.1 | ✅ OK |
| chatdev.chativot.com (DEV) | v4.11.2 | v4.12.1 | ✅ OK |

- Correo de invitación de agentes: **funcionando**
- Correo de recuperación de contraseña: **funcionando**
- Templates personalizados con identidad Chativot: **aplicados**

---

## 8. Procedimiento ante Futuras Incidencias

### 8.1 Si el correo deja de funcionar

```bash
# Verificar contenedores activos
docker ps | grep chatwoot

# Verificar variables SMTP cargadas
docker exec chatwoot-rails env | grep SMTP

# Revisar logs de Sidekiq
docker logs chatwoot-sidekiq 2>&1 | grep -i 'mail\|smtp\|error' | tail -30

# Prueba de envío directo
docker exec -it chatwoot-rails bundle exec rails runner \
"ActionMailer::Base.mail(from: 'admin@chativot.com', to: 'admin@chativot.com', subject: 'Test', body: 'Test').deliver_now"
```

### 8.2 Si el App Password fue revocado

Google puede revocar un App Password si se cambia la contraseña principal o se detecta actividad inusual.

```bash
# Actualizar el App Password en .env
sed -i 's|SMTP_PASSWORD=.*|SMTP_PASSWORD=NUEVO_APP_PASSWORD|' /opt/chativot/.env

# Recrear los contenedores para aplicar el cambio
cd /opt/chativot && docker compose up -d --force-recreate chatwoot-rails chatwoot-sidekiq
```

### 8.3 Comportamiento esperado en entorno multi-account

El correo de invitación **solo se envía cuando el email del agente es nuevo en el sistema**. Si el usuario ya existe en otra cuenta dentro del mismo Chatwoot, el sistema lo agrega directamente sin enviar correo. Este es el comportamiento esperado de la plataforma.

---

## 9. Checklist de Verificación

| # | Verificación | Estado |
|---|-------------|--------|
| 1 | Contenedores `chatwoot-rails` y `chatwoot-sidekiq` corriendo | ✅ |
| 2 | Variables SMTP correctas cargadas en el contenedor | ✅ |
| 3 | Prueba de envío directo desde `rails runner` exitosa | ✅ |
| 4 | Correo de invitación de agente llega al destinatario | ✅ |
| 5 | `MAILER_SENDER_EMAIL` coincide con `SMTP_USERNAME` | ✅ |
| 6 | App Password vigente y no revocado por Google | ✅ |

---

*Elaborado por: **Rodrigo González Cerpa** — Analista de Infraestructura*  
*Área Gerencia Informática — Chativot*  
*Abril 2026*
