Summary / goal
- Problem: OpenProject is enforcing 2FA at the application/plugin level even though the admin user has no OTP devices, causing a login loop.
- Goal: Restore admin web access safely (non‑destructive), then implement a repeatable, reversible fix to disable application‑level 2FA enforcement until you can reconfigure 2FA properly.

Safe plan (high level)
1. Back up the OpenProject database.
2. Temporarily disable application‑level 2FA enforcement (Setting.plugin_openproject_two_factor_authentication.enforced = false).
3. Kill existing sessions so the change takes effect immediately.
4. Verify you can log in via the web UI.
5. If desired, remove plugin settings (reversible) or create a small admin script in repo so future recoveries are easier.
6. Re-enable 2FA properly once you have email/OTP flows working and documented.

Commands you can run right now (non-destructive)
1) Create an on‑host DB backup (important)
- From the machine where you run docker compose:
  docker compose exec -T openproject-db pg_dump -U openproject openproject > openproject_backup_$(date +%Y%m%dT%H%M%S).sql

2) Check current plugin setting
  docker compose exec -T openproject bash -lc 'openproject run rails runner "p Setting.plugin_openproject_two_factor_authentication"'

3) Disable 2FA enforcement (recommended immediate fix)
- This sets the plugin config so 2FA is not enforced at app level:
  docker compose exec -T openproject bash -lc 'openproject run rails runner "Setting.plugin_openproject_two_factor_authentication = {\"enforced\" => false, \"allow_remember_for_days\" => 0}; puts \"2FA enforcement disabled\""' 

4) (Optional) Delete plugin settings entirely (reversible but more blunt)
- This removes any stored plugin config; the plugin may then use defaults or not run:
  docker compose exec -T openproject bash -lc 'openproject run rails runner "Setting.where(name: \"plugin_openproject_two_factor_authentication\").delete_all; puts \"2FA plugin settings deleted\""' 

5) Clear sessions so all users (including admin) get fresh auth state
  docker compose exec -T openproject bash -lc 'openproject run rails runner "ActiveRecord::Base.connection.execute(\"DELETE FROM sessions\") ; puts \"Sessions cleared\""' 

6) Verify setting after change
  docker compose exec -T openproject bash -lc 'openproject run rails runner "p Setting.plugin_openproject_two_factor_authentication"'

7) Try to log in via web UI (http://localhost:8082) as admin. If you changed the admin password previously use that password.

If the Rails-runner commands complain about missing constants/paths, try replacing openproject run rails runner with bin/rails runner in the container command (both variants shown here work for typical OpenProject images):
  docker compose exec -T openproject bash -lc 'bin/rails runner "puts Setting.plugin_openproject_two_factor_authentication"'

Verification checklist
- After step (3) or (4) and clearing sessions, web login should no longer redirect to /two_factor_authentication/request.
- The rails runner check should print something like {"enforced"=>false, ...} or nil (if deleted).
- If login succeeds, immediately update admin account settings (password, add backup codes, configure 2FA) and document steps.

Reverting / re-enabling 2FA later
- To re-enable enforcement:
  docker compose exec -T openproject bash -lc 'openproject run rails runner "Setting.plugin_openproject_two_factor_authentication = {\"enforced\" => true, \"allow_remember_for_days\" => 0}; puts \"2FA enforcement enabled\""' 
- Or restore the DB backup if you need to roll back changes (dangerous; will lose intervening changes).

Make the fix repeatable (script)
- I recommend adding a small maintenance script in your repo so you or teammates can run it quickly. Save this under ai-workspace/scripts/manage-openproject-2fa.sh and make executable.

```bash name=ai-workspace/scripts/manage-openproject-2fa.sh
#!/usr/bin/env bash
# Usage: manage-openproject-2fa.sh status|disable|enable|delete|clear-sessions
set -e
ACTION=${1:-status}

case "$ACTION" in
  status)
    docker compose exec -T openproject bash -lc 'openproject run rails runner "p Setting.plugin_openproject_two_factor_authentication"'
    ;;
  disable)
    echo "Disabling 2FA enforcement..."
    docker compose exec -T openproject bash -lc 'openproject run rails runner "Setting.plugin_openproject_two_factor_authentication = {\"enforced\" => false, \"allow_remember_for_days\" => 0}; puts \"2FA enforcement disabled\""' 
    ;;
  enable)
    echo "Enabling 2FA enforcement..."
    docker compose exec -T openproject bash -lc 'openproject run rails runner "Setting.plugin_openproject_two_factor_authentication = {\"enforced\" => true}; puts \"2FA enforcement enabled\""' 
    ;;
  delete)
    echo "Deleting 2FA plugin settings..."
    docker compose exec -T openproject bash -lc 'openproject run rails runner "Setting.where(name: \"plugin_openproject_two_factor_authentication\").delete_all; puts \"2FA plugin settings deleted\""' 
    ;;
  clear-sessions)
    echo "Clearing sessions..."
    docker compose exec -T openproject bash -lc 'openproject run rails runner "ActiveRecord::Base.connection.execute(\"DELETE FROM sessions\"); puts \"Sessions cleared\""' 
    ;;
  *)
    echo "Usage: $0 status|disable|enable|delete|clear-sessions"
    exit 2
    ;;
esac
```

Usage: make executable (chmod +x ai-workspace/scripts/manage-openproject-2fa.sh) and run:
- ./ai-workspace/scripts/manage-openproject-2fa.sh disable
- ./ai-workspace/scripts/manage-openproject-2fa.sh clear-sessions

Safety notes & recommended follow-ups
- Always back up the DB before modifying settings (pg_dump command above).
- These changes are reversible through the same commands or restoring the DB backup.
- After regaining access, properly configure 2FA:
  - Install/configure SMTP so verification flows work.
  - Re-enable 2FA enforcement only after users have registered/linked devices or backup codes are provisioned.
  - Document recovery steps for admin access (eg: a disabled-secondary-admin account or documented Rails console fixes).
- Audit logs: check OpenProject logs to confirm the setting change was applied and to verify no plugin errors remain.
  docker compose logs --tail=200 openproject

If you want, I can:
- Create the script file in your repository (open a PR). (Tell me to proceed and I’ll create a branch + PR.)
- Build an automated one‑click GH Actions maintenance job to run the disable/enable commands during emergency recovery.
- Craft an INSERT/UPDATE snippet to create a temporary admin bypass user if you’d rather create a second admin account.

Next immediate step for you
1. Run the DB backup command.
2. Run the disable command (or the script).
3. Clear sessions.
4. Try logging in.

If you run into any errors (copy/paste the exact output), generate an issue summary report.