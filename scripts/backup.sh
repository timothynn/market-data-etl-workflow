#!/bin/bash

# n8n Backup Script
# Creates a complete backup of n8n data, workflows, and database

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="n8n-backup-${TIMESTAMP}"
TEMP_DIR="/tmp/${BACKUP_NAME}"

echo -e "${GREEN}Starting n8n backup...${NC}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"
mkdir -p "${TEMP_DIR}"

# Check if Docker containers are running
if ! docker compose ps | grep -q "Up"; then
    echo -e "${RED}Error: n8n containers are not running${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/5] Backing up n8n workflows...${NC}"
docker compose exec -T n8n n8n export:workflow --all --output=/tmp/workflows.json || true
docker compose cp n8n:/tmp/workflows.json "${TEMP_DIR}/workflows.json"

echo -e "${YELLOW}[2/5] Backing up n8n credentials...${NC}"
docker compose exec -T n8n n8n export:credentials --all --output=/tmp/credentials.json || true
docker compose cp n8n:/tmp/credentials.json "${TEMP_DIR}/credentials.json"

echo -e "${YELLOW}[3/5] Backing up PostgreSQL database...${NC}"
docker compose exec -T postgres pg_dump -U n8n n8n > "${TEMP_DIR}/database.sql"

echo -e "${YELLOW}[4/5] Backing up n8n data directory...${NC}"
docker compose cp n8n:/home/node/.n8n "${TEMP_DIR}/n8n-data"

echo -e "${YELLOW}[5/5] Creating archive...${NC}"
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C /tmp "${BACKUP_NAME}"

# Cleanup
rm -rf "${TEMP_DIR}"

# Get backup size
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)

echo -e "${GREEN}✓ Backup completed successfully!${NC}"
echo -e "${GREEN}  Location: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz${NC}"
echo -e "${GREEN}  Size: ${BACKUP_SIZE}${NC}"

# Keep only last 7 backups
echo -e "${YELLOW}Cleaning old backups (keeping last 7)...${NC}"
cd "${BACKUP_DIR}" && ls -t n8n-backup-*.tar.gz | tail -n +8 | xargs -r rm --

echo -e "${GREEN}Done!${NC}"
