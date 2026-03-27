# 🔄 `04_sincronizar_dev_a_prod.sh`

**Ubicación:** `/opt/chativot-repo/04_sincronizar_dev_a_prod.sh`
**Ejecutar en:** Servidor de **DESARROLLO** (`89.167.98.137`) como `root`

## ¿Qué hace?
Copia datos no críticos de DEV → PRODUCCIÓN:

| Sincroniza ✅ | NO toca ❌ |
|---------------|------------|
| n8n: workflows, credenciales, tags, webhooks | chatwoot: usuarios, conversaciones, contactos, mensajes |
| Fzap: configuraciones | n8n: historial de ejecuciones |

Usa `ON CONFLICT DO NOTHING` — nunca sobreescribe lo existente en producción.

## ¿Cuándo ejecutarlo?
- Cuando terminaste de crear/modificar workflows en DEV y están aprobados
- NUNCA durante horario pico de atención al cliente

## Cómo ejecutarlo
```bash
cd /opt/chativot-repo
bash 04_sincronizar_dev_a_prod.sh
# Pedirá confirmación — escribir: si
```

## Prerrequisitos
- Ejecutar **desde DEV**, nunca desde producción
- SSH configurado hacia `32.193.7.26`
- `N8N_ENCRYPTION_KEY` debe ser **idéntica** en ambos `.env`
  → Si difieren, las credenciales de n8n quedan corruptas en producción

## ⚠️ Advertencias
- Verificar conectividad SSH antes: `ssh root@32.193.7.26 echo ok`
- NUNCA ejecutar en sentido inverso (prod→dev) sin backup previo
- No ejecutar con ejecuciones activas en n8n de producción
