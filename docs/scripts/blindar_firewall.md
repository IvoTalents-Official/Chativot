# 🛡️ `blindar_firewall.sh`

**Ubicación:** `/root/blindar_firewall.sh`
**Ejecutar en:** Servidor de **PRODUCCIÓN** como `root`

## ¿Qué hace?
Configura `iptables` dejando abiertos solo los puertos necesarios y bloqueando todo lo demás:

| Puerto | Servicio |
|--------|----------|
| 22 | SSH |
| 80 | HTTP |
| 443 | HTTPS |

Limpia `DOCKER-USER` para que Docker no bypass iptables. Guarda reglas con `netfilter-persistent` (sobreviven reinicios).

## ¿Cuándo ejecutarlo?
- Una vez en la instalación inicial del servidor
- Si el firewall fue reseteado o tiene reglas incorrectas
- Después de restaurar desde snapshot

## Cómo ejecutarlo
```bash
bash /root/blindar_firewall.sh
```

## Prerrequisitos
- **Tener sesión SSH activa** antes de ejecutar
- Verificar estado previo: `iptables -L -n -v`

## ⚠️ Advertencias
- 🚨 **CRÍTICO:** Si ejecutas sin conexión SSH activa, el puerto 22 queda bloqueado y pierdes acceso al servidor
- Si necesitas un puerto extra abierto, agrégalo al script antes de ejecutar
- Verificar resultado: `iptables -L INPUT -n -v`
