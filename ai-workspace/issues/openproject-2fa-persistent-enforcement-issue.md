# OpenProject 2FA Persistent Enforcement Issue - Detailed Analysis Report

**Date**: September 24, 2025  
**Issue**: OpenProject continues to enforce 2FA despite multiple disable attempts  
**Status**: UNRESOLVED - Requires further investigation  
**Impact**: Admin login redirects to 2FA setup page, preventing normal authentication  

## 🔍 ISSUE SUMMARY

OpenProject container continues to enforce Two-Factor Authentication (2FA) for the admin user despite:
- Setting `OPENPROJECT_2FA_ENFORCED: "false"` in docker-compose.yml
- Removing 2FA plugin settings from the database
- Clearing all sessions and OTP devices
- Restarting the container with new environment variables

The login flow consistently redirects to `/two_factor_authentication/request` instead of completing authentication.

## 🏗️ ENVIRONMENT DETAILS

### Container Configuration
- **OpenProject Version**: 16.4.1-slim
- **Container Name**: `openproject`
- **Database**: PostgreSQL 16.10
- **Network**: content-automation-network
- **Port Mapping**: 8082:8080

### Current Environment Variables
```yaml
environment:
  OPENPROJECT_HTTPS: "false"
  OPENPROJECT_2FA_ENFORCED: "false"  # ← Added to disable 2FA
  OPENPROJECT_HOST__NAME: localhost:8082
  OPENPROJECT_SECRET_KEY_BASE: ${OPENPROJECT_SECRET_KEY_BASE}
  OPENPROJECT_DEFAULT__LANGUAGE: "en"
  DATABASE_URL: postgresql://openproject:openproject@openproject-db:5432/openproject
```

### Admin User Credentials
- **Username**: `admin`
- **Password**: `DevAdmin24` (successfully reset)
- **Login URL**: http://localhost:8082

## 🔄 ATTEMPTED SOLUTIONS

### 1. Environment Variable Configuration ✅
**Action**: Added `OPENPROJECT_2FA_ENFORCED: "false"` to docker-compose.yml  
**Result**: Environment variable correctly set in container  
**Verification**:
```bash
$ docker compose exec -T openproject bash -lc 'env | grep -i 2fa'
OPENPROJECT_2FA_ENFORCED=false
```

### 2. Container Restart ✅
**Action**: Full stop/start of OpenProject container  
**Commands**:
```bash
cd content-automation-platform/content-automation-stack
docker compose down
docker compose --profile openproject up -d
```
**Result**: Container restarted successfully with new environment variables

### 3. Database Plugin Setting Removal ✅
**Action**: Removed 2FA plugin configuration from OpenProject database  
**Rails Commands**:
```ruby
# Completely remove the plugin setting
Setting.where(name: "plugin_openproject_two_factor_authentication").delete_all

# Verify removal
Setting.plugin_openproject_two_factor_authentication.inspect
# Returns: {"active_strategies" => [:totp, :webauthn], "enforced" => false, "allow_remember_for_days" => 0}
```

### 4. User-Level 2FA Device Cleanup ✅
**Action**: Removed all OTP devices from admin user  
**Rails Commands**:
```ruby
admin_user = User.find_by(login: "admin")
admin_user.otp_devices.destroy_all
admin_user.otp_devices.count  # Returns: 0
```

### 5. Session Clearing ✅
**Action**: Cleared all active sessions to force fresh authentication  
**Rails Command**:
```ruby
ActiveRecord::Base.connection.execute("DELETE FROM sessions")
```

### 6. Comprehensive 2FA Disable Script ✅
**Action**: Executed aggressive 2FA removal script  
**Rails Script**:
```ruby
# Method 1: Completely remove the plugin setting
Setting.where(name: "plugin_openproject_two_factor_authentication").delete_all

# Method 2: Clear all sessions again
ActiveRecord::Base.connection.execute("DELETE FROM sessions")

# Method 3: Verify admin user has no 2FA devices
admin_user = User.find_by(login: "admin")
admin_user.otp_devices.destroy_all if admin_user

# Method 4: Check for any other 2FA-related settings
two_fa_settings = Setting.where("name LIKE ?", "%two_factor%")
# Found: 0 2FA-related settings
```

## 📊 LOG ANALYSIS

### Persistent 2FA Redirect Pattern
Despite all disable attempts, the login flow shows consistent 2FA enforcement:

```
# Latest login attempt logs (2025-09-24T04:45:51)
I, [2025-09-24T04:45:51.577937 #47]  INFO -- : [38406f5c-a21e-4fb9-9762-6a892f5b12ae] 
method=POST path=/login format=html controller=AccountController action=login 
status=302 allocations=4609 duration=204.69 view=0.00 db=4.15 
location=http://localhost:8082/two_factor_authentication/request user=1

I, [2025-09-24T04:45:51.606004 #47]  INFO -- : [1fe601e3-f046-4a19-8bb9-31a630c19081] 
method=GET path=/two_factor_authentication/request format=html 
controller=TwoFactorAuthentication::AuthenticationController action=request_otp 
status=302 allocations=3330 duration=8.07 view=0.00 db=1.04 
location=http://localhost:8082/login/two_factor_authentication/674bac5095a6216868906e28d8a523f9 user=1

I, [2025-09-24T04:45:51.623976 #47]  INFO -- : [66899f86-fc5d-46de-8b08-f9ed1d3f85a0] 
method=GET path=/login/two_factor_authentication/674bac5095a6216868906e28d8a523f9 
format=html controller=AccountController action=stage_success 
status=302 allocations=4815 duration=14.51 view=0.00 db=2.15 
location=http://localhost:8082/ user=1

I, [2025-09-24T04:45:51.631421 #47]  INFO -- : [539626cc-623a-4388-b51b-b398658ad8f8] 
method=GET path=/ format=html controller=HomescreenController action=index 
status=302 allocations=2240 duration=3.40 view=0.00 db=0.86 
location=http://localhost:8082/login user=1
```

