# Cach DevOps - Multi-Environment Deployment

This repository contains the DevOps configuration for the Cach Connect platform, including Docker configurations, Nginx reverse proxy setup, and consolidated monitoring stack.

## Architecture Overview

### Domain Structure
```
Production:
- api.cachconnect.co.ke          → API (port 3001)
- agents.cachconnect.co.ke       → Agents App (port 3011)
- distributors.cachconnect.co.ke → Distributors App (port 3021)
- business.cachconnect.co.ke     → Business App (port 3031)
- admin.cachconnect.co.ke        → Admin App (port 3041)
- lenders.cachconnect.co.ke      → Lenders App (port 3051)

Staging:
- api.staging.cachconnect.co.ke          → API (port 3002)
- agents.staging.cachconnect.co.ke       → Agents App (port 3012)
- distributors.staging.cachconnect.co.ke → Distributors App (port 3022)
- business.staging.cachconnect.co.ke     → Business App (port 3032)
- admin.staging.cachconnect.co.ke        → Admin App (port 3042)
- lenders.staging.cachconnect.co.ke      → Lenders App (port 3052)

Sandbox:
- api.sandbox.cachconnect.co.ke          → API (port 3003)
- agents.sandbox.cachconnect.co.ke       → Agents App (port 3013)
- distributors.sandbox.cachconnect.co.ke → Distributors App (port 3023)
- business.sandbox.cachconnect.co.ke     → Business App (port 3033)
- admin.sandbox.cachconnect.co.ke        → Admin App (port 3043)
- lenders.sandbox.cachconnect.co.ke      → Lenders App (port 3053)

Shared Services:
- monitoring.cachconnect.co.ke   → Grafana (port 3100)
- storage.cachconnect.co.ke      → MinIO Console (port 9001)
```

## Key Features

1. **Consolidated Monitoring**: Single Grafana/Loki instance for all environments
2. **SSL Termination**: Automatic SSL certificate management with Let's Encrypt
3. **Load Balancing**: Nginx reverse proxy with rate limiting
4. **Environment Separation**: Isolated containers per environment
5. **Centralized Logging**: All logs aggregated to single Loki instance
6. **Health Monitoring**: Health checks for all services

## Prerequisites

