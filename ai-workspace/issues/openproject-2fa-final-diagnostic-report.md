# OpenProject 2FA Login Issue - Final Comprehensive Diagnostic Report

**Date:** September 24, 2025  
**Time:** 1:42 AM EST  
**Issue:** Persistent 2FA enforcement preventing admin login despite comprehensive disable attempts  
**Status:** UNRESOLVED - Requires alternative approach  
**Severity:** CRITICAL - Admin access completely blocked  

## Executive Summary

Despite implementing multiple comprehensive approaches to disable OpenProject's Two-Factor Authentication (2FA) system, the issue persists. The 2FA system continues to intercept login attempts and redirect to `/two_factor_authentication/request`, creating an authentication loop that prevents admin access to the web interface.

## System Information

### Environment Details
- **OpenProject Image:** `openproject/openproject:16.4.1-slim`
- **Ruby Version:** 3.4.5 (2025-07-16 revision 20cda200d3) +PRISM [aarch64-linux]
- **Rails Version:** 8.0.2.1
- **Container Platform:** Docker Compose
- **Host OS:** macOS (ARM64)

### Current Configuration State

#### Environment Variables (Applied)
```bash
OPENPROJECT_2FA_ENFORCED=false
OPENPROJECT_2FA_DISABLED=true
OPENPROJECT_2FA_ACTIVE__STRATEGIES=[]
OPENPROJECT_EMERGENCY_DISABLE_2FA=true
```

#### Database Configuration
```ruby
OpenProject::Configuration["2fa"]: nil
Setting.plugin_openproject_two_factor_authentication: {
  "active_strategies" => [:totp, :webauthn], 
  "enforced" => false, 
  "allow_remember_for_days" => 0
}
```

#### TokenStrategyManager Status
```ruby
TokenStrategyManager.enforced?: false
TokenStrategyManager.enabled?: true  # ← PROBLEM: Still enabled
TokenStrategyManager.active_strategies: [
  OpenProject::TwoFactorAuthentication::TokenStrategy::Totp,
  OpenProject::TwoFactorAuthentication::TokenStrategy::Webauthn
]
```

#### Admin User Status
```ruby
Admin ID: 1
Admin status: active
Admin locked: false
Admin failed login count: 0
Admin OTP devices count: 0  # ← Correctly cleared
```

## Problem Analysis

### Root Cause Identification

1. **Environment Variables Not Effective**
   - Despite setting multiple 2FA-related environment variables, they are not being read or processed by OpenProject
   - `OpenProject::Configuration["2fa"]` remains `nil`, indicating environment variables are not being parsed

2. **Database Settings Ignored**
   - Plugin settings show `"enforced" => false` but `TokenStrategyManager.enabled?` still returns `true`
   - Active strategies remain populated despite attempts to clear them

3. **TokenStrategyManager Override Ineffective**
   - Runtime monkeypatching of TokenStrategyManager methods doesn't persist across web server processes
   - Emergency initializer not loading or not taking effect

4. **Deep Integration Issue**
   - 2FA system appears to be hardcoded into authentication middleware at multiple levels
   - Routes and controllers for 2FA remain active and intercept login flow

### Authentication Flow Analysis

**Current Broken Flow:**
```
1. POST /login (credentials valid) 
   ↓
2. 302 redirect to /two_factor_authentication/request
   ↓  
3. GET /two_factor_authentication/request
   ↓
4. 302 redirect to /login/two_factor_authentication/[token]
   ↓
5. GET /login/two_factor_authentication/[token] 
   ↓
6. 302 redirect to / (stage_success)
   ↓
7. GET / → 302 redirect to /login (authentication loop)
```

**Expected Flow:**
```
1. POST /login (credentials valid)
   ↓
2. 302 redirect to / (dashboard)
   ↓
3. User successfully logged in
```

### Active 2FA Routes (Still Present)
The system still has 22 active 2FA-related routes, including:
- `/two_factor_authentication/request` (intercepting login)
- `/two_factor_authentication/confirm`
- `/two_factor_authentication/backup_code`
- Multiple device registration and management routes

## Attempted Solutions

### ✅ Successfully Implemented (But Ineffective)

1. **Environment Variable Configuration**
   ```yaml
   environment:
     OPENPROJECT_2FA_ENFORCED: "false"
     OPENPROJECT_2FA_DISABLED: "true"
     OPENPROJECT_2FA_ACTIVE__STRATEGIES: "[]"
     OPENPROJECT_EMERGENCY_DISABLE_2FA: "true"
   ```

2. **Database-Level Changes**
   - Deleted all 2FA plugin settings: `Setting.where(name: 'plugin_openproject_two_factor_authentication').delete_all`
   - Cleared all user sessions multiple times
   - Verified admin user has 0 OTP devices

3. **Emergency Initializer Implementation**
   - Created comprehensive initializer at `config/initializers/emergency_disable_2fa.rb`
   - Attempted monkeypatching of TokenStrategyManager methods
   - Tried to unregister authentication stages
   - Deployed to container and restarted OpenProject

4. **Management Scripts**
   - Created `ai-workspace/scripts/manage-openproject-2fa.sh` for emergency recovery
   - Provided reversible commands for future troubleshooting

### ❌ Why Solutions Failed

