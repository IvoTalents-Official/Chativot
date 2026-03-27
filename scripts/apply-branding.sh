#!/bin/bash
sleep 15

# Esperar que chatwoot esté corriendo
until docker exec chatwoot-rails echo "ready" 2>/dev/null; do
  sleep 5
done

# Copiar logo
docker cp /opt/chativot/chatwoot-custom/Chativot.png chatwoot-rails:/app/public/brand-assets/Chativot.png

# Copiar JS modificados
docker cp /opt/chativot/chatwoot-custom/DashboardIcon-2tevt9IJ.js chatwoot-rails:/app/public/vite/assets/
docker cp /opt/chativot/chatwoot-custom/v3app-DdPZtMec.js chatwoot-rails:/app/public/vite/assets/

# Copiar favicons
for f in favicon-16.png favicon-32.png favicon-96.png favicon-512.png favicon-apple.png; do
  if [ -f /opt/chativot/chatwoot-custom/$f ]; then
    docker cp /opt/chativot/chatwoot-custom/$f chatwoot-rails:/app/public/
  fi
done

echo "$(date) - Branding aplicado" >> /opt/chativot/branding.log
