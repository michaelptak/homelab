#!/bin/bash

BACKUP_DIR="/storage/backups"
DATE=$(date +%Y%m%d_%H%M%S)

echo "Backup started at $(date)"

mkdir -p "$BACKUP_DIR"

echo "Backing up compose files..."
tar czf "$BACKUP_DIR/compose_$DATE.tar.gz" -C /storage/docker compose || echo "ERROR: compose backup failed"

echo "Backing up config files..."
tar czf "$BACKUP_DIR/config_$DATE.tar.gz" -C /storage/docker config || echo "ERROR: config backup failed"

echo "Backing up secrets..."
tar czf "$BACKUP_DIR/secrets_$DATE.tar.gz" -C /storage/docker secrets || echo "ERROR: secrets backup failed"

echo "Backing up data..."
tar czf "$BACKUP_DIR/data_$DATE.tar.gz" -C /storage/docker data || echo "ERROR: data backup failed"

echo "Backing up system configs..."
tar czf "$BACKUP_DIR/system_$DATE.tar.gz" /etc/fstab /etc/ssh/sshd_config /etc/mdadm/mdadm.conf || echo "ERROR: system backup failed"

echo "Backup finished at $(date)"
