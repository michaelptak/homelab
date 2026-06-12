# Lychee

Self-hosted photo management for visually organizing images into albums. Runs behind Traefik with its own MariaDB database.

## Prerequisites

- Traefik running with the `proxy` network and wildcard cert for `*.homelab.local`
- DB secrets in `/storage/docker/secrets/lychee_db_password` and `lychee_db_root_password`
- App key in `/storage/docker/secrets/lychee_app_key`

## Files

- [configs/docker/lychee.yml](../configs/docker/lychee.yml) - Docker Compose file

## Setup

Generate the database secrets:

```bash
openssl rand -base64 32 | sudo tee /storage/docker/secrets/lychee_db_root_password
openssl rand -base64 32 | sudo tee /storage/docker/secrets/lychee_db_password
sudo chmod 600 /storage/docker/secrets/lychee_db_*
sudo chown root:root /storage/docker/secrets/lychee_db_*
```

Generate the app key (Lychee refuses to start without it):

```bash
echo "base64:$(openssl rand -base64 32)" | sudo tee /storage/docker/secrets/lychee_app_key
sudo chmod 600 /storage/docker/secrets/lychee_app_key
sudo chown root:root /storage/docker/secrets/lychee_app_key
```

Save all three values in your password manager.

Create data and image directories:

```bash
mkdir -p /storage/docker/data/lychee/config
mkdir -p /storage/docker/data/lychee/db
sudo mkdir -p /storage/media/images
sudo chown $(whoami):$(whoami) /storage/media/images
```

Deploy:

```bash
cd /storage/docker/compose
docker compose -f lychee.yml up -d
```

First boot takes ~30s for DB init. Watch with `docker logs -f lychee` until you see `Application ready!`.
