# 📦 `01_exportar_produccion.sh`

**Ubicación:** `/root/01_exportar_produccion.sh`
**Ejecutar en:** Servidor de **PRODUCCIÓN** (`IP-SERVIDOR-PROD`) como `root`

## ¿Qué hace?
Exporta todo el stack en `/tmp/chativot_export`:
1. `docker-compose.yml` y `.env`
2. Todas las imágenes Docker (~12GB)
3. Dump completo de PostgreSQL (todos los clientes)
4. Todos los volúmenes Docker

## ¿Cuándo ejecutarlo?
- Antes de clonar producción a un servidor de desarrollo nuevo
- Antes de migrar de servidor
- Como backup manual puntual

## Cómo ejecutarlo
```bash
bash /root/01_exportar_produccion.sh
```
Tiempo estimado: **20-40 minutos**

## Prerrequisitos
- Mínimo **20GB libres** en `/tmp` → verificar: `df -h /tmp`
- Todos los contenedores corriendo → verificar: `docker ps`

## ⚠️ Advertencias
- El dump de PostgreSQL contiene **datos reales de clientes**
- NO dejar el export en `/tmp` más de 24 horas
- Limpiar después: `rm -rf /tmp/chativot_export`

## Siguiente paso
```bash
# Transferir al servidor dev:
scp -r root@IP-SERVIDOR-PROD:/tmp/chativot_export/ /tmp/
# Luego en dev importar con:
bash 03_importar_en_dev.sh
```
