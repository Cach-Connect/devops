#!/bin/bash

# Cach Multi-Environment Deployment Script
# Usage: ./deploy.sh [command] [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=""
SERVICE=""
ACTION="deploy"
FORCE=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  start-monitoring    Start consolidated monitoring stack"
    echo "  stop-monitoring     Stop consolidated monitoring stack"
    echo "  start-nginx         Start nginx reverse proxy"
    echo "  stop-nginx          Stop nginx reverse proxy"
    echo "  start-all           Start all services (monitoring + nginx + apps)"
    echo "  stop-all            Stop all services"
    echo "  deploy-app          Deploy specific app to environment"
    echo "  status              Show status of all services"
    echo "  logs                Show logs for specific service"
    echo "  ssl-renew           Renew SSL certificates"
    echo ""
    echo "Options:"
    echo "  -e, --environment   Environment (production|staging|sandbox)"
    echo "  -s, --service       Service name (api|agents|distributors|business|admin|lenders)"
    echo "  -f, --force         Force action without confirmation"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start-all"
    echo "  $0 deploy-app -e production -s api"
    echo "  $0 logs -s nginx"
    echo "  $0 status"
}

# Function to parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            start-monitoring|stop-monitoring|start-nginx|stop-nginx|start-all|stop-all|deploy-app|status|logs|ssl-renew)
                ACTION="$1"
                shift
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -s|--service)
                SERVICE="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Function to validate environment
