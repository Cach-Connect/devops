#!/bin/bash

# Cach Connect Server Setup Script
# This script sets up the initial server structure and dependencies

set -e

echo "🚀 Starting Cach Connect Server Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons"
   exit 1
fi

# Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
print_status "Installing required packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    htop \
    vim \
    nginx \
    certbot \
    python3-certbot-nginx \
    ufw

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    print_success "Docker installed successfully"
else
    print_warning "Docker is already installed"
fi

# Install Docker Compose
print_status "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed successfully"
else
    print_warning "Docker Compose is already installed"
fi

# Create directory structure
print_status "Creating directory structure..."
sudo mkdir -p /opt/cach/{production,staging,sandbox,shared}
sudo mkdir -p /opt/cach/shared/{nginx,grafana,loki,promtail,prometheus,alertmanager,certbot}
sudo mkdir -p /opt/cach/shared/grafana/{provisioning,dashboards}
sudo mkdir -p /opt/cach/shared/grafana/provisioning/{dashboards,datasources,notifiers}

# Set proper permissions
sudo chown -R $USER:$USER /opt/cach
chmod -R 755 /opt/cach

print_success "Directory structure created"

# Setup Nginx
print_status "Configuring Nginx..."
sudo systemctl enable nginx
sudo systemctl start nginx

# Create nginx configuration directories
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled

# Backup original nginx config
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Setup firewall
print_status "Configuring firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw --force enable

print_success "Firewall configured"

# Create environment configuration templates
print_status "Creating environment configuration templates..."

# Production environment file
cat > /opt/cach/production/.env.production << 'EOF'
# Production Environment Configuration
ENVIRONMENT=production

# Docker Images
API_IMAGE_NAME=abc254/api-cach-api
AGENT_IMAGE_NAME=abc254/cach-agents
DISTRIBUTOR_IMAGE_NAME=abc254/cach-distributors
BUSINESS_IMAGE_NAME=abc254/cach-business
ADMIN_IMAGE_NAME=abc254/cach-admin
LENDER_IMAGE_NAME=abc254/cach-lenders

# Image Tags
API_PRODUCTION_TAG=main
AGENT_PRODUCTION_TAG=main
DISTRIBUTOR_PRODUCTION_TAG=main
BUSINESS_PRODUCTION_TAG=main
ADMIN_PRODUCTION_TAG=main
LENDER_PRODUCTION_TAG=main

# Database (Update these values)
DATABASE_URL=postgresql://cach_user:CHANGE_THIS_PASSWORD@postgres:5432/cach_db_production
DATABASE_PASSWORD=CHANGE_THIS_PASSWORD

# JWT (Update these values)
JWT_SECRET=CHANGE_THIS_JWT_SECRET
JWT_EXPIRES_IN=7d

# MinIO (Update these values)
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=CHANGE_THIS_MINIO_PASSWORD
MINIO_SECRET_KEY=CHANGE_THIS_SECRET
MINIO_ACCESS_KEY=CHANGE_THIS_ACCESS_KEY
MINIO_BUCKET_NAME=cach-storage
MINIO_USE_SSL=false
MINIO_ENDPOINT=minio
MINIO_PORT=9000

# Grafana
GRAFANA_PASSWORD=CHANGE_THIS_GRAFANA_PASSWORD
GRAFANA_DOMAIN=monitoring.cachconnect.co.ke

# SMTP (Update these values)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=true
SMTP_USER=your_smtp_user
SMTP_PASS=your_smtp_password
SMTP_FROM_NAME=Cach Connect
SMTP_FROM_EMAIL=noreply@cachconnect.co.ke
SUPPORT_EMAIL=support@cachconnect.co.ke

# CORS and Security
CORS_ORIGINS=https://agents.cachconnect.co.ke,https://distributors.cachconnect.co.ke,https://business.cachconnect.co.ke,https://admin.cachconnect.co.ke,https://lenders.cachconnect.co.ke
ALLOWED_FILE_TYPES=pdf,jpg,jpeg,png,doc,docx
MAX_FILE_SIZE=10485760

# Logging
LOG_LEVEL=info
EOF

# Staging environment file
cat > /opt/cach/staging/.env.staging << 'EOF'
# Staging Environment Configuration
ENVIRONMENT=staging

