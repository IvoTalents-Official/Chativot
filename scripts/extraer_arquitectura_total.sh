#!/bin/bash

OUTPUT="architecture_total.md"
echo "Generando reporte maestro de arquitectura con arte ASCII. Esto tomará unos segundos..."

# 1. Cabecera y Logo ASCII de Ubuntu
echo "# Reporte Maestro de Arquitectura y Estado del Servidor" > $OUTPUT
echo "" >> $OUTPUT
echo '```text' >> $OUTPUT
echo "            .-/+oossssoo+/-.               " >> $OUTPUT
echo "        \`:+ssssssssssssssssss+:\`           " >> $OUTPUT
echo "      -+ssssssssssssssssssyyssss+-         " >> $OUTPUT
echo "    .ossssssssssssssssssdMMMNysssso.       " >> $OUTPUT
echo "   /ssssssssssshdmmNNmmyNMMMMhssssss/      " >> $OUTPUT
echo "  +ssssssssshmydMMMMMMMNddddyssssssss+     " >> $OUTPUT
echo " /sssssssshNMMMyhhyyyyhmNMMMNhssssssss/    " >> $OUTPUT
echo ".ssssssssdMMMNhsssssssssshNMMMdssssssss.   " >> $OUTPUT
echo "+sssshhhyNMMNyssssssssssssyNMMMysssssss+   " >> $OUTPUT
echo "ossyNMMMNyMMhsssssssssssssshmmmhssssssso   " >> $OUTPUT
echo "ossyNMMMNyMMhsssssssssssssshmmmhssssssso   " >> $OUTPUT
echo "+sssshhhyNMMNyssssssssssssyNMMMysssssss+   " >> $OUTPUT
echo ".ssssssssdMMMNhsssssssssshNMMMdssssssss.   " >> $OUTPUT
echo " \sssssssshNMMMyhhyyyyhdNMMMNhssssssss/    " >> $OUTPUT
echo "  +sssssssssdmydMMMMMMMMddddyssssssss+     " >> $OUTPUT
echo "   \ssssssssssshdmmNNmmyNMMMMhssssss/      " >> $OUTPUT
echo "    .ossssssssssssssssssdMMMNysssso.       " >> $OUTPUT
echo "      -+sssssssssssssssssyyyssss+-         " >> $OUTPUT
echo "        \`:+ssssssssssssssssss+:\`           " >> $OUTPUT
echo "            .-/+oossssoo+/-.               " >> $OUTPUT
echo '```' >> $OUTPUT
echo "" >> $OUTPUT

echo "**Generado el:** $(date)" >> $OUTPUT
echo "**Hostname:** $(hostname)" >> $OUTPUT

# 2. Hardware y Sistema Operativo
echo -e "\n## 1. Sistema Operativo y Hardware" >> $OUTPUT
echo '```text' >> $OUTPUT
cat /etc/os-release | grep PRETTY_NAME >> $OUTPUT
uname -r >> $OUTPUT
echo "--- CPU ---" >> $OUTPUT
lscpu | grep -E "^Model name|^CPU\(s\):|^Thread\(s\) per core:" >> $OUTPUT
echo "--- MEMORIA (Total, Usada, Libre, Swap) ---" >> $OUTPUT
free -h >> $OUTPUT
echo "--- ALMACENAMIENTO Y PARTICIONES ---" >> $OUTPUT
lsblk >> $OUTPUT
echo "--- ESPACIO EN DISCO ---" >> $OUTPUT
df -h / >> $OUTPUT
echo '```' >> $OUTPUT

# 3. Red e IPs
echo -e "\n## 2. Red e IPs Asignadas" >> $OUTPUT
echo '```text' >> $OUTPUT
echo "--- IPs INTERNAS Y TARJETAS DE RED ---" >> $OUTPUT
ip -br a >> $OUTPUT
echo "--- IP PÚBLICA ---" >> $OUTPUT
curl -s --max-time 5 ifconfig.me >> $OUTPUT
echo "" >> $OUTPUT
echo '```' >> $OUTPUT

# 4. Seguridad (Iptables)
echo -e "\n## 3. Seguridad y Cortafuegos (Iptables Nativo)" >> $OUTPUT
echo '```text' >> $OUTPUT
echo "--- PUERTOS ABIERTOS Y ESCUCHANDO ---" >> $OUTPUT
ss -tulpn >> $OUTPUT
echo "--- REGLAS ACTIVAS DE IPTABLES ---" >> $OUTPUT
iptables-save >> $OUTPUT
echo '```' >> $OUTPUT

# 5. Auditoría de Vulnerabilidades
echo -e "\n## 4. Auditoría de Vulnerabilidades (Parches Pendientes)" >> $OUTPUT
echo '```text' >> $OUTPUT
echo "Actualizando lista de repositorios silenciosamente..." >> $OUTPUT
apt-get update -qq
echo "Buscando paquetes con actualizaciones de seguridad pendientes..." >> $OUTPUT
apt-get -s upgrade | grep "^Inst" | grep -i security >> $OUTPUT
echo "Total de paquetes con actualizaciones disponibles (general):" >> $OUTPUT
apt list --upgradable 2>/dev/null | wc -l >> $OUTPUT
echo '```' >> $OUTPUT

# 6. Docker (Contenedores, Redes, Volúmenes)
echo -e "\n## 5. Ecosistema Docker COMPLETO" >> $OUTPUT
echo "### Contenedores (Todos)" >> $OUTPUT
echo '```text' >> $OUTPUT
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}\t{{.Size}}" >> $OUTPUT
echo '```' >> $OUTPUT

echo "### Redes Docker" >> $OUTPUT
echo '```text' >> $OUTPUT
docker network ls >> $OUTPUT
echo '```' >> $OUTPUT

echo "### Volúmenes Docker" >> $OUTPUT
echo '```text' >> $OUTPUT
docker volume ls >> $OUTPUT
echo '```' >> $OUTPUT

echo "### Imágenes Descargadas" >> $OUTPUT
echo '```text' >> $OUTPUT
docker images >> $OUTPUT
echo '```' >> $OUTPUT

# 7. Apache Virtual Hosts
echo -e "\n## 6. Configuración de Apache (Virtual Hosts)" >> $OUTPUT
echo '```text' >> $OUTPUT
docker exec apache httpd -S 2>/dev/null || docker exec apache apache2ctl -S 2>/dev/null >> $OUTPUT
echo '```' >> $OUTPUT

# 8. Archivos Docker Compose (Seguros)
echo -e "\n## 7. Archivos Docker Compose (Seguros - Sin contraseñas)" >> $OUTPUT
find /opt/chativot* -maxdepth 2 -type f \( -name "docker-compose.yml" -o -name "docker-compose.yaml" \) 2>/dev/null | while read file; do
    echo "### Archivo: $file" >> $OUTPUT
    echo '```yaml' >> $OUTPUT
    grep -ivE "password|passwd|secret|token" "$file" >> $OUTPUT
    echo '```' >> $OUTPUT
done

echo "Listo. Todo guardado impecable en $OUTPUT"
