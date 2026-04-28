#!/bin/bash
echo "Parcheando puertos vulnerables en Docker Compose..."

find /opt/chativot* -type f \( -name "docker-compose.yml" -o -name "docker-compose.yaml" \) | while read file; do
    echo "Procesando $file..."
    # Reemplaza puertos expuestos agregando 127.0.0.1
    sed -i -E '/127\.0\.0\.1/! s/- "([0-9]{4,5}):([0-9]{1,5})"/- "127.0.0.1:\1:\2"/g' "$file"
    
    # Levanta la infraestructura con los nuevos parámetros de seguridad
    dir=$(dirname "$file")
    cd "$dir" && docker compose up -d
done
echo "¡Puertos internos asegurados!"
