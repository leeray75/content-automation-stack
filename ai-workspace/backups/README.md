# OpenProject Database Backups

This directory contains database backups for the OpenProject instance.

## Backup Files

Database backups are automatically named with timestamps:
- Format: `openproject_backup_YYYYMMDDTHHMMSS.sql`
- Example: `openproject_backup_20250924T050000.sql`

## Creating Backups

### Manual Backup
```bash
# Using the management script
./ai-workspace/scripts/manage-openproject-2fa.sh backup-db

# Direct command
docker compose exec -T openproject-db pg_dump -U openproject openproject > ai-workspace/backups/openproject_backup_$(date +%Y%m%dT%H%M%S).sql
```

### Emergency Backup
The `emergency-disable` command automatically creates a backup before making changes:
```bash
./ai-workspace/scripts/manage-openproject-2fa.sh emergency-disable
```

## Restoring Backups

⚠️ **WARNING: Restoring a backup will overwrite all current data!**

### Stop OpenProject
```bash
docker compose stop openproject
```

### Restore Database
```bash
# Replace BACKUP_FILE with your actual backup filename
docker compose exec -T openproject-db psql -U openproject -d openproject < ai-workspace/backups/BACKUP_FILE.sql
```

### Restart OpenProject
```bash
docker compose start openproject
```

## Backup Retention

- Keep at least 3 recent backups
- Archive older backups to external storage
- Test restore procedures periodically

## Emergency Recovery

If you're locked out of OpenProject due to 2FA issues:

1. **Create backup first:**
   ```bash
   ./ai-workspace/scripts/manage-openproject-2fa.sh backup-db
   ```

2. **Emergency disable 2FA:**
   ```bash
   ./ai-workspace/scripts/manage-openproject-2fa.sh emergency-disable
   ```

3. **Try logging in** at http://localhost:8082
   - Username: `admin`
   - Password: `DevAdmin24`

## Backup Storage Locations

- **Local:** `ai-workspace/backups/` (this directory)
- **External:** Consider backing up to cloud storage or external drives
- **Git:** Backup files are excluded from git (see .gitignore)

## Security Notes

- Backup files contain sensitive data
- Store backups securely
- Encrypt backups for external storage
- Limit access to backup files

## Troubleshooting

### Backup Creation Fails
- Check Docker containers are running
- Verify database connectivity
- Check disk space

### Restore Fails
- Verify backup file integrity
- Check PostgreSQL version compatibility
- Ensure database is accessible

## Related Files

- `../scripts/manage-openproject-2fa.sh` - Management script
- `../../docker-compose.yml` - Container configuration
- `../../docs/openproject-admin-credentials.md` - Admin credentials
