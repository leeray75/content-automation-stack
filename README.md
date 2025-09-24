# Content Automation Stack

A robust Docker Compose orchestration for the Content Automation Platform, providing seamless integration of API, UI, and MCP ingestion services.

## Overview

This repository provides a complete Docker Compose stack that orchestrates three core services:

- **Content Automation API** - RESTful API for content management
- **Content Automation UI** - Next.js frontend application
- **Content Automation MCP Ingestion** - Model Context Protocol ingestion service

## Prerequisites

Before getting started, ensure you have the following installed:

- **Docker** (v20.10 or later) - [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose V2** (recommended) - [Install Docker Compose](https://docs.docker.com/compose/install/)
- **Git** (v2.13 or later) - [Install Git](https://git-scm.com/downloads)

### System Requirements

- **Memory**: 4GB RAM minimum, 8GB recommended
- **Storage**: 10GB free space for images and containers
- **Network**: Internet connection for initial setup and image pulls

## Quick Start

1. **Clone and setup the repository:**
   ```bash
   git clone <repository-url>
   cd content-automation-stack
   ./scripts/setup.sh
   ```

2. **Start the stack:**
   ```bash
   ./scripts/start.sh --build --detach
   ```

3. **Access the services:**
   - API: http://localhost:3000
   - UI: http://localhost:3001
   - MCP Ingestion: http://localhost:3002

4. **View logs:**
   ```bash
   ./scripts/logs.sh --follow
   ```

5. **Stop the stack:**
   ```bash
   ./scripts/stop.sh
   ```

## Optional Local Integrations

The stack supports optional local integrations for enhanced development and demo workflows. These services are enabled via Docker Compose profiles and provide local instances of project management and design tools.

### Available Integrations

#### OpenProject (Project Management)
- **Profile**: `openproject`
- **Services**: Project management, task tracking, time tracking
- **Access**: http://localhost:8082
- **Database**: PostgreSQL (persistent)

#### Penpot (Design & Prototyping)
- **Profile**: `penpot`
- **Services**: Design tool, prototyping, collaboration
- **Frontend**: http://localhost:9001
- **Backend API**: http://localhost:6060
- **Exporter**: http://localhost:6061
- **Database**: PostgreSQL (persistent)
- **Cache**: Redis

### Usage Commands

#### Core Services Only (Default)
```bash
# Start only API, UI, and MCP services
docker compose up
./scripts/start.sh
```

#### With OpenProject
```bash
# Start core services + OpenProject
docker compose --profile openproject up
./scripts/start.sh --profile openproject

# Build and start with OpenProject
docker compose --profile openproject up --build
./scripts/start.sh --profile openproject --build
```

#### With Penpot
```bash
# Start core services + Penpot
docker compose --profile penpot up
./scripts/start.sh --profile penpot

# Build and start with Penpot
docker compose --profile penpot up --build
./scripts/start.sh --profile penpot --build
```

#### With Both Integrations
```bash
# Start all services
docker compose --profile openproject --profile penpot up
./scripts/start.sh --profile openproject --profile penpot

# Build and start all services
docker compose --profile openproject --profile penpot up --build
./scripts/start.sh --profile openproject --profile penpot --build
```

### Service Endpoints

| Service | URL | Purpose |
|---------|-----|---------|
| **Core Services** | | |
| API | http://localhost:3000 | Content automation API |
| UI | http://localhost:3001 | Web interface |
| MCP Ingestion | http://localhost:3002 | MCP protocol service |
| **OpenProject** | | |
| Web Interface | http://localhost:8082 | Project management |
| Health Check | http://localhost:8082/health_check | Service status |
| **Penpot** | | |
| Frontend | http://localhost:9001 | Design interface |
| Backend API | http://localhost:6060 | API services |
| API Info | http://localhost:6060/api/info | Service information |
| Exporter | http://localhost:6061 | Export services |

### First-Run Setup

#### OpenProject Setup
1. **Start OpenProject:**
   ```bash
   docker compose --profile openproject up -d
   ```

2. **Access the web interface:** http://localhost:8082

3. **Initial login:**
   - Username: `admin`
   - Password: `admin`
   - Change password on first login

4. **Generate API token:**
   - Go to Account Settings → Access tokens
   - Create new token with required permissions
   - Copy token to `.env` file:
     ```env
     OPENPROJECT_API_TOKEN=your_generated_token_here
     ```

5. **Restart core services** to pick up the new token:
   ```bash
   docker compose restart content-automation-api content-automation-ui content-automation-mcp-ingestion
   ```

#### Penpot Setup
1. **Start Penpot:**
   ```bash
   docker compose --profile penpot up -d
   ```

2. **Access the frontend:** http://localhost:9001

3. **Registration options:**
   - **Demo mode**: Registration enabled by default (`PENPOT_ALLOW_REGISTRATION=true`)
   - **Demo data**: Optionally enable with `PENPOT_PRELOAD_DEMO_DATA=true`

4. **Create account:**
   - Register new account via web interface
   - Or use demo data if enabled

5. **API access:**
   - Generate API token through Penpot interface
   - Add to `.env` file:
     ```env
     PENPOT_API_TOKEN=your_penpot_token_here
     ```

### Environment Configuration

#### Required Variables
Copy and customize these variables in your `.env` file:

```env
# OpenProject Integration
OPENPROJECT_BASE_URL=http://openproject:8080
OPENPROJECT_API_TOKEN=your_openproject_token

# Penpot Integration
PENPOT_FRONTEND_URL=http://penpot-frontend:9001
PENPOT_BACKEND_URL=http://penpot-backend:6060
PENPOT_EXPORTER_URL=http://penpot-exporter:6061
PENPOT_API_TOKEN=your_penpot_token

# Penpot Configuration
PENPOT_PUBLIC_URI=http://localhost:9001
PENPOT_SECRET_KEY=change-me-in-production
PENPOT_ALLOW_REGISTRATION=true
PENPOT_PRELOAD_DEMO_DATA=false
```

#### Enterprise Deployment
For production/enterprise deployments, pin specific image versions:

```env
# Pin specific versions instead of 'latest'
OPENPROJECT_IMAGE_TAG=13.0.0
PENPOT_BACKEND_IMAGE_TAG=1.19.0
PENPOT_FRONTEND_IMAGE_TAG=1.19.0
PENPOT_EXPORTER_IMAGE_TAG=1.19.0
```

### Data Persistence

All optional services use persistent volumes:

- **OpenProject**: Database and application data persist across restarts
- **Penpot**: Database, assets, and Redis data persist across restarts

#### Volume Management
```bash
# List all volumes
docker volume ls

# Inspect specific volumes
docker volume inspect content-automation-stack_openproject_db_data
docker volume inspect content-automation-stack_penpot_db_data

# Remove volumes (⚠️ data will be lost)
docker compose down --volumes
```

### Health Monitoring

#### Check Service Health
```bash
# Core services
curl http://localhost:3000/health    # API
curl http://localhost:3001/          # UI
curl http://localhost:3002/health    # MCP

# OpenProject
curl http://localhost:8082/health_check

# Penpot
curl http://localhost:6060/api/info  # Backend
curl http://localhost:9001/          # Frontend
curl http://localhost:6061/          # Exporter
```

#### Service Status
```bash
# Check all services
docker compose ps

# Check specific profiles
docker compose --profile openproject ps
docker compose --profile penpot ps
```

### Troubleshooting

#### Common Issues

**1. Port conflicts:**
```bash
# Check what's using the ports
lsof -i :8082  # OpenProject
lsof -i :9001  # Penpot Frontend
lsof -i :6060  # Penpot Backend
lsof -i :6061  # Penpot Exporter
```

**2. Database initialization:**
```bash
# Wait for databases to initialize (first run takes longer)
docker compose logs openproject-db
docker compose logs penpot-db

# Check database health
docker compose exec openproject-db pg_isready -U openproject
docker compose exec penpot-db pg_isready -U penpot
```

**3. Service startup order:**
```bash
# Services start in dependency order:
# 1. Databases (PostgreSQL, Redis)
# 2. Backend services
# 3. Frontend services

# Check startup progress
docker compose logs --follow openproject
docker compose logs --follow penpot-backend
```

**4. Memory requirements:**
```bash
# Optional services require additional memory
# Recommended: 8GB+ RAM for full stack
# Monitor resource usage:
docker stats
```

#### Reset Optional Services
```bash
# Stop and remove optional service data
docker compose --profile openproject --profile penpot down --volumes

# Restart with fresh data
docker compose --profile openproject --profile penpot up --build
```

### Integration with Core Services

The core services (API, UI, MCP) automatically receive environment variables for optional services when profiles are active:

- **API Service**: Can make HTTP requests to OpenProject/Penpot APIs
- **UI Service**: Can display links and integrate with external tools
- **MCP Service**: Can ingest data from project management and design tools

#### Example Integration Code

**API Service Integration:**
```javascript
// Check if OpenProject is available
if (process.env.OPENPROJECT_BASE_URL && process.env.OPENPROJECT_API_TOKEN) {
  // Make API calls to OpenProject
  const response = await fetch(`${process.env.OPENPROJECT_BASE_URL}/api/v3/projects`, {
    headers: { 'Authorization': `Bearer ${process.env.OPENPROJECT_API_TOKEN}` }
  });
}

// Check if Penpot is available
if (process.env.PENPOT_BACKEND_URL && process.env.PENPOT_API_TOKEN) {
  // Make API calls to Penpot
  const response = await fetch(`${process.env.PENPOT_BACKEND_URL}/api/projects`, {
    headers: { 'Authorization': `Bearer ${process.env.PENPOT_API_TOKEN}` }
  });
}
```

**UI Service Integration:**
```javascript
// Next.js environment variables (prefixed with NEXT_PUBLIC_)
const openProjectUrl = process.env.NEXT_PUBLIC_OPENPROJECT_BASE_URL;
const penpotUrl = process.env.NEXT_PUBLIC_PENPOT_FRONTEND_URL;

// Conditionally show integration links
{openProjectUrl && (
  <a href={openProjectUrl} target="_blank">Open Project Management</a>
)}
{penpotUrl && (
  <a href={penpotUrl} target="_blank">Open Design Tool</a>
)}
```

## Project Structure

```
content-automation-stack/
├── ai-workspace/                    # AI workspace documentation
│   ├── planning/                    # Implementation plans
│   └── completion-reports/          # Completion reports
├── services/                        # Git submodules
│   ├── content-automation-api/      # API service (submodule)
│   ├── content-automation-ui/       # UI service (submodule)
│   └── content-automation-mcp-ingestion/ # MCP service (submodule)
├── scripts/                         # Automation scripts
│   ├── setup.sh                     # Initial setup and submodule management
│   ├── start.sh                     # Start the stack
│   ├── stop.sh                      # Stop the stack
│   └── logs.sh                      # View service logs
├── docker-compose.yml               # Docker Compose configuration
├── .env.example                     # Environment variables template
├── .gitignore                       # Git ignore rules
├── .gitmodules                      # Git submodules configuration
└── README.md                        # This file
```

## Scripts Reference

### Setup Script (`./scripts/setup.sh`)

Initializes the project and sets up git submodules.

```bash
./scripts/setup.sh [OPTIONS]

Options:
  --build    Build Docker images after setup
  --help     Show help message

Examples:
  ./scripts/setup.sh           # Setup without building
  ./scripts/setup.sh --build   # Setup and build images
```

**What it does:**
- Checks prerequisites (Docker, Docker Compose, Git)
- Initializes git repository if needed
- Adds and updates git submodules
- Creates `.env` file from `.env.example`
- Optionally builds Docker images

### Start Script (`./scripts/start.sh`)

Starts the Docker Compose stack.

```bash
./scripts/start.sh [OPTIONS]

Options:
  --build      Build images before starting
  --detach     Run in detached mode (background)
  --help       Show help message

Examples:
  ./scripts/start.sh                    # Start in foreground
  ./scripts/start.sh --build            # Build and start
  ./scripts/start.sh --detach           # Start in background
  ./scripts/start.sh --build --detach   # Build and start in background
```

### Stop Script (`./scripts/stop.sh`)

Stops the Docker Compose stack and removes containers.

```bash
./scripts/stop.sh [OPTIONS]

Options:
  --volumes    Remove named volumes (⚠️ data will be lost)
  --images     Remove all images (will need to rebuild)
  --help       Show help message

Examples:
  ./scripts/stop.sh                     # Stop stack, keep data
  ./scripts/stop.sh --volumes           # Stop and remove volumes
  ./scripts/stop.sh --images            # Stop and remove images
  ./scripts/stop.sh --volumes --images  # Stop and remove everything
```

### Logs Script (`./scripts/logs.sh`)

Views logs for all services or specific services.

```bash
./scripts/logs.sh [OPTIONS]

Options:
  --follow, -f    Follow log output (live updates)
  --tail, -t N    Show last N lines
  --api           Show only API service logs
  --ui            Show only UI service logs
  --mcp           Show only MCP ingestion service logs
  --help          Show help message

Examples:
  ./scripts/logs.sh                     # Show all logs
  ./scripts/logs.sh --follow            # Follow all logs
  ./scripts/logs.sh --tail 100          # Show last 100 lines
  ./scripts/logs.sh --api --follow      # Follow API logs only
  ./scripts/logs.sh --ui --mcp          # Show UI and MCP logs
```

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and customize as needed:

```bash
cp .env.example .env
```

**Key variables:**

```env
# Service Ports
API_PORT=3000          # API service port
UI_PORT=3001           # UI service port
MCP_PORT=3002          # MCP ingestion service port

# Environment
NODE_ENV=development   # development | production

# API Configuration
DATABASE_URL=          # Database connection string
JWT_SECRET=            # JWT signing secret

# UI Configuration
NEXT_PUBLIC_API_URL=http://localhost:3000  # API URL for frontend

# MCP Configuration
MCP_AUTH_ENABLED=false # Enable MCP authentication
```

### Service Dependencies

The services have the following dependency chain:

1. **API** starts first (no dependencies)
2. **UI** starts after API is healthy
3. **MCP Ingestion** starts after API is healthy

### Health Checks

All services include health checks:

- **API**: `GET /health`
- **UI**: `GET /` (Next.js default)
- **MCP**: `GET /health`

Health checks run every 30 seconds with a 10-second timeout.

## Development

### Working with Submodules

**Update all submodules:**
```bash
git submodule update --remote --recursive
```

**Update specific submodule:**
```bash
git submodule update --remote services/content-automation-api
```

**Pull latest changes in submodules:**
```bash
cd services/content-automation-api
git pull origin main
cd ../..
git add services/content-automation-api
git commit -m "Update API submodule"
```

### Local Development

For local development of individual services:

1. **API Development:**
   ```bash
   cd services/content-automation-api
   npm install
   npm run dev
   ```

2. **UI Development:**
   ```bash
   cd services/content-automation-ui
   npm install
   npm run dev
   ```

3. **MCP Development:**
   ```bash
   cd services/content-automation-mcp-ingestion
   npm install
   npm run dev
   ```

### Custom Docker Compose

For development overrides, create `docker-compose.override.yml`:

```yaml
version: '3.8'

services:
  content-automation-api:
    volumes:
      - ./services/content-automation-api:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    command: npm run dev

  content-automation-ui:
    volumes:
      - ./services/content-automation-ui:/app
      - /app/node_modules
      - /app/.next
    environment:
      - NODE_ENV=development
    command: npm run dev
```

## Networking

Services communicate via the `content-automation-network` Docker network:

- **Internal communication**: Services can reach each other by service name
- **External access**: Only mapped ports are accessible from host

**Service URLs (internal):**
- API: `http://content-automation-api:3000`
- UI: `http://content-automation-ui:3000`
- MCP: `http://content-automation-mcp-ingestion:3001`

## Troubleshooting

### Common Issues

**1. Docker Compose V1 warnings:**
```bash
# If you see warnings about legacy docker-compose:
# See docs/docker-compose-v2-upgrade.md for upgrade instructions
# Or update Docker Desktop to get V2 automatically
```

**2. Port conflicts:**
```bash
# Check what's using the port
lsof -i :3000

# Change ports in .env file
API_PORT=3010
UI_PORT=3011
MCP_PORT=3012
```

**3. Submodule issues:**
```bash
# Reset submodules
git submodule deinit --all
git submodule update --init --recursive
```

**4. Docker issues:**
```bash
# Clean up Docker resources
docker system prune -a
docker volume prune

# Rebuild everything
./scripts/stop.sh --volumes --images
./scripts/start.sh --build
```

**5. Permission issues:**
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

### Debugging

**View service status:**
```bash
docker compose ps
```

**Inspect specific service:**
```bash
docker compose logs content-automation-api
docker exec -it content-automation-api sh
```

**Check resource usage:**
```bash
docker stats
```

### Log Analysis

**Follow all logs with timestamps:**
```bash
./scripts/logs.sh --follow | while read line; do echo "$(date): $line"; done
```

**Filter logs by service:**
```bash
./scripts/logs.sh --api | grep ERROR
./scripts/logs.sh --ui | grep -i warning
```

## Production Deployment

### Security Considerations

1. **Environment Variables:**
   - Use strong, unique secrets for `JWT_SECRET`
   - Set `NODE_ENV=production`
   - Configure proper database credentials

2. **Network Security:**
   - Use reverse proxy (nginx, Traefik)
   - Enable HTTPS/TLS
   - Restrict port access

3. **Container Security:**
   - Services run as non-root users
   - Minimal base images (Alpine Linux)
   - Regular security updates

### Performance Optimization

1. **Resource Limits:**
   ```yaml
   services:
     content-automation-api:
       deploy:
         resources:
           limits:
             memory: 512M
             cpus: '0.5'
   ```

2. **Volume Optimization:**
   - Use named volumes for persistent data
   - Avoid bind mounts in production

3. **Image Optimization:**
   - Multi-stage builds reduce image size
   - Layer caching improves build times

## Monitoring

### Health Monitoring

```bash
# Check all service health
curl http://localhost:3000/health  # API
curl http://localhost:3001/        # UI
curl http://localhost:3002/health  # MCP
```

### Log Monitoring

```bash
# Monitor error logs
./scripts/logs.sh --follow | grep -i error

# Monitor performance
./scripts/logs.sh --api | grep -E "(response|latency)"
```

## Contributing

### Updating Submodules

1. **Make changes in individual service repositories**
2. **Update submodule references:**
   ```bash
   git submodule update --remote
   git add services/
   git commit -m "Update submodules to latest versions"
   ```

### Adding New Services

1. **Add as submodule:**
   ```bash
   git submodule add <repository-url> services/<service-name>
   ```

2. **Update docker-compose.yml:**
   ```yaml
   services:
     new-service:
       build:
         context: ./services/new-service
       # ... configuration
   ```

3. **Update scripts and documentation**

## Support

### Getting Help

1. **Check logs:** `./scripts/logs.sh --follow`
2. **Verify configuration:** Review `.env` file
3. **Check service status:** `docker compose ps`
4. **Review documentation:** Service-specific READMEs in submodules

### Reporting Issues

When reporting issues, include:

- Operating system and Docker version
- Complete error messages and logs
- Steps to reproduce the issue
- Current configuration (`.env` file, excluding secrets)

## License

This project is licensed under the MIT License. See individual service repositories for their specific licenses.

## References

- [Docker Compose Best Practices](https://docs.docker.com/compose/best-practices/)
- [Git Submodules Documentation](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [Content Automation API](https://github.com/leeray75/content-automation-api)
- [Content Automation UI](https://github.com/leeray75/content-automation-ui)
- [Content Automation MCP Ingestion](https://github.com/leeray75/content-automation-mcp-ingestion)