validate_environment() {
    if [[ -n "$ENVIRONMENT" && "$ENVIRONMENT" != "production" && "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "sandbox" ]]; then
        print_error "Invalid environment: $ENVIRONMENT. Must be production, staging, or sandbox."
        exit 1
    fi
}

# Function to validate service
validate_service() {
    if [[ -n "$SERVICE" && "$SERVICE" != "api" && "$SERVICE" != "agents" && "$SERVICE" != "distributors" && "$SERVICE" != "business" && "$SERVICE" != "admin" && "$SERVICE" != "lenders" && "$SERVICE" != "nginx" && "$SERVICE" != "monitoring" && "$SERVICE" != "postgres" && "$SERVICE" != "minio" ]]; then
        print_error "Invalid service: $SERVICE. Must be api, agents, distributors, business, admin, lenders, postgres, minio, nginx, or monitoring."
        exit 1
    fi
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to setup environment configuration
setup_environment_config() {
    local target_env="$1"
    local script_dir="$(dirname "$0")"
    local config_file
    local example_file
    
    # Check if we're in a deployment directory (has env/ folder locally)
    if [[ -d "$script_dir/../env" ]]; then
        config_file="$script_dir/../env/${target_env}.env"
        example_file="$script_dir/../env/config.example"
    else
        # We're in the main devops directory
        config_file="$script_dir/../env/${target_env}.env"
        example_file="$script_dir/../env/config.example"
    fi
    
    # Check if environment-specific config exists
    if [[ ! -f "$config_file" ]]; then
        if [[ -f "$example_file" ]]; then
            print_warning "Environment config file not found: $config_file"
            print_status "Creating from example file..."
            cp "$example_file" "$config_file"
            print_warning "Please edit $config_file with your environment-specific values before proceeding"
            print_status "Key variables to update:"
            echo "  - Database passwords and URLs"
            echo "  - JWT secrets"
            echo "  - SMTP configuration"
            echo "  - MinIO credentials"
            echo "  - Domain configurations"
            exit 1
        else
            print_error "No configuration template found at $example_file"
            exit 1
        fi
    fi
    
    # Export the config file path for docker-compose
    export ENV_FILE="$config_file"
    print_status "Using environment config: $config_file"
}

# Function to load environment variables
load_environment() {
    local env_file="$1"
    if [[ -f "$env_file" ]]; then
        print_status "Loading environment variables from $env_file"
        set -a  # automatically export all variables
        source "$env_file"
        set +a  # stop automatically exporting
    else
        print_error "Environment file not found: $env_file"
        exit 1
    fi
}

# Function to create network if it doesn't exist
create_network() {
    if ! docker network ls | grep -q "cach-network"; then
        print_status "Creating cach-network..."
        if docker network create cach-network; then
            print_success "Network cach-network created successfully"
        else
            print_error "Failed to create cach-network"
            exit 1
        fi
    else
        print_status "Network cach-network already exists"
    fi
}

# Function to start monitoring stack
start_monitoring() {
    print_status "Starting consolidated monitoring stack..."
    local script_dir="$(dirname "$0")"
    
    # Determine nginx directory location
    local nginx_dir
    if [[ -d "$script_dir/../nginx" ]]; then
        nginx_dir="$script_dir/../nginx"
    else
        nginx_dir="$script_dir/../../nginx"
    fi
    
    cd "$nginx_dir"
    
    # Create necessary directories
    mkdir -p certs www
    
    # Load environment configuration
    local main_env_file="$script_dir/../.env"
    if [[ -f "$main_env_file" ]]; then
        load_environment "$main_env_file"
    fi
    
    # Ensure network exists
    create_network
    
    # Start monitoring services
    docker-compose -f docker-compose.nginx.yml up -d postgres_monitoring minio_monitoring loki promtail grafana
    
    print_success "Monitoring stack started"
    print_status "Grafana: https://monitoring.cachconnect.co.ke (admin/admin123)"
    print_status "MinIO Console: https://storage.cachconnect.co.ke"
}

# Function to stop monitoring stack
stop_monitoring() {
    print_status "Stopping consolidated monitoring stack..."
    local script_dir="$(dirname "$0")"
    
    # Determine nginx directory location
    local nginx_dir
    if [[ -d "$script_dir/../nginx" ]]; then
        nginx_dir="$script_dir/../nginx"
    else
        nginx_dir="$script_dir/../../nginx"
    fi
    
    cd "$nginx_dir"
    docker-compose -f docker-compose.nginx.yml down
    print_success "Monitoring stack stopped"
}

# Function to create dummy SSL certificates
create_dummy_ssl_certificates() {
    local domains=(
        "${API_DOMAIN:-api.cachconnect.co.ke}"
        "${AGENT_DOMAIN:-agents.cachconnect.co.ke}"
        "${DISTRIBUTOR_DOMAIN:-distributors.cachconnect.co.ke}"
        "${BUSINESS_DOMAIN:-business.cachconnect.co.ke}"
        "${ADMIN_DOMAIN:-admin.cachconnect.co.ke}"
        "${LENDER_DOMAIN:-lenders.cachconnect.co.ke}"
        "${STORAGE_DOMAIN:-storage.cachconnect.co.ke}"
        "${MONITORING_DOMAIN:-monitoring.cachconnect.co.ke}"
    )
    
    for domain in "${domains[@]}"; do
        local cert_file="certs/${domain}.crt"
        local key_file="certs/${domain}.key"
        
        if [[ ! -f "$cert_file" || ! -f "$key_file" ]]; then
            print_status "Creating dummy SSL certificate for $domain..."
            
            # Check if openssl is available
            if command -v openssl >/dev/null 2>&1; then
                openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                    -keyout "$key_file" \
                    -out "$cert_file" \
                    -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain" 2>/dev/null
            else
                # Fallback: use docker to create certificates
                print_status "OpenSSL not found, using Docker to create certificate..."
                docker run --rm -v "$(pwd)/certs:/certs" alpine/openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                    -keyout "/certs/${domain}.key" \
                    -out "/certs/${domain}.crt" \
                    -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain" 2>/dev/null
            fi
            
            # Verify certificate was created
            if [[ -f "$cert_file" && -f "$key_file" ]]; then
                print_success "Created certificate for $domain"
            else
                print_error "Failed to create certificate for $domain"
            fi
        fi
    done
}

# Function to start nginx
start_nginx() {
    print_status "Starting nginx reverse proxy..."
    local script_dir="$(dirname "$0")"
    
    # Determine nginx directory location
    local nginx_dir
    if [[ -d "$script_dir/../nginx" ]]; then
        nginx_dir="$script_dir/../nginx"
    else
        nginx_dir="$script_dir/../../nginx"
    fi
    
    cd "$nginx_dir"
    
    # Create necessary directories
    mkdir -p certs www logs
    
    # Load environment configuration
    local main_env_file="$script_dir/../.env"
    if [[ -f "$main_env_file" ]]; then
        load_environment "$main_env_file"
    fi
    
    # Ensure network exists
    create_network
    
    # Create dummy SSL certificates if they don't exist
    print_status "Checking SSL certificates..."
    create_dummy_ssl_certificates
    
    # Debug: Check if certificates were created
    print_status "Verifying certificates were created..."
    ls -la certs/ || echo "No certs directory found"
    
    # Start nginx first (without certbot to avoid dependency issues)
    print_status "Starting nginx..."
    docker-compose -f docker-compose.nginx.yml up -d nginx
    
    # Debug: Check if nginx started
    sleep 2
    if docker ps | grep -q "cach-nginx"; then
        print_success "Nginx container started successfully"
    else
        print_error "Nginx container failed to start"
        print_status "Checking nginx logs..."
        docker logs cach-nginx 2>&1 || echo "No logs available"
        print_status "Checking docker-compose logs..."
        docker-compose -f docker-compose.nginx.yml logs nginx || echo "No compose logs available"
    fi
    
    # Wait a moment for nginx to start
    sleep 5
    
    # Now start certbot to get real certificates
    print_status "Starting certbot for SSL certificates..."
    docker-compose -f docker-compose.nginx.yml up -d certbot
    
    print_success "Nginx reverse proxy started"
    print_status "HTTP: Port 80, HTTPS: Port 443"
}

# Function to stop nginx
stop_nginx() {
    print_status "Stopping nginx reverse proxy..."
    local script_dir="$(dirname "$0")"
    
    # Determine nginx directory location
    local nginx_dir
    if [[ -d "$script_dir/../nginx" ]]; then
        nginx_dir="$script_dir/../nginx"
    else
        nginx_dir="$script_dir/../../nginx"
    fi
    
    cd "$nginx_dir"
    docker-compose -f docker-compose.nginx.yml stop nginx certbot
    print_success "Nginx reverse proxy stopped"
}

# Function to start all services
start_all() {
    print_status "Starting all Cach services..."
    
    # Setup main environment configuration
    local main_env_file="$(dirname "$0")/../.env"
    if [[ ! -f "$main_env_file" ]]; then
        print_status "Creating main environment file from example..."
        cp "$(dirname "$0")/../env/config.example" "$main_env_file"
        print_warning "Please edit $main_env_file with your configuration before proceeding"
        exit 1
    fi
    
    create_network
    start_monitoring
    sleep 10  # Wait for monitoring to be ready
    start_nginx
    sleep 5   # Wait for nginx to be ready
    
    # Start all application services
    cd "$(dirname "$0")/.."
    load_environment "$main_env_file"
    docker-compose -f docker-compose.main.yml --env-file "$main_env_file" up -d
    
    print_success "All services started"
    show_status
}

# Function to stop all services
stop_all() {
    print_status "Stopping all Cach services..."
    
    cd "$(dirname "$0")/.."
    docker-compose -f docker-compose.main.yml down
    
    stop_nginx
    stop_monitoring
    
    print_success "All services stopped"
}

# Function to deploy specific app
deploy_app() {
    if [[ -z "$ENVIRONMENT" || -z "$SERVICE" ]]; then
        print_error "Environment and service must be specified for app deployment"
        show_usage
        exit 1
    fi
    
    print_status "Deploying $SERVICE to $ENVIRONMENT environment..."
    
    # Setup environment configuration
    setup_environment_config "$ENVIRONMENT"
    
    local script_dir="$(dirname "$0")"
    local work_dir
    
    # Determine working directory - if we have docker-compose.main.yml locally, use current dir
    if [[ -f "$script_dir/../docker-compose.main.yml" ]]; then
        work_dir="$script_dir/.."
    else
        work_dir="$script_dir/../.."
    fi
    
    cd "$work_dir"
    
    # Load the main environment file
    local main_env_file="$work_dir/.env"
    if [[ -f "$main_env_file" ]]; then
        load_environment "$main_env_file"
    fi
    
    # Handle different service types
    case $SERVICE in
        api)
            IMAGE_VAR="API_${ENVIRONMENT^^}_TAG"
            CONTAINER_NAME="cach-api-$ENVIRONMENT"
            ;;
        agents)
            IMAGE_VAR="AGENT_${ENVIRONMENT^^}_TAG"
            CONTAINER_NAME="cach-agents-$ENVIRONMENT"
            ;;
        distributors)
            IMAGE_VAR="DISTRIBUTOR_${ENVIRONMENT^^}_TAG"
            CONTAINER_NAME="cach-distributors-$ENVIRONMENT"
            ;;
        business)
            IMAGE_VAR="BUSINESS_${ENVIRONMENT^^}_TAG"
            CONTAINER_NAME="cach-business-$ENVIRONMENT"
            ;;
        admin)
            IMAGE_VAR="ADMIN_${ENVIRONMENT^^}_TAG"
            CONTAINER_NAME="cach-admin-$ENVIRONMENT"
            ;;
        lenders)
            IMAGE_VAR="LENDER_${ENVIRONMENT^^}_TAG"
            CONTAINER_NAME="cach-lenders-$ENVIRONMENT"
            ;;
        postgres)
            CONTAINER_NAME="cach-postgres-$ENVIRONMENT"
            ;;
        minio)
            CONTAINER_NAME="cach-minio-$ENVIRONMENT"
            ;;
    esac
    
    # Stop and remove existing container
    print_status "Stopping existing container..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    
    # Start dependencies and the service
    print_status "Starting updated service and dependencies..."
    if [[ "$SERVICE" == "postgres" || "$SERVICE" == "minio" ]]; then
        # For infrastructure services, use the service name as defined in docker-compose
        docker-compose -f docker-compose.main.yml --env-file "$main_env_file" up -d "${SERVICE}-${ENVIRONMENT}"
    else
        # For application services, start dependencies first, then the service
        case $SERVICE in
            api)
                print_status "Starting API dependencies (postgres and minio)..."
                docker-compose -f docker-compose.main.yml --env-file "$main_env_file" up -d "postgres-${ENVIRONMENT}" "minio-${ENVIRONMENT}"
                
                print_status "Waiting for PostgreSQL to be ready..."
                timeout 60 bash -c "until docker exec cach-postgres-${ENVIRONMENT} pg_isready -U cach_user; do echo 'Waiting for PostgreSQL...'; sleep 5; done" || print_warning "PostgreSQL health check timeout"
                
                print_status "Waiting for MinIO to be ready..."
                timeout 60 bash -c "until docker exec cach-minio-${ENVIRONMENT} curl -f http://localhost:9000/minio/health/live; do echo 'Waiting for MinIO...'; sleep 5; done" || print_warning "MinIO health check timeout"
                
                print_status "Dependencies are ready, starting API..."
                ;;
        esac
        
        # Start the main service
        docker-compose -f docker-compose.main.yml --env-file "$main_env_file" up -d "${SERVICE}-${ENVIRONMENT}"
    fi
    
    # Wait for health check
    print_status "Waiting for service to be healthy..."
    sleep 30
    
    # Check if container is running
    if docker ps | grep -q "$CONTAINER_NAME"; then
        print_success "$SERVICE deployed successfully to $ENVIRONMENT"
    else
        print_error "Deployment failed. Check logs with: $0 logs -s ${SERVICE}-${ENVIRONMENT}"
        exit 1
    fi
}

