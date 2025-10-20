# n8n Workflow Starter - Makefile
# Convenient commands for common operations

.PHONY: help setup start stop restart logs backup restore clean status health

# Default target
help:
	@echo "n8n Workflow Starter - Available Commands"
	@echo "=========================================="
	@echo "setup          - Initial project setup"
	@echo "start          - Start all services"
	@echo "stop           - Stop all services"
	@echo "restart        - Restart all services"
	@echo "logs           - View logs (all services)"
	@echo "logs-n8n       - View n8n logs only"
	@echo "logs-db        - View database logs only"
	@echo "backup         - Create backup"
	@echo "restore        - Restore from latest backup"
	@echo "export         - Export all workflows"
	@echo "clean          - Remove all containers and volumes"
	@echo "status         - Show service status"
	@echo "health         - Check service health"
	@echo "shell-n8n      - Open shell in n8n container"
	@echo "shell-db       - Open psql shell"
	@echo "update         - Update to latest n8n version"

# Initial setup
setup:
	@echo "Setting up n8n Workflow Starter..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✓ Created .env file"; \
		echo "⚠️  Please edit .env and change default passwords!"; \
	else \
		echo "✓ .env already exists"; \
	fi
	@mkdir -p workflows/custom workflows/export credentials logs backups
	@chmod +x scripts/*.sh
	@echo "✓ Setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Edit .env and change passwords"
	@echo "  2. Run 'make start' to start services"

# Start services
start:
	@echo "Starting n8n services..."
	@docker compose up -d
	@echo "✓ Services started!"
	@echo "  Access n8n at: http://localhost:5678"
	@echo "  Access PgAdmin at: http://localhost:5050"

# Stop services
stop:
	@echo "Stopping n8n services..."
	@docker compose down
	@echo "✓ Services stopped"

# Restart services
restart:
	@echo "Restarting n8n services..."
	@docker compose restart
	@echo "✓ Services restarted"

# View logs (all services)
logs:
	@docker compose logs -f

# View n8n logs only
logs-n8n:
	@docker compose logs -f n8n

# View database logs only
logs-db:
	@docker compose logs -f postgres

# Create backup
backup:
	@echo "Creating backup..."
	@./scripts/backup.sh

# Restore from backup (requires BACKUP_FILE variable)
restore:
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "Error: Please specify BACKUP_FILE"; \
		echo "Usage: make restore BACKUP_FILE=backups/n8n-backup-YYYYMMDD_HHMMSS.tar.gz"; \
		exit 1; \
	fi
	@./scripts/restore.sh $(BACKUP_FILE)

# Export workflows
export:
	@echo "Exporting workflows..."
	@./scripts/export-workflows.sh

# Clean everything (WARNING: removes all data!)
clean:
	@echo "⚠️  WARNING: This will remove all containers, volumes, and data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		echo "✓ Cleanup complete"; \
	else \
		echo "Cancelled"; \
	fi

# Show service status
status:
	@docker compose ps

# Check service health
health:
	@echo "Checking service health..."
	@echo ""
	@echo "n8n:"
	@curl -s http://localhost:5678/healthz && echo "  ✓ Healthy" || echo "  ✗ Unhealthy"
	@echo ""
	@echo "PostgreSQL:"
	@docker compose exec -T postgres pg_isready -U n8n && echo "  ✓ Ready" || echo "  ✗ Not ready"

# Open shell in n8n container
shell-n8n:
	@docker compose exec n8n sh

# Open PostgreSQL shell
shell-db:
	@docker compose exec postgres psql -U n8n -d n8n

# Update to latest n8n version
update:
	@echo "Updating to latest n8n version..."
	@docker compose pull
	@docker compose up -d
	@echo "✓ Updated to latest version"
	@docker compose exec n8n n8n --version
