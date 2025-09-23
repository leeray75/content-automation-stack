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
