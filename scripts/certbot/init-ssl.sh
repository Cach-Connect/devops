#!/bin/bash

# Cach Connect SSL Certificate Initialization Script
# This script obtains initial SSL certificates for all domains

set -e

DOMAINS=(
    "api.cachconnect.co.ke"
    "api.staging.cachconnect.co.ke"
    "admin.cachconnect.co.ke"
    "admin.staging.cachconnect.co.ke"
    "agents.cachconnect.co.ke"
    "agents.staging.cachconnect.co.ke"
    "distributors.cachconnect.co.ke"
    "distributors.staging.cachconnect.co.ke"
    "business.cachconnect.co.ke"
    "business.staging.cachconnect.co.ke"
    "lenders.cachconnect.co.ke"
    "lenders.staging.cachconnect.co.ke"
    "files.cachconnect.co.ke"
    "files.staging.cachconnect.co.ke"
    "grafana.cachconnect.co.ke"
    "alerts.cachconnect.co.ke"
    "www.cachconnect.co.ke"
    "cachconnect.co.ke"
)

EMAIL="admin@cachconnect.co.ke"
STAGING=${1:-false}

if [ "$STAGING" = "true" ]; then
    echo "🧪 Using Let's Encrypt staging environment"
    STAGING_FLAG="--staging"
else
    echo "🔒 Using Let's Encrypt production environment"
    STAGING_FLAG=""
fi

echo "🚀 Starting SSL certificate initialization for Cach Connect..."

# Create required directories
mkdir -p /etc/letsencrypt
mkdir -p /var/www/certbot

for domain in "${DOMAINS[@]}"; do
    echo "📜 Obtaining certificate for $domain..."
    
    certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        $STAGING_FLAG \
        -d $domain
    
    if [ $? -eq 0 ]; then
        echo "✅ Certificate obtained successfully for $domain"
    else
        echo "❌ Failed to obtain certificate for $domain"
    fi
done

echo "🔄 Reloading nginx configuration..."
nginx -s reload

echo "🎉 SSL certificate initialization completed!"
echo "📅 Certificates will auto-renew. Check with: certbot certificates"
