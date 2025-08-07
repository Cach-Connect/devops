#!/bin/bash

# Cach Connect SSL Certificate Renewal Script (containerized)
# Runs certbot using the Docker image defined in docker-compose.shared.yml

set -e

echo "🔄 Starting SSL certificate renewal (via Docker)..."

# Move to shared root (where docker-compose.shared.yml lives)
cd "$(dirname "$0")/../.."

# Ensure required directories exist
mkdir -p ssl/letsencrypt ssl/www

# Run certbot renew inside the container with proper mounts from docker-compose
# Note: Using docker-compose run so we leverage the volumes defined there
docker-compose -f docker-compose.shared.yml run --rm \
  certbot renew --webroot -w /var/www/certbot --quiet || true

# Reload nginx inside its container to pick up any renewed certs
echo "🔄 Reloading nginx..."
docker-compose -f docker-compose.shared.yml exec -T nginx nginx -s reload || {
  echo "⚠️  Could not reload nginx (container may be restarting)."
}

echo "🎉 SSL certificate renewal run completed"
