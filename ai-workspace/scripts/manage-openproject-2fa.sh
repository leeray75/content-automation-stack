#!/usr/bin/env bash
# OpenProject 2FA Management Script
# Usage: manage-openproject-2fa.sh status|disable|enable|delete|clear-sessions|backup-db
set -e

ACTION=${1:-status}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKUP_DIR="$PROJECT_ROOT/ai-workspace/backups"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Change to project root for docker compose commands
cd "$PROJECT_ROOT"

case "$ACTION" in
  status)
    echo "=== OpenProject 2FA Status ==="
    echo "Checking current 2FA configuration..."
    docker compose exec -T openproject bash -lc 'bin/rails runner "
      puts \"Environment variable: #{ENV[\"OPENPROJECT_2FA_ENFORCED\"]}\"
      puts \"Plugin setting: #{Setting.plugin_openproject_two_factor_authentication.inspect}\"
      admin_user = User.find_by(login: \"admin\")
      puts \"Admin OTP devices: #{admin_user&.otp_devices&.count || 0}\"
      puts \"Admin has backup codes: #{admin_user&.otp_backup_codes&.present? || false}\"
    "'
    ;;
  disable)
    echo "=== Disabling 2FA enforcement ==="
    docker compose exec -T openproject bash -lc 'bin/rails runner "
      Setting.plugin_openproject_two_factor_authentication = {\"enforced\" => false, \"allow_remember_for_days\" => 0}
      puts \"✅ 2FA enforcement disabled\"
    "'
    ;;
  enable)
    echo "=== Enabling 2FA enforcement ==="
    docker compose exec -T openproject bash -lc 'bin/rails runner "
      Setting.plugin_openproject_two_factor_authentication = {\"enforced\" => true, \"allow_remember_for_days\" => 0}
      puts \"✅ 2FA enforcement enabled\"
    "'
    ;;
  delete)
    echo "=== Deleting 2FA plugin settings ==="
    docker compose exec -T openproject bash -lc 'bin/rails runner "
      Setting.where(name: \"plugin_openproject_two_factor_authentication\").delete_all
      puts \"✅ 2FA plugin settings deleted\"
    "'
    ;;
  clear-sessions)
    echo "=== Clearing all sessions ==="
    docker compose exec -T openproject bash -lc 'bin/rails runner "
      ActiveRecord::Base.connection.execute(\"DELETE FROM sessions\")
      puts \"✅ All sessions cleared\"
    "'
    ;;
  backup-db)
    echo "=== Creating database backup ==="
    BACKUP_FILE="$BACKUP_DIR/openproject_backup_$(date +%Y%m%dT%H%M%S).sql"
    docker compose exec -T openproject-db pg_dump -U openproject openproject > "$BACKUP_FILE"
    echo "✅ Database backup created: $BACKUP_FILE"
    ;;
  reset-admin)
    echo "=== Resetting admin user 2FA ==="
    docker compose exec -T openproject bash -lc 'bin/rails runner "
      admin_user = User.find_by(login: \"admin\")
      if admin_user
        admin_user.otp_devices.destroy_all
        admin_user.otp_backup_codes = []
        admin_user.save!(validate: false)
        puts \"✅ Admin user 2FA reset - devices: #{admin_user.otp_devices.count}, backup codes: #{admin_user.otp_backup_codes.present?}\"
      else
        puts \"❌ Admin user not found\"
      end
    "'
    ;;
  emergency-disable)
    echo "=== EMERGENCY: Complete 2FA disable ==="
    echo "1. Creating database backup..."
    BACKUP_FILE="$BACKUP_DIR/emergency_backup_$(date +%Y%m%dT%H%M%S).sql"
    docker compose exec -T openproject-db pg_dump -U openproject openproject > "$BACKUP_FILE"
    echo "✅ Backup created: $BACKUP_FILE"
    
    echo "2. Deleting plugin settings..."
    docker compose exec -T openproject bash -lc 'bin/rails runner "
      Setting.where(name: \"plugin_openproject_two_factor_authentication\").delete_all
      puts \"✅ Plugin settings deleted\"
    "'
    
    echo "3. Clearing admin 2FA..."
    docker compose exec -T openproject bash -lc 'bin/rails runner "
      admin_user = User.find_by(login: \"admin\")
      if admin_user
        admin_user.otp_devices.destroy_all
        admin_user.otp_backup_codes = []
        admin_user.save!(validate: false)
        puts \"✅ Admin 2FA cleared\"
      end
    "'
    
    echo "4. Clearing all sessions..."
    docker compose exec -T openproject bash -lc 'bin/rails runner "
      ActiveRecord::Base.connection.execute(\"DELETE FROM sessions\")
      puts \"✅ Sessions cleared\"
    "'
    
    echo "✅ Emergency 2FA disable complete. Try logging in now."
    ;;
  *)
    echo "Usage: $0 status|disable|enable|delete|clear-sessions|backup-db|reset-admin|emergency-disable"
    echo ""
    echo "Commands:"
    echo "  status           - Show current 2FA configuration"
    echo "  disable          - Disable 2FA enforcement (recommended)"
    echo "  enable           - Enable 2FA enforcement"
    echo "  delete           - Delete 2FA plugin settings completely"
    echo "  clear-sessions   - Clear all user sessions"
    echo "  backup-db        - Create database backup"
    echo "  reset-admin      - Reset admin user 2FA devices and codes"
    echo "  emergency-disable - Complete 2FA disable (backup + delete + clear)"
    echo ""
    echo "Examples:"
    echo "  $0 emergency-disable  # Complete recovery from 2FA lockout"
    echo "  $0 disable && $0 clear-sessions  # Standard disable sequence"
    echo "  $0 backup-db  # Create backup before changes"
    exit 2
    ;;
esac
