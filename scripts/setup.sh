#!/bin/bash

# Cach Environment Setup Script
# This script helps set up environment configuration files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo "  init            Initialize all environment configuration files"
    echo "  create-env      Create specific environment file"
    echo "  validate        Validate existing configuration files"
    echo "  list            List all configuration files"
    echo ""
    echo "Options:"
    echo "  -e, --environment   Environment (production|staging|sandbox)"
    echo "  -f, --force         Overwrite existing files"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 init"
    echo "  $0 create-env -e production"
    echo "  $0 validate"
}

# Function to create environment file
create_env_file() {
    local env_name="$1"
    local force="$2"
    local env_file="$(dirname "$0")/../env/${env_name}.env"
    local example_file="$(dirname "$0")/../env/config.example"
    
    if [[ -f "$env_file" && "$force" != "true" ]]; then
        print_warning "Environment file already exists: $env_file"
        echo -n "Overwrite? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_status "Skipped $env_file"
            return 0
        fi
    fi
    
    if [[ ! -f "$example_file" ]]; then
        print_error "Example configuration file not found: $example_file"
        return 1
    fi
    
    print_status "Creating $env_file from template..."
    cp "$example_file" "$env_file"
    
    # Update environment-specific values
    case "$env_name" in
        "production")
            sed -i.bak "s/ENVIRONMENT=.*/ENVIRONMENT=production/" "$env_file"
            sed -i.bak "s/api\\.staging\\.cachconnect\\.co\\.ke/api.cachconnect.co.ke/g" "$env_file"
            sed -i.bak "s/agents\\.staging\\.cachconnect\\.co\\.ke/agents.cachconnect.co.ke/g" "$env_file"
            sed -i.bak "s/distributors\\.staging\\.cachconnect\\.co\\.ke/distributors.cachconnect.co.ke/g" "$env_file"
            sed -i.bak "s/business\\.staging\\.cachconnect\\.co\\.ke/business.cachconnect.co.ke/g" "$env_file"
            sed -i.bak "s/admin\\.staging\\.cachconnect\\.co\\.ke/admin.cachconnect.co.ke/g" "$env_file"
            sed -i.bak "s/lenders\\.staging\\.cachconnect\\.co\\.ke/lenders.cachconnect.co.ke/g" "$env_file"
            ;;
        "staging")
            sed -i.bak "s/ENVIRONMENT=.*/ENVIRONMENT=staging/" "$env_file"
            # URLs are already set for staging in the example
            ;;
        "sandbox")
            sed -i.bak "s/ENVIRONMENT=.*/ENVIRONMENT=sandbox/" "$env_file"
            sed -i.bak "s/api\\.staging\\.cachconnect\\.co\\.ke/api.sandbox.cachconnect.co.ke/g" "$env_file"
            sed -i.bak "s/agents\\.staging\\.cachconnect\\.co\\.ke/agents.sandbox.cachconnect.co.ke/g" "$env_file"
            sed -i.bak "s/distributors\\.staging\\.cachconnect\\.co\\.ke/distributors.sandbox.cachconnect.co.ke/g" "$env_file"
            sed -i.bak "s/business\\.staging\\.cachconnect\\.co\\.ke/business.sandbox.cachconnect.co.ke/g" "$env_file"
            sed -i.bak "s/admin\\.staging\\.cachconnect\\.co\\.ke/admin.sandbox.cachconnect.co.ke/g" "$env_file"
            sed -i.bak "s/lenders\\.staging\\.cachconnect\\.co\\.ke/lenders.sandbox.cachconnect.co.ke/g" "$env_file"
            ;;
    esac
    
    # Remove backup files
    rm -f "${env_file}.bak"
    
    print_success "Created $env_file"
    print_warning "⚠️  IMPORTANT: Please edit $env_file and update the following:"
    echo "   - Database passwords (DATABASE_PASSWORD, MONITORING_DB_PASSWORD)"
    echo "   - JWT secret (JWT_SECRET)"
    echo "   - MinIO credentials (MINIO_ROOT_USER, MINIO_ROOT_PASSWORD, etc.)"
    echo "   - SMTP configuration (SMTP_USER, SMTP_PASS)"
    echo "   - Grafana password (GRAFANA_PASSWORD)"
    echo ""
}

