# ✅ Onboarding Checklist — Nuevo Cliente Chativot

> Completar en orden. Marcar cada paso con [x] al terminarlo.

---

## Datos del Cliente

| Campo                  | Valor |
|------------------------|-------|
| Nombre cliente         |       |
| Empresa                |       |
| Email contacto         |       |
| Fecha onboarding       |       |
| Responsable Chativot   |       |

---

## FASE 1 — Chatwoot

**URL:** https://chat.chativot.com
**Acceso:** admin@chativot.com / (ver .env)

### 1.1 Crear cuenta del cliente
- [ ] Ingresar a https://chat.chativot.com con credenciales de administrador
- [ ] Ir al menú superior derecho → **Super Admin**
- [ ] Ir a la sección **Accounts**
- [ ] Clic en **New Account**
- [ ] Completar nombre de la empresa del cliente
- [ ] Guardar y anotar el **Account ID** generado: `_______`

### 1.2 Crear usuario administrador del cliente
- [ ] Ir a la sección **Users**
- [ ] Clic en **New User**
- [ ] Completar nombre completo y email del cliente
- [ ] En **Role** seleccionar: `Administrator`
- [ ] En **Account** seleccionar la cuenta recién creada
- [ ] Guardar
- [ ] El cliente recibirá email de activación — confirmar que lo recibió
- [ ] El cliente podrá crear sus propios agentes desde su cuenta y enviarles invitación

---

## FASE 2 — Fzap (WhatsApp)

**URL:** https://fzap.chativot.com
**Acceso:** Seleccionar "Acceso Administrador" → Token: `VIwZHIxZzAzMDA5MjEwNSU=`

### 2.1 Crear carpeta del cliente
- [ ] Ingresar a https://fzap.chativot.com
- [ ] Seleccionar **Acceso Administrador** e ingresar el token
- [ ] Crear una **carpeta** con el nombre del cliente
- [ ] Dentro de la carpeta, generar un **token** para el cliente
- [ ] Anotar el token generado: `_______`

### 2.2 Crear instancia WhatsApp
- [ ] Con el token del cliente, crear una **instancia QR de WhatsApp**
- [ ] Pedirle al cliente que escanee el QR con su WhatsApp Business
- [ ] Confirmar que el estado quede en `CONNECTED`
- [ ] Copiar el **Webhook URL** generado por la instancia: `_______`

### 2.3 Conectar Fzap → Chatwoot
- [ ] En Chatwoot → cuenta del cliente → **Settings → Inboxes → Add Inbox**
- [ ] Seleccionar tipo **API**
- [ ] Pegar el Webhook URL de Fzap en el campo correspondiente
- [ ] Guardar y anotar el **Inbox ID**: `_______`
- [ ] Enviar mensaje de prueba → confirmar que llega a Chatwoot ✅

---

## FASE 3 — n8n (Automatizaciones)

**URL:** https://n8n.chativot.com
**Acceso:** admin@chativot.com / (ver .env)

### 3.1 Crear carpeta y workflows del cliente
- [ ] Ingresar a https://n8n.chativot.com
- [ ] Ir a **Personal** → crear **carpeta** con el nombre del cliente
- [ ] Dentro de la carpeta, importar o crear los JSON de automatización CRM Chatwoot
- [ ] Actualizar en cada workflow las credenciales e Inbox ID del cliente
- [ ] Activar los workflows (toggle **ON**)
- [ ] Enviar mensaje de prueba → confirmar que el flujo se ejecuta ✅

---

## FASE 4 — PostgreSQL (pgAdmin)

**URL:** https://bd.chativot.com
**Acceso:** admin@chativot.com / (ver .env)

### 4.1 Crear base de datos del cliente
- [ ] Ingresar a https://bd.chativot.com
- [ ] Crear base de datos: `n8n_[nombre_cliente]`
  > Ejemplo: `n8n_tuentradaweb`

### 4.2 Crear tabla `n8n_chat_histories`
```sql
CREATE TABLE n8n_chat_histories (
    id          INTEGER,
    session_id  CHARACTER VARYING,
    message     JSONB,
    created_at  TIMESTAMP WITH TIME ZONE
);
```

### 4.3 Crear tabla `documents`
```sql
CREATE TABLE documents (
    id        BIGINT,
    content   TEXT,
    metadata  JSONB,
    embedding VECTOR
);
```

- [ ] Verificar que ambas tablas quedaron creadas ✅

---

## FASE 5 — WhatsApp Meta Business API (solo si el cliente usa Meta en lugar de Fzap)

### 5.1 Crear empresa en Meta Business Manager
- [ ] Ir a https://business.facebook.com
- [ ] Crear cuenta → completar nombre empresa, nombre admin y email
- [ ] Verificar el email de confirmación

### 5.2 Verificar la empresa
- [ ] En Business Manager → **Configuración → Centro de seguridad → Iniciar verificación**
- [ ] Completar: nombre legal, país, teléfono, sitio web, documento legal (RUT/escritura)
- [ ] Esperar aprobación de Meta: **2-5 días hábiles**
- [ ] Confirmación: aparece ícono de verificación azul ✅

### 5.3 Crear app en Meta for Developers
- [ ] Ir a https://developers.facebook.com/apps
- [ ] Clic en **Crear app** → tipo **Business**
- [ ] Vincular a la empresa verificada
- [ ] En el dashboard → **Agregar producto → WhatsApp → Configurar**

### 5.4 Configurar WhatsApp Business API
- [ ] En **WhatsApp → Configuración de la API**:
  - Agregar y verificar el número de teléfono del cliente (SMS o llamada)
  - Anotar **Phone Number ID**: `_______`
  - Anotar **WhatsApp Business Account ID**: `_______`
- [ ] Generar token permanente:
  - **Configuración → Usuarios del sistema → Crear usuario Admin**
  - Generar token con permisos: `whatsapp_business_messaging`, `whatsapp_business_management`
  - Anotar token: `_______`

### 5.5 Conectar con Chatwoot
- [ ] En Chatwoot → cuenta del cliente → **Settings → Inboxes → Add Inbox**
- [ ] Seleccionar tipo **WhatsApp** → proveedor **WhatsApp Cloud API**
- [ ] Completar: Phone Number ID, Business Account ID, Token
- [ ] Guardar y copiar el **Webhook URL** que genera Chatwoot
- [ ] En Meta for Developers → **WhatsApp → Configuración → Webhooks**
  - Pegar la URL de Chatwoot
  - Verificar con el token que muestra Chatwoot
  - Suscribir al evento: `messages`
- [ ] Enviar mensaje de prueba → confirmar que llega a Chatwoot ✅

---

## FASE 6 — Verificación Final y Entrega

### 6.1 Checklist de verificación
- [ ] Mensaje entrante WhatsApp → aparece en Chatwoot ✅
- [ ] n8n responde automáticamente ✅
- [ ] Tablas PostgreSQL se están llenando ✅
- [ ] Cliente accede a Chatwoot con su usuario ✅
- [ ] Cliente puede crear sus propios agentes ✅

### 6.2 Credenciales a entregar al cliente
| Dato | Valor |
|------|-------|
| URL Chatwoot | https://chat.chativot.com |
| Email | `[email del usuario creado]` |
| Contraseña temporal | `_______` |
| Número WhatsApp conectado | `_______` |

### 6.3 Post-entrega
- [ ] Crear carpeta: `/opt/chativot-repo/clientes/[nombre_cliente]/`
- [ ] Documentar Account ID, Inbox ID y token Fzap
- [ ] Agendar revisión a los 7 días

---
*Chativot — Plantilla onboarding v2.0*
