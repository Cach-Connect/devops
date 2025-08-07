#!/bin/sh

# Cach Connect SSL Certificate Initialization Script
# This script obtains initial SSL certificates for all domains

set -e

DOMAINS="api.cachconnect.co.ke \
admin.cachconnect.co.ke \
cachconnect.co.ke \
www.cachconnect.co.ke \
agents.cachconnect.co.ke \
distributors.cachconnect.co.ke \
business.cachconnect.co.ke \
lenders.cachconnect.co.ke \
api.staging.cachconnect.co.ke \
admin.staging.cachconnect.co.ke \
staging.cachconnect.co.ke \
agents.staging.cachconnect.co.ke \
distributors.staging.cachconnect.co.ke \
business.staging.cachconnect.co.ke \
lenders.staging.cachconnect.co.ke \
api.sandbox.cachconnect.co.ke \
admin.sandbox.cachconnect.co.ke \
agents.sandbox.cachconnect.co.ke \
distributors.sandbox.cachconnect.co.ke \
business.sandbox.cachconnect.co.ke \
lenders.sandbox.cachconnect.co.ke \
monitoring.cachconnect.co.ke \
storage.cachconnect.co.ke \
storage.staging.cachconnect.co.ke \
storage.sandbox.cachconnect.co.ke"

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

for domain in $DOMAINS; do
    echo "📜 Obtaining certificate for $domain..."
    # Allow failure per-domain so we continue the loop
    set +e
    certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        $STAGING_FLAG \
        -d $domain -v
    status=$?
    set -e
    if [ $status -eq 0 ]; then
        echo "✅ Certificate obtained successfully for $domain"
    else
        echo "❌ Failed to obtain certificate for $domain"
    fi
done

echo "🎉 SSL certificate initialization completed!"
echo "📅 Certificates will auto-renew. Check with: certbot certificates"
