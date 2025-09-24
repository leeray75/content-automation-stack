# Docker Configuration Analysis Report

## Issues Identified After Reviewing Official Documentation

### 1. OpenProject Configuration Issues

**Problem**: OpenProject is failing during database migration and restarting continuously.

**Root Causes Identified**:

1. **Missing Required Environment Variables**:
   - According to OpenProject docs, we need `OPENPROJECT_SECRET_KEY_BASE` with a proper random value
   - Current value "supersecretkey" is not secure and may cause issues

2. **Port Mapping Mismatch**:
   - OpenProject container runs on port 80 internally, but we're mapping to 8080
   - Our healthcheck is checking port 8080, but container serves on port 80
   - Official docs show: `docker run -p 8080:80` (external:internal)

3. **Missing Volume Mounts**:
   - Official docs require persistent storage for `/var/openproject/pgdata` and `/var/openproject/assets`
   - We only mount assets, missing pgdata volume

4. **Database Connection Issues**:
   - DATABASE_URL format may be incorrect
   - Missing database initialization steps

### 2. Penpot Configuration Issues

**Problem**: Penpot backend is starting but not responding properly.

**Root Causes Identified**:

1. **Missing Required Environment Variables**:
   - `PENPOT_FLAGS` may be needed for proper initialization
   - `PENPOT_TELEMETRY_ENABLED` should be set
   - `PENPOT_REGISTRATION_DOMAIN_WHITELIST` may be needed

2. **Port Configuration**:
   - Official Penpot runs on port 9001 for frontend
   - We're exposing backend on 6060 but may need different configuration

3. **Missing Services**:
   - Official Penpot setup includes exporter service
   - We have it but may need proper configuration

4. **Volume Configuration**:
   - Penpot needs persistent storage for assets
   - Our volume mapping may be incorrect

## Recommended Fixes

### OpenProject Fixes

1. **Fix Port Mapping**:
   ```yaml
   ports:
     - "8082:80"  # Map external 8082 to internal 80
   ```

2. **Add Required Environment Variables**:
   ```yaml
   environment:
     OPENPROJECT_SECRET_KEY_BASE: "generated-secure-random-key-here"
     OPENPROJECT_HOST__NAME: "localhost:8082"
     OPENPROJECT_HTTPS: "false"
     OPENPROJECT_DEFAULT__LANGUAGE: "en"
   ```

3. **Add Missing Volume**:
   ```yaml
   volumes:
     - openproject_pgdata:/var/openproject/pgdata
     - openproject_assets:/var/openproject/assets
   ```

4. **Fix Healthcheck**:
   ```yaml
   healthcheck:
     test: ["CMD-SHELL", "curl -fsS http://localhost:80/ || exit 1"]
   ```

### Penpot Fixes

1. **Add Missing Environment Variables**:
   ```yaml
   environment:
     PENPOT_FLAGS: "enable-registration enable-login-with-password"
     PENPOT_TELEMETRY_ENABLED: "false"
     PENPOT_PUBLIC_URI: "http://localhost:9001"
   ```

2. **Fix Service Dependencies**:
   - Ensure proper startup order
   - Add proper health checks

3. **Volume Configuration**:
   ```yaml
   volumes:
     - penpot_assets:/opt/data/assets
   ```

## Implementation Priority

1. **High Priority**: Fix OpenProject port mapping and environment variables
2. **High Priority**: Add missing OpenProject volumes
3. **Medium Priority**: Fix Penpot environment variables
4. **Low Priority**: Optimize health checks and startup times

## Testing Strategy

1. Fix OpenProject configuration first
2. Test OpenProject startup and accessibility
3. Fix Penpot configuration
4. Test Penpot startup and accessibility
5. Verify integration between services
