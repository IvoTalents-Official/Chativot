# Arquitectura del Servidor — Chativot.com

> Actualizado: 20 de March de 2026 | v2.0 — Post hardening

## Instancia
| Campo | Valor |
|---|---|
| Proveedor | AWS EC2 |
| Tipo | t3.large (2 vCPU / 8 GB RAM) |
| OS | Ubuntu 24.04.4 LTS (Noble Numbat) |
| Kernel | 6.17.0-1007-aws |
| IP privada | 172.26.9.16 |
| Uptime | up 4 days, 7 hours, 37 minutes |

## Docker
| Campo | Valor |
|---|---|
| Docker Engine | 29.3.0 |
| Docker Compose | 5.1.0 |
| Contenedores activos | 12 |
| Imágenes en disco | 11 |

## Contenedores
| Nombre | Imagen | Estado | Puertos |
|---|---|---|---|
| chatwoot-rails | `chatwoot/chatwoot:v4.11.2` | Up 14 hours | 0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp |
| chatwoot-sidekiq | `chatwoot/chatwoot:v4.11.2` | Up 14 hours | 3000/tcp |
| fzap | `dncarbonell/fzap:latest` | Up 3 days | 0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp |
| redisinsight | `redis/redisinsight:latest` | Up 4 days | 0.0.0.0:5540->5540/tcp, [::]:5540->5540/tcp |
| apache | `httpd:2.4-alpine` | Up 4 days | 0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp |
| zabbix-web | `zabbix/zabbix-web-nginx-pgsql:latest` | Up 4 days (healthy) | 8443/tcp, 0.0.0.0:8081->8080/tcp, [::]:8081->8080/tcp |
| pgadmin | `dpage/pgadmin4:latest` | Up 4 days | 443/tcp, 0.0.0.0:5050->80/tcp, [::]:5050->80/tcp |
| zabbix-server | `zabbix/zabbix-server-pgsql:latest` | Up 4 days | 0.0.0.0:10051->10051/tcp, [::]:10051->10051/tcp |
| n8n | `n8nio/n8n:latest` | Up 4 days | 0.0.0.0:5678->5678/tcp, [::]:5678->5678/tcp |
| redis | `redis:7-alpine` | Up 4 days (healthy) | 0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp |
| postgres | `pgvector/pgvector:pg16` | Up 4 days (healthy) | 0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp |
| certbot | `certbot/certbot:latest` | Up 4 days | 80/tcp, 443/tcp |

## Seguridad aplicada (19 Mar 2026)
| Medida | Estado |
|---|---|
| SWAP 4 GB activa y persistente | ✅ |
| DOCKER-USER iptables (8 puertos bloqueados) | ✅ |
| iptables-persistent instalado | ✅ |
| Imágenes residuales eliminadas (~4.67 GB) | ✅ |
| Cron residual eliminado | ✅ |
| UFW | ⚠ Pendiente instalar |
| Credenciales hardcodeadas en compose | ⚠ Pendiente migrar a .env |

## Disco
| Campo | Valor |
|---|---|
| Uso disco | 19G de 154G (12% usado) |

## Reglas DOCKER-USER activas
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
