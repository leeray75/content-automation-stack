# Issue #5: Extend Docker Compose Stack for Manifest-Centric Workflow

## Overview
This issue extends the Docker Compose stack to support the Manifest-centric automation workflow with optional local OpenProject and Penpot services for prototype/demo purposes. The implementation adds Docker Compose profiles to enable optional services while maintaining production-leaning best practices.

## Implementation Plan

### Phase 1: Analysis and Setup
- [x] Analyze GitHub issue requirements
- [x] Review existing docker-compose.yml structure
- [x] Review existing .env.example configuration
- [x] Create feature branch: `issue-5/manifest-centric-compose`
- [x] Create implementation planning document

### Phase 2: Docker Compose Extensions
- [ ] Add OpenProject profile services (openproject-db, openproject)
- [ ] Add Penpot profile services (penpot-db, penpot-redis, penpot-backend, penpot-frontend, penpot-exporter)
- [ ] Configure persistent volumes for data retention
- [ ] Add healthchecks for all new services
- [ ] Configure service dependencies and startup ordering
- [ ] Add environment variable wiring to core services

### Phase 3: Environment Configuration
- [ ] Extend .env.example with OpenProject configuration
- [ ] Extend .env.example with Penpot configuration
- [ ] Add image tag override variables for enterprise pinning
- [ ] Add demo-specific configuration flags

### Phase 4: Documentation Updates
- [ ] Add "Optional Local Integrations" section to README
- [ ] Document profile usage commands
- [ ] Document port mappings and service endpoints
- [ ] Document token setup and first-run procedures
- [ ] Add enterprise deployment guidance

### Phase 5: Testing and Validation
- [ ] Validate docker-compose.yml syntax
- [ ] Test core services only deployment
- [ ] Test OpenProject profile deployment
- [ ] Test Penpot profile deployment
- [ ] Test combined profiles deployment
- [ ] Verify healthcheck endpoints
- [ ] Test data persistence across restarts

## Technical Considerations

### Architecture Decisions
- **Profiles**: Use Docker Compose profiles to make OpenProject and Penpot optional
- **Images**: Default to latest upstream images for demo, provide env vars for pinning
- **Networking**: Use existing content-automation-network for service communication
- **Persistence**: Add named volumes for databases and application data
- **Healthchecks**: Implement comprehensive health monitoring for startup ordering