# Function to initialize all environment files
init_all() {
    local force="$1"
    
    print_status "Initializing all environment configuration files..."
    
    # Create env directory if it doesn't exist
    local env_dir="$(dirname "$0")/../env"
    mkdir -p "$env_dir"
    
    # Create main .env file (uses production settings by default)
    local main_env_file="$(dirname "$0")/../.env"
    if [[ ! -f "$main_env_file" || "$force" == "true" ]]; then
        print_status "Creating main environment file..."
        create_env_file "production" "$force"
        cp "$(dirname "$0")/../env/production.env" "$main_env_file"
        print_success "Created main .env file"
    fi
    
    # Create environment-specific files
    for env in production staging sandbox; do
        create_env_file "$env" "$force"
    done
    
    print_success "Environment initialization complete!"
    print_status "Next steps:"
    echo "  1. Edit the environment files with your specific configuration"
    echo "  2. Run './scripts/deploy.sh start-all' to start all services"
    echo "  3. Or deploy specific services with './scripts/deploy.sh deploy-app -e <env> -s <service>'"
}

# Function to validate configuration files
validate_config() {
    print_status "Validating configuration files..."
    
    local validation_failed=false
    local example_file="$(dirname "$0")/../env/config.example"
    
    # Check if example file exists
    if [[ ! -f "$example_file" ]]; then
        print_error "Example configuration file not found: $example_file"
        return 1
    fi
    
    # Check main .env file
    local main_env_file="$(dirname "$0")/../.env"
    if [[ ! -f "$main_env_file" ]]; then
        print_warning "Main .env file not found: $main_env_file"
        validation_failed=true
    else
        print_success "Main .env file found"
    fi
    
    # Check environment-specific files
    for env in production staging sandbox; do
        local env_file="$(dirname "$0")/../env/${env}.env"
        if [[ ! -f "$env_file" ]]; then
            print_warning "Environment file not found: $env_file"
            validation_failed=true
        else
            print_success "$env environment file found"
            
            # Check for placeholder values
            if grep -q "your_" "$env_file"; then
                print_warning "⚠️  $env_file contains placeholder values that need to be updated"
                validation_failed=true
            fi
        fi
    done
    
    if [[ "$validation_failed" == "true" ]]; then
        print_error "Configuration validation failed. Run 'setup.sh init' to create missing files."
        return 1
    else
        print_success "All configuration files are present and appear valid"
    fi
}

# Function to list configuration files
list_config() {
    print_status "Configuration files:"
    
    local env_dir="$(dirname "$0")/../env"
    local main_env_file="$(dirname "$0")/../.env"
    
    echo ""
    echo "Main configuration:"
    if [[ -f "$main_env_file" ]]; then
        echo -e "  ${GREEN}✓${NC} $main_env_file"
    else
        echo -e "  ${RED}✗${NC} $main_env_file (missing)"
    fi
    
    echo ""
    echo "Environment-specific configurations:"
    for env in production staging sandbox; do
        local env_file="$env_dir/${env}.env"
        if [[ -f "$env_file" ]]; then
            echo -e "  ${GREEN}✓${NC} $env_file"
        else
            echo -e "  ${RED}✗${NC} $env_file (missing)"
        fi
    done
    
    echo ""
    echo "Template:"
    local example_file="$env_dir/config.example"
    if [[ -f "$example_file" ]]; then
        echo -e "  ${GREEN}✓${NC} $example_file"
    else
        echo -e "  ${RED}✗${NC} $example_file (missing)"
    fi
    echo ""
}

# Parse command line arguments
COMMAND=""
ENVIRONMENT=""
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        init|create-env|validate|list)
            COMMAND="$1"
            shift
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
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

# Validate environment if provided
if [[ -n "$ENVIRONMENT" && "$ENVIRONMENT" != "production" && "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "sandbox" ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be production, staging, or sandbox."
    exit 1
fi

# Main execution
case "$COMMAND" in
    init)
        init_all "$FORCE"
        ;;
    create-env)
        if [[ -z "$ENVIRONMENT" ]]; then
            print_error "Environment must be specified for create-env command"
            show_usage
            exit 1
        fi
        create_env_file "$ENVIRONMENT" "$FORCE"
        ;;
    validate)
        validate_config
        ;;
    list)
        list_config
        ;;
    "")
        print_error "No command specified"
        show_usage
        exit 1
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac