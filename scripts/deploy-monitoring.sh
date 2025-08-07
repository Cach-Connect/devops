#!/bin/bash

# Cach Connect Monitoring Stack Deployment Script

set -e

ENVIRONMENT=${1:-production}
ACTION=${2:-up}

echo "🚀 Deploying Cach Connect monitoring stack..."
echo "🔧 Environment: $ENVIRONMENT"
echo "⚡ Action: $ACTION"

# Navigate to the devops directory
cd "$(dirname "$0")/.."

# Create required directories
echo "📁 Creating required directories..."
mkdir -p ssl/certs ssl/private ssl/www
mkdir -p monitoring/grafana/dashboards
mkdir -p logs

# Set permissions
chmod +x scripts/certbot/*.sh

if [ "$ACTION" = "up" ]; then
    echo "🐳 Starting monitoring services..."
    
    # Start shared services (monitoring stack)
    docker-compose -f docker-compose/docker-compose.shared.yml up -d
    
    echo "⏳ Waiting for services to be ready..."
    sleep 30
    
    # Check service health
    echo "🔍 Checking service health..."
    
    services=("prometheus" "grafana" "loki" "alertmanager")
    for service in "${services[@]}"; do
        if docker ps | grep -q "cach_$service"; then
            echo "✅ $service is running"
        else
            echo "❌ $service is not running"
        fi
    done
    
    echo "🎉 Monitoring stack deployment completed!"
    echo "📊 Access points:"
    echo "   - Grafana: http://localhost:3000 (admin/admin123)"
    echo "   - Prometheus: http://localhost:9090"
    echo "   - Alertmanager: http://localhost:9093"
    
elif [ "$ACTION" = "down" ]; then
    echo "🛑 Stopping monitoring services..."
    docker-compose -f docker-compose/docker-compose.shared.yml down
    
elif [ "$ACTION" = "restart" ]; then
    echo "🔄 Restarting monitoring services..."
    docker-compose -f docker-compose/docker-compose.shared.yml restart
    
elif [ "$ACTION" = "logs" ]; then
    echo "📋 Showing monitoring services logs..."
    docker-compose -f docker-compose/docker-compose.shared.yml logs -f
    
else
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [environment] [up|down|restart|logs]"
    exit 1
fi
