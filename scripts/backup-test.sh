#!/bin/bash
BACKUP_DIR="/storage/backups"
DATE=$(date +%Y%m%d_%H%M%S)

echo "Backup started at $(date)"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup compose files
tar czf "$BACKUP_DIR/compose_$DATE.tar.gz" -C /storage/docker compose

echo "Backup finished at $(date)"
