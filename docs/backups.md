# Automated Backups

Daily backups using a shell script and systemd timer.

## What Gets Backed Up

- `/storage/docker/compose/` - Docker compose files
- `/storage/docker/config/` - Service configs (Prometheus, etc.)
- `/storage/docker/secrets/` - Passwords and credentials
- `/storage/docker/data/` - Service data (Grafana, NextCloud, etc.)
- NextCloud database (dumped via mariadb-dump)
- System configs (`/etc/fstab`, `/etc/ssh/sshd_config`, `/etc/mdadm/mdadm.conf`)

Backups are stored in `/storage/backups/` and retained for 7 days.

## Files

- [scripts/homelab-backup.sh](../scripts/homelab-backup.sh) - Backup script
- `/etc/systemd/system/homelab-backup.service` - Systemd service
- `/etc/systemd/system/homelab-backup.timer` - Systemd timer (runs daily at 2 AM UTC)

## Setup

Copy the backup script:
```bash
sudo cp scripts/homelab-backup.sh /usr/local/bin/homelab-backup.sh
sudo chmod +x /usr/local/bin/homelab-backup.sh
```

Create the systemd service at `/etc/systemd/system/homelab-backup.service`:
```ini
[Unit]
Description=Homelab Backup
After=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/homelab-backup.sh
```

Create the timer at `/etc/systemd/system/homelab-backup.timer`:
```ini
[Unit]
Description=Run Homelab Backup Daily

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable homelab-backup.timer
sudo systemctl start homelab-backup.timer
```

## Manual Backup
```bash
sudo systemctl start homelab-backup.service
```

## Check Status
```bash
# Next scheduled run
systemctl list-timers | grep homelab

# Logs from last run
journalctl -u homelab-backup.service
```

## Restoring

To restore the NextCloud database:
```bash
DB_PASS=$(sudo cat /storage/docker/secrets/nextcloud_db_password)
cat /storage/backups/nextcloud_db_TIMESTAMP.sql | docker exec -i nextcloud-db mariadb -u nextcloud -p"$DB_PASS" nextcloud
```

To restore other files, extract the relevant tar archive:
```bash
sudo tar xzf /storage/backups/compose_TIMESTAMP.tar.gz -C /storage/docker/
```