# Function to show status
show_status() {
    print_status "Cach Services Status:"
    echo ""
    
    # Check nginx
    if docker ps | grep -q "cach-nginx"; then
        echo -e "${GREEN}✓${NC} Nginx Reverse Proxy: Running"
    else
        echo -e "${RED}✗${NC} Nginx Reverse Proxy: Stopped"
    fi
    
    # Check monitoring
    if docker ps | grep -q "cach-grafana-consolidated"; then
        echo -e "${GREEN}✓${NC} Monitoring Stack: Running"
    else
        echo -e "${RED}✗${NC} Monitoring Stack: Stopped"
    fi
    
    echo ""
    echo "Infrastructure Services:"
    
    # Check PostgreSQL and MinIO for each environment
    for service in postgres minio; do
        echo "  $service:"
        for env in production staging sandbox; do
            container_name="cach-${service}-${env}"
            
            if docker ps | grep -q "$container_name"; then
                echo -e "    ${GREEN}✓${NC} $env: Running"
            else
                echo -e "    ${RED}✗${NC} $env: Stopped"
            fi
        done
        echo ""
    done
    
    echo "Application Services:"
    
    # Check each service and environment
    for service in api agents distributors business admin lenders; do
        echo "  $service:"
        for env in production staging sandbox; do
            container_name="cach-${service}-${env}"
            if [[ "$service" == "agents" ]]; then
                container_name="cach-agents-${env}"
            elif [[ "$service" == "distributors" ]]; then
                container_name="cach-distributors-${env}"
            fi
            
            if docker ps | grep -q "$container_name"; then
                echo -e "    ${GREEN}✓${NC} $env: Running"
            else
                echo -e "    ${RED}✗${NC} $env: Stopped"
            fi
        done
        echo ""
    done
}