### Technology Choices
- **OpenProject**: openproject/openproject:latest with PostgreSQL 16
- **Penpot**: penpotapp/* images with PostgreSQL 16 and Redis 7
- **Database**: PostgreSQL 16 for both OpenProject and Penpot
- **Cache**: Redis 7 for Penpot session/cache storage

### Port Mappings
- OpenProject: 8082:8080 (host:container)
- Penpot Frontend: 9001:9001
- Penpot Backend: 6060:6060
- Penpot Exporter: 6061:6061
- Core services: maintain existing mappings (API 3000, UI 3001, MCP 3002)

### Volume Strategy
- `openproject_db_data`: PostgreSQL data for OpenProject
- `openproject_app_data`: OpenProject application assets
- `penpot_db_data`: PostgreSQL data for Penpot
- `penpot_assets`: Penpot application assets
- `manifest_data`: Core API manifest storage (if needed)

## Environment Variables

### Core Service Integration
```bash
# OpenProject Integration
OPENPROJECT_BASE_URL=http://openproject:8080
OPENPROJECT_API_TOKEN=

# Penpot Integration
PENPOT_FRONTEND_URL=http://penpot-frontend:9001
PENPOT_BACKEND_URL=http://penpot-backend:6060
PENPOT_EXPORTER_URL=http://penpot-exporter:6061
PENPOT_API_TOKEN=
```

### Image Tag Overrides
```bash
# Enterprise Version Pinning
OPENPROJECT_IMAGE_TAG=latest
PENPOT_BACKEND_IMAGE_TAG=latest
PENPOT_FRONTEND_IMAGE_TAG=latest
PENPOT_EXPORTER_IMAGE_TAG=latest
```

### Service Configuration
```bash
# Penpot Demo Configuration
PENPOT_PUBLIC_URI=http://localhost:9001
PENPOT_SECRET_KEY=change-me
PENPOT_ALLOW_REGISTRATION=true
PENPOT_PRELOAD_DEMO_DATA=false
```

## Success Criteria

### Core Functionality
- [ ] `docker compose up` starts core services (API, UI, MCP) successfully
- [ ] All core service healthchecks pass
- [ ] Data persists across container restarts

### OpenProject Integration
- [ ] `docker compose --profile openproject up` starts OpenProject stack
- [ ] OpenProject web interface accessible at http://localhost:8082
- [ ] OpenProject healthcheck passes: `/health_check`
- [ ] Core services can reach `OPENPROJECT_BASE_URL`
- [ ] Database data persists across restarts

### Penpot Integration
- [ ] `docker compose --profile penpot up` starts Penpot stack
- [ ] Penpot frontend accessible at http://localhost:9001
- [ ] Penpot backend API accessible at http://localhost:6060
- [ ] All Penpot healthchecks pass
- [ ] Core services can reach Penpot URLs
- [ ] Database and assets persist across restarts

### Combined Deployment
- [ ] `docker compose --profile openproject --profile penpot up` starts all services
- [ ] All healthchecks pass in correct dependency order
- [ ] No port conflicts or networking issues

### Documentation
- [ ] README includes clear usage instructions
- [ ] Environment setup documented
- [ ] Token generation procedures documented
- [ ] Enterprise deployment guidance provided

## Potential Challenges

### Service Dependencies
- Ensure proper startup ordering with healthcheck dependencies
- Handle database initialization timing
- Manage network connectivity between services

### Resource Requirements
- Multiple databases may require significant memory
- Consider resource limits for demo environments
- Document minimum system requirements

### Configuration Complexity
- Balance between demo simplicity and production readiness
- Provide clear guidance for token/secret management
- Ensure environment variable precedence is clear

## Future Enhancements (Out of Scope)

### Production Hardening
- Managed database services
- External object storage (S3-compatible)
- Secrets management integration
- TLS termination and ingress
- Centralized logging and monitoring
- Backup and restore procedures

### Enterprise Features
- Version pinning strategy
- Security scanning integration
- Multi-environment configuration
- CI/CD pipeline integration

## Testing Strategy

### Local Development Testing
1. **Syntax Validation**: `docker compose config`
2. **Core Services**: `docker compose up --detach`
3. **OpenProject**: `docker compose --profile openproject up --detach`
4. **Penpot**: `docker compose --profile penpot up --detach`
5. **Combined**: `docker compose --profile openproject --profile penpot up --detach`

### Health Verification
1. **Core Services**: Check existing health endpoints
2. **OpenProject**: `curl http://localhost:8082/health_check`
3. **Penpot Backend**: `curl http://localhost:6060/api/info`
4. **Penpot Frontend**: `curl http://localhost:9001/`
5. **Penpot Exporter**: `curl http://localhost:6061/`

### Data Persistence Testing
1. Start services with profiles
2. Create test data in each service
3. Stop and restart containers
4. Verify data persistence

## Implementation Timeline

### Phase 1: Setup (Completed)
- Branch creation and planning documentation

### Phase 2: Core Implementation (Next)
- Docker Compose service definitions
- Volume and network configuration
- Healthcheck implementation

### Phase 3: Configuration (Following)
- Environment variable setup
- Service integration wiring

### Phase 4: Documentation (Final)
- README updates
- Usage documentation
- Enterprise guidance

## Links and References
- GitHub Issue: [#5](https://github.com/leeray75/content-automation-stack/issues/5)
- OpenProject Documentation: https://docs.openproject.org/
- Penpot Documentation: https://help.penpot.app/
- Docker Compose Profiles: https://docs.docker.com/compose/profiles/
