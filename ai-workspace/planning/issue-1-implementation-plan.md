# Issue #1: Implement Docker Compose orchestration with git submodules and setup scripts

## Overview
Implement a robust Docker Compose orchestration for the Content Automation API, UI, and MCP ingestion services, following latest industry standards and best practices. Use git submodules for service integration, add automation scripts, and ensure maintainability and ease of setup for developers.

## Implementation Plan

### Phase 1: Project Structure Setup
- [ ] Create basic project structure with ai-workspace directories
- [ ] Initialize git repository if needed
- [ ] Create .gitignore file for Docker and development artifacts

### Phase 2: Git Submodules Integration
- [ ] Add content-automation-api as git submodule
- [ ] Add content-automation-ui as git submodule  
- [ ] Add content-automation-mcp-ingestion as git submodule
- [ ] Configure .gitmodules with relative paths

### Phase 3: Docker Compose Configuration
- [ ] Create docker-compose.yml with all three services
- [ ] Configure service networking and dependencies
- [ ] Set up volume mounts and environment variables
- [ ] Create .env.example with configurable ports and variables

### Phase 4: Automation Scripts
- [ ] Create setup.sh script for initialization
- [ ] Create start.sh script for bringing up the stack
- [ ] Create stop.sh script for bringing down the stack
- [ ] Create logs.sh script for viewing service logs
- [ ] Make all scripts executable

### Phase 5: Documentation
- [ ] Create comprehensive README.md
- [ ] Document prerequisites and installation steps
- [ ] Add usage instructions and troubleshooting
- [ ] Include contribution guidelines for submodule updates

## Technical Considerations
- Use Docker Compose v2 syntax (docker compose vs docker-compose)
- Implement proper service dependencies and health checks
- Configure inter-service communication via Docker networks
- Follow security best practices for container configuration
- Ensure cross-platform compatibility (Linux, macOS, Windows)

## Success Criteria
- All three submodules are added and referenced with relative paths
- The stack can be setup by running the provided scripts
- Developers can build, run, stop, and view logs for all services easily
- Documentation is clear and follows industry standards
- The stack works with the latest stable Docker Compose

## File Structure
```
content-automation-stack/
├── ai-workspace/
│   ├── planning/
│   │   └── issue-1-implementation-plan.md
│   └── completion-reports/
├── services/
│   ├── content-automation-api/          (submodule)
│   ├── content-automation-ui/           (submodule)
│   └── content-automation-mcp-ingestion/ (submodule)
├── scripts/
│   ├── setup.sh
│   ├── start.sh
│   ├── stop.sh
│   └── logs.sh
├── docker-compose.yml
├── .env.example
├── .gitignore
├── .gitmodules
└── README.md
