#!/bin/bash

# Cach Connect Shared Infrastructure Deployment Script
# This script deploys the shared monitoring and infrastructure stack

set -e

ENVIRONMENT=${1:-production}
ACTION=${2:-deploy}
SSL_MODE=${3:-production}

echo "🚀 Cach Connect Shared Infrastructure Deployment"
echo "🔧 Environment: $ENVIRONMENT"
echo "⚡ Action: $ACTION"
echo "🔒 SSL Mode: $SSL_MODE"

# Navigate to the devops directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVOPS_DIR="$(dirname "$SCRIPT_DIR")"
cd "$DEVOPS_DIR"

# Function to check if a service is healthy
check_service_health() {
    local service=$1
    local port=$2
    local endpoint=${3:-"/"}
    
    echo "🔍 Checking $service health..."
    timeout=30
    while [ $timeout -gt 0 ]; do
        if curl -s "http://localhost:$port$endpoint" > /dev/null; then
            echo "✅ $service is healthy"
            return 0
        fi
        echo "⏳ Waiting for $service... ($timeout seconds remaining)"
        sleep 5
        timeout=$((timeout-5))
    done
    echo "❌ $service health check failed"
    return 1
}

# Function to deploy services
deploy_services() {
    echo "📋 Creating required directories..."
    mkdir -p ssl/certs ssl/private ssl/www
    mkdir -p logs
    
    echo "🔧 Setting script permissions..."
    chmod +x scripts/*.sh scripts/certbot/*.sh 2>/dev/null || echo "⚠️  Some scripts may not exist yet"
    
    # Verify critical files exist
    echo "🔍 Verifying configuration files..."
    required_files=(
        "monitoring/prometheus/prometheus.yml"
        "monitoring/loki/loki.yml"
        "monitoring/promtail/promtail.yml"
        "monitoring/alertmanager/alertmanager.yml"
        "monitoring/grafana/provisioning/datasources/datasources.yml"
        "nginx/nginx.conf"
        "docker-compose/docker-compose.shared.yml"
    )
    
    missing_files=false
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            echo "✅ $file exists"
        else
            echo "❌ $file is missing"
            missing_files=true
        fi
    done
    
    if [ "$missing_files" = true ]; then
        echo "❌ Some required configuration files are missing."
        echo "📁 Current directory structure:"
        find . -type f -name "*.yml" -o -name "*.yaml" -o -name "*.conf" | head -20
        echo "💡 Make sure you're running this from the devops directory with all files present."
        return 1
    fi
    
    echo "📋 Setting up environment configuration..."
    if [ ! -f ".env.monitoring" ]; then
        cp env.monitoring.example .env.monitoring
        echo "⚠️  Please edit .env.monitoring with your actual values"
    fi
    
    echo "🐳 Pulling latest Docker images..."
    docker-compose -f docker-compose/docker-compose.shared.yml pull
    
    echo "🚀 Starting shared services..."
    docker-compose -f docker-compose/docker-compose.shared.yml up -d
    
    echo "⏳ Waiting for services to initialize..."
    sleep 30
    
    echo "🔍 Checking service health..."
    services=(
        "prometheus:9090:-/healthy"
        "grafana:3000:/api/health"
        "loki:3100:/ready"
        "alertmanager:9093:-/healthy"
    )
    
    all_healthy=true
    for service_info in "${services[@]}"; do
        IFS=':' read -r service port endpoint <<< "$service_info"
        if ! check_service_health "$service" "$port" "$endpoint"; then
            all_healthy=false
        fi
    done
    
    if [ "$all_healthy" = false ]; then
        echo "❌ Some services failed health checks. Showing logs..."
        docker-compose -f docker-compose/docker-compose.shared.yml logs --tail=50
        return 1
    fi
    
    echo "🎉 All services are healthy!"
    echo "📊 Access points:"
    echo "   - Grafana: http://localhost:3000 (admin/CachConnect2024!)"
    echo "   - Prometheus: http://localhost:9090"
    echo "   - Alertmanager: http://localhost:9093"
    echo "   - Loki: http://localhost:3100"
}

# Function to setup SSL
setup_ssl() {
    echo "🔒 Setting up SSL certificates..."
    
    # Ensure nginx is running
    docker-compose -f docker-compose/docker-compose.shared.yml up -d nginx
    sleep 10
    
    # Run SSL setup
    if [ "$SSL_MODE" = "staging" ]; then
        ./scripts/setup-ssl.sh staging
    else
        ./scripts/setup-ssl.sh false
    fi
    
    echo "✅ SSL setup completed"
}

# Function to restart services
restart_services() {
    echo "🔄 Restarting shared services..."
    docker-compose -f docker-compose/docker-compose.shared.yml restart
    
    # Brief health check
    sleep 15
    if check_service_health "grafana" "3000" "/api/health"; then
        echo "✅ Services restarted successfully"
    else
        echo "⚠️  Services restarted but may still be starting up"
    fi
}

# Function to stop services
stop_services() {
    echo "🛑 Stopping shared services..."
    docker-compose -f docker-compose/docker-compose.shared.yml down
    echo "✅ Services stopped successfully"
}

# Function to show logs
show_logs() {
    echo "📋 Showing service logs..."
    docker-compose -f docker-compose/docker-compose.shared.yml logs -f
}

# Function to show status
show_status() {
    echo "📊 Service status:"
    docker-compose -f docker-compose/docker-compose.shared.yml ps
    
    echo ""
    echo "🔍 Container health:"
    docker ps --filter "name=cach_" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Main execution
case "$ACTION" in
    "deploy")
        deploy_services
        ;;
    "ssl-setup")
        setup_ssl
        ;;
    "ssl-renew")
        echo "🔄 Renewing SSL certificates..."
        ./scripts/certbot/renew-ssl.sh
        ;;
    "restart")
        restart_services
        ;;
    "stop")
        stop_services
        ;;
    "logs")
        show_logs
        ;;
    "status")
        show_status
        ;;
    "full-deploy")
        deploy_services
        setup_ssl
        ;;
    *)
        echo "❌ Unknown action: $ACTION"
        echo ""
        echo "Usage: $0 [environment] [action] [ssl_mode]"
        echo ""
        echo "Actions:"
        echo "  deploy       - Deploy monitoring stack"
        echo "  ssl-setup    - Setup SSL certificates"
        echo "  ssl-renew    - Renew SSL certificates"
        echo "  restart      - Restart all services"
        echo "  stop         - Stop all services"
        echo "  logs         - Show service logs"
        echo "  status       - Show service status"
        echo "  full-deploy  - Deploy stack and setup SSL"
        echo ""
        echo "SSL Modes:"
        echo "  staging      - Use Let's Encrypt staging (for testing)"
        echo "  production   - Use Let's Encrypt production"
        exit 1
        ;;
esac

# Cleanup
echo "🧹 Cleaning up unused Docker resources..."
docker system prune -f > /dev/null 2>&1 || true

echo "🎉 Operation completed successfully!"