### Flow Analysis
1. **POST /login** → 302 redirect to `/two_factor_authentication/request`
2. **GET /two_factor_authentication/request** → 302 redirect to `/login/two_factor_authentication/{token}`
3. **GET /login/two_factor_authentication/{token}** → 302 redirect to `/`
4. **GET /** → 302 redirect back to `/login`
5. **Loop continues** - user never successfully authenticates

## 🔍 CURRENT STATUS VERIFICATION

### Environment Variable Status ✅
```bash
$ docker compose exec -T openproject bash -lc 'env | grep -i 2fa'
OPENPROJECT_2FA_ENFORCED=false
```

### Database Plugin Status ✅
```ruby
Setting.plugin_openproject_two_factor_authentication.inspect
# Returns: {"active_strategies" => [:totp, :webauthn], "enforced" => false, "allow_remember_for_days" => 0}
```

### User OTP Devices Status ✅
```ruby
User.find_by(login: "admin").otp_devices.count
# Returns: 0
```

### Container Health ✅
```bash
$ docker compose ps openproject
NAME         IMAGE                              COMMAND                  SERVICE      CREATED          STATUS                    PORTS
openproject  openproject/openproject:16.4.1-slim  "./docker/prod/entrypoint"  openproject  About an hour ago  Up About an hour (healthy)  0.0.0.0:8082->8080/tcp
```

## 🚨 ROOT CAUSE HYPOTHESIS

Based on the persistent behavior despite comprehensive disable attempts, the issue likely stems from one of these factors:

### 1. **User-Level 2FA Enforcement Flag**
The admin user may have individual 2FA requirements stored in user attributes that override global settings.

**Investigation needed**:
```ruby
admin_user = User.find_by(login: "admin")
admin_user.attributes.select { |k, v| k.include?("two_factor") || k.include?("2fa") || k.include?("otp") }
```

### 2. **OpenProject Version-Specific Behavior**
OpenProject 16.4.1-slim may have different 2FA handling compared to other versions, potentially ignoring the `OPENPROJECT_2FA_ENFORCED` environment variable.

### 3. **Alternative Environment Variable Names**
The correct environment variable might be different:
- `OPENPROJECT_TWO_FACTOR_AUTHENTICATION_ENFORCED`
- `OPENPROJECT_2FA_REQUIRED`
- `OPENPROJECT_FORCE_2FA`

### 4. **Database Migration State**
The 2FA plugin may have created database migrations that enforce 2FA at the schema level, requiring manual database intervention.

### 5. **Configuration File Override**
OpenProject may be reading 2FA configuration from a file that overrides environment variables.

## 🔧 RECOMMENDED NEXT STEPS

### Immediate Actions
1. **Investigate user-level 2FA flags**:
   ```ruby
   admin_user = User.find_by(login: "admin")
   admin_user.update_column(:force_password_change, false)
   # Check for any 2FA-related user attributes
   ```

2. **Try alternative environment variable names**:
   ```yaml
   environment:
     OPENPROJECT_2FA_ENFORCED: "false"
     OPENPROJECT_TWO_FACTOR_AUTHENTICATION_ENFORCED: "false"
     OPENPROJECT_2FA_REQUIRED: "false"
   ```

3. **Create new admin user as workaround**:
   ```ruby
   new_admin = User.create!(
     login: "admin2",
     firstname: "Admin",
     lastname: "User",
     mail: "admin2@example.com",
     admin: true,
     status: User::STATUSES[:active]
   )
   new_admin.update!(password: "DevAdmin24", password_confirmation: "DevAdmin24")
   ```

### Long-term Solutions
1. **OpenProject Version Upgrade/Downgrade**: Test with different OpenProject versions
2. **Custom Docker Image**: Build custom image with 2FA plugin completely removed
3. **Database Schema Investigation**: Examine 2FA-related database tables and constraints
4. **OpenProject Community Support**: Consult OpenProject forums/documentation for version-specific 2FA behavior

## 📋 IMPACT ASSESSMENT

### Current Functionality
- ✅ **Container Health**: OpenProject running normally
- ✅ **Database Connectivity**: PostgreSQL connection working
- ✅ **Password Authentication**: Admin password correctly set to `DevAdmin24`
- ❌ **Web Login**: Blocked by 2FA enforcement loop

### Workaround Options
1. **API Access**: May still work if 2FA only affects web interface
2. **Database Direct Access**: Admin tasks can be performed via Rails console
3. **New User Creation**: Create additional admin user without 2FA history

## 📚 REFERENCES

### OpenProject Documentation
- [OpenProject 2FA Configuration](https://www.openproject.org/docs/system-admin-guide/authentication/two-factor-authentication/)
- [OpenProject Environment Variables](https://www.openproject.org/docs/installation-and-operations/configuration/environment/)

### Related Files
- `docker-compose.yml` - Container configuration with 2FA environment variable
- `.env` - Environment variables (password updated)
- `docs/openproject-admin-credentials.md` - Credential documentation

### Previous Reports
- `openproject-2fa-login-issue-diagnostic-report.md` - Initial 2FA investigation

---

**Report Generated**: September 24, 2025, 12:48 AM  
**Next Review**: Pending additional investigation steps  
**Priority**: Medium (workarounds available, but web login blocked)