1. **Environment Variables Not Parsed**
   - OpenProject 16.4.1-slim may not support these specific environment variable names
   - Configuration parsing may occur before our variables are available

2. **Database Settings Override**
   - Default plugin configuration appears to override database settings
   - Active strategies are loaded from plugin defaults, not database

3. **Initializer Loading Issues**
   - Emergency initializer may not be loading at the correct time in the Rails boot process
   - Monkeypatching may not persist across Puma worker processes

4. **Middleware Integration**
   - 2FA authentication appears to be integrated at the Rack middleware level
   - Routes and controllers remain active regardless of configuration

## Technical Deep Dive

### Critical Discovery: TokenStrategyManager Behavior

The key issue is that while `TokenStrategyManager.enforced?` returns `false`, `TokenStrategyManager.enabled?` still returns `true`. This suggests:

1. **Enforcement vs. Enablement**: These are separate concepts in OpenProject's 2FA system
2. **Active Strategies**: The presence of active strategies (TOTP, WebAuthn) keeps the system enabled
3. **Default Configuration**: Plugin defaults override environment and database settings

### Authentication Stage Analysis

```ruby
Authentication::Stage defined: true
# two_factor_authentication stage likely still registered
```

The authentication stage system is still active, meaning the 2FA stage is still part of the login flow.

### Log Evidence

Recent login attempt logs show the exact same pattern:
```
POST /login → 302 to /two_factor_authentication/request
GET /two_factor_authentication/request → 302 to /login/two_factor_authentication/[token]  
GET /login/two_factor_authentication/[token] → 302 to /
GET / → 302 to /login (loop)
```

## Recommended Solutions

### 🔧 Immediate Options (High Success Probability)

1. **Alternative OpenProject Version**
   ```yaml
   # Try older version without mandatory 2FA
   image: openproject/openproject:13.4.1-slim
   ```

2. **Fresh Installation Without 2FA Plugin**
   - Deploy new OpenProject instance
   - Exclude 2FA plugin from installation
   - Migrate data if needed

3. **Container Volume Mount Override**
   ```yaml
   volumes:
     - ./custom-config:/app/config/initializers/zzz_disable_2fa.rb
   ```

### 🛠 Advanced Options (Medium Success Probability)

4. **Direct Database Manipulation**
   ```sql
   -- Disable plugin at database level
   DELETE FROM settings WHERE name LIKE '%two_factor%';
   DELETE FROM settings WHERE name LIKE '%2fa%';
   ```

5. **Custom Docker Image**
   - Build custom OpenProject image
   - Remove 2FA plugin entirely
   - Patch authentication flow

6. **Nginx Proxy Bypass**
   - Route `/two_factor_authentication/*` to redirect to `/`
   - Intercept 2FA requests at proxy level

### 🔬 Debugging Options (For Investigation)

7. **Source Code Analysis**
   ```bash
   # Examine OpenProject source for 2FA integration points
   docker exec openproject find /app -name "*.rb" | xargs grep -l "two_factor"
   ```

8. **Middleware Stack Analysis**
   ```ruby
   # Examine Rails middleware stack
   Rails.application.middleware.each { |m| puts m }
   ```

## Current System State

### ✅ Working Components
- **Admin credentials**: Username `admin`, Password `DevAdmin24`
- **Database connectivity**: Full access via Rails console
- **Container health**: OpenProject running normally
- **Password authentication**: Validates correctly
- **User account status**: Active, unlocked, 0 failed attempts

### ❌ Broken Components  
- **Web interface login**: Blocked by 2FA loop
- **Environment variable parsing**: Not working
- **Database setting override**: Not effective
- **Emergency initializer**: Not loading or not effective

### 📁 Created Assets
- **Database backups**: `ai-workspace/backups/`
- **Emergency scripts**: `ai-workspace/scripts/manage-openproject-2fa.sh`
- **Diagnostic reports**: `ai-workspace/issues/`
- **Emergency initializer**: `config/initializers/emergency_disable_2fa.rb`

## Next Steps Recommendation

### Priority 1: Alternative Deployment
1. **Deploy OpenProject 13.x** (before mandatory 2FA)
2. **Test login functionality** 
3. **Migrate data if successful**

### Priority 2: Custom Solution
1. **Build custom Docker image** without 2FA plugin
2. **Patch authentication middleware**
3. **Deploy and test**

### Priority 3: Proxy Workaround
1. **Add Nginx reverse proxy**
2. **Redirect 2FA routes to dashboard**
3. **Test bypass effectiveness**

## Conclusion

The OpenProject 2FA system in version 16.4.1-slim appears to be deeply integrated and resistant to standard configuration-based disabling methods. The issue requires either:

1. **Version downgrade** to a release without mandatory 2FA
2. **Custom image build** with 2FA components removed
3. **Proxy-level workaround** to bypass 2FA routes

All implemented solutions remain in place and are reversible. The system is stable and ready for alternative approaches.

---

**Report Generated:** September 24, 2025, 1:42 AM EST  
**Analysis Duration:** 2+ hours  
**Methods Used:** Environment variables, database manipulation, runtime patching, middleware analysis  
**Outcome:** Issue persists, alternative approach required  
**Risk Level:** LOW - All changes are reversible, system stable  
**Data Safety:** HIGH - Database backups created, no data loss risk
