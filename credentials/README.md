# Credentials Directory

This directory stores encrypted n8n credentials. 

## ⚠️ Important Security Information

### Never Commit Credentials!

The `.gitignore` is configured to prevent committing credential files, but always double-check:

```bash
# Verify nothing is tracked
git status credentials/
```

### Credential Files

n8n stores credentials as encrypted JSON files with names like:
- `credentials-1.json`
- `credentials-2.json`
- etc.

**These files are encrypted by n8n** but should still never be committed to version control.

## 🔐 Best Practices

### 1. Use Environment Variables

For production, use environment variables instead of storing credentials in n8n:

```yaml
# In docker-compose.yml
environment:
  - SMTP_USER=${SMTP_USER}
  - SMTP_PASSWORD=${SMTP_PASSWORD}
  - API_KEY=${API_KEY}
```

### 2. Backup Credentials Securely

When backing up:
```bash
# Encrypt backup
tar -czf credentials.tar.gz credentials/
gpg -c credentials.tar.gz
rm credentials.tar.gz

# Store encrypted file safely
mv credentials.tar.gz.gpg /secure/location/
```

### 3. Rotate Credentials Regularly

- Change passwords every 90 days
- Revoke unused API keys
- Audit access regularly

### 4. Use Separate Credentials per Environment

- Development: `dev-` prefix
- Staging: `staging-` prefix  
- Production: `prod-` prefix

## 📝 Credential Types in n8n

Common credentials you might configure:

### Email (SMTP)
- Gmail
- SendGrid
- Amazon SES
- Custom SMTP

### Databases
- PostgreSQL
- MySQL
- MongoDB
- Redis

### APIs
- Slack
- Discord
- Telegram
- Twitter/X
- GitHub
- OpenAI
- Stripe

### Cloud Services
- AWS (S3, Lambda, etc.)
- Azure
- Google Cloud
- DigitalOcean

### CRM/Marketing
- HubSpot
- Salesforce
- Mailchimp
- ActiveCampaign

## 🔄 Migrating Credentials

### Export from old instance
```bash
docker compose exec n8n n8n export:credentials --all --output=/tmp/creds.json
```

### Import to new instance
```bash
docker compose exec n8n n8n import:credentials --input=/tmp/creds.json
```

## 🆘 Troubleshooting

### Credentials not loading

1. Check file permissions:
   ```bash
   ls -la credentials/
   # Should be owned by user 1000:1000
   ```

2. Verify encryption key is consistent:
   ```bash
   # Check .env file
   grep ENCRYPTION_KEY .env
   ```

3. Check n8n logs:
   ```bash
   docker compose logs n8n | grep -i credential
   ```

### Lost encryption key

⚠️ **If you lose the encryption key, credentials cannot be recovered!**

Always backup:
- `.env` file with `N8N_ENCRYPTION_KEY`
- Credential export files
- Store securely (password manager, vault)

## 📖 Resources

- [n8n Credentials Documentation](https://docs.n8n.io/credentials/)
- [Security Best Practices](https://docs.n8n.io/hosting/security/)
- [Credential Types](https://docs.n8n.io/integrations/credentials/)
