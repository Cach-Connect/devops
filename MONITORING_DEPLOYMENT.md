# Monitoring Stack Deployment Guide

This guide explains how to deploy and manage the monitoring infrastructure (Grafana, Nginx, Loki, etc.) using GitHub Actions.

## 🚀 Deployment Options

### 1. **Automatic Monitoring Deployment**

**Workflow:** `.github/workflows/deploy-monitoring.yml`

**Triggers:**
- Push to `main` branch with changes to:
  - `nginx/**` (Nginx configuration)
  - `scripts/**` (Deployment scripts)
  - `env/**` (Environment files)
  - `.github/workflows/deploy-monitoring.yml`
- Manual dispatch via GitHub Actions UI

**What it deploys:**
- Nginx reverse proxy with SSL termination
- Grafana dashboard and visualization
- Loki log aggregation
- Promtail log collection
- Monitoring PostgreSQL database
- Monitoring MinIO object storage

### 2. **Manual Infrastructure Deployment**

**Workflow:** `.github/workflows/deploy-infrastructure.yml`

**Triggers:**
- Manual dispatch only (workflow_dispatch)

**Options:**
- **Component:** Choose what to deploy
  - `all` - Deploy everything
  - `nginx` - Just the reverse proxy
  - `monitoring` - Just monitoring stack (Grafana, Loki)
  - `postgres` - PostgreSQL for specific environment
  - `minio` - MinIO for specific environment
- **Environment:** Choose target environment
  - `production`
  - `staging` 
  - `sandbox`

## 🔧 Required GitHub Secrets

Ensure these secrets are configured in your repository:

### **SSH Access**
- `VPS_SSH_PASSWORD` - SSH password for server access  
- `VPS_HOST` - Server hostname/IP
- `VPS_USER` - SSH username

### **Database**
- `POSTGRES_PASSWORD` - PostgreSQL password

### **Storage**
- `MINIO_ROOT_USER` - MinIO admin username
- `MINIO_ROOT_PASSWORD` - MinIO admin password

### **Monitoring**
- `GRAFANA_PASSWORD` - Grafana admin password

### **SSL/Email**
- `ACME_EMAIL` - Email for Let's Encrypt certificates

## 🌐 Required GitHub Variables

Configure these variables for domain routing:

- `API_DOMAIN` - e.g., `api.cachconnect.co.ke`
- `AGENT_DOMAIN` - e.g., `agents.cachconnect.co.ke`
- `DISTRIBUTOR_DOMAIN` - e.g., `distributors.cachconnect.co.ke`
- `BUSINESS_DOMAIN` - e.g., `business.cachconnect.co.ke`
- `ADMIN_DOMAIN` - e.g., `admin.cachconnect.co.ke`
- `LENDER_DOMAIN` - e.g., `lenders.cachconnect.co.ke`
- `STORAGE_DOMAIN` - e.g., `storage.cachconnect.co.ke`
- `GRAFANA_DOMAIN` - e.g., `monitoring.cachconnect.co.ke`
- `MINIO_BUCKET_NAME` - e.g., `cach-storage`
- `MINIO_USE_SSL` - `false` for development, `true` for production

## 📋 Deployment Steps

### **Initial Setup (One-time)**

1. **Configure Secrets & Variables**
   - Go to GitHub repository → Settings → Secrets and variables → Actions
   - Add all required secrets and variables listed above

2. **Deploy Full Infrastructure**
   - Go to Actions → "Deploy Infrastructure Components"
   - Click "Run workflow"
   - Select `component: all`, `environment: production`
   - Click "Run workflow"

### **Regular Monitoring Updates**

The monitoring stack will auto-deploy when you push changes to:
- Nginx configuration (`nginx/`)
- Deployment scripts (`scripts/`)
- Environment templates (`env/`)

### **Manual Component Updates**

1. **Update Just Nginx:**
   - Actions → "Deploy Infrastructure Components"
   - `component: nginx`, `environment: production`

2. **Update Just Monitoring:**
   - Actions → "Deploy Infrastructure Components"  
   - `component: monitoring`, `environment: production`

3. **Add New Environment Database:**
   - Actions → "Deploy Infrastructure Components"
   - `component: postgres`, `environment: staging`

## 🔍 Monitoring & Verification

After deployment, verify services:

### **Check Container Status**
```bash
ssh user@yourserver
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### **Access Services**
- **Grafana:** `https://monitoring.cachconnect.co.ke`
  - Username: `admin`
  - Password: `${GRAFANA_PASSWORD}`
- **MinIO Console:** `https://storage.cachconnect.co.ke`
  - Username: `${MINIO_ROOT_USER}`
  - Password: `${MINIO_ROOT_PASSWORD}`

### **Check Logs**
```bash
# Nginx logs
docker logs cach-nginx

# Grafana logs
docker logs cach-grafana

# Loki logs
docker logs cach-loki
```

## 🛠️ Troubleshooting

### **Nginx Not Starting**
1. Check configuration: `docker exec cach-nginx nginx -t`
2. View logs: `docker logs cach-nginx`
3. Verify domain DNS records point to your server

### **SSL Certificate Issues**
1. Check Certbot logs: `docker logs cach-certbot`
2. Verify domain ownership and DNS propagation
3. Ensure ports 80/443 are open and accessible

### **Grafana Not Accessible**
1. Check if container is running: `docker ps | grep grafana`
2. Verify port mapping: Should expose 3000 internally
3. Check Nginx proxy configuration for Grafana upstream

### **Database Connection Issues**
1. Verify PostgreSQL containers: `docker ps | grep postgres`
2. Check database connectivity: `docker exec cach-postgres-production pg_isready`
3. Verify environment variables in containers

## 🔄 Rollback

If deployment fails:

1. **Stop problematic services:**
   ```bash
   ssh user@yourserver
   cd ~/devops
   ./scripts/deploy.sh stop-monitoring
   ./scripts/deploy.sh stop-nginx
   ```

2. **Redeploy from last working state:**
   - Revert changes in git
   - Push to trigger auto-deployment
   - Or run manual deployment workflow

## 📊 Service Architecture

```
Internet
    ↓
Nginx (Port 80/443) - SSL Termination & Routing
    ↓
┌─────────────────┬────────────────┬──────────────────┐
│   Applications  │   Monitoring   │     Storage      │
│                 │                │                  │
│ api:3001        │ grafana:3000   │ minio:9000-9005  │
│ agents:3011     │ loki:3100      │ postgres:5432    │
│ business:3021   │ promtail       │ postgres:5433    │
│ admin:3031      │                │ postgres:5434    │
│ distributors:3041│               │                  │
│ lenders:3051    │                │                  │
└─────────────────┴────────────────┴──────────────────┘
            ↓
    Docker Network (cach-network)
```

This setup provides:
- ✅ **SSL termination** at Nginx level
- ✅ **Domain-based routing** to correct services  
- ✅ **Centralized logging** via Loki
- ✅ **Monitoring dashboards** via Grafana
- ✅ **Zero-downtime deployments** for individual services
- ✅ **Environment isolation** with separate databases/storage