# Emergency: force TwoFactorAuthentication to be completely disabled at runtime.
# Deploy only for emergency recovery, then remove and restart.
if ENV['OPENPROJECT_EMERGENCY_DISABLE_2FA'] == 'true' || ENV['OPENPROJECT_2FA_DISABLED'] == 'true'
  Rails.logger.warn '[emergency_disable_2fa] initializer loaded - EMERGENCY MODE ACTIVE'

  Rails.application.config.after_initialize do
    begin
      # Best-effort: set environment/config value so TokenStrategyManager sees it
      OpenProject::Configuration['2fa'] ||= {}
      OpenProject::Configuration['2fa']['enforced'] = false
      OpenProject::Configuration['2fa']['disabled'] = true
      OpenProject::Configuration['2fa']['active_strategies'] = []
      Rails.logger.warn '[emergency_disable_2fa] OpenProject::Configuration["2fa"] adjusted'
    rescue => e
      Rails.logger.warn "[emergency_disable_2fa] failed to set configuration: #{e.class}: #{e.message}"
    end

    begin
      # Delete plugin settings from database
      Setting.where(name: 'plugin_openproject_two_factor_authentication').delete_all
      Rails.logger.warn '[emergency_disable_2fa] deleted 2FA plugin settings from database'
    rescue => e
      Rails.logger.warn "[emergency_disable_2fa] failed to delete plugin settings: #{e.class}: #{e.message}"
    end

    begin
      # Monkeypatch TokenStrategyManager.enforced? and enabled? to return false
      if defined?(OpenProject::TwoFactorAuthentication::TokenStrategyManager)
        mod = OpenProject::TwoFactorAuthentication::TokenStrategyManager
        mod.singleton_class.class_eval do
          define_method(:enforced?) { false }
          define_method(:enabled?) { false }
          define_method(:active_strategies) { [] }
        end
        Rails.logger.warn '[emergency_disable_2fa] monkeypatched TokenStrategyManager.enforced?/enabled?/active_strategies => false/false/[]'
      end
    rescue => e
      Rails.logger.warn "[emergency_disable_2fa] monkeypatch failed: #{e.class}: #{e.message}"
    end

    begin
      # Remove the two_factor_authentication stage from the Authentication::Stage registry if present
      if defined?(OpenProject::Authentication::Stage)
        begin
          if OpenProject::Authentication::Stage.respond_to?(:registered?) && 
             OpenProject::Authentication::Stage.registered?(:two_factor_authentication)
            OpenProject::Authentication::Stage.unregister(:two_factor_authentication)
            Rails.logger.warn '[emergency_disable_2fa] unregistered two_factor_authentication stage'
          end
        rescue => e
          Rails.logger.warn "[emergency_disable_2fa] unregister attempt failed: #{e.class}: #{e.message}"
        end
      end
    rescue => e
      Rails.logger.warn "[emergency_disable_2fa] stage removal failed: #{e.class}: #{e.message}"
    end

    # Clear all sessions to force fresh authentication state
    begin
      ActiveRecord::Base.connection.execute("DELETE FROM sessions")
      Rails.logger.warn '[emergency_disable_2fa] cleared all sessions'
    rescue => e
      Rails.logger.warn "[emergency_disable_2fa] failed to clear sessions: #{e.class}: #{e.message}"
    end

    Rails.logger.warn '[emergency_disable_2fa] EMERGENCY 2FA DISABLE COMPLETE'
  end
end
