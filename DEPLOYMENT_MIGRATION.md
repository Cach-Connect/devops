# Deployment Migration Guide

This document outlines the changes needed to migrate from individual app deployments to the centralized nginx reverse proxy deployment system.

## ✅ Completed Updates

### 1. **Agent App** (`/agent/.github/workflows/deploy.yml`)
- ✅ Updated port assignments (3010→3011, 3011→3012, 3012→3013)
- ✅ Integrated with centralized deployment script
- ✅ Updated to use domain-based URLs in output
- ✅ Removed individual docker-compose downloads

### 2. **Distributor App** (`/distributor/.github/workflows/deploy.yml`)
- ✅ Updated port assignments (3020→3021, 3021→3022, 3022→3023)
- ✅ Integrated with centralized deployment script
- ✅ Updated to use domain-based URLs in output
- ✅ Removed individual docker-compose downloads

### 3. **API** (`/api/.github/workflows/deploy.yml`)
- ✅ Integrated with centralized deployment script
- ✅ Updated to use domain-based URLs in output
- ✅ Updated monitoring URLs to use shared services
- ✅ Simplified deployment process

## 🔄 Required Updates for Remaining Apps

The following apps need similar workflow updates:

### 4. **Business App** (`/business/.github/workflows/deploy.yml`)
**Required Changes:**
- Update port assignments:
  - Production: 3030 → 3031
  - Staging: 3031 → 3032  
  - Sandbox: 3032 → 3033
- Replace deployment script with centralized approach
- Update domain URLs in output

### 5. **Admin App** (`/admin/.github/workflows/deploy.yml`)
**Required Changes:**
- Update port assignments:
  - Production: 3040 → 3041
  - Staging: 3041 → 3042
  - Sandbox: 3042 → 3043
- Replace deployment script with centralized approach
- Update domain URLs in output

### 6. **Lender App** (`/lender/.github/workflows/deploy.yml`)
**Required Changes:**
- Update port assignments:
  - Production: 3050 → 3051
  - Staging: 3051 → 3052
  - Sandbox: 3052 → 3053
- Replace deployment script with centralized approach
- Update domain URLs in output

## 📋 Migration Template

For each remaining app, apply these changes:

### 1. Update Port Assignments
```bash
# In the setup job, change the port mapping:
case "$ENVIRONMENT" in
  "production")
    echo "app_port=NEW_PROD_PORT" >> $GITHUB_OUTPUT
    ;;
  "staging")
    echo "app_port=NEW_STAGING_PORT" >> $GITHUB_OUTPUT
    ;;
  "sandbox")
    echo "app_port=NEW_SANDBOX_PORT" >> $GITHUB_OUTPUT
    ;;
esac
```

### 2. Replace Deployment Script
Replace the SSH deployment section with:
```bash
script: |
  # Deploy using centralized DevOps deployment script
  echo "🚀 Deploying [APP_NAME] using centralized deployment..."
  
  # Navigate to the centralized devops directory
  cd ~/devops || {
    echo "❌ DevOps directory not found. Setting up..."
    git clone https://github.com/Cach-Connect/devops.git ~/devops
    cd ~/devops
  }
  
  # Pull latest devops configuration
  git pull origin main
  
  # Make deploy script executable
  chmod +x scripts/deploy.sh
  
  # Update environment variables
  case "${{ needs.setup.outputs.environment }}" in
    "production")
      export [APP]_PRODUCTION_TAG=${{ needs.setup.outputs.tag }}
      sed -i "s/[APP]_PRODUCTION_TAG=.*/[APP]_PRODUCTION_TAG=${{ needs.setup.outputs.tag }}/" .env 2>/dev/null || echo "[APP]_PRODUCTION_TAG=${{ needs.setup.outputs.tag }}" >> .env
      ;;
    "staging")
      export [APP]_STAGING_TAG=${{ needs.setup.outputs.tag }}
      sed -i "s/[APP]_STAGING_TAG=.*/[APP]_STAGING_TAG=${{ needs.setup.outputs.tag }}/" .env 2>/dev/null || echo "[APP]_STAGING_TAG=${{ needs.setup.outputs.tag }}" >> .env
      ;;
    "sandbox")
      export [APP]_SANDBOX_TAG=${{ needs.setup.outputs.tag }}
      sed -i "s/[APP]_SANDBOX_TAG=.*/[APP]_SANDBOX_TAG=${{ needs.setup.outputs.tag }}/" .env 2>/dev/null || echo "[APP]_SANDBOX_TAG=${{ needs.setup.outputs.tag }}" >> .env
      ;;
  esac
  
  # Deploy the app
  ./scripts/deploy.sh deploy-app -e ${{ needs.setup.outputs.environment }} -s [service-name]
  
  # Health check and status
  timeout 120 bash -c 'until curl -f http://localhost:${{ needs.setup.outputs.app_port }}/; do echo "Waiting..."; sleep 5; done'
  ./scripts/deploy.sh status
  
  # Show results with domain
  case "${{ needs.setup.outputs.environment }}" in
    "production")
      DOMAIN="https://[app].cachconnect.co.ke"
      ;;
    "staging") 
      DOMAIN="https://[app].staging.cachconnect.co.ke"
      ;;
    "sandbox")
      DOMAIN="https://[app].sandbox.cachconnect.co.ke"
      ;;
  esac
  
  echo "✅ Deployment complete!"
  echo "🌐 [App Name]: $DOMAIN"
  echo "🔧 Direct Port Access: http://$(curl -s ifconfig.me):${{ needs.setup.outputs.app_port }}"
```

### 3. Update Summary URLs
Replace the summary section URL output with:
```bash
echo "### 📡 Service URLs:" >> $GITHUB_STEP_SUMMARY
case "${{ needs.setup.outputs.environment }}" in
  "production")
    echo "- **[App Name]**: https://[app].cachconnect.co.ke" >> $GITHUB_STEP_SUMMARY
    ;;
  "staging")
    echo "- **[App Name]**: https://[app].staging.cachconnect.co.ke" >> $GITHUB_STEP_SUMMARY
    ;;
  "sandbox")
    echo "- **[App Name]**: https://[app].sandbox.cachconnect.co.ke" >> $GITHUB_STEP_SUMMARY
    ;;
esac
echo "- **Direct Port**: Port ${{ needs.setup.outputs.app_port }}" >> $GITHUB_STEP_SUMMARY
```

## 🔧 Variable Replacements by App

| App | [APP] | [app] | [service-name] | [App Name] |
|-----|-------|-------|----------------|------------|
| Business | BUSINESS | business | business | Business App |
| Admin | ADMIN | admin | admin | Admin App |
| Lender | LENDER | lenders | lenders | Lender App |

## 🚀 Benefits After Migration

1. **Centralized Management**: All deployments use the same script and configuration
2. **Domain-based Access**: Clean URLs with SSL termination
3. **Consolidated Monitoring**: Single Grafana/Loki instance for all environments
4. **Simplified Maintenance**: One place to update deployment logic
5. **Better Resource Usage**: Shared nginx and monitoring reduces server load

## 🔍 Testing the Migration

After updating each workflow:

1. **Test deployment**: Trigger the workflow for each environment
2. **Verify domains**: Check that the domain URLs work correctly
3. **Check monitoring**: Ensure logs appear in the consolidated Grafana
4. **Validate health**: Confirm health checks pass on new ports

## 📝 Notes

- The centralized devops repository must be available at the expected GitHub location
- DNS records for all domains must point to the server
- SSL certificates will be managed automatically by the nginx setup
- The centralized deployment script handles starting/stopping individual services
- All apps will share the same Docker network for inter-service communication