# Function to show logs
show_logs() {
    if [[ -z "$SERVICE" ]]; then
        print_error "Service must be specified for logs"
        show_usage
        exit 1
    fi
    
    case $SERVICE in
        nginx)
            docker logs -f cach-nginx
            ;;
        monitoring)
            docker logs -f cach-grafana-consolidated
            ;;
        *)
            if [[ -n "$ENVIRONMENT" ]]; then
                if [[ "$SERVICE" == "agents" ]]; then
                    docker logs -f "cach-agents-$ENVIRONMENT"
                elif [[ "$SERVICE" == "distributors" ]]; then
                    docker logs -f "cach-distributors-$ENVIRONMENT"
                else
                    docker logs -f "cach-${SERVICE}-${ENVIRONMENT}"
                fi
            else
                print_error "Environment must be specified for app logs"
                exit 1
            fi
            ;;
    esac
}

# Function to renew SSL certificates
ssl_renew() {
    print_status "Renewing SSL certificates..."
    cd "$(dirname "$0")/../nginx"
    
    # Stop nginx temporarily
    docker-compose -f docker-compose.nginx.yml stop nginx
    
    # Renew certificates
    docker-compose -f docker-compose.nginx.yml run --rm certbot renew
    
    # Restart nginx
    docker-compose -f docker-compose.nginx.yml start nginx
    
    print_success "SSL certificates renewed"
}

# Main execution
main() {
    parse_args "$@"
    
    # If no action specified, show usage
    if [[ -z "$ACTION" ]]; then
        show_usage
        exit 1
    fi
    
    validate_environment
    validate_service
    check_docker
    
    case $ACTION in
        start-monitoring)
            create_network
            start_monitoring
            ;;
        stop-monitoring)
            stop_monitoring
            ;;
        start-nginx)
            create_network
            start_nginx
            ;;
        stop-nginx)
            stop_nginx
            ;;
        start-all)
            start_all
            ;;
        stop-all)
            if [[ "$FORCE" == "false" ]]; then
                echo -n "Are you sure you want to stop all services? (y/N): "
                read -r response
                if [[ ! "$response" =~ ^[Yy]$ ]]; then
                    print_status "Operation cancelled"
                    exit 0
                fi
            fi
            stop_all
            ;;
        deploy-app)
            deploy_app
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        ssl-renew)
            ssl_renew
            ;;
        *)
            print_error "Unknown action: $ACTION"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"