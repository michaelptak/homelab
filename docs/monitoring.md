# Monitoring

Prometheus for metrics collection, Grafana for visualization, and Node Exporter for host metrics.

## Prerequisites

- Traefik running with metrics enabled (`--metrics.prometheus=true`)
- Traefik connected to the `monitoring` network
- Grafana admin password in `/storage/docker/secrets/grafana_admin_password`

## Files

- [configs/docker/monitoring.yml](../configs/docker/monitoring.yml) - Docker Compose file
- [configs/config/prometheus.yml](../configs/config/prometheus.yml) - Prometheus scrape configuration

## Setup

Create the monitoring network:
```bash
docker network create monitoring
```

Create data directories:
```bash
mkdir -p /storage/docker/data/prometheus
mkdir -p /storage/docker/data/grafana
mkdir -p /storage/docker/config

# Set ownership for container UIDs
sudo chown 65534:65534 /storage/docker/data/prometheus
sudo chown 472:472 /storage/docker/data/grafana
```

Copy `prometheus.yml` to `/storage/docker/config/`.

Deploy:
```bash
cd /storage/docker/compose
docker compose -f monitoring.yml up -d
```

Add DNS entries to client `/etc/hosts`:
```
SERVER_IP prometheus.homelab.local
SERVER_IP grafana.homelab.local
```

## Grafana Setup

1. Log in at https://grafana.homelab.local (admin / your password)
2. Go to Connections → Data sources → Add data source
3. Select Prometheus, set URL to `http://prometheus:9090`, click Save & test
4. Go to Dashboards → New → Import
5. Enter dashboard ID `1860` (Node Exporter Full), select Prometheus data source, import

## Traefik Changes

Traefik needs metrics enabled and access to the monitoring network. Add to `traefik.yml`:
```yaml
command:
  # ... existing commands ...
  - --metrics.prometheus=true

networks:
  - proxy
  - monitoring
```

And at the bottom:
```yaml
networks:
  proxy:
    external: true
  monitoring:
    external: true
```

Restart Traefik after changes.

## Troubleshooting

### Prometheus won't start (permission denied)

Prometheus runs as UID 65534. Fix data directory ownership:
```bash
sudo chown -R 65534:65534 /storage/docker/data/prometheus
```

### Grafana password not working

Reset the admin password:
```bash
docker exec grafana grafana-cli admin reset-admin-password newPassword
```
