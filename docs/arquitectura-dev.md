# Arquitectura de Infraestructura — Servidor Developer (Hetzner)

> **Version:** v2.0 — Post Hardening de Seguridad  
> **Fecha:** 20 de marzo de 2026  
> **Servidor:** Hetzner vServer — hostname: dev  
> **IP publica:** 89.167.98.137  

---

## Mejoras de seguridad aplicadas

| Mejora | Estado |
|--------|--------|
| SWAP 8 GB activada y persistente (swappiness=10) | OK |
| DOCKER-USER iptables (8 puertos bloqueados desde eth0) | OK |
| iptables-persistent instalado (/etc/iptables/rules.v4) | OK |
| Certbot levantado — renovacion SSL automatica cada 6h | OK |
| external:true en certbot_certs y certbot_html | OK |
| alpine:latest eliminada (imagen residual) | OK |
| Volumenes anonimos limpiados (docker volume prune) | OK |
| UFW limpiado — solo puertos 22, 80, 443, 10051 | OK |

---

## Indice

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Hardware y Sistema Operativo](#2-hardware-y-sistema-operativo)
3. [Memoria RAM y SWAP](#3-memoria-ram-y-swap)
4. [Almacenamiento](#4-almacenamiento-y-sistema-de-archivos)
5. [Red y Conectividad](#5-red-y-conectividad)
6. [Firewall UFW y DOCKER-USER](#6-firewall-ufw-y-docker-user)
7. [Reglas DOCKER-USER](#7-reglas-docker-user-iptables)
8. [Puertos Expuestos](#8-puertos-expuestos-estado-actual)
9. [Docker Engine](#9-docker-engine)
10. [Contenedores](#10-contenedores-en-ejecucion)
11. [Imagenes Docker](#11-imagenes-docker)
12. [Volumenes Docker](#12-volumenes-docker)
13. [Certificados SSL](#13-certificados-ssl)
14. [Estructura del Proyecto](#14-estructura-del-proyecto-optchativot)
15. [Variables de Entorno](#15-variables-de-entorno-env)
16. [Servicios systemd](#16-servicios-del-sistema-systemd)
17. [Cron](#17-tareas-programadas-cron)
18. [Comparativa con Produccion AWS](#18-comparativa-con-servidor-de-produccion-aws)
19. [Resumen de Seguridad](#19-resumen-de-seguridad-y-pendientes)

---

## 1. Resumen Ejecutivo

Servidor de desarrollo Chativot sobre Hetzner vServer KVM con Ubuntu 24.04.4 LTS,
ejecutando 12 contenedores Docker. Todas las mejoras de seguridad fueron aplicadas
el 20 de marzo de 2026, equiparando el nivel de hardening con el servidor de produccion AWS.

| Campo | Valor |
|-------|-------|
| Proveedor | Hetzner (Alemania) |
| Tipo | vServer (KVM) |
| Sistema Operativo | Ubuntu 24.04.4 LTS |
| Kernel | 6.8.0-90-generic |
| Uptime | up 2 days, 9 hours, 13 minutes |
| Hostname | dev |
| IP publica | 89.167.98.137 /32 en eth0 |
| Docker Engine | 29.3.0 (Community) |
| Docker Compose | 5.1.0 |
| Contenedores activos | 12 running |
| Imagenes en disco | 11 (todas en uso) |
| Swap | 8.0Gi activa, persistente, swappiness=10 |
| Firewall | UFW + DOCKER-USER iptables (8 puertos bloqueados) |
| SSL | 7 certificados vigentes — vencen 16 Jun 2026 |
| Certbot | Activo — renovacion automatica cada 6h |
| Cron activo | Ninguno |
| Disco usado | N/A |

---

## 2. Hardware y Sistema Operativo

### 2.1 CPU

| Campo | Valor |
|-------|-------|
| Modelo | AMD EPYC-Rome Processor @ 2.0GHz |
| vCPUs | 16 (16 cores, 1 thread/core, SMT deshabilitado) |
| Arquitectura | x86_64 64-bit |
| Hypervisor | KVM (Hetzner — full virtualization) |
| Familia CPU | 23 — Zen 2 (EPYC Rome) |
| NUMA nodes | 1 (node0: CPU 0-15) |
| L1d/L1i cache | 512 KiB c/u (32 KiB por core) |
| L2 cache | 8 MiB (512 KiB por core) |
| L3 cache | 16 MiB (compartida) |
| Instrucciones | AVX, AVX2, AES-NI, SHA-NI, CLWB, RDSEED |
| SMT | Deshabilitado — mitigacion Retbleed |

### 2.2 Sistema Operativo

| Campo | Valor |
|-------|-------|
| Distribucion | Ubuntu 24.04.4 LTS (Noble Numbat) |
| Kernel | 6.8.0-90-generic |
| Firmware | QEMU/KVM — BIOS 2017-11-11 |
| Cgroup version | v2 (systemd) |
| AppArmor | Activo (builtin) |
| Seccomp | Activo (builtin) |
| Machine ID | 6b62716b458d419da2f3e6fecae7ca13 |
| QEMU Guest Agent | Activo (gestion remota Hetzner) |

---

## 3. Memoria RAM y SWAP

| Campo | Valor |
|-------|-------|
| RAM total | 30Gi |
| SWAP total | 8.0Gi (/swapfile en disco SATA) |
| vm.swappiness | 10 (persistente en /etc/sysctl.conf) |
| SWAP en /etc/fstab | /swapfile none swap sw 0 0 |

> SWAP configurada: activa, persistente, swappiness=10. OOM Killer protegido.

---

## 4. Almacenamiento y Sistema de Archivos

### 4.1 Disco SATA

| Dispositivo | Tamano | Tipo | FS | Punto de montaje |
|-------------|--------|------|----|-----------------|
| sda | 76.3 GB | SATA disk | — | Disco principal |
| sda1 | 76 GB | partition | ext4 | / (raiz) |
| sda14 | 1 MB | partition | — | BIOS boot (GPT) |
| sda15 | 256 MB | partition | vfat | /boot/efi |
| sr0 | 1024 MB | rom | — | CD-ROM virtual Hetzner |
| /swapfile | 8 GB | archivo | swap | Memoria virtual |

### 4.2 Uso del disco

| Filesystem | Tipo | Tamano | Usado | Uso% | Montado en |
|------------|------|--------|-------|------|------------|
| /dev/sda1 | ext4 | 75 GB | 15 GB | 21% | / |
| /dev/sda15 | vfat | 253 MB | 146 KB | 1% | /boot/efi |
| tmpfs (shm) | tmpfs | 16 GB | 0 | 0% | /dev/shm |

> Disco: 15 GB usados de 75 GB (21%). Quedan 58 GB libres.

---

## 5. Red y Conectividad

### 5.1 Interfaces de red

| Interfaz | IP / Subnet | MTU | Descripcion |
|----------|-------------|-----|-------------|
| lo | 127.0.0.1/8 | 65536 | Loopback |
| eth0 | 89.167.98.137/32 (DHCP) | 1500 | NIC principal Hetzner — IP publica /32 |
| docker0 | 172.17.0.1/16 | 1500 | Red Docker default (sin contenedores) |
| br-08124a7b0933 | 172.18.0.1/16 | 1500 | Bridge chativot_chativot (stack activo) |
| veth* (x11) | — | 1500 | Interfaces virtuales por contenedor |

### 5.2 DNS y Rutas

| Campo | Valor |
|-------|-------|
| Resolver local | 127.0.0.53 (systemd-resolved) |
| DNS Hetzner | 185.12.64.1 / 185.12.64.2 |
| Gateway | 172.31.1.1 (Hetzner cloud router) |

### 5.3 Redes Docker

| Network ID | Nombre | Driver | Estado |
|------------|--------|--------|--------|
| 08124a7b0933 | chativot_chativot | bridge | ACTIVA — todos los servicios |
| 2a4138f15c12 | bridge | bridge | Docker default (sin uso) |
| 488753ea01e7 | host | host | Red del host |
| 1a28ddc61310 | none | null | Sin red |

---

## 6. Firewall UFW y DOCKER-USER

### UFW — Reglas activas post-hardening

| Puerto | Protocolo | Accion | Servicio |
|--------|-----------|--------|----------|
| 22 | tcp (IPv4+6) | ALLOW IN | SSH — acceso administrativo |
| 80 | tcp (IPv4+6) | ALLOW IN | HTTP Apache — redirige a HTTPS |
| 443 | tcp (IPv4+6) | ALLOW IN | HTTPS Apache — trafico publico |
| 10051 | tcp (IPv4+6) | ALLOW IN | Zabbix Server — agentes remotos |

| Campo | Valor |
|-------|-------|
| Estado UFW | Activo |
| Politica incoming | deny (por defecto) |
| iptables-persistent | Instalado — /etc/iptables/rules.v4 |

---

## 7. Reglas DOCKER-USER (iptables)

La cadena DOCKER-USER bloquea acceso externo desde eth0.
El trafico interno (172.18.0.0/16) NO es afectado.

| # | Puerto | Protocolo | Interfaz | Accion | Servicio protegido |
|---|--------|-----------|----------|--------|-------------------|
| 1 | 8081 | tcp | eth0 | DROP | Zabbix Web UI |
| 2 | 5540 | tcp | eth0 | DROP | RedisInsight |
| 3 | 5050 | tcp | eth0 | DROP | pgAdmin 4 |
| 4 | 8080 | tcp | eth0 | DROP | fZap WhatsApp API |
| 5 | 3000 | tcp | eth0 | DROP | Chatwoot Rails |
| 6 | 5678 | tcp | eth0 | DROP | n8n Workflows |
| 7 | 6379 | tcp | eth0 | DROP | Redis |
| 8 | 5432 | tcp | eth0 | DROP | PostgreSQL |

### Estado actual de la cadena DOCKER-USER

```
Chain DOCKER-USER (1 references)
num  target     prot opt source               destination         
1    DROP       6    --  0.0.0.0/0            0.0.0.0/0            tcp dpt:8081
2    DROP       6    --  0.0.0.0/0            0.0.0.0/0            tcp dpt:5540
3    DROP       6    --  0.0.0.0/0            0.0.0.0/0            tcp dpt:5050
4    DROP       6    --  0.0.0.0/0            0.0.0.0/0            tcp dpt:8080
5    DROP       6    --  0.0.0.0/0            0.0.0.0/0            tcp dpt:3000
6    DROP       6    --  0.0.0.0/0            0.0.0.0/0            tcp dpt:5678
7    DROP       6    --  0.0.0.0/0            0.0.0.0/0            tcp dpt:6379
8    DROP       6    --  0.0.0.0/0            0.0.0.0/0            tcp dpt:5432
```

---

## 8. Puertos Expuestos Estado Actual

| Puerto | Proceso | Servicio | Acceso externo |
|--------|---------|----------|----------------|
| 22 | sshd | SSH | ABIERTO (admin) |
| 80 | docker-proxy apache | HTTP | ABIERTO (redirige HTTPS) |
| 443 | docker-proxy apache | HTTPS | ABIERTO (trafico publico) |
| 3000 | docker-proxy chatwoot | Chatwoot Rails | BLOQUEADO DOCKER-USER |
| 5050 | docker-proxy pgadmin | pgAdmin 4 | BLOQUEADO DOCKER-USER |
| 5432 | docker-proxy postgres | PostgreSQL | BLOQUEADO DOCKER-USER |
| 5540 | docker-proxy redisinsight | RedisInsight | BLOQUEADO DOCKER-USER |
| 5678 | docker-proxy n8n | n8n | BLOQUEADO DOCKER-USER |
| 6379 | docker-proxy redis | Redis | BLOQUEADO DOCKER-USER |
| 8080 | docker-proxy fzap | fZap API | BLOQUEADO DOCKER-USER |
| 8081 | docker-proxy zabbix-web | Zabbix Web | BLOQUEADO DOCKER-USER |
| 10051 | docker-proxy zabbix-server | Zabbix agentes | ABIERTO (agentes) |

---

## 9. Docker Engine

| Campo | Valor |
|-------|-------|
| Version | 29.3.0 (Community Edition) |
| API version | 1.54 |
| containerd | v2.2.2 |
| runc | v1.3.4 |
| Storage Driver | overlayfs (io.containerd.snapshotter.v1) |
| Logging Driver | json-file |
| Cgroup Driver | systemd (v2) |
| Security Options | apparmor + seccomp + cgroupns |
| Docker Root Dir | /var/lib/docker |
| Compose plugin | 5.1.0 |
| Contenedores | 12 running / 0 paused / 0 stopped |
| Imagenes | 11 (todas en uso activo) |

---

## 10. Contenedores en Ejecucion

| Contenedor | Imagen | Estado | Puertos |
|------------|--------|--------|---------|
| certbot | certbot/certbot:latest | Up 23 minutes | 80/tcp, 443/tcp |
| apache | httpd:2.4-alpine | Up 2 days | 0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp |
| pgadmin | dpage/pgadmin4:latest | Up 2 days | 443/tcp, 0.0.0.0:5050->80/tcp, [::]:5050->80/tcp |
| fzap | dncarbonell/fzap:latest | Up 2 days | 0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp |
| chatwoot-rails | chatwoot/chatwoot:v4.11.2 | Up 2 days | 0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp |
| n8n | n8nio/n8n:latest | Up 2 days | 0.0.0.0:5678->5678/tcp, [::]:5678->5678/tcp |
| chatwoot-sidekiq | chatwoot/chatwoot:v4.11.2 | Up 2 days | 3000/tcp |
| zabbix-web | zabbix/zabbix-web-nginx-pgsql:latest | Up 2 days (healthy) | 8443/tcp, 0.0.0.0:8081->8080/tcp, [::]:8081->8080/tcp |
| zabbix-server | zabbix/zabbix-server-pgsql:latest | Up 2 days | 0.0.0.0:10051->10051/tcp, [::]:10051->10051/tcp |
| redisinsight | redis/redisinsight:latest | Up 2 days | 0.0.0.0:5540->5540/tcp, [::]:5540->5540/tcp |
| redis | redis:7-alpine | Up 2 days (healthy) | 0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp |
| postgres | pgvector/pgvector:pg16 | Up 2 days (healthy) | 0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp |

---

## 11. Imagenes Docker

Tras la limpieza, todas las imagenes tienen contenedor activo. Sin residuos.

| Imagen:Tag | Image ID | Tamano | Estado |
|------------|----------|--------|--------|
| dncarbonell/fzap:latest | 393254adf4cd | 1.09GB | EN USO |
| zabbix/zabbix-web-nginx-pgsql:latest | 4d23de6390cc | 340MB | EN USO |
| zabbix/zabbix-server-pgsql:latest | b118d2f69194 | 99.5MB | EN USO |
| n8nio/n8n:latest | cb5fc3fb9bf6 | 1.98GB | EN USO |
| certbot/certbot:latest | c23159d30afd | 298MB | EN USO |
| chatwoot/chatwoot:v4.11.2 | 6a3e3c5c1332 | 2.8GB | EN USO |
| dpage/pgadmin4:latest | d243a4bcc02d | 742MB | EN USO |
| pgvector/pgvector:pg16 | 7d400e340efb | 621MB | EN USO |
| redis/redisinsight:latest | 55542a762210 | 544MB | EN USO |
| redis:7-alpine | 8b81dd37ff02 | 61.2MB | EN USO |
| httpd:2.4-alpine | 8f26f33a7002 | 97.8MB | EN USO |

---

## 12. Volumenes Docker

| Volumen | Tamano | Contenido |
|---------|--------|-----------|
| chativot_postgres_data | 341.2 MB | Todas las bases de datos PostgreSQL |
| chativot_chatwoot_storage | 51.14 MB | Archivos adjuntos y media de Chatwoot |
| chativot_n8n_data | 27.14 MB | Workflows y credenciales de n8n |
| chativot_pgadmin_data | 1.611 MB | Configuracion de pgAdmin 4 |
| chativot_redis_data | 272.3 KB | Persistencia Redis (RDB/AOF) |
| chativot_certbot_certs | 54.21 KB | Certificados SSL (external:true) |
| chativot_certbot_html | 0 B | ACME challenge webroot (external:true) |
| chativot_fzap_data | 0 B | Base de datos interna fZap |
| chativot_fzap_instances | 0 B | Sesiones WhatsApp (QR/auth) |
| chativot_zabbix_server_data | 0 B | Datos internos Zabbix |

> Volumenes anonimos eliminados con docker volume prune -f.

---

## 13. Certificados SSL

| Dominio | Vencimiento | Dias restantes | Estado |
|---------|-------------|----------------|--------|
| chatdev.chativot.com | 16 Jun 2026 | 87 dias | VALIDO |
| bddev.chativot.com | 16 Jun 2026 | 87 dias | VALIDO |
| dev.chativot.com | 16 Jun 2026 | 87 dias | VALIDO |
| fzapdev.chativot.com | 16 Jun 2026 | 87 dias | VALIDO |
| n8ndev.chativot.com | 16 Jun 2026 | 87 dias | VALIDO |
| redisdev.chativot.com | 16 Jun 2026 | 87 dias | VALIDO |
| zabbixdev.chativot.com | 16 Jun 2026 | 87 dias | VALIDO |

| Campo | Valor |
|-------|-------|
| Contenedor certbot | Activo — levantado 20 Mar 2026 |
| Renovacion automatica | Cada 6 horas (certbot renew --webroot) |
| Metodo validacion | Webroot |
| Tipo de clave | ECDSA |

---

## 14. Estructura del Proyecto (/opt/chativot)

| Archivo / Directorio | Tamano | Descripcion |
|----------------------|--------|-------------|
| docker-compose.yml | 8.1 KB | Stack Docker (certbot volumes external:true) |
| .env | 1.9 KB | Variables de entorno (credenciales) |
| apache/ | dir | Configuracion Apache y VirtualHosts SSL |
| scripts/ | dir | Scripts SQL de inicializacion de BD |

---

## 15. Variables de Entorno (.env)

Todos los valores estan redactados por seguridad.

| Variable | Grupo | Proposito |
|----------|-------|-----------|
| POSTGRES_USER / PASSWORD | PostgreSQL | Superusuario del motor de BD |
| PGADMIN_EMAIL / PASSWORD | pgAdmin | Credenciales de acceso web |
| ZABBIX_DB / USER / PASSWORD | Zabbix | BD y credenciales Zabbix |
| ZABBIX_TZ | Zabbix / n8n | Timezone compartida |
| N8N_DB / USER / PASSWORD | n8n | Base de datos n8n |
| N8N_BASIC_AUTH_USER / PASSWORD | n8n | Autenticacion basica del panel |
| N8N_ENCRYPTION_KEY | n8n | Cifrado de credenciales |
| N8N_CHATIVOT_DB / USER / PASS | n8n extra | BD n8n para Chativot |
| N8N_TUENTRADAWEB_DB / USER / PASS | n8n extra | BD n8n para Tu Entrada Web |
| FZAP_DB / USER / PASSWORD | fZap | Base de datos fZap |
| FZAP_ADMIN_TOKEN | fZap | Token de admin API |
| CHATWOOT_DB / USER / PASSWORD | Chatwoot | Base de datos Chatwoot |
| CHATWOOT_SECRET_KEY_BASE | Chatwoot | Clave secreta Rails |
| REDIS_PASSWORD | Redis | Contrasena Redis (compartida) |
| DOMAIN_BD/ZABBIX/N8N/FZAP/CHAT | Dominios | Subdominios *.dev.chativot.com |
| SMTP_* (7 variables) | Email | Configuracion Gmail para Chatwoot |
| CERTBOT_EMAIL | Certbot | Email para alertas SSL |

---

## 16. Servicios del Sistema (systemd)

Total servicios activos: 21

| Servicio | Descripcion |
|----------|-------------|
| docker.service | Motor Docker |
| containerd.service | Runtime de contenedores |
| ssh.service | Servidor OpenSSH |
| cron.service | Daemon cron (sin tareas activas) |
| rsyslog.service | Logging del sistema |
| systemd-timesyncd.service | NTP (sin chrony — Hetzner default) |
| systemd-networkd.service | Configuracion de red |
| systemd-resolved.service | Resolucion DNS stub |
| qemu-guest-agent.service | Agente QEMU Hetzner |
| snapd.service | Daemon Snap |
| unattended-upgrades.service | Parches de seguridad automaticos |
| multipathd.service | Device multipath controller |
| atd.service | Deferred execution scheduler |
| polkit.service | Gestor de autorizaciones |

---

## 17. Tareas Programadas (cron)

Sin tareas cron activas. crontab -l retorna salida vacia.

---

## 18. Comparativa con Servidor de Produccion (AWS)

| Caracteristica | Dev Hetzner v2 | Prod AWS v2 |
|----------------|----------------|-------------|
| Proveedor | Hetzner (Alemania) | AWS (us-east-1) |
| Tipo instancia | vServer KVM | t3.large KVM |
| CPU | 16 vCPU AMD EPYC Rome 2.0GHz | 2 vCPU Intel Xeon 2.5GHz |
| RAM | 30 GiB | 7.6 GiB |
| Disco | 76 GB SATA | 160 GB NVMe SSD |
| Swap | 8 GB OK | 4 GB OK |
| vm.swappiness | 10 OK | 10 OK |
| DOCKER-USER 8 puertos | OK en eth0 | OK en ens5 |
| iptables-persistent | OK | OK |
| UFW | OK (4 reglas limpias) | No instalado |
| Certbot activo | OK 12 contenedores | OK 12 contenedores |
| SSL valido | OK 7 certs 87 dias | OK 6 certs 87 dias |
| Imagenes residuales | 0 OK | 0 OK |
| Volumenes anonimos | 0 OK limpiados | 9 pendientes |
| Cron activo | Ninguno OK | Ninguno OK |
| NIC MTU | 1500 estandar | 9001 jumbo frames |
| Kernel | 6.8.0-90-generic | 6.17.0-1007-aws |
| QEMU Guest Agent | Si Hetzner | No AWS SSM Agent |

---

## 19. Resumen de Seguridad y Pendientes

### 19.1 Mejoras aplicadas el 20 Mar 2026

| Mejora | Fecha | Detalle |
|--------|-------|---------|
| SWAP 8 GB activa | 20 Mar 2026 | /swapfile fstab swappiness=10 |
| DOCKER-USER iptables | 20 Mar 2026 | 8 puertos bloqueados desde eth0 |
| iptables-persistent | 20 Mar 2026 | /etc/iptables/rules.v4 |
| Certbot levantado | 20 Mar 2026 | 7 certs SSL vigentes renovacion auto |
| external:true certbot | 20 Mar 2026 | docker-compose.yml actualizado |
| alpine eliminada | 20 Mar 2026 | Imagen residual removida |
| Volumenes limpiados | 20 Mar 2026 | docker volume prune -f ejecutado |
| UFW puertos internos removidos | 20 Mar 2026 | Solo 22 80 443 10051 |

### 19.2 Pendientes recomendados

| # | Tarea | Prioridad |
|---|-------|-----------|
| 1 | Live Restore Docker | Media |
| 2 | Restringir SSH por IP via UFW | Media |
| 3 | Snapshots automaticos Hetzner | Alta |
| 4 | Migrar credenciales fZap a .env | Alta |
| 5 | Migrar SMTP_PASSWORD a .env | Alta |

### 19.3 Postura de seguridad actual

| Area | Estado | Detalle |
|------|--------|---------|
| Puertos internos Docker | SEGURO | 8 puertos bloqueados via DOCKER-USER |
| Memoria OOM Killer | SEGURO | 8 GB swap activa y persistente |
| Firewall UFW | CORRECTO | Activo con 4 puertos legitimos |
| Persistencia iptables | ACTIVO | iptables-persistent instalado |
| Certbot SSL | ACTIVO | 7 certs validos renovacion auto |
| Imagenes residuales | LIMPIO | 0 imagenes sin uso |
| Volumenes anonimos | LIMPIO | Eliminados con docker volume prune |
| Cron | LIMPIO | Sin tareas activas |
| Live Restore Docker | PENDIENTE | Deshabilitado |
| SSH sin restriccion IP | PENDIENTE | Puerto 22 abierto a cualquier origen |
| Snapshots Hetzner | PENDIENTE | Sin politica de backup |
| Credenciales en compose | PENDIENTE | fZap y SMTP en texto plano |

---

*Generado automaticamente desde el servidor de desarrollo — Chativot.com — 20 Mar 2026*