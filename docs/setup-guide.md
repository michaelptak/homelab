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
