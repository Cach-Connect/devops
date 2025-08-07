#!/bin/bash

# Fix Deployment Script - Resolves common deployment issues on the server

echo "🔧 Cach Connect Deployment Fix"
echo "=============================="

cd /opt/cach/shared 2>/dev/null || {
    echo "❌ Cannot access /opt/cach/shared"
    echo "Creating directory structure..."
    mkdir -p /opt/cach/shared
    cd /opt/cach/shared
}

echo "📍 Working in: $(pwd)"

echo ""
echo "🛑 Stopping any running containers..."
docker-compose -f docker-compose.shared.yml down 2>/dev/null || echo "No containers to stop"

echo ""
echo "🧹 Cleaning up problematic files/directories..."

# Remove files that might have been created as directories
problematic_paths=(
    "monitoring/alertmanager/alertmanager.yml"
    "monitoring/prometheus/prometheus.yml"
    "monitoring/loki/loki.yml"
    "monitoring/promtail/promtail.yml"
    "monitoring/grafana/provisioning/datasources/datasources.yml"
    "nginx/nginx.conf"
    "nginx/conf.d/cach.conf"
)

for path in "${problematic_paths[@]}"; do
    if [ -d "$path" ]; then
        echo "🗑️  Removing directory: $path (should be a file)"
        rm -rf "$path"
    fi
done

echo ""
echo "📋 Re-copying configuration from ~/devops..."

# Ensure source exists
if [ ! -d "~/devops" ]; then
    echo "📥 Cloning devops repository..."
    cd ~
    git clone https://github.com/Cach-Connect/devops.git || {
        echo "❌ Failed to clone devops repo"
        exit 1
    }
    cd /opt/cach/shared
fi

# Update devops
echo "🔄 Updating devops configuration..."
cd ~/devops
git pull origin main
cd /opt/cach/shared

# Clean copy of files
echo "📋 Copying files with clean slate..."

# Remove and recreate directories
rm -rf monitoring nginx scripts
mkdir -p monitoring nginx scripts ssl/certs ssl/private ssl/www logs

# Copy files properly
echo "📁 Copying monitoring configuration..."
if [ -d "~/devops/monitoring" ]; then
    cp -r ~/devops/monitoring/* ./monitoring/
else
    echo "❌ ~/devops/monitoring not found"
    exit 1
fi

echo "📁 Copying nginx configuration..."
if [ -d "~/devops/nginx" ]; then
    cp -r ~/devops/nginx/* ./nginx/
else
    echo "❌ ~/devops/nginx not found"
    exit 1
fi

echo "📁 Copying scripts..."
if [ -d "~/devops/scripts" ]; then
    cp -r ~/devops/scripts/* ./scripts/
    chmod +x scripts/*.sh scripts/certbot/*.sh 2>/dev/null
else
    echo "❌ ~/devops/scripts not found"
    exit 1
fi

echo "📁 Copying docker-compose file..."
if [ -f "~/devops/docker-compose/docker-compose.shared.yml" ]; then
    cp ~/devops/docker-compose/docker-compose.shared.yml .
else
    echo "❌ ~/devops/docker-compose/docker-compose.shared.yml not found"
    exit 1
fi

echo ""
echo "🔍 Verifying files were copied correctly..."

required_files=(
    "monitoring/alertmanager/alertmanager.yml"
    "monitoring/prometheus/prometheus.yml"
    "monitoring/loki/loki.yml"
    "monitoring/promtail/promtail.yml"
    "monitoring/grafana/provisioning/datasources/datasources.yml"
    "nginx/nginx.conf"
    "docker-compose.shared.yml"
)

all_good=true
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file ($(stat -c%s "$file" 2>/dev/null || echo "unknown") bytes)"
    else
        echo "❌ $file missing"
        all_good=false
    fi
done

if [ "$all_good" = false ]; then
    echo ""
    echo "❌ Some files are still missing. Check the source ~/devops directory."
    echo "Directory structure:"
    find . -name "*.yml" -o -name "*.yaml" | head -20
    exit 1
fi

echo ""
echo "✅ All files verified successfully!"

echo ""
echo "🚀 Attempting to start services..."
docker-compose -f docker-compose.shared.yml up -d

echo ""
echo "⏳ Waiting 30 seconds for services to start..."
sleep 30

echo ""
echo "🔍 Checking service status..."
docker-compose -f docker-compose.shared.yml ps

echo ""
echo "🎉 Fix script completed!"
echo ""
echo "💡 Next steps:"
echo "1. Check if containers are running above"
echo "2. If still failing, check logs: docker-compose -f docker-compose.shared.yml logs"
echo "3. Test access: curl http://localhost:9090/-/healthy"