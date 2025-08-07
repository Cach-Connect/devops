#!/bin/bash

# Cach Connect SSL Setup Script

set -e

STAGING=${1:-false}

echo "🔒 Setting up SSL certificates for Cach Connect..."

# Navigate to the devops directory
cd "$(dirname "$0")/.."

# Create required directories
mkdir -p ssl/letsencrypt ssl/www

# Ensure nginx is running to serve ACME challenge
if ! docker ps | grep -q "cach_nginx"; then
    echo "🚀 Starting nginx for ACME challenge..."
    docker-compose -f docker-compose.shared.yml up -d nginx
    sleep 10
fi

# Run the SSL initialization script
echo "📜 Obtaining SSL certificates..."
docker run --rm \
    -v "$(pwd)/ssl/letsencrypt:/etc/letsencrypt" \
    -v "$(pwd)/ssl/www:/var/www/certbot" \
    -v "$(pwd)/scripts/certbot:/scripts" \
    --entrypoint=/bin/bash \
    certbot/certbot:latest \
    /scripts/init-ssl.sh $STAGING

# Set up automatic renewal via cron
echo "⏰ Setting up automatic renewal..."
cat > /tmp/certbot-cron << 'EOF'
# Renew SSL certificates twice daily
0 12 * * * /opt/cach/devops/scripts/certbot/renew-ssl.sh >> /var/log/certbot-renew.log 2>&1
0 0 * * * /opt/cach/devops/scripts/certbot/renew-ssl.sh >> /var/log/certbot-renew.log 2>&1
EOF

# Install cron job (requires sudo)
if [ "$EUID" -eq 0 ]; then
    crontab /tmp/certbot-cron
    echo "✅ Automatic renewal configured"
else
    echo "⚠️  Please run the following as root to set up automatic renewal:"
    echo "   sudo crontab /tmp/certbot-cron"
fi

rm /tmp/certbot-cron

echo "🎉 SSL setup completed!"
echo "🔄 Reloading nginx with SSL configuration..."
docker-compose -f docker-compose.shared.yml restart nginx

echo "✅ SSL certificates are now active!"