# Docker Images
API_IMAGE_NAME=abc254/api-cach-api
AGENT_IMAGE_NAME=abc254/cach-agents
DISTRIBUTOR_IMAGE_NAME=abc254/cach-distributors
BUSINESS_IMAGE_NAME=abc254/cach-business
ADMIN_IMAGE_NAME=abc254/cach-admin
LENDER_IMAGE_NAME=abc254/cach-lenders

# Image Tags
API_STAGING_TAG=staging
AGENT_STAGING_TAG=staging
DISTRIBUTOR_STAGING_TAG=staging
BUSINESS_STAGING_TAG=staging
ADMIN_STAGING_TAG=staging
LENDER_STAGING_TAG=staging

# Database (Update these values)
DATABASE_URL=postgresql://cach_user:CHANGE_THIS_PASSWORD@postgres:5432/cach_db_staging
DATABASE_PASSWORD=CHANGE_THIS_PASSWORD

# JWT (Update these values)
JWT_SECRET=CHANGE_THIS_JWT_SECRET_STAGING
JWT_EXPIRES_IN=7d

# MinIO (Update these values)
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=CHANGE_THIS_MINIO_PASSWORD_STAGING
MINIO_SECRET_KEY=CHANGE_THIS_SECRET_STAGING
MINIO_ACCESS_KEY=CHANGE_THIS_ACCESS_KEY_STAGING
MINIO_BUCKET_NAME=cach-storage-staging
MINIO_USE_SSL=false
MINIO_ENDPOINT=minio
MINIO_PORT=9000

# Grafana
GRAFANA_PASSWORD=CHANGE_THIS_GRAFANA_PASSWORD
GRAFANA_DOMAIN=monitoring.cachconnect.co.ke

# SMTP (Update these values - can use same as production for staging)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=true
SMTP_USER=your_smtp_user_staging
SMTP_PASS=your_smtp_password_staging
SMTP_FROM_NAME=Cach Connect Staging
SMTP_FROM_EMAIL=noreply-staging@cachconnect.co.ke
SUPPORT_EMAIL=support-staging@cachconnect.co.ke

# CORS and Security
CORS_ORIGINS=https://agents.staging.cachconnect.co.ke,https://distributors.staging.cachconnect.co.ke,https://business.staging.cachconnect.co.ke,https://admin.staging.cachconnect.co.ke,https://lenders.staging.cachconnect.co.ke
ALLOWED_FILE_TYPES=pdf,jpg,jpeg,png,doc,docx
MAX_FILE_SIZE=10485760

# Logging
LOG_LEVEL=debug
EOF

# Sandbox environment file
cat > /opt/cach/sandbox/.env.sandbox << 'EOF'
# Sandbox Environment Configuration
ENVIRONMENT=sandbox

# Docker Images
API_IMAGE_NAME=abc254/api-cach-api
AGENT_IMAGE_NAME=abc254/cach-agents
DISTRIBUTOR_IMAGE_NAME=abc254/cach-distributors
BUSINESS_IMAGE_NAME=abc254/cach-business
ADMIN_IMAGE_NAME=abc254/cach-admin
LENDER_IMAGE_NAME=abc254/cach-lenders

# Image Tags
API_SANDBOX_TAG=sandbox
AGENT_SANDBOX_TAG=sandbox
DISTRIBUTOR_SANDBOX_TAG=sandbox
BUSINESS_SANDBOX_TAG=sandbox
ADMIN_SANDBOX_TAG=sandbox
LENDER_SANDBOX_TAG=sandbox

# Database (Update these values)
DATABASE_URL=postgresql://cach_user:CHANGE_THIS_PASSWORD@postgres:5432/cach_db_sandbox
DATABASE_PASSWORD=CHANGE_THIS_PASSWORD

# JWT (Update these values)
JWT_SECRET=CHANGE_THIS_JWT_SECRET_SANDBOX
JWT_EXPIRES_IN=7d

# MinIO (Update these values)
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=CHANGE_THIS_MINIO_PASSWORD_SANDBOX
MINIO_SECRET_KEY=CHANGE_THIS_SECRET_SANDBOX
MINIO_ACCESS_KEY=CHANGE_THIS_ACCESS_KEY_SANDBOX
MINIO_BUCKET_NAME=cach-storage-sandbox
MINIO_USE_SSL=false
MINIO_ENDPOINT=minio
MINIO_PORT=9000

