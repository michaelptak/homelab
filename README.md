# Homelab

A place for me to document my setup and scripts for my personal home server for reproducibility. Using it for self-hosted services, mainly for fun and as a learning environment for Linux, Docker, networking, etc.

## Hardware

- **CPU**: Intel Core i7-6700 @ 3.40GHz
- **RAM**: 32GB
- **GPU**: NVIDIA GTX 1050 Ti (for potential future transcoding)
- **OS Drive**: 1TB NVMe SSD
- **Storage**: 2x 8TB HDD in RAID1
- **OS**: Ubuntu Server 24.04 LTS

## Current Services

**Running:**
- Traefik - reverse proxy with SSL
- Portainer - container management
- NextCloud - file storage
- Navidrome - music streaming
- Grafana + Prometheus - monitoring
- Languagetool - editing tool for writing

## Network

- Local access only (no external exposure, at least for now)
- SSL via mkcert local CA
- Services accessed via `*.homelab.local` domains

## Project Status

**Working:**
- Base system with SSH hardening, UFW firewall
- RAID1 storage array with SMART monitoring
- Docker with Traefik reverse proxy
- Local SSL certificates
- NextCloud deployment
- Navidrome music streaming server
- Remote access via Tailscale

**Planned:**
- Automated backups

## Documentation
Note: Still in progress.
- [Setup Guide](docs/setup-guide.md)
- [Troubleshooting](docs/troubleshooting.md)