- Docker and Docker Compose installed
- Domain names configured and pointing to your server
- SSL certificates (automated with Let's Encrypt)

## Quick Start

### 1. Clone and Setup
```bash
git clone <repository>
cd devops
```

### 2. Configure Environment Variables

#### Option A: Automated Setup (Recommended)
```bash
# Initialize all environment files automatically
./scripts/setup.sh init

# This creates:
# - .env (main configuration)
# - env/production.env
# - env/staging.env  
# - env/sandbox.env

# Edit the generated files with your specific values
vim .env
vim env/production.env
vim env/staging.env
vim env/sandbox.env
```

#### Option B: Manual Setup
```bash
# Copy the example configuration
cp env/config.example env/production.env
cp env/config.example env/staging.env
cp env/config.example env/sandbox.env
cp env/config.example .env

# Edit each file with your environment-specific values
vim .env
vim env/production.env
vim env/staging.env
vim env/sandbox.env
```

#### Validate Configuration
```bash
# Check if all configuration files are present and valid
./scripts/setup.sh validate

# List all configuration files
./scripts/setup.sh list
```

### 3. Start All Services
```bash
# Make the deploy script executable
chmod +x scripts/deploy.sh

# Start all services (monitoring + nginx + apps)
./scripts/deploy.sh start-all
```

### 4. Check Status
```bash
./scripts/deploy.sh status
```

## Deployment Commands

### Service Management
```bash
# Start/stop monitoring stack
./scripts/deploy.sh start-monitoring
./scripts/deploy.sh stop-monitoring

# Start/stop nginx reverse proxy
./scripts/deploy.sh start-nginx
./scripts/deploy.sh stop-nginx

# Start/stop all services
./scripts/deploy.sh start-all
./scripts/deploy.sh stop-all --force
```

### Application Deployment
```bash
# Deploy specific app to specific environment
./scripts/deploy.sh deploy-app -e production -s api
./scripts/deploy.sh deploy-app -e staging -s agents
./scripts/deploy.sh deploy-app -e sandbox -s distributors
```

### Monitoring and Logs
```bash
# Check service status
./scripts/deploy.sh status

# View logs
./scripts/deploy.sh logs -s nginx
./scripts/deploy.sh logs -s monitoring
./scripts/deploy.sh logs -e production -s api
./scripts/deploy.sh logs -e staging -s agents
```

### SSL Management
```bash
# Renew SSL certificates
./scripts/deploy.sh ssl-renew
```

## File Structure

```
devops/
├── nginx/
│   ├── nginx.conf                    # Main nginx configuration
│   ├── docker-compose.nginx.yml      # Nginx + monitoring stack
│   ├── loki-config.yml              # Loki configuration
│   ├── promtail-config.yml          # Promtail configuration
│   ├── grafana-datasources.yml      # Grafana data sources
│   └── grafana-dashboards.yml       # Grafana dashboard providers
├── scripts/
│   └── deploy.sh                     # Main deployment script
├── env/
│   ├── config.example               # Environment configuration template
│   ├── production.env               # Production environment config
│   ├── staging.env                  # Staging environment config
│   └── sandbox.env                  # Sandbox environment config
├── docker-compose.main.yml          # Main application orchestrator
└── README.md                        # This file
```

## Configuration Management

### Environment Configuration Files

The system uses environment-specific configuration files:

```
devops/
├── .env                          # Main configuration (used for shared services)
├── env/
│   ├── config.example           # Template for all configurations
│   ├── production.env           # Production environment settings
│   ├── staging.env              # Staging environment settings
│   └── sandbox.env              # Sandbox environment settings
```

### Configuration Hierarchy

1. **Main `.env` file**: Used for shared services (nginx, monitoring)
2. **Environment-specific files**: Used when deploying individual services
3. **Docker-compose override**: `ENV_FILE` variable can specify which config to use

### Required Configuration Variables

Each environment file must include:

- **Environment Settings**: `ENVIRONMENT`, image tags
- **Database Configuration**: URLs, passwords, connection settings
- **Authentication**: JWT secrets, token expiration
- **External Services**: SMTP, MinIO, monitoring credentials
- **Application URLs**: Domain configurations for each app
- **Security**: CORS origins, file upload limits

### Setup Commands

```bash
# Initialize all configuration files
./scripts/setup.sh init

# Create specific environment
./scripts/setup.sh create-env -e production

# Validate existing configuration
./scripts/setup.sh validate

# List all configuration files
./scripts/setup.sh list

# Force overwrite existing files
./scripts/setup.sh init --force
```

## Configuration Details

### Nginx Configuration
- SSL termination with HTTP to HTTPS redirect
- Rate limiting (10 req/s for API, 20 req/s for web apps)
- Security headers
- Gzip compression
- Access and error logging

### Monitoring Stack
- **Grafana**: Web UI for monitoring and alerting
- **Loki**: Log aggregation and querying
- **Promtail**: Log collection agent
- **PostgreSQL**: Grafana database backend
- **MinIO**: Object storage for monitoring data

### Environment Separation
Each environment (production/staging/sandbox) runs:
- Isolated API instance
- Isolated frontend app instances
- Separate databases and storage
- Environment-specific logging labels

## Monitoring Access

- **Grafana**: https://monitoring.cachconnect.co.ke
  - Username: admin
  - Password: [set in GRAFANA_PASSWORD]

- **MinIO Console**: https://storage.cachconnect.co.ke
  - Username: [MINIO_ROOT_USER]
  - Password: [MINIO_ROOT_PASSWORD]

## Security Features

1. **SSL/TLS**: Automatic certificate generation and renewal
2. **Rate Limiting**: Protection against DDoS and abuse
3. **Security Headers**: XSS, CSRF, and clickjacking protection
4. **Access Control**: Isolated environments and services
5. **Secret Management**: Environment variables for sensitive data

## Backup Strategy

### Database Backups
```bash
# Production database backup
docker exec cach-postgres-production pg_dump -U cach_user cach_db_production > backup_prod_$(date +%Y%m%d).sql

# Monitoring database backup
docker exec cach-postgres-monitoring pg_dump -U monitoring_user monitoring_db > backup_monitoring_$(date +%Y%m%d).sql
```

### Volume Backups
```bash
# Backup all volumes
docker run --rm -v cach_uploads_production:/data -v $(pwd):/backup ubuntu tar czf /backup/uploads_production_$(date +%Y%m%d).tar.gz /data
```

## Troubleshooting

### Common Issues

1. **SSL Certificate Issues**
   ```bash
   # Check certificate status
   ./scripts/deploy.sh ssl-renew
   
   # Manual certificate generation
   cd nginx
   docker-compose -f docker-compose.nginx.yml run --rm certbot certonly --webroot --webroot-path=/var/www/certbot --email your-email@domain.com --agree-tos --no-eff-email -d your-domain.com
   ```

2. **Service Not Starting**
   ```bash
   # Check logs
   ./scripts/deploy.sh logs -s [service-name]
   
   # Check container status
   docker ps -a | grep cach
   ```

3. **Network Issues**
   ```bash
   # Recreate network
   docker network rm cach-network
   docker network create cach-network
   ```

4. **Database Connection Issues**
   ```bash
   # Check database health
   docker exec cach-postgres-production pg_isready -U cach_user
   ```

### Log Locations

- **Nginx Logs**: Container logs and `/var/log/nginx/` in nginx container
- **Application Logs**: Collected by Promtail and available in Grafana
- **System Logs**: Docker container logs via `docker logs [container-name]`

## Performance Optimization

1. **Nginx Caching**: Configured for static assets
2. **Gzip Compression**: Enabled for text-based content
3. **Connection Pooling**: PostgreSQL connection limits
4. **Resource Limits**: Docker memory and CPU limits (configure as needed)

## Updates and Maintenance

### Updating Applications
```bash
# Pull latest images and redeploy
./scripts/deploy.sh deploy-app -e production -s api
```

### Updating Infrastructure
```bash
# Update nginx configuration
./scripts/deploy.sh stop-nginx
# Edit nginx/nginx.conf
./scripts/deploy.sh start-nginx

# Update monitoring stack
./scripts/deploy.sh stop-monitoring
# Edit configuration files
./scripts/deploy.sh start-monitoring
```

## Support

For issues and questions:
1. Check logs: `./scripts/deploy.sh logs -s [service]`
2. Check status: `./scripts/deploy.sh status`
3. Review this documentation
4. Contact DevOps team

## License

[Your License Here]