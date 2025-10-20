#!/bin/bash

# n8n Workflow Export Script
# Exports all workflows as individual JSON files

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

EXPORT_DIR="./workflows/export"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo -e "${GREEN}Exporting n8n workflows...${NC}"

# Create export directory
mkdir -p "${EXPORT_DIR}"

# Check if n8n is running
if ! docker compose ps n8n | grep -q "Up"; then
    echo -e "${YELLOW}Starting n8n...${NC}"
    docker compose up -d n8n
    sleep 10
fi

# Export all workflows
echo -e "${YELLOW}Fetching workflows...${NC}"
docker compose exec -T n8n n8n export:workflow --all --output=/tmp/all-workflows.json

# Copy to host
docker compose cp n8n:/tmp/all-workflows.json "${EXPORT_DIR}/all-workflows-${TIMESTAMP}.json"

echo -e "${GREEN}✓ Workflows exported!${NC}"
echo -e "${GREEN}  Location: ${EXPORT_DIR}/all-workflows-${TIMESTAMP}.json${NC}"

# List workflows
WORKFLOW_COUNT=$(docker compose exec -T n8n n8n list:workflow | wc -l)
echo -e "${GREEN}  Total workflows: ${WORKFLOW_COUNT}${NC}"
