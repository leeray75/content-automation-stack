Short answer
- I inspected the OpenProject source and confirmed where 2FA enforcement is decided and loaded: modules/two_factor_authentication/lib/... (engine.rb, token_strategy_manager.rb, two_factor_settings_controller.rb). The plugin checks environment/configuration first and then falls back to DB settings. The simplest, supported fix is to set the documented environment switch to disable 2FA (OPENPROJECT_2FA_DISABLED=true) or to set OPENPROJECT_2FA_ENFORCED=false and restart. If that doesn't take effect (because configuration is cached or the plugin is loaded earlier), you can apply a reversible emergency initializer that forces the TokenStrategyManager to treat 2FA as not enforced.

What I found in the code (key locations)
- modules/two_factor_authentication/lib/open_project/two_factor_authentication/engine.rb
  - Registers the authentication stage conditionally: active: -> { ::OpenProject::TwoFactorAuthentication::TokenStrategyManager.enabled? } and runs TokenStrategyManager.validate_configuration! in config.to_prepare. This is where the 2FA stage is wired into the authentication flow.
- modules/two_factor_authentication/lib/open_project/two_factor_authentication/token_strategy_manager.rb
  - This module exposes methods like enabled?, enforced?, enforced_by_configuration?, configurable_by_ui? and reads the OpenProject::Configuration["2fa"] (which is populated from environment alias OPENPROJECT_2FA). The code therefore honors env/config before DB.
- modules/two_factor_authentication/app/controllers/two_factor_authentication/two_factor_settings_controller.rb
  - Handles writes to plugin settings (and checks Setting.plugin_openproject_two_factor_authentication_writable?).
- docs show the supported env variables:
  - OPENPROJECT_2FA_ENFORCED, OPENPROJECT_2FA_ACTIVE__STRATEGIES, and OPENPROJECT_2FA_DISABLED (docs explicitly note OPENPROJECT_2FA_DISABLED="true" will disable 2FA and remove menus).

Diagnosis checklist (run these first — no code changes)
1. Check effective configuration in Rails console:
   - docker compose exec openproject bash -lc 'openproject run rails console --sandbox -e production'
     Then run:
     - p OpenProject::Configuration["2fa"]                 # environment/config values
     - p Setting.plugin_openproject_two_factor_authentication # DB-stored plugin settings
     - p OpenProject::TwoFactorAuthentication::TokenStrategyManager.enforced?
     - p OpenProject::TwoFactorAuthentication::TokenStrategyManager.enabled?
     - p OpenProject::TwoFactorAuthentication::TokenStrategyManager.configurable_by_ui?

   If OpenProject::Configuration["2fa"] shows enforced=true or OPENPROJECT_2FA_DISABLED is not set, the environment is still telling the plugin to enforce 2FA. If TokenStrategyManager.enforced? returns true despite DB showing enforced: false, the environment/config path is taking precedence.

2. Ensure environment variables are set correctly in your runtime (docker-compose / container env):
   - Preferred to fully disable 2FA quickly:
     - OPENPROJECT_2FA_DISABLED=true
   - Alternatively to allow 2FA but not enforce:
     - OPENPROJECT_2FA_ENFORCED=false
   - After changing compose/env, restart the openproject service:
     - docker compose restart openproject

Supported, recommended fixes (ordered)
1) Easiest — set the documented environment flag to disable 2FA (safe & reversible)
- Edit your docker-compose or container env and add:
  - OPENPROJECT_2FA_DISABLED=true
- Restart:
  - docker compose restart openproject
- Verify via rails runner or logs:
  - docker compose exec openproject bash -lc 'openproject run rails runner "p OpenProject::Configuration['\"'2fa'\"'] ; p ::OpenProject::TwoFactorAuthentication::TokenStrategyManager.enabled?"'

2) If you cannot change environment variables or they don't take effect (config cached/loaded differently), set OPENPROJECT_2FA_ACTIVE__STRATEGIES to empty to remove active strategies:
- OPENPROJECT_2FA_ACTIVE__STRATEGIES="[]"
- Restart service.

3) If env changes and restarts do not remove the 2FA stage (rare), use a reversible emergency initializer to force the plugin to treat enforcement as false at runtime. This is intended as an emergency recovery step and should be removed immediately after you regain access.

