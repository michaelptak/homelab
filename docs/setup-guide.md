# Setup Guide

Setup process for the home server. Placeholders are used for values that will vary by environment:
- `SERVER_IP` - server's static IP address
- `LAN_SUBNET` - local network range (e.g. 192.168.1.0/24)
- `USERNAME` - admin user account
- `UUID` - filesystem UUID from blkid

I organized them into "Days" based on how much time I planned to spend on each section (Did not go according to plan)

## Day 1: Foundation

### Step 1: OS Installation

Installed Ubuntu Server 24.04 LTS to the NVMe SSD. During installation:
- Configured network with DHCP (static IP assigned via router reservation)
- Enabled OpenSSH server
- Created admin user

Post-install essentials:
```bash
sudo apt update && sudo apt upgrade -y

sudo apt install -y curl wget git vim htop tree unzip \
  software-properties-common apt-transport-https \
  ca-certificates gnupg lsb-release smartmontools mkcert

# Time sync
sudo systemctl enable --now systemd-timesyncd

# Firewall (LAN-only access)
sudo ufw enable
sudo ufw allow from LAN_SUBNET to any port 22
sudo ufw allow from LAN_SUBNET to any port 80
sudo ufw allow from LAN_SUBNET to any port 443

# SSD maintenance
sudo systemctl enable --now fstrim.timer

# Drive monitoring
sudo systemctl enable --now smartd
```

### Step 2: SSH Hardening

Generate key pair on client machine:
```bash
ssh-keygen -t ed25519 -C "homelab-access"
ssh-copy-id USERNAME@SERVER_IP
```

Test key auth before disabling passwords:
```bash
ssh -o PreferredAuthentications=publickey USERNAME@SERVER_IP
```

Harden `/etc/ssh/sshd_config`:
```
Port 2222
PasswordAuthentication no
PermitRootLogin no
MaxAuthTries 3
AllowUsers USERNAME
ClientAliveInterval 300
ClientAliveCountMax 2
```

**Important:** Ubuntu's cloud-init overrides sshd_config. Remove the override:
```bash
sudo rm /etc/ssh/sshd_config.d/50-cloud-init.conf
```

Apply changes (keep current session open as backup):
```bash
sudo sshd -t
sudo ufw allow from LAN_SUBNET to any port 2222
sudo systemctl restart ssh

# Test in a NEW terminal before closing current session
ssh -p 2222 USERNAME@SERVER_IP

# Only after confirming it works:
sudo ufw delete allow from LAN_SUBNET to any port 22
```

### Step 3: RAID Setup

Identify drives:
```bash
lsblk
sudo fdisk -l
```

Create partitions on each HDD:
```bash
sudo fdisk /dev/sda  # n, p, 1, defaults, w
sudo fdisk /dev/sdb  # repeat
```

Create RAID1 array:
```bash
sudo apt install mdadm -y
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 \
  --metadata=1.2 --bitmap=internal /dev/sda1 /dev/sdb1
```

Format and mount:
```bash
sudo mkfs.ext4 /dev/md0
sudo blkid /dev/md0  # note the UUID

sudo mkdir /storage
echo 'UUID=UUID /storage ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
sudo mount -a
sudo chown USERNAME:USERNAME /storage
```

Save RAID config:
```bash
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
sudo update-initramfs -u
```

Enable SMART monitoring:
```bash
sudo smartctl -s on /dev/sda
sudo smartctl -s on /dev/sdb
```


## Day 2: Services and Management

### Step 4: Docker Installation

Follow the official Docker installation guide for Ubuntu:
https://docs.docker.com/engine/install/ubuntu/

After installation:
```bash
# Add user to docker group
sudo usermod -aG docker USERNAME
newgrp docker

# Enable on boot
sudo systemctl enable docker

# Configure log rotation
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

sudo systemctl restart docker
```

Create directory structure:
```bash
mkdir -p /storage/docker/{compose,data,secrets}
chmod 700 /storage/docker/secrets
```

### Step 5: SSL Certificates

Using mkcert for local CA:
```bash
mkcert -install

mkdir -p /storage/docker/data/certs
cd /storage/docker/data/certs

# Generate wildcard cert for local domain
mkcert "*.homelab.local" "homelab.local" "localhost" "127.0.0.1" "::1" SERVER_IP

# Rename for Traefik
mv _wildcard.homelab.local+5.pem homelab.local.pem
mv _wildcard.homelab.local+5-key.pem homelab.local-key.pem

chmod 600 *.pem
```

Copy the CA to client machines for browser trust:
```bash
# From client machine
scp -P 2222 USERNAME@SERVER_IP:~/.local/share/mkcert/rootCA.pem .
# Then install in your browser/system trust store
```

### Step 6: Secrets Setup

Generate and store service passwords:
```bash
# Generate passwords
NEXTCLOUD_DB_ROOT_PASSWORD=$(openssl rand -base64 32)
NEXTCLOUD_DB_PASSWORD=$(openssl rand -base64 32)
GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 32)
TRAEFIK_DASHBOARD_PASSWORD=$(openssl rand -base64 32)

# Store in files
echo "$NEXTCLOUD_DB_ROOT_PASSWORD" | sudo tee /storage/docker/secrets/nextcloud_db_root_password
echo "$NEXTCLOUD_DB_PASSWORD" | sudo tee /storage/docker/secrets/nextcloud_db_password
echo "$GRAFANA_ADMIN_PASSWORD" | sudo tee /storage/docker/secrets/grafana_admin_password

# Traefik dashboard uses htpasswd format
echo "admin:$(openssl passwd -apr1 "$TRAEFIK_DASHBOARD_PASSWORD")" | sudo tee /storage/docker/secrets/traefik_dashboard_auth

# Secure permissions
sudo chmod 600 /storage/docker/secrets/*
sudo chown root:root /storage/docker/secrets/*

# Save these passwords somewhere safe (password manager)
echo "NextCloud DB Root: $NEXTCLOUD_DB_ROOT_PASSWORD"
echo "NextCloud DB User: $NEXTCLOUD_DB_PASSWORD"
echo "Grafana Admin: $GRAFANA_ADMIN_PASSWORD"
echo "Traefik Dashboard: admin / $TRAEFIK_DASHBOARD_PASSWORD"
```

### Step 7: Traefik Reverse Proxy

Create dynamic TLS config:
```bash
mkdir -p /storage/docker/data/traefik/dynamic

tee /storage/docker/data/traefik/dynamic/tls.yml > /dev/null <<EOF
tls:
  certificates:
    - certFile: /certs/homelab.local.pem
      keyFile: /certs/homelab.local-key.pem
EOF
```

Create Docker network and deploy:
```bash
docker network create proxy

cd /storage/docker/compose
docker compose -f traefik.yml up -d
```

See [configs/docker/traefik.yml](../configs/docker/traefik.yml) for the compose file.

### Step 8: Portainer
```bash
cd /storage/docker/compose
docker compose -f portainer.yml up -d
```

See [configs/docker/portainer.yml](../configs/docker/portainer.yml) for the compose file.

At this point, initialize a git repository in `/storage/docker/compose` to track configuration changes locally.

### Local DNS

Add entries to `/etc/hosts` on client machines:
```
SERVER_IP traefik.homelab.local
SERVER_IP portainer.homelab.local
```

### Verify

After setup, these should be accessible:
- https://traefik.homelab.local (admin / your password)
- https://portainer.homelab.local
