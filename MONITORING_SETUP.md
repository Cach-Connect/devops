# Cach Connect Monitoring & Infrastructure Setup

This document describes the complete monitoring and infrastructure setup for Cach Connect, including Grafana, Prometheus, Loki, Nginx reverse proxy, and SSL certificate management.

## 🏗️ Architecture Overview

```
Internet → Nginx (SSL/Reverse Proxy) → Applications
    ↓
Prometheus ← Node Exporter, cAdvisor, App Metrics
    ↓
Grafana ← Loki ← Promtail (Log Collection)
    ↓
Alertmanager → Email/Slack Notifications
```

## 📋 Components

### Monitoring Stack
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation and storage
- **Promtail**: Log collection agent
- **Alertmanager**: Alert routing and notifications
- **Node Exporter**: System metrics
- **cAdvisor**: Container metrics

### Infrastructure
- **Nginx**: Reverse proxy and load balancer
- **Certbot**: Automatic SSL certificate management
- **Docker**: Container orchestration

## 🚀 Quick Start

### 1. Deploy Monitoring Stack

```bash
# Navigate to devops directory
cd /path/to/cach/devops

# Copy and configure environment file
cp env.monitoring.example .env.monitoring
# Edit .env.monitoring with your actual values

# Deploy the monitoring stack
./scripts/deploy-monitoring.sh production up
```

### 2. Setup SSL Certificates

```bash
# Initial SSL setup (use staging for testing)
./scripts/setup-ssl.sh staging  # For testing
./scripts/setup-ssl.sh false    # For production
```

### 3. Access Monitoring Services

- **Grafana**: https://grafana.cachconnect.co.ke
  - Default login: admin/CachConnect2024!
- **Prometheus**: http://your-server:9090
- **Alertmanager**: http://your-server:9093

## 🔧 Configuration

### Environment Variables

Create `.env.monitoring` from the example file and configure:

```bash
# Required variables
GRAFANA_ADMIN_PASSWORD=your_secure_password
SMTP_PASSWORD=your_email_password
SLACK_WEBHOOK_URL=your_slack_webhook (optional)
```

### Nginx Configuration

The nginx configuration automatically:
- Routes traffic to appropriate applications
- Handles SSL termination
- Provides load balancing
- Implements security headers
- Rate limiting for API endpoints

### SSL Certificates

SSL certificates are automatically:
- Obtained from Let's Encrypt
- Renewed every 12 hours via cron
- Applied to all configured domains

## 📊 Dashboards

### Pre-configured Dashboards

1. **System Overview**: CPU, Memory, Disk usage
2. **Application Performance**: Response times, error rates
3. **Container Metrics**: Docker container health
4. **Nginx Metrics**: Request rates, response codes
5. **Database Performance**: PostgreSQL metrics
6. **MinIO Storage**: Object storage metrics

### Custom Dashboards

Add custom dashboards in `/monitoring/grafana/dashboards/` as JSON files.

## 🚨 Alerting

### Alert Types

- **Critical**: Service down, high error rates, disk space low
- **Warning**: High CPU/memory usage, slow response times

### Notification Channels

- **Email**: Sent to configured admin addresses
- **Slack**: Posted to designated channels
- **Webhook**: Custom integrations

### Alert Configuration

Edit `/monitoring/alertmanager/alertmanager.yml` to customize:
- Notification recipients
- Alert routing rules
- Escalation policies

## 🔍 Logs

### Log Sources

- **Application logs**: From Docker containers
- **System logs**: From the host system
- **Nginx logs**: Access and error logs
- **Docker logs**: Container lifecycle events

### Log Retention

- **Loki**: 30 days (configurable)
- **Nginx**: Rotated daily, kept for 30 days
- **Application**: Managed by Docker logging driver

## 🛠️ Management Commands

### Monitoring Stack

```bash
# Start all services
./scripts/deploy-monitoring.sh production up

# Stop all services
./scripts/deploy-monitoring.sh production down

# Restart services
./scripts/deploy-monitoring.sh production restart

# View logs
./scripts/deploy-monitoring.sh production logs
```

### SSL Management

```bash
# Check certificate status
docker run --rm -v $(pwd)/ssl/certs:/etc/letsencrypt certbot/certbot certificates

# Manual renewal
docker run --rm -v $(pwd)/ssl/certs:/etc/letsencrypt -v $(pwd)/ssl/www:/var/www/certbot certbot/certbot renew

# Test renewal
docker run --rm -v $(pwd)/ssl/certs:/etc/letsencrypt -v $(pwd)/ssl/www:/var/www/certbot certbot/certbot renew --dry-run
```

## 🔧 Troubleshooting

### Common Issues

1. **SSL Certificate Issues**
   ```bash
   # Check nginx configuration
   docker exec cach_nginx nginx -t
   
   # Check certificate files
   ls -la ssl/certs/live/
   ```

2. **Monitoring Services Not Starting**
   ```bash
   # Check service logs
   docker-compose -f docker-compose.shared.yml logs grafana
   
   # Check resource usage
   docker stats
   ```

3. **Network Connectivity Issues**
   ```bash
   # Check network configuration
   docker network ls
   docker network inspect monitoring_network
   ```

### Log Locations

- **Application logs**: Docker container logs
- **Nginx logs**: `/var/log/nginx/`
- **SSL logs**: `/var/log/letsencrypt/`
- **System logs**: `/var/log/`

## 🔒 Security

### Security Features

- **SSL/TLS**: All traffic encrypted
- **Rate limiting**: Protection against abuse
- **Security headers**: XSS, CSRF protection
- **Access control**: IP-based restrictions (configurable)

### Firewall Configuration

Ensure these ports are open:
- **80**: HTTP (redirects to HTTPS)
- **443**: HTTPS
- **9090**: Prometheus (internal only)
- **3000**: Grafana (via nginx)
- **9093**: Alertmanager (internal only)

## 📈 Scaling

### Horizontal Scaling

- Add more nginx instances behind a load balancer
- Use Prometheus federation for multiple instances
- Implement Grafana clustering for high availability

### Vertical Scaling

- Increase Docker container resources
- Adjust Prometheus retention and storage
- Optimize Grafana dashboard queries

## 🔄 Backup & Recovery

### Automated Backups

- **Grafana dashboards**: Exported daily
- **Prometheus data**: Snapshot-based backup
- **SSL certificates**: Automatically backed up

### Recovery Procedures

1. **Restore Grafana**: Import dashboard JSON files
2. **Restore Prometheus**: Restore from snapshots
3. **Restore SSL**: Re-run certificate generation

## 📞 Support

For issues and support:
- Check logs first using provided commands
- Review this documentation
- Contact the devops team

## 🔄 Updates

To update the monitoring stack:

1. Pull latest configurations from git
2. Update Docker images: `docker-compose pull`
3. Restart services: `./scripts/deploy-monitoring.sh production restart`

---

**Last Updated**: 2024-01-XX
**Version**: 1.0.0
