# Cach Connect Deployment Order

This document explains the correct order for deploying Cach Connect services to ensure proper network connectivity.

## 🏗️ Network Architecture

The Cach Connect infrastructure uses a shared network approach where:

1. **Shared Infrastructure** creates the Docker networks
2. **Application Services** connect to these existing networks
3. **Nginx** (in shared infrastructure) acts as reverse proxy for all services

## 📋 Required Deployment Order

### 1. **Deploy Shared Infrastructure FIRST**

```bash
# Via GitHub Actions
Environment: staging/production
Action: deploy

# Or via script
./scripts/deploy-shared.sh staging deploy
```

**What this creates:**
- Docker networks: `cach_staging_network`, `cach_production_network`, `cach_sandbox_network`
- Monitoring stack: Prometheus, Grafana, Loki, Alertmanager
- Reverse proxy: Nginx with SSL termination

### 2. **Deploy Application Services**

After shared infrastructure is running, deploy in any order:

```bash
# API
# Via GitHub Actions in api repository
Environment: staging/production
Action: deploy

# Agent App  
# Via GitHub Actions in agent repository
Environment: staging/production
Action: deploy

# Other apps (admin, distributors, business, lenders)
# Follow same pattern
```

## 🔗 Network Connectivity

### Network Layout:
```
Shared Infrastructure (docker-compose.shared.yml)
├── Creates: cach_staging_network
├── Creates: cach_production_network  
├── Creates: cach_sandbox_network
└── Creates: cach_monitoring_network

Application Services (docker-compose.staging.yml)
├── Connects to: cach_staging_network (external)
└── Services: postgres, minio, api, admin, agents, etc.
```

### Service Communication:
- **Internet** → **Nginx** → **Application Services**
- **Prometheus** → **Application Metrics Endpoints**
- **Promtail** → **Application Logs** → **Loki**

## ⚠️ Important Notes

### Network Dependencies
- **Shared infrastructure MUST be deployed first**
- Application services will fail if networks don't exist
- Networks are persistent (survive container restarts)

### Error Indicators
If you see this error:
```
network cach_staging_network declared as external, but could not be found
```

**Solution**: Deploy shared infrastructure first!

### Network Management
```bash
# List Docker networks
docker network ls

# Inspect a network
docker network inspect cach_staging_network

# Remove networks (only when all services are down)
docker network rm cach_staging_network
```

## 🔄 Redeployment Scenarios

### Full Environment Reset
```bash
# 1. Stop all application services
docker-compose -f docker-compose.staging.yml down

# 2. Stop shared infrastructure  
cd /opt/cach/shared
docker-compose -f docker-compose.shared.yml down

# 3. Remove networks (optional, for clean slate)
docker network rm cach_staging_network cach_production_network cach_sandbox_network cach_monitoring_network

# 4. Redeploy shared infrastructure
./scripts/deploy-shared.sh staging deploy

# 5. Redeploy application services
# Use GitHub Actions or local docker-compose
```

### Update Shared Infrastructure Only
```bash
# Safe to restart without affecting applications
cd /opt/cach/shared
docker-compose -f docker-compose.shared.yml restart
```

### Update Application Services Only
```bash
# Applications can be updated independently
cd /opt/cach/staging/api
docker-compose -f docker-compose.staging.yml up -d api
```

## 🚨 Troubleshooting

### Problem: Networks not found
```bash
# Check if shared infrastructure is running
docker ps | grep cach_

# Check if networks exist
docker network ls | grep cach_

# Solution: Deploy shared infrastructure first
```

### Problem: Services can't communicate
```bash
# Check network connectivity
docker exec cach_api_staging ping prometheus

# Check network configuration
docker network inspect cach_staging_network
```

### Problem: Nginx can't proxy to services
```bash
# Verify nginx is on multiple networks
docker inspect cach_nginx | grep NetworkMode

# Check if application services are reachable
docker exec cach_nginx ping cach_api_staging
```

## 📊 Monitoring Deployment

### Check Deployment Status
```bash
# Shared infrastructure status
cd /opt/cach/shared
docker-compose -f docker-compose.shared.yml ps

# Application services status  
cd /opt/cach/staging/api
docker-compose -f docker-compose.staging.yml ps
```

### Health Checks
```bash
# Monitoring services
curl http://localhost:9090/-/healthy  # Prometheus
curl http://localhost:3000/api/health # Grafana
curl http://localhost:3100/ready      # Loki

# Application services (via nginx proxy)
curl https://api.staging.cachconnect.co.ke/health
```

## 🔒 Security Considerations

### Network Isolation
- Each environment has its own network
- Services can only communicate within their network
- Monitoring network is separate but connected via nginx

### SSL Management
- SSL certificates managed in shared infrastructure
- All external traffic goes through nginx with SSL termination
- Internal communication uses HTTP (within Docker networks)

---

**Remember**: Always deploy shared infrastructure first! 🚀
