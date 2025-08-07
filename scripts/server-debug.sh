#!/bin/bash

# Server Debug Script - Run this on the server to diagnose deployment issues

echo "🔍 Cach Connect Server Deployment Debug"
echo "========================================"

echo ""
echo "📍 Current location:"
pwd

echo ""
echo "📁 /opt/cach directory structure:"
if [ -d "/opt/cach" ]; then
    ls -la /opt/cach/
    
    if [ -d "/opt/cach/shared" ]; then
        echo ""
        echo "📁 /opt/cach/shared structure:"
        cd /opt/cach/shared
        echo "Current directory: $(pwd)"
        ls -la
        
        echo ""
        echo "📋 Looking for monitoring files:"
        if [ -d "monitoring" ]; then
            echo "Monitoring directory exists:"
            find monitoring -type f -name "*.yml" -o -name "*.yaml" 2>/dev/null | head -10
            
            echo ""
            echo "📋 Specific file checks:"
            files_to_check=(
                "monitoring/alertmanager/alertmanager.yml"
                "monitoring/prometheus/prometheus.yml"
                "monitoring/loki/loki.yml"
                "monitoring/promtail/promtail.yml"
                "docker-compose.shared.yml"
            )
            
            for file in "${files_to_check[@]}"; do
                if [ -f "$file" ]; then
                    echo "✅ $file exists ($(stat -c%s "$file") bytes)"
                    # Show first few lines to verify it's a proper file
                    echo "   First 3 lines:"
                    head -n 3 "$file" | sed 's/^/   /'
                else
                    echo "❌ $file missing"
                    # Check if it exists as a directory (common mistake)
                    if [ -d "$file" ]; then
                        echo "   ⚠️  EXISTS AS DIRECTORY! This is the problem."
                        echo "   Contents:"
                        ls -la "$file" | head -5 | sed 's/^/   /'
                    fi
                fi
            done
        else
            echo "❌ monitoring directory doesn't exist"
        fi
        
        echo ""
        echo "📋 Docker compose file check:"
        if [ -f "docker-compose.shared.yml" ]; then
            echo "✅ docker-compose.shared.yml exists"
            echo "First 10 lines:"
            head -n 10 docker-compose.shared.yml | sed 's/^/   /'
        else
            echo "❌ docker-compose.shared.yml missing"
        fi
        
    else
        echo "❌ /opt/cach/shared doesn't exist"
    fi
else
    echo "❌ /opt/cach doesn't exist"
fi

echo ""
echo "🏠 Home directory devops check:"
if [ -d "~/devops" ]; then
    echo "✅ ~/devops exists"
    ls -la ~/devops/ | head -5
    
    echo ""
    echo "📋 Source monitoring files in ~/devops:"
    if [ -d "~/devops/monitoring" ]; then
        find ~/devops/monitoring -name "*.yml" -o -name "*.yaml" 2>/dev/null | head -5
    else
        echo "❌ ~/devops/monitoring doesn't exist"
    fi
else
    echo "❌ ~/devops doesn't exist"
fi

echo ""
echo "🐳 Docker status:"
echo "Running containers:"
docker ps | grep cach || echo "No cach containers running"

echo ""
echo "Docker networks:"
docker network ls | grep cach || echo "No cach networks found"

echo ""
echo "🔍 Recent Docker events (last 10):"
docker events --since="$(date -d '10 minutes ago' --iso-8601)" --until="$(date --iso-8601)" 2>/dev/null | tail -10 || echo "No recent events or date command not available"

echo ""
echo "📊 System info:"
echo "Disk space for /opt:"
df -h /opt 2>/dev/null || echo "Cannot check /opt disk space"

echo ""
echo "User and permissions:"
echo "Current user: $(whoami)"
echo "Groups: $(groups)"
echo "Can write to /opt/cach:"
if touch /opt/cach/test_write 2>/dev/null; then
    echo "✅ Yes"
    rm -f /opt/cach/test_write
else
    echo "❌ No"
fi

echo ""
echo "🎯 Debug complete!"
echo ""
echo "💡 Next steps:"
echo "1. If files exist as directories instead of files, remove them and re-run deployment"
echo "2. If files are missing entirely, check the GitHub Actions log for copy errors"
echo "3. If permissions issues, check user access to /opt/cach"
