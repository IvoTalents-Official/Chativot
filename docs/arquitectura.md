# Arquitectura de Infraestructura — Chativot.com

> **Version:** v2.0 — Post Hardening de Seguridad
> **Fecha de captura:** 19 de marzo de 2026
> **Generado desde:** servidor de produccion (datos reales del sistema)

---

## Mejoras aplicadas en esta version

| Mejora | Estado |
|--------|--------|
| SWAP 4 GB activada y persistente | OK |
| DOCKER-USER iptables (8 puertos bloqueados desde exterior) | OK |
| iptables-persistent instalado (reglas sobreviven reinicios) | OK |
| 5 imagenes residuales eliminadas (~4.67 GB liberados) | OK |
| Cron de branding eliminado | OK |
| vm.swappiness=10 configurado en /etc/sysctl.conf | OK |

---

## Indice

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Hardware y Sistema Operativo](#2-hardware-y-sistema-operativo)
3. [Memoria RAM y SWAP](#3-memoria-ram-y-swap)
4. [Almacenamiento y Sistema de Archivos](#4-almacenamiento-y-sistema-de-archivos)
5. [Red y Conectividad](#5-red-y-conectividad)
6. [Firewall y Seguridad de Red](#6-firewall-y-seguridad-de-red)
7. [Reglas DOCKER-USER iptables](#7-reglas-docker-user-iptables)
8. [Puertos Expuestos](#8-puertos-expuestos--estado-actual)
9. [Docker Engine](#9-docker-engine)
10. [Contenedores en Ejecucion](#10-contenedores-en-ejecucion)
11. [Imagenes Docker](#11-imagenes-docker)
12. [Volumenes Docker](#12-volumenes-docker)
13. [Estructura del Proyecto](#13-estructura-del-proyecto-optchativot)
14. [Variables de Entorno](#14-variables-de-entorno-env)
15. [Servicios del Sistema](#15-servicios-del-sistema-systemd)
16. [Tareas Programadas](#16-tareas-programadas-cron)
17. [Resumen de Seguridad y Pendientes](#17-resumen-de-seguridad-y-pendientes)

---

## 1. Resumen Ejecutivo

El servidor Chativot opera sobre una instancia **AWS EC2 t3.large** con Ubuntu 24.04.4 LTS, ejecutando **12 contenedores Docker** en estado running. Durante la sesion de mantenimiento del 19 de marzo de 2026 se aplicaron todas las mejoras de seguridad identificadas en la auditoria inicial.

| Campo | Valor |
|-------|-------|
| Proveedor Cloud | Amazon Web Services (AWS) |
| Tipo de instancia | t3.large (2 vCPU, 8 GB RAM) |
| Sistema Operativo | Ubuntu 24.04.4 LTS - Noble Numbat |
| Kernel | 6.17.0-1007-aws |
| Uptime al momento | up 4 days, 8 hours, 8 minutes |
| Hostname interno | ip-172-26-9-16 |
| IP privada VPC | 172.26.9.16 /20 |
| Docker Engine | 29.3.0 (Community) |
| Docker Compose | 5.1.0 (plugin) |
| Contenedores activos | 12 running / 0 detenidos |
| Imagenes en disco | 11 (todas en uso activo - 0 residuales) |
| Swap | 4 GB activa, persistente, swappiness=10 |
| Firewall | DOCKER-USER iptables (8 puertos protegidos) + iptables-persistent |
| Cron activo | Ninguno |
| Disco usado | N/A |

---

## 2. Hardware y Sistema Operativo

### 2.1 CPU

| Campo | Valor |
|-------|-------|
| Modelo | Intel Xeon Platinum 8259CL @ 2.50GHz |
| vCPUs asignadas | 2 (1 socket, 1 core, 2 threads - Hyper-Threading) |
| Arquitectura | x86_64, 64-bit |
| Hypervisor | KVM (Amazon EC2 - full virtualization) |
| NUMA nodes | 1 (node0: CPU 0,1) |
| Instrucciones AVX | AVX, AVX2, AVX-512F/DQ/BW/VL, AES-NI |

### 2.2 Sistema Operativo y Kernel

| Campo | Valor |
|-------|-------|
| Distribucion | Ubuntu 24.04.4 LTS (Noble Numbat) |
| Kernel | 6.17.0-1007-aws (optimizado para AWS) |
| Firmware | Amazon EC2 UEFI 1.0 (2017-10-16) |
| Cgroup version | v2 (systemd cgroup driver) |
| AppArmor | Activo (profile: builtin) |
| Seccomp | Activo (profile: builtin) |
| Machine ID | ec2d634de33b6146c1fdb574d47cbe48 |

---

## 3. Memoria RAM y SWAP

| Campo | Valor |
|-------|-------|
| RAM total | 7.6Gi |
| RAM usada | 3.1Gi |
| RAM libre | 561Mi |
| Buff/cache | 4.4Gi |
| SWAP total | 4.0Gi (/swapfile - archivo en disco NVMe) |
| SWAP usada | 3.2Mi |
| SWAP libre | 4.0Gi |
| Prioridad SWAP | -2 (ultimo recurso) |
| vm.swappiness | 10 (persistente en /etc/sysctl.conf) |
| SWAP en fstab | /swapfile none swap sw 0 0 |

> SWAP configurada correctamente: activa sin reinicio, persistente en /etc/fstab, vm.swappiness=10. El OOM Killer ya no puede terminar contenedores por agotamiento de memoria.

---

## 4. Almacenamiento y Sistema de Archivos

### 4.1 Disco NVMe

| Dispositivo | Tamano | Tipo | FS | Punto de montaje |
|-------------|--------|------|----|-----------------|
| nvme0n1 | 160 GB | NVMe SSD | - | Disco principal |
| nvme0n1p1 | 159 GB | partition | ext4 | / (raiz) |
| nvme0n1p14 | 4 MB | partition | - | BIOS boot (GPT) |
| nvme0n1p15 | 106 MB | partition | vfat | /boot/efi |
| nvme0n1p16 | 913 MB | partition | ext4 | /boot |
| /swapfile | 4 GB | archivo | swap | Memoria virtual |

### 4.2 Uso actual del disco

| Filesystem | Tipo | Tamano | Usado | Uso% | Montado en |
|------------|------|--------|-------|------|------------|
| /dev/root (nvme0n1p1) | ext4 | 154 GB | 19 GB | 12% | / |
| /dev/nvme0n1p16 | ext4 | 881 MB | 162 MB | 20% | /boot |
| /dev/nvme0n1p15 | vfat | 105 MB | 6.2 MB | 6% | /boot/efi |
| tmpfs | tmpfs | 3.9 GB | 0 | 0% | /dev/shm |

> Disco principal: 19 GB usados de 154 GB disponibles (12%). Quedan 136 GB libres.

---

## 5. Red y Conectividad

### 5.1 Interfaces de red

| Interfaz | IP / Subnet | MTU | Descripcion |
|----------|-------------|-----|-------------|
| lo | 127.0.0.1/8 | 65536 | Loopback |
| ens5 | 172.26.9.16/20 (DHCP) | 9001 (Jumbo frames) | NIC principal AWS - VPC 172.26.0.0/20 |
| docker0 | 172.17.0.1/16 | 1500 | Red Docker default (sin uso activo) |
| br-85b3890bc611 | 172.18.0.1/16 | 1500 | Bridge red chativot_chativot (stack activo) |
| veth* (x13) | - | 1500 | Interfaces virtuales por contenedor |

### 5.2 DNS

| Campo | Valor |
|-------|-------|
| Resolver local | 127.0.0.53 (systemd-resolved stub) |
| DNS uplink | 172.26.0.2 (AWS internal DNS) |
| Search domain | ec2.internal |

### 5.3 Tabla de rutas

| Destino | Gateway | Interfaz | Descripcion |
|---------|---------|----------|-------------|
| 0.0.0.0/0 | 172.26.0.1 | ens5 | Default GW (DHCP) |
| 172.17.0.0/16 | - | docker0 | Red Docker default (linkdown) |
| 172.18.0.0/16 | - | br-85b3890bc611 | Red chativot (activo) |
| 172.26.0.0/20 | - | ens5 | VPC subnet |

### 5.4 Redes Docker

| Network ID | Nombre | Driver | Estado |
|------------|--------|--------|--------|
| 85b3890bc611 | chativot_chativot | bridge | ACTIVA - todos los servicios |
| 11d1ddb8a0ef | bridge | bridge | Docker default (sin contenedores) |
| 93d7ff2cceca | host | host | Red del host |
| 7b39c074b131 | none | null | Sin red |

---

## 6. Firewall y Seguridad de Red

> ADVERTENCIA: UFW no instalado en este servidor. La seguridad de red se gestiona mediante iptables directamente a traves de la cadena DOCKER-USER. Se recomienda instalar UFW o usar Security Groups de AWS como capa adicional.

| Campo | Valor |
|-------|-------|
| Mecanismo activo | iptables + cadena DOCKER-USER |
| Persistencia | iptables-persistent instalado |
| Archivo de reglas | /etc/iptables/rules.v4 (guardado Mar 19 23:29) |
| Firewall backend Docker | iptables |

---

## 7. Reglas DOCKER-USER (iptables)

La cadena DOCKER-USER bloquea acceso externo directo a puertos internos de Docker desde ens5 (Internet). El trafico interno entre contenedores (172.18.0.0/16) NO es afectado - produccion opera normalmente.

| # | Puerto | Protocolo | Interfaz | Accion | Servicio protegido |
|---|--------|-----------|----------|--------|-------------------|
| 1 | 8081 | tcp | ens5 | DROP | Zabbix Web UI |
| 2 | 5540 | tcp | ens5 | DROP | RedisInsight |
| 3 | 5050 | tcp | ens5 | DROP | pgAdmin 4 |
| 4 | 8080 | tcp | ens5 | DROP | fZap WhatsApp API |
| 5 | 3000 | tcp | ens5 | DROP | Chatwoot Rails |
| 6 | 5678 | tcp | ens5 | DROP | n8n Workflows |
| 7 | 6379 | tcp | ens5 | DROP | Redis |
| 8 | 5432 | tcp | ens5 | DROP | PostgreSQL |

### Estado actual de la cadena DOCKER-USER
```
Chain DOCKER-USER (1 references)
num   pkts bytes target     prot opt in     out     source               destination         
1        0     0 DROP       6    --  ens5   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8081
2        0     0 DROP       6    --  ens5   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:5540
3        0     0 DROP       6    --  ens5   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:5050
4        0     0 DROP       6    --  ens5   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080
5        0     0 DROP       6    --  ens5   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:3000
6        0     0 DROP       6    --  ens5   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:5678
7        0     0 DROP       6    --  ens5   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:6379
8        0     0 DROP       6    --  ens5   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:5432
```

### Puertos publicos permitidos

| Puerto | Servicio | Justificacion |
|--------|----------|---------------|
| 22 | SSH | Acceso administrativo remoto |
| 80 | Apache HTTP | Redirige a HTTPS (necesario para ACME/Certbot) |
| 443 | Apache HTTPS | Trafico publico de todos los subdominios |
| 10051 | Zabbix Server | Recepcion de datos de agentes remotos |

---

## 8. Puertos Expuestos — Estado Actual

| Puerto | Proceso | Servicio | Acceso externo |
|--------|---------|----------|----------------|
| 22 | sshd | SSH | ABIERTO (acceso admin) |
| 80 | docker-proxy -> apache | HTTP | ABIERTO (redirige a HTTPS) |
| 443 | docker-proxy -> apache | HTTPS SSL | ABIERTO (trafico publico) |
| 3000 | docker-proxy -> chatwoot | Chatwoot Rails | BLOQUEADO por DOCKER-USER |
| 5050 | docker-proxy -> pgadmin | pgAdmin 4 | BLOQUEADO por DOCKER-USER |
| 5432 | docker-proxy -> postgres | PostgreSQL | BLOQUEADO por DOCKER-USER |
| 5540 | docker-proxy -> redisinsight | RedisInsight | BLOQUEADO por DOCKER-USER |
| 5678 | docker-proxy -> n8n | n8n | BLOQUEADO por DOCKER-USER |
| 6379 | docker-proxy -> redis | Redis | BLOQUEADO por DOCKER-USER |
| 8080 | docker-proxy -> fzap | fZap API | BLOQUEADO por DOCKER-USER |
| 8081 | docker-proxy -> zabbix-web | Zabbix Web | BLOQUEADO por DOCKER-USER |
| 10051 | docker-proxy -> zabbix-server | Zabbix agentes | ABIERTO (agentes remotos) |

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
| Security Options | apparmor + seccomp (builtin) + cgroupns |
| Docker Root Dir | /var/lib/docker |
| Compose plugin | 5.1.0 |
| Contenedores | 12 running / 0 paused / 0 stopped |
| Imagenes | 11 (100% en uso activo) |

---

## 10. Contenedores en Ejecucion

| Contenedor | Imagen | Estado | Puertos |
|------------|--------|--------|---------|
| chatwoot-rails | chatwoot/chatwoot:v4.11.2 | Up 14 hours | 0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp |
| chatwoot-sidekiq | chatwoot/chatwoot:v4.11.2 | Up 14 hours | 3000/tcp |
| fzap | dncarbonell/fzap:latest | Up 3 days | 0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp |
| redisinsight | redis/redisinsight:latest | Up 4 days | 0.0.0.0:5540->5540/tcp, [::]:5540->5540/tcp |
| apache | httpd:2.4-alpine | Up 4 days | 0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp |
| zabbix-web | zabbix/zabbix-web-nginx-pgsql:latest | Up 4 days (healthy) | 8443/tcp, 0.0.0.0:8081->8080/tcp, [::]:8081->8080/tcp |
| pgadmin | dpage/pgadmin4:latest | Up 4 days | 443/tcp, 0.0.0.0:5050->80/tcp, [::]:5050->80/tcp |
| zabbix-server | zabbix/zabbix-server-pgsql:latest | Up 4 days | 0.0.0.0:10051->10051/tcp, [::]:10051->10051/tcp |
| n8n | n8nio/n8n:latest | Up 4 days | 0.0.0.0:5678->5678/tcp, [::]:5678->5678/tcp |
| redis | redis:7-alpine | Up 4 days (healthy) | 0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp |
| postgres | pgvector/pgvector:pg16 | Up 4 days (healthy) | 0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp |
| certbot | certbot/certbot:latest | Up 4 days | 80/tcp, 443/tcp |

---

## 11. Imagenes Docker

Tras la limpieza realizada, las 11 imagenes presentes tienen contenedor activo. No hay residuos.

| Imagen:Tag | Image ID | Tamano | Estado |
|------------|----------|--------|--------|
| dncarbonell/fzap:latest | `393254adf4cd` | 1.09GB | EN USO |
| zabbix/zabbix-web-nginx-pgsql:latest | `4d23de6390cc` | 340MB | EN USO |
| zabbix/zabbix-server-pgsql:latest | `b118d2f69194` | 99.5MB | EN USO |
| n8nio/n8n:latest | `cb5fc3fb9bf6` | 1.98GB | EN USO |
| certbot/certbot:latest | `c23159d30afd` | 298MB | EN USO |
| chatwoot/chatwoot:v4.11.2 | `6a3e3c5c1332` | 2.8GB | EN USO |
| dpage/pgadmin4:latest | `d243a4bcc02d` | 742MB | EN USO |
| pgvector/pgvector:pg16 | `7d400e340efb` | 621MB | EN USO |
| redis/redisinsight:latest | `55542a762210` | 544MB | EN USO |
| redis:7-alpine | `8b81dd37ff02` | 61.2MB | EN USO |
| httpd:2.4-alpine | `8f26f33a7002` | 97.8MB | EN USO |

### Imagenes eliminadas en la sesion de limpieza

| Imagen eliminada | Espacio liberado |
|-----------------|-----------------|
| chatwoot/chatwoot:latest | ~2.8 GB |
| atendai/evolution-api:latest | ~1.37 GB (13 meses de antiguedad) |
| postgres:16-alpine | ~395 MB |
| nginx:alpine | ~93.5 MB |
| alpine:latest | ~13.1 MB |
| **Total** | **~4.67 GB** |

---

## 12. Volumenes Docker

| Volumen | Tamano | Contenido |
|---------|--------|-----------|
| chativot_postgres_data | 387.6 MB | Todas las bases de datos PostgreSQL |
| chativot_chatwoot_storage | 82.8 MB | Archivos, avatares y media de Chatwoot |
| chativot_n8n_data | 35.66 MB | Workflows y credenciales de n8n |
| chativot_pgadmin_data | 714.9 KB | Configuracion de pgAdmin 4 |
| chativot_redis_data | 552.2 KB | Persistencia Redis (RDB/AOF) |
| chativot_certbot_certs | 47.02 KB | Certificados SSL Let's Encrypt |
| chativot_certbot_html | 0 B | ACME challenge webroot |
| chativot_fzap_data | 0 B | Base de datos interna fZap |
| chativot_fzap_instances | 0 B | Sesiones WhatsApp (QR/auth) |
| chativot_zabbix_server_data | 0 B | Datos internos Zabbix |

> PENDIENTE: existen 9 volumenes anonimos (nombre de hash) sin contenedor activo. Limpiar con: docker volume prune -f

---

## 13. Estructura del Proyecto (/opt/chativot)

| Archivo / Directorio | Tamano | Descripcion |
|----------------------|--------|-------------|
| .env | 1.9K | Variables de entorno (credenciales) |
| Chativot.png | 30K | Logo principal Chativot |
| Chativot.svg | 4.5K | Logo principal Chativot (vectorial) |
| Chativot1.png | 174K | Logo variante 1 |
| Chativot1.svg | 4.4K | Logo variante 1 (vectorial) |
| Chativot1_512.png | 181K | Logo 512px para branding |
| Chativot_logo.png | 12K | Logo fondo claro |
| Chativot_logo_dark.png | 12K | Logo fondo oscuro |
| apache | 4.0K | Configuracion Apache + VirtualHosts |
| apply-branding.sh | 801 | Script branding (sin cron asociado) |
| branding.log | 0 | Log vaciado - cron eliminado (0 bytes) |
| chatwoot-custom | 4.0K | Archivos de personalizacion Chatwoot |
| docker-compose.yml | 8.1K | Definicion completa del stack Docker |
| favicon-16.png | 1.3K | Favicon 16px |
| favicon-32.png | 2.8K | Favicon 32px |
| favicon-512.png | 213K | Favicon 512px |
| favicon-96.png | 16K | Favicon 96px |
| favicon-apple.png | 41K | Favicon Apple Touch |
| favicon.png | 129K | Favicon original |
| install.sh | 5.3K | Script de instalacion inicial |
| nginx | 4.0K | Directorio legacy (sin uso activo) |
| scripts | 4.0K | Scripts SQL de inicializacion de BD |

---

## 14. Variables de Entorno (.env)

Todos los valores estan redactados por seguridad.

| Variable | Grupo | Proposito |
|----------|-------|-----------|
| POSTGRES_USER / PASSWORD | PostgreSQL | Superusuario del motor de BD |
| PGADMIN_EMAIL / PASSWORD | pgAdmin | Credenciales de acceso web |
| ZABBIX_DB / DB_USER / DB_PASSWORD | Zabbix | BD y credenciales Zabbix |
| ZABBIX_TZ | Zabbix / n8n | Timezone compartida |
| N8N_DB / DB_USER / DB_PASSWORD | n8n | Base de datos n8n |
| N8N_BASIC_AUTH_USER / PASSWORD | n8n | Autenticacion basica del panel |
| N8N_ENCRYPTION_KEY | n8n | Cifrado de credenciales almacenadas |
| N8N_CHATIVOT_DB / USER / PASS | n8n extra | BD n8n para Chativot |
| N8N_TUENTRADAWEB_DB / USER / PASS | n8n extra | BD n8n para Tu Entrada Web |
| FZAP_DB / DB_USER / DB_PASSWORD | fZap | Base de datos fZap |
| FZAP_ADMIN_TOKEN | fZap | Token de admin API |
| CHATWOOT_DB / DB_USER / DB_PASSWORD | Chatwoot | Base de datos Chatwoot |
| CHATWOOT_SECRET_KEY_BASE | Chatwoot | Clave secreta Rails |
| REDIS_PASSWORD | Redis | Contrasena Redis (compartida) |
| DOMAIN_BD / ZABBIX / N8N / FZAP / CHAT | Dominios | Subdominios publicos por servicio |
| SMTP_* (7 variables) | Email | Configuracion Gmail para Chatwoot |
| CERTBOT_EMAIL | Certbot | Email para alertas SSL |

---

## 15. Servicios del Sistema (systemd)

Total servicios activos: 27

| Servicio | Descripcion |
|----------|-------------|
| docker.service | Motor Docker - servicio principal del stack |
| containerd.service | Runtime de contenedores (dependencia de Docker) |
| ssh.service | Servidor OpenSSH - acceso administrativo |
| cron.service | Daemon cron (activo pero sin tareas configuradas) |
| rsyslog.service | Logging del sistema operativo |
| chrony.service | Sincronizacion de tiempo NTP |
| systemd-networkd.service | Configuracion de red del sistema |
| systemd-resolved.service | Resolucion DNS stub |
| snap.amazon-ssm-agent.amazon-ssm-agent.service | AWS Systems Manager Agent |
| unattended-upgrades.service | Parches de seguridad automaticos del OS |
| irqbalance.service | Balanceo de interrupciones entre CPUs |
| multipathd.service | Device multipath controller (AWS EBS) |
| fwupd.service | Daemon de actualizacion de firmware |
| polkit.service | Gestor de autorizaciones del sistema |
| acpid.service | Daemon de eventos ACPI (power management) |
| udisks2.service | Gestor de discos (montaje automatico) |

---

## 16. Tareas Programadas (cron)

Sin tareas cron activas. La tarea `*/5 * * * * /opt/chativot/apply-branding.sh` fue eliminada el 19 Mar 2026. El archivo branding.log fue vaciado (0 bytes).

---

## 17. Resumen de Seguridad y Pendientes

### 17.1 Medidas aplicadas

| Medida | Fecha | Detalle |
|--------|-------|---------|
| SWAP 4 GB activa | 19 Mar 2026 | /swapfile, persistente en fstab, swappiness=10 |
| DOCKER-USER iptables | 19 Mar 2026 | 8 puertos bloqueados desde ens5 (Internet) |
| iptables-persistent | 19 Mar 2026 | Reglas guardadas en /etc/iptables/rules.v4 |
| Limpieza de imagenes | 19 Mar 2026 | 5 imagenes eliminadas, ~4.67 GB liberados |
| Eliminacion cron | 19 Mar 2026 | Sin tareas residuales en background |
| branding.log vaciado | 19 Mar 2026 | Sin crecimiento indefinido |

### 17.2 Pendientes recomendados

| # | Tarea | Prioridad | Accion |
|---|-------|-----------|--------|
| 1 | Instalar UFW | Alta | apt install ufw && ufw allow 22,80,443,10051/tcp && ufw enable |
| 2 | Limpiar volumenes anonimos | Media | docker volume prune -f |
| 3 | Live Restore Docker | Media | Agregar live-restore:true en /etc/docker/daemon.json |
| 4 | Migrar credenciales fZap a .env | Alta | Reemplazar valores hardcodeados en docker-compose.yml |
| 5 | Migrar SMTP_PASSWORD a .env | Alta | Mover contrasena Gmail de compose a .env |
| 6 | Restringir SSH por IP | Media | Security Group AWS o iptables por IP de administracion |
| 7 | Snapshots automaticos EBS | Alta | Configurar desde consola AWS Lightsail/EC2 |

### 17.3 Postura de seguridad actual

| Area | Estado | Detalle |
|------|--------|---------|
| Puertos internos Docker | SEGURO | 8 puertos bloqueados via DOCKER-USER |
| Memoria (OOM Killer) | SEGURO | 4 GB swap activa y persistente |
| Imagenes residuales | LIMPIO | 0 imagenes sin uso en disco |
| Tareas cron residuales | LIMPIO | Sin tareas activas en crontab |
| Persistencia iptables | ACTIVO | iptables-persistent instalado |
| Firewall UFW | PENDIENTE | No instalado - usando iptables directo |
| Credenciales en compose | PENDIENTE | fZap y SMTP aun en texto plano |
| Acceso SSH sin restriccion | PENDIENTE | Puerto 22 abierto a cualquier origen |
| Volumenes anonimos Docker | PENDIENTE | 9 volumenes huerfanos a limpiar |
| Snapshots / Backup EBS | PENDIENTE | Sin politica de backup configurada |
| Live Restore Docker | PENDIENTE | Deshabilitado |

---

*Documento generado automaticamente desde el servidor de produccion — Chativot.com — 19 Mar 2026*
