# n8n Workflow Starter

A production-ready n8n (open source) workflow automation project with Docker, PostgreSQL, and pre-built workflow templates.

![n8n](https://img.shields.io/badge/n8n-workflow%20automation-FF6D5A?style=for-the-badge&logo=n8n)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)

## 📋 Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Workflow Examples](#workflow-examples)
- [Configuration](#configuration)
- [Production Deployment](#production-deployment)
- [Backup & Restore](#backup--restore)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## ✨ Features

- 🐳 **Docker Compose setup** - One-command deployment
- 🗄️ **PostgreSQL database** - Production-ready persistence
- 🔐 **Basic authentication** - Secure by default
- 📊 **Health checks** - Container monitoring
- 🔄 **Auto-restart** - High availability
- 📝 **Execution logging** - Full audit trail
- 🎯 **Example workflows** - Ready-to-use templates
- 🛡️ **Security best practices** - Credentials management
- 📦 **Volume persistence** - Data safety
- 🌍 **Timezone support** - Configurable locale

## 🔧 Prerequisites

### For NixOS:

```nix
# Add to /etc/nixos/configuration.nix
virtualisation.docker.enable = true;
users.users.YOUR_USERNAME.extraGroups = [ "docker" ];
```

Then rebuild:
```bash
sudo nixos-rebuild switch
sudo systemctl start docker
```

### For other systems:
- Docker Engine 20.10+
- Docker Compose 2.0+
- 2GB RAM minimum
- 10GB disk space

## 🚀 Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/n8n-workflow-starter.git
cd n8n-workflow-starter
```

### 2. Configure environment

```bash
cp .env.example .env
nano .env  # Edit credentials
```

**Important**: Change the default password in `.env`:
```bash
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_secure_password_here
```

### 3. Start n8n

```bash
docker compose up -d
```

### 4. Access n8n

Open your browser to: **http://localhost:5678**

Default credentials (change these!):
- Username: `admin`
- Password: `changeme123`

## 📁 Project Structure

```
n8n-workflow-starter/
├── .github/                    # GitHub workflows & templates
│   └── workflows/
│       └── docker-build.yml   # CI/CD pipeline
├── workflows/                  # n8n workflow files
│   ├── examples/              # Pre-built workflow templates
│   │   ├── webhook-to-database.json
│   │   ├── scheduled-data-sync.json
│   │   ├── email-notification.json
│   │   └── api-integration.json
│   └── custom/                # Your custom workflows
├── credentials/               # Encrypted credentials storage
│   ├── .gitignore
│   └── README.md
├── scripts/                   # Utility scripts
│   ├── backup.sh             # Backup workflows & DB
│   ├── restore.sh            # Restore from backup
│   └── export-workflows.sh   # Export workflows as JSON
├── config/                    # Configuration files
│   ├── .env.example          # Environment template
│   └── n8n-config.json       # n8n settings
├── docs/                      # Documentation
│   ├── getting-started.md
│   ├── workflow-examples.md
│   ├── deployment.md
│   └── troubleshooting.md
├── logs/                      # Application logs
├── docker-compose.yml         # Docker orchestration
├── .gitignore
├── README.md
├── LICENSE
└── CONTRIBUTING.md
```

## 🎯 Workflow Examples

### 1. Webhook to Database
Receives webhook data and stores it in PostgreSQL.

**Use case**: Form submissions, API callbacks, event tracking

### 2. Scheduled Data Sync
Runs on a schedule to sync data between systems.

**Use case**: Daily reports, data backups, API polling

### 3. Email Notifications
Monitors conditions and sends email alerts.

**Use case**: Error alerts, status updates, reports

### 4. API Integration
Connects multiple APIs to automate workflows.

**Use case**: CRM updates, Slack notifications, data enrichment

## ⚙️ Configuration

### Environment Variables

Edit `.env` to customize:

```bash
# Authentication
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=strong_password

# Host settings
N8N_HOST=localhost
N8N_PORT=5678
WEBHOOK_URL=http://localhost:5678/

# Database
POSTGRES_USER=n8n
POSTGRES_PASSWORD=secure_db_password
POSTGRES_DB=n8n

# Timezone
TIMEZONE=Africa/Nairobi
```

### Advanced Configuration

For production deployments, see [docs/deployment.md](docs/deployment.md)

## 🌐 Production Deployment

### 1. Enable HTTPS

Update `.env`:
```bash
N8N_PROTOCOL=https
N8N_HOST=workflows.yourdomain.com
WEBHOOK_URL=https://workflows.yourdomain.com/
```

### 2. Add SSL certificates

```bash
# Using Let's Encrypt
docker run -it --rm \
  -v /etc/letsencrypt:/etc/letsencrypt \
  certbot/certbot certonly --standalone \
  -d workflows.yourdomain.com
```

### 3. Use strong passwords

```bash
# Generate secure password
openssl rand -base64 32
```

### 4. Enable Redis queue (optional)

Uncomment Redis service in `docker-compose.yml` and add to `.env`:
```bash
EXECUTIONS_MODE=queue
QUEUE_BULL_REDIS_HOST=redis
```

## 💾 Backup & Restore

### Create Backup

```bash
./scripts/backup.sh
```

Creates timestamped backup in `backups/` directory.

### Restore from Backup

```bash
./scripts/restore.sh backups/n8n-backup-2025-10-20.tar.gz
```

### Export Workflows

```bash
./scripts/export-workflows.sh
```

Exports all workflows to `workflows/export/` as JSON files.

## 🔍 Monitoring

### View logs

```bash
# All services
docker compose logs -f

# n8n only
docker compose logs -f n8n

# Last 100 lines
docker compose logs --tail=100 n8n
```

### Check health

```bash
docker compose ps
```

### Database access

```bash
docker compose exec postgres psql -U n8n -d n8n
```

## 🐛 Troubleshooting

### n8n won't start

```bash
# Check logs
docker compose logs n8n

# Restart services
docker compose restart

# Full rebuild
docker compose down -v
docker compose up -d --build
```

### Database connection errors

```bash
# Verify PostgreSQL is running
docker compose ps postgres

# Check database logs
docker compose logs postgres

# Reset database
docker compose down -v
docker volume rm n8n-workflow-starter_postgres_data
docker compose up -d
```

### Port already in use

```bash
# Find process using port 5678
sudo lsof -i :5678

# Kill process
sudo kill -9 <PID>

# Or change port in .env
N8N_PORT=5679
```

### Reset credentials

```bash
# Stop n8n
docker compose down

# Remove credential files
rm -rf credentials/*.json

# Restart
docker compose up -d
```

## 📚 Documentation

- [n8n Official Docs](https://docs.n8n.io/)
- [Workflow Examples](docs/workflow-examples.md)
- [Deployment Guide](docs/deployment.md)
- [API Reference](https://docs.n8n.io/api/)

## 🤝 Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-workflow`)
3. Commit your changes (`git commit -m 'Add amazing workflow'`)
4. Push to the branch (`git push origin feature/amazing-workflow`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [n8n.io](https://n8n.io/) - Amazing workflow automation tool
- [Docker](https://www.docker.com/) - Container platform
- Community contributors

## 📧 Support

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/n8n-workflow-starter/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/n8n-workflow-starter/discussions)
- **n8n Community**: [community.n8n.io](https://community.n8n.io/)

---

Made with ❤️ for workflow automation enthusiasts
