# Docker Compose V2 Upgrade Guide

This guide helps you upgrade from Docker Compose V1 (legacy `docker-compose`) to Docker Compose V2 (modern `docker compose`).

## Why Upgrade to Docker Compose V2?

- **Security**: V1 stopped receiving updates in July 2023, including security patches
- **Performance**: Improved build performance with BuildKit
- **Integration**: Better integration with Docker CLI platform
- **Features**: Continued new feature development only in V2
- **Support**: V1 is no longer supported by Docker

## Current Status Check

Run these commands to check your current Docker Compose version:

```bash
# Check if you have Docker Compose V2
docker compose version

# Check if you have legacy V1
docker-compose version
```

## Upgrade Methods

### Method 1: Docker Desktop (Recommended)

The easiest way to get Docker Compose V2 is to install or update Docker Desktop:

**For macOS:**
1. Download the latest Docker Desktop from [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/)
2. Install or update Docker Desktop
3. Docker Compose V2 is included automatically

**For Windows:**
1. Download the latest Docker Desktop from [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
2. Install or update Docker Desktop
3. Docker Compose V2 is included automatically

**For Linux:**
1. Download the latest Docker Desktop from [Docker Desktop for Linux](https://docs.docker.com/desktop/setup/install/linux/)
2. Install or update Docker Desktop
3. Docker Compose V2 is included automatically

### Method 2: Manual Installation (Linux Only)

If you prefer not to use Docker Desktop on Linux, you can install Docker Compose V2 manually:

#### Option A: Using Docker's Repository (Recommended)

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt-get update

# Install Docker Compose plugin
sudo apt-get install docker-compose-plugin
```

#### Option B: Manual Download and Install

```bash
# Create the plugins directory
mkdir -p ~/.docker/cli-plugins/

# Download the latest release
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose

# Make it executable
chmod +x ~/.docker/cli-plugins/docker-compose

# Verify installation
docker compose version
```

## Key Differences Between V1 and V2

### Command Syntax

| V1 (Legacy) | V2 (Modern) |
|-------------|-------------|
| `docker-compose up` | `docker compose up` |
| `docker-compose down` | `docker compose down` |
| `docker-compose build` | `docker compose build` |
| `docker-compose logs` | `docker compose logs` |

**Key Change**: Replace the hyphen (`-`) with a space.

### Container Naming

- **V1**: Uses underscores (`_`) as separators: `myproject_service_1`
- **V2**: Uses hyphens (`-`) as separators: `myproject-service-1`

This change ensures container names are valid DNS hostnames.

### Compatibility Mode

If you need V1-style container names temporarily:

```bash
# Use compatibility flag
docker compose --compatibility up

# Or set environment variable
export COMPOSE_COMPATIBILITY=true
docker compose up
```

## Migration Steps

### 1. Verify Your Project Works

Before upgrading, test your current setup:

```bash
# Preview configuration after V2 interpolation
docker compose config

# Check for any warnings or errors
docker compose validate
```

### 2. Update Scripts and Documentation

Update any scripts that use `docker-compose` to use `docker compose`:

```bash
# Old
docker-compose up -d
docker-compose logs -f

# New
docker compose up -d
docker compose logs -f
```

### 3. Handle Running Containers

When you first run V2 on a project with V1 containers:

1. **Stop existing containers**: `docker-compose down`
2. **Start with V2**: `docker compose up`

V2 will recreate containers with new naming conventions.

### 4. Update CI/CD Pipelines

Update your CI/CD configurations:

```yaml
# GitHub Actions example
- name: Start services
  run: docker compose up -d

# GitLab CI example
script:
  - docker compose build
  - docker compose up -d
```

## Environment Variables

V2 has more consistent environment variable handling. Check if your project uses:

- Multiple `.env` files
- Complex variable interpolation
- Literal `$` signs in values
- Advanced expansion syntax like `${VAR:?error}`

Test with: `docker compose config`

## Troubleshooting

### Common Issues

**1. Command not found: `docker compose`**
```bash
# Solution: Install Docker Compose V2 or update Docker Desktop
```

**2. Container name conflicts**
```bash
# Solution: Stop V1 containers first
docker-compose down
docker compose up
```

**3. Environment variable issues**
```bash
# Solution: Test configuration
docker compose config
```

**4. Script compatibility**
```bash
# Solution: Update scripts to use 'docker compose' instead of 'docker-compose'
```

### Verification Commands

```bash
# Check Docker Compose V2 is installed
docker compose version

# Verify project configuration
docker compose config

# Test project startup
docker compose up --dry-run
```

## Benefits After Upgrade

- **Security**: Latest security updates and patches
- **Performance**: Faster builds with BuildKit
- **Features**: Access to new Docker Compose features
- **Integration**: Better Docker CLI integration
- **Support**: Official Docker support

## Rollback (If Needed)

If you need to temporarily use V1:

1. **Install V1 manually** (not recommended for security reasons)
2. **Use compatibility mode** with V2:
   ```bash
   docker compose --compatibility up
   ```

## Additional Resources

- [Official Docker Compose V2 Migration Guide](https://docs.docker.com/compose/migrate/)
- [Docker Compose Installation Guide](https://docs.docker.com/compose/install/)
- [Docker Desktop Downloads](https://docs.docker.com/desktop/)
- [Docker Compose V2 Release Notes](https://docs.docker.com/compose/release-notes/)

## Support

If you encounter issues during migration:

1. Check the [Docker Compose GitHub Issues](https://github.com/docker/compose/issues)
2. Review the [Docker Community Forums](https://forums.docker.com/)
3. Consult the [Docker Documentation](https://docs.docker.com/)

---

**Note**: This guide is based on Docker's official documentation as of September 2025. Always refer to the latest Docker documentation for the most current information.
