#!/bin/bash

# Debug Deployment Script - helps identify file structure issues

echo "🔍 Cach Connect Deployment Debug"
echo "================================"

echo ""
echo "📁 Current working directory:"
pwd

echo ""
echo "📋 Directory structure:"
echo "Top level:"
ls -la

echo ""
echo "📋 Monitoring directory:"
if [ -d "monitoring" ]; then
    find monitoring -type f | head -20
else
    echo "❌ monitoring directory not found"
fi

echo ""
echo "📋 Nginx directory:"
if [ -d "nginx" ]; then
    find nginx -type f | head -10
else
    echo "❌ nginx directory not found"
fi

echo ""
echo "📋 Scripts directory:"
if [ -d "scripts" ]; then
    find scripts -type f | head -10
else
    echo "❌ scripts directory not found"
fi

echo ""
echo "📋 Docker compose files:"
find . -name "docker-compose*.yml" -o -name "*.yml" | grep -E "(docker-compose|yml)" | head -10

echo ""
echo "🐳 Docker status:"
echo "Docker version:"
docker --version

echo ""
echo "Docker compose version:"
docker-compose --version

echo ""
echo "🔍 Docker networks:"
docker network ls | grep cach || echo "No cach networks found"

echo ""
echo "🔍 Docker containers:"
docker ps | grep cach || echo "No cach containers running"

echo ""
echo "📊 System resources:"
echo "Disk space:"
df -h | head -5

echo ""
echo "Memory:"
free -h

echo ""
echo "🔍 Environment variables (safe ones):"
env | grep -E "(ENVIRONMENT|NODE_ENV)" || echo "No relevant env vars found"

echo ""
echo "🎯 Debug complete!"
echo "Share this output when reporting deployment issues."
