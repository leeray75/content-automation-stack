# Issue #10: OpenProject Environment Reset and 2FA Removal Implementation Plan

## Overview
Implement a robust, scriptable process to reset the OpenProject environment (container, DB, assets) for the `openproject` profile in Docker Compose, ensuring that all 2FA enforcement is cleared and the system starts with default settings and with 2FA disabled.

## Issue Analysis

### Current State
- OpenProject is configured with multiple 2FA-related environment variables in docker-compose.yml:
  - `OPENPROJECT_2FA_ENFORCED: "false"`
  - `OPENPROJECT_2FA_DISABLED: "true"`
  - `OPENPROJECT_2FA_ACTIVE__STRATEGIES: "[]"`
  - `OPENPROJECT_EMERGENCY_DISABLE_2FA: "true"`
- Named volumes: `openproject_db_data` and `openproject_assets`
- Current image: `openproject/openproject:16.4.1-slim`
- Database: PostgreSQL 16.10 with required extensions

### Problem Statement
Previous attempts to disable 2FA enforcement via environment variables or DB settings have failed. A destructive reset is the most reliable way to ensure a clean OpenProject instance with no 2FA enforcement or data dependencies.

## Implementation Plan

### Phase 1: Create Reset Script
**File**: `ai-workspace/scripts/reset-openproject.sh`

**Core Functions**:
1. **Environment Validation**
   - Check if Docker and Docker Compose are available
   - Verify we're in the correct directory
   - Source environment variables from `.env`

2. **Cleanup Operations**
   - Stop all OpenProject-related containers (`openproject`, `openproject-db`, `openproject-db-init`)
   - Remove containers with `--force` flag
   - Remove named volumes (`openproject_db_data`, `openproject_assets`)
   - Clean up any orphaned containers

3. **Image Management**
   - Pull latest (or specified) OpenProject image
   - Option to specify alternative image tag (e.g., 13.4.1-slim for fallback)

4. **Startup Sequence**
   - Start database container and wait for health check
   - Run DB initialization container and wait for completion
   - Start OpenProject container
   - Monitor startup logs with timeout

5. **Verification Steps**
   - Check container health status
   - Verify environment variables are present in running container
   - Optional: Test basic connectivity to OpenProject
   - Optional: Run Rails runner commands to verify 2FA settings

### Phase 2: Documentation
**Updates to**:
- Script header with comprehensive usage documentation
- README.md section explaining the reset process
- Warning about data destruction

### Phase 3: Optional Enhancements
- Backup functionality before reset
- Image tag override option
- Compose override file for testing older images

## Technical Specifications

### Script Requirements
- **Language**: Bash
- **Location**: `ai-workspace/scripts/reset-openproject.sh`
- **Permissions**: Executable (`chmod +x`)
- **Dependencies**: Docker, Docker Compose, curl (for health checks)

### Key Features
- **Idempotent**: Safe to re-run multiple times
- **Verbose**: Clear logging of each step
- **Error Handling**: Proper exit codes and error messages
- **Configurable**: Support for different image tags
- **Safe**: Confirmation prompts for destructive operations

### Environment Variables Used
- `OPENPROJECT_IMAGE_TAG` (from .env, default: 16.4.1-slim)
- All existing OpenProject environment variables from docker-compose.yml

### Docker Compose Profile
- Uses `--profile openproject` to target only OpenProject services
- Preserves other services (API, UI, MCP, Penpot)

## Implementation Steps

### Step 1: Create the Reset Script
```bash
#!/bin/bash
# OpenProject Environment Reset Script
# Destroys all OpenProject data and starts fresh with 2FA disabled
```

### Step 2: Implement Core Functions
- `check_prerequisites()`
- `confirm_reset()`
- `cleanup_containers()`
- `cleanup_volumes()`
- `pull_image()`
- `start_services()`
- `verify_startup()`
- `check_2fa_status()`

### Step 3: Add Logging and Error Handling
- Colored output for better readability
- Progress indicators
- Comprehensive error messages
- Exit codes for automation

### Step 4: Testing
- Test with current image (16.4.1-slim)
- Test with fallback image (13.4.1-slim)
- Verify 2FA is actually disabled
- Test idempotency

## Success Criteria

### Primary Goals
- ✅ Script successfully removes all OpenProject containers and volumes
- ✅ Fresh OpenProject instance starts with no 2FA enforcement
- ✅ Admin login works without 2FA prompts
- ✅ Script is idempotent and safe to re-run

### Secondary Goals
- ✅ Clear documentation and usage instructions
- ✅ Support for alternative image tags
- ✅ Comprehensive logging and error handling
- ✅ Integration with existing Docker Compose setup

### Verification Tests
1. Run script on existing OpenProject installation
2. Verify all containers and volumes are removed
3. Confirm fresh startup completes successfully
4. Test admin login at http://localhost:8082
5. Verify no 2FA prompts appear
6. Check environment variables in running container
7. Test script re-run (idempotency)

## Risk Mitigation

### Data Loss Prevention
- Clear warnings about data destruction
- Confirmation prompts before destructive operations
- Optional backup functionality

### Rollback Strategy
- Document how to restore from backups
- Provide alternative image tags for testing
- Keep existing docker-compose.yml unchanged

### Error Recovery
- Detailed error messages with suggested fixes
- Graceful handling of partial failures
- Manual cleanup instructions if script fails

## Timeline
- **Phase 1**: Script implementation (30-45 minutes)
- **Phase 2**: Documentation (15 minutes)
- **Phase 3**: Testing and refinement (15-30 minutes)
- **Total**: 1-1.5 hours

## Dependencies
- Docker and Docker Compose installed
- Existing docker-compose.yml configuration
- `.env` file with OpenProject settings
- Network connectivity for image pulls

## Notes
- This is a destructive operation that will remove all OpenProject data
- The script targets only OpenProject services, leaving other stack components intact
- Environment variables for 2FA disabling are already configured in docker-compose.yml
- Fallback to older OpenProject images may be necessary if 2FA issues persist