Proposed emergency initializer (add to your app, remove after recovery)
```ruby name=config/initializers/emergency_disable_2fa.rb
# Emergency: force TwoFactorAuthentication to be non-enforced at runtime.
# Deploy only for emergency recovery, then remove and restart.
if ENV['OPENPROJECT_EMERGENCY_DISABLE_2FA'] == 'true' || ENV['OPENPROJECT_2FA_DISABLED'] == 'true'
  Rails.logger.warn '[emergency_disable_2fa] initializer loaded'

  Rails.application.config.after_initialize do
    begin
      # Best-effort: set environment/config value so TokenStrategyManager sees it
      OpenProject::Configuration['2fa'] ||= {}
      OpenProject::Configuration['2fa']['enforced'] = false
      OpenProject::Configuration['2fa']['disabled'] = true
      Rails.logger.warn '[emergency_disable_2fa] OpenProject::Configuration[\"2fa\"] adjusted'
    rescue => e
      Rails.logger.warn "[emergency_disable_2fa] failed to set configuration: #{e.class}: #{e.message}"
    end

    begin
      # Monkeypatch TokenStrategyManager.enforced? and enabled? to return false
      if defined?(OpenProject::TwoFactorAuthentication::TokenStrategyManager)
        mod = OpenProject::TwoFactorAuthentication::TokenStrategyManager
        mod.singleton_class.class_eval do
          define_method(:enforced?) { false }
          define_method(:enabled?) { false }
        end
        Rails.logger.warn '[emergency_disable_2fa] monkeypatched TokenStrategyManager.enforced?/enabled? => false'
      end
    rescue => e
      Rails.logger.warn "[emergency_disable_2fa] monkeypatch failed: #{e.class}: #{e.message}"
    end

    begin
      # Remove the two_factor_authentication stage from the Authentication::Stage registry if present
      if defined?(OpenProject::Authentication::Stage)
        begin
          OpenProject::Authentication::Stage.unregister(:two_factor_authentication) if OpenProject::Authentication::Stage.registered?(:two_factor_authentication) rescue nil
          Rails.logger.warn '[emergency_disable_2fa] attempted to unregister two_factor_authentication stage'
        rescue => e
          Rails.logger.warn "[emergency_disable_2fa] unregister attempt failed: #{e.class}: #{e.message}"
        end
      end
    rescue => e
      Rails.logger.warn "[emergency_disable_2fa] stage removal failed: #{e.class}: #{e.message}"
    end
  end
end
```

Commands to deploy the initializer via Docker Compose (example)
- Copy the file into the container app (or add to your source and redeploy). Quick approach using a here-doc into the container:
  - docker compose exec openproject bash -lc "mkdir -p /app/config/initializers && cat > /app/config/initializers/emergency_disable_2fa.rb <<'RB'\n[paste file contents here]\nRB"
- Set the emergency environment variable:
  - Add to your compose service (openproject): environment: - OPENPROJECT_EMERGENCY_DISABLE_2FA=true
- Restart:
  - docker compose restart openproject
- Tail logs to confirm initializer ran:
  - docker compose logs -f --tail=200 openproject

Emergency alternative: create an emergency admin user (if UI still blocked)
- docker compose exec openproject bash -lc 'openproject run rails runner "u = User.find_by(login: '\''emergency_admin'\'') || User.create!(login: '\''emergency_admin'\'', firstname: '\''Emergency'\'', lastname: '\''Admin'\'', mail: '\''emergency@localhost'\'', password: '\''EmergencyAdmin24'\'', password_confirmation: '\''EmergencyAdmin24'\'', admin: true, status: User.statuses[:active]); u.otp_devices.destroy_all if u.respond_to?(:otp_devices); u.save!(validate:false); puts u.inspect"'

Post-recovery tasks (must do)
- Remove the emergency initializer and emergency admin account.
- Configure SMTP and user enrollment; re-enable 2FA via environment or UI only after user devices/backup codes are available.
- Audit logs to ensure no unauthorized access during emergency period.

Why this solves the issue
- The module TokenStrategyManager reads environment/config first. The docs explicitly support OPENPROJECT_2FA_DISABLED and OPENPROJECT_2FA_ENFORCED. Setting OPENPROJECT_2FA_DISABLED=true is the supported, simplest way to stop 2FA from being considered — this removes the 2FA authentication stage at boot. If configuration is cached or loaded earlier than where you can write the DB setting, the emergency initializer forces the TokenStrategyManager to report enabled?/enforced? as false so the authentication stage will not be activated — this is reversible and limited in scope.

If you want, I can:
- Produce a small pull request (initializer + README) for your repository to add this emergency initializer and helper script, or
- Give the exact one-liner commands for your environment to set the env var in docker-compose and restart if you paste your docker-compose snippet for the openproject service.

If anything fails when you try these steps, paste:
- output of: docker compose exec openproject bash -lc 'openproject run rails runner "p OpenProject::Configuration['\"'2fa'\"']; p Setting.plugin_openproject_two_factor_authentication; p ::OpenProject::TwoFactorAuthentication::TokenStrategyManager.enforced?; p ::OpenProject::TwoFactorAuthentication::TokenStrategyManager.enabled?"'
- the last ~300 lines of logs: docker compose logs --tail=300 openproject

I’ll read them and give the exact minimal change tailored to the code paths in your build.