# Grafana
GRAFANA_PASSWORD=CHANGE_THIS_GRAFANA_PASSWORD
GRAFANA_DOMAIN=monitoring.cachconnect.co.ke

# SMTP (Update these values - can use test SMTP for sandbox)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=true
SMTP_USER=your_smtp_user_sandbox
SMTP_PASS=your_smtp_password_sandbox
SMTP_FROM_NAME=Cach Connect Sandbox
SMTP_FROM_EMAIL=noreply-sandbox@cachconnect.co.ke
SUPPORT_EMAIL=support-sandbox@cachconnect.co.ke

# CORS and Security
CORS_ORIGINS=https://agents.sandbox.cachconnect.co.ke,https://distributors.sandbox.cachconnect.co.ke,https://business.sandbox.cachconnect.co.ke,https://admin.sandbox.cachconnect.co.ke,https://lenders.sandbox.cachconnect.co.ke
ALLOWED_FILE_TYPES=pdf,jpg,jpeg,png,doc,docx
MAX_FILE_SIZE=10485760

# Logging
LOG_LEVEL=debug
EOF

print_success "Environment configuration files created"

# Create basic Grafana provisioning
cat > /opt/cach/shared/grafana/provisioning/datasources/loki.yml << 'EOF'
apiVersion: 1
datasources:
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    isDefault: false
    editable: true
EOF

cat > /opt/cach/shared/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

print_success "Grafana provisioning configured"

# Create system service for automatic Docker network creation
print_status "Setting up Docker networks..."
docker network create cach_production_network 2>/dev/null || print_warning "Production network already exists"
docker network create cach_staging_network 2>/dev/null || print_warning "Staging network already exists"
docker network create cach_sandbox_network 2>/dev/null || print_warning "Sandbox network already exists"
docker network create cach_shared_network 2>/dev/null || print_warning "Shared network already exists"

print_success "Docker networks created"

# Create log rotation configuration
print_status "Setting up log rotation..."
sudo tee /etc/logrotate.d/cach-docker << 'EOF' > /dev/null
/var/lib/docker/containers/*/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    copytruncate
}
EOF

print_success "Log rotation configured"

print_success "🎉 Server setup completed!"
print_warning "⚠️  IMPORTANT: Please update the following before deploying:"
print_warning "   1. Update all CHANGE_THIS_* values in the .env files"
print_warning "   2. Copy your docker-compose files to the appropriate directories"
print_warning "   3. Copy your nginx configuration files"
print_warning "   4. Set up your domain DNS records"
print_warning "   5. Configure your GitHub secrets for deployment"
print_warning ""
print_status "Next steps:"
print_status "   1. Copy docker-compose files: cp docker-compose.*.yml /opt/cach/"
print_status "   2. Copy nginx config: sudo cp -r nginx/* /etc/nginx/"
print_status "   3. Copy observability configs to /opt/cach/shared/"
print_status "   4. Update environment variables in .env files"
print_status "   5. Test nginx config: sudo nginx -t"
print_status "   6. Start shared services: cd /opt/cach/shared && docker-compose -f docker-compose.shared.yml up -d"
print_status "   7. Setup SSL certificates using the infrastructure GitHub Action"
print_status ""
print_status "📋 Environment file locations:"
print_status "   - Production: /opt/cach/production/.env.production"
print_status "   - Staging: /opt/cach/staging/.env.staging"
print_status "   - Sandbox: /opt/cach/sandbox/.env.sandbox"
print_status ""
print_status "🔧 Don't forget to configure GitHub repository secrets:"
print_status "   - DOCKER_USERNAME"
print_status "   - DOCKER_PASSWORD"
print_status "   - VPS_HOST (server IP)"
print_status "   - VPS_USER (server user)"
print_status "   - VPS_SSH_PASSWORD"
print_status "   - PORT (SSH port, optional)"
print_status "   - ADMIN_EMAIL (for SSL certificates)"
print_status ""
print_status "🚪 You may need to log out and back in for Docker group permissions to take effect"