# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- [issue-2](https://github.com/leeray75/content-automation-stack/issues/2) - Fixed MCP ingestion service crash due to missing pino-pretty dependency
- [issue-1](https://github.com/leeray75/content-automation-stack/issues/1) - Fixed Docker health checks and service startup issues
- Resolved API service health check failures by switching from curl-based to Node.js-based health checks
- Fixed long startup times by optimizing health check configuration and start periods
- Added curl package to API service Dockerfile for compatibility
- Resolved MCP ingestion service restart loop caused by logger configuration error
- Added pino-pretty dependency to production dependencies for proper logging functionality

## [1.0.0] - 2025-09-22
### Added
- [issue-1](https://github.com/leeray75/content-automation-stack/issues/1) - Docker Compose orchestration with git submodules and setup scripts
- Complete Docker Compose configuration for three services:
  - content-automation-api (API service)
  - content-automation-ui (Next.js frontend)
  - content-automation-mcp-ingestion (MCP ingestion service)
- Git submodules integration with relative paths:
  - services/content-automation-api
  - services/content-automation-ui
  - services/content-automation-mcp-ingestion
- Comprehensive automation scripts:
  - `scripts/setup.sh` - Initial setup and submodule management
  - `scripts/start.sh` - Start the stack with build and detach options
  - `scripts/stop.sh` - Stop the stack with cleanup options
  - `scripts/logs.sh` - View service logs with filtering and follow options
- Environment configuration:
  - `.env.example` with configurable ports and service variables
  - Support for development and production environments
- Service networking and dependencies:
  - Custom Docker network (content-automation-network)
  - Health checks for all services
  - Proper service startup dependencies
- Security features:
  - Non-root user execution in containers
  - Minimal Alpine Linux base images
  - CORS configuration for cross-origin requests
- Documentation:
  - Comprehensive README.md with usage instructions
  - Troubleshooting guide and best practices
  - Development workflow documentation
  - Production deployment guidelines
- Project structure following industry standards:
  - AI workspace for planning and completion reports
  - Proper .gitignore for Docker and development artifacts
  - Git submodules configuration with .gitmodules

### Technical Details
- Docker Compose version 3.8 with modern syntax
- Health checks with 30-second intervals and 10-second timeouts
- Volume mounts for development with node_modules optimization
- Environment variable injection for service configuration
- Graceful shutdown and container cleanup procedures
- Cross-platform compatibility (Linux, macOS, Windows)

### Service Configuration
- **API Service**: Port 3000, health check on /health endpoint
- **UI Service**: Port 3001, depends on API health, Next.js optimizations
- **MCP Service**: Port 3002, depends on API health, MCP protocol support

### Scripts Features
- **setup.sh**: Prerequisites checking, git repository initialization, submodule management
- **start.sh**: Build options, detached mode, service status reporting
- **stop.sh**: Volume and image cleanup options, confirmation prompts
- **logs.sh**: Service filtering, follow mode, tail options

### Documentation Coverage
- Quick start guide with step-by-step instructions
- Complete scripts reference with examples
- Configuration management and environment variables
- Development workflow and submodule management
- Troubleshooting common issues and debugging
- Production deployment and security considerations
- Performance optimization and monitoring guidelines
