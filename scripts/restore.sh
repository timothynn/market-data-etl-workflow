#!/bin/bash

# n8n Restore Script
# Restores n8n from a backup archive

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if backup file is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide backup file${NC}"
    echo "Usage: $0 <backup-file.tar.gz>"
    exit 1
fi

BACKUP_FILE="$1"
TEMP_DIR="/tmp/n8n-restore-$(date +%s)"

# Check if backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
    echo -e "${RED}Error: Backup file not found: ${BACKUP_FILE}${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  WARNING: This will overwrite current n8n data!${NC}"
echo -e "${YELLOW}Press Ctrl+C to cancel, or Enter to continue...${NC}"
read

echo -e "${GREEN}Starting restore from: ${BACKUP_FILE}${NC}"

# Create temp directory
mkdir -p "${TEMP_DIR}"

echo -e "${YELLOW}[1/6] Extracting backup archive...${NC}"
tar -xzf "${BACKUP_FILE}" -C "${TEMP_DIR}"

# Find extracted directory
EXTRACTED_DIR=$(find "${TEMP_DIR}" -maxdepth 1 -type d -name "n8n-backup-*" | head -n 1)

if [ -z "${EXTRACTED_DIR}" ]; then
    echo -e "${RED}Error: Could not find backup data in archive${NC}"
    exit 1
fi

echo -e "${YELLOW}[2/6] Stopping n8n...${NC}"
docker compose down

echo -e "${YELLOW}[3/6] Restoring PostgreSQL database...${NC}"
docker compose up -d postgres
sleep 5
docker compose exec -T postgres dropdb -U n8n n8n --if-exists
docker compose exec -T postgres createdb -U n8n n8n
docker compose exec -T postgres psql -U n8n n8n < "${EXTRACTED_DIR}/database.sql"

echo -e "${YELLOW}[4/6] Restoring n8n data...${NC}"
docker compose up -d n8n
sleep 10

if [ -f "${EXTRACTED_DIR}/workflows.json" ]; then
    echo -e "${YELLOW}[5/6] Importing workflows...${NC}"
    docker compose cp "${EXTRACTED_DIR}/workflows.json" n8n:/tmp/workflows.json
    docker compose exec -T n8n n8n import:workflow --input=/tmp/workflows.json
else
    echo -e "${YELLOW}[5/6] No workflows to restore${NC}"
fi

if [ -f "${EXTRACTED_DIR}/credentials.json" ]; then
    echo -e "${YELLOW}[6/6] Importing credentials...${NC}"
    docker compose cp "${EXTRACTED_DIR}/credentials.json" n8n:/tmp/credentials.json
    docker compose exec -T n8n n8n import:credentials --input=/tmp/credentials.json
else
    echo -e "${YELLOW}[6/6] No credentials to restore${NC}"
fi

# Cleanup
rm -rf "${TEMP_DIR}"

echo -e "${YELLOW}Restarting services...${NC}"
docker compose restart

echo -e "${GREEN}✓ Restore completed successfully!${NC}"
echo -e "${GREEN}  n8n is now running with restored data${NC}"
echo -e "${GREEN}  Access: http://localhost:5678${NC}"
