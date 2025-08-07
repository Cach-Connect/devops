# Quick Server Fix

Since the devops repository doesn't exist on your server, here's a quick manual fix:

## Run these commands on your server:

```bash
# SSH to your server first
ssh your-username@your-server

# Navigate to home directory
cd ~

# Clone the devops repository
git clone https://github.com/Cach-Connect/devops.git

# Verify it was cloned
ls -la devops/

# Now run the fix script
cd /opt/cach/shared
~/devops/scripts/fix-deployment.sh
```

## Alternative if git clone fails:

If you can't clone from GitHub (network/auth issues), you can manually create the files:

```bash
# Create the directory structure
mkdir -p /opt/cach/shared/monitoring/alertmanager
mkdir -p /opt/cach/shared/monitoring/prometheus  
mkdir -p /opt/cach/shared/monitoring/loki
mkdir -p /opt/cach/shared/monitoring/promtail
mkdir -p /opt/cach/shared/monitoring/grafana/provisioning/datasources
mkdir -p /opt/cach/shared/nginx/conf.d

# Create a minimal alertmanager config
cat > /opt/cach/shared/monitoring/alertmanager/alertmanager.yml << 'EOF'
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@cachconnect.co.ke'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://127.0.0.1:5001/'
EOF

# Create minimal prometheus config
cat > /opt/cach/shared/monitoring/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

# Create minimal loki config
cat > /opt/cach/shared/monitoring/loki/loki.yml << 'EOF'
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h
EOF

# Create minimal promtail config
cat > /opt/cach/shared/monitoring/promtail/promtail.yml << 'EOF'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log
EOF

# Create minimal grafana datasource
cat > /opt/cach/shared/monitoring/grafana/provisioning/datasources/datasources.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

# Create minimal nginx config
cat > /opt/cach/shared/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent"';

    access_log /var/log/nginx/access.log main;
    sendfile on;
    keepalive_timeout 65;

    include /etc/nginx/conf.d/*.conf;
}
EOF

# Create minimal site config
cat > /opt/cach/shared/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;

    location / {
        return 200 "Nginx is working!";
        add_header Content-Type text/plain;
    }
}
EOF

# Now try to start the services
cd /opt/cach/shared
docker-compose -f docker-compose.shared.yml up -d
```

## Check if it worked:

```bash
# Check container status
docker-compose -f docker-compose.shared.yml ps

# Check logs if something failed
docker-compose -f docker-compose.shared.yml logs
```

After this manual fix, you can re-run the GitHub Actions deployment and it should work properly!
