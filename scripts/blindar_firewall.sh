#!/bin/bash
echo "Configurando firewall nativo (Iptables)..."

# 1. Asegurar persistencia y política salvavidas
sudo apt-get install -y iptables-persistent
sudo iptables -P INPUT ACCEPT

# 2. Limpieza de reglas de entrada
sudo iptables -F INPUT

# 3. Reglas esenciales (Loopback y Conexiones activas como tu SSH)
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 4. Puertos permitidos al público
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 5. Política estricta de bloqueo
sudo iptables -P INPUT DROP

# 6. Limpiar cadena DOCKER-USER
sudo iptables -F DOCKER-USER
sudo iptables -A DOCKER-USER -j RETURN

# 7. Guardar reglas
sudo netfilter-persistent save
echo "¡Firewall de producción blindado!"
