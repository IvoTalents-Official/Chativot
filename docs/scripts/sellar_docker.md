# 🔒 `sellar_docker.sh`

**Ubicación:** `/root/sellar_docker.sh`
**Ejecutar en:** Servidor de **PRODUCCIÓN** como `root`

## ¿Qué hace?
Modifica todos los `docker-compose.yml` para que los puertos solo escuchen en `127.0.0.1` y no queden expuestos públicamente. Luego reinicia los contenedores.
```yaml
# Antes (inseguro):
- "5432:5432"
# Después (seguro):
- "127.0.0.1:5432:5432"
```

## ¿Cuándo ejecutarlo?
- Una vez después de instalar el stack por primera vez
- Si se agrega un servicio nuevo con puertos expuestos
- Después de restaurar desde backup sin esta configuración

## Cómo ejecutarlo
```bash
bash /root/sellar_docker.sh
```

## ⚠️ Advertencias
- Reinicia todos los contenedores → ~30 seg de interrupción
- Apache (80/443) queda en `0.0.0.0` correctamente — el script lo respeta
- Verificar resultado: `ss -tulpn` → ningún servicio sin `127.0.0.1`
- Es seguro ejecutar múltiples veces (idempotente)
