#!/bin/bash

# Cach Connect SSL Certificate Renewal Script
# This script should be run via cron for automatic certificate renewal

set -e

echo "🔄 Starting SSL certificate renewal check..."

# Attempt to renew certificates
certbot renew --quiet --webroot --webroot-path=/var/www/certbot

# Check if renewal was successful
if [ $? -eq 0 ]; then
    echo "✅ Certificate renewal check completed successfully"
    
    # Reload nginx if certificates were renewed
    if [ -f /var/log/letsencrypt/letsencrypt.log ]; then
        if grep -q "renewed" /var/log/letsencrypt/letsencrypt.log; then
            echo "🔄 Certificates were renewed, reloading nginx..."
            nginx -s reload
            echo "✅ Nginx reloaded successfully"
        fi
    fi
else
    echo "❌ Certificate renewal failed"
    exit 1
fi

echo "🎉 SSL certificate renewal process completed!"
