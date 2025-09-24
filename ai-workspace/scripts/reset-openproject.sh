#!/bin/bash

# OpenProject Environment Reset Script
# 
# This script performs a complete reset of the OpenProject environment by:
# 1. Stopping and removing all OpenProject containers
# 2. Removing all OpenProject volumes (DATABASE AND ASSETS WILL BE LOST)
# 3. Pulling the latest OpenProject image
# 4. Starting fresh OpenProject services with 2FA disabled
#
# WARNING: This is a DESTRUCTIVE operation that will permanently delete:
# - All OpenProject database data
# - All OpenProject assets and uploads
# - All user accounts and project data
#
# Usage:
#   ./reset-openproject.sh [OPTIONS]
#
# Options:
#   -h, --help              Show this help message
#   -y, --yes               Skip confirmation prompts (for automation)
#   -t, --tag TAG           Use specific OpenProject image tag (default: from .env)
#   -v, --verbose           Enable verbose output
#   --no-pull               Skip pulling latest image
#   --backup                Create backup before reset (not implemented yet)
#
# Examples:
#   ./reset-openproject.sh                    # Interactive reset with current image
#   ./reset-openproject.sh -y                 # Non-interactive reset
#   ./reset-openproject.sh -t 13.4.1-slim     # Reset with specific image tag
#   ./reset-openproject.sh -y -v              # Non-interactive with verbose output
#
# Exit Codes:
#   0 - Success
#   1 - General error
#   2 - Missing dependencies
#   3 - User cancelled
#   4 - Docker/Compose error
#   5 - Startup verification failed

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
ENV_FILE="$PROJECT_ROOT/.env"

# Default options
SKIP_CONFIRMATION=false
VERBOSE=false
CUSTOM_TAG=""
SKIP_PULL=false
CREATE_BACKUP=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${CYAN}[VERBOSE]${NC} $1"
    fi
}

# Help function
show_help() {
    cat << 'EOF'
OpenProject Environment Reset Script

This script performs a complete reset of the OpenProject environment by stopping
and removing all containers, deleting all volumes, and starting fresh services.

WARNING: This is a DESTRUCTIVE operation that will permanently delete all
OpenProject data including database, assets, users, and projects.

Usage:
  ./reset-openproject.sh [OPTIONS]

Options:
  -h, --help              Show this help message
  -y, --yes               Skip confirmation prompts (for automation)
  -t, --tag TAG           Use specific OpenProject image tag (default: from .env)
  -v, --verbose           Enable verbose output
  --no-pull               Skip pulling latest image
  --backup                Create backup before reset (not implemented yet)

Examples:
  ./reset-openproject.sh                    # Interactive reset with current image
  ./reset-openproject.sh -y                 # Non-interactive reset
  ./reset-openproject.sh -t 13.4.1-slim     # Reset with specific image tag
  ./reset-openproject.sh -y -v              # Non-interactive with verbose output

Exit Codes:
  0 - Success
  1 - General error
  2 - Missing dependencies
  3 - User cancelled
  4 - Docker/Compose error
  5 - Startup verification failed

For more information, see the implementation plan:
  ai-workspace/planning/issue-10-implementation-plan.md
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=true
                shift
                ;;
            -t|--tag)
                CUSTOM_TAG="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --no-pull)
                SKIP_PULL=true
                shift
                ;;
            --backup)
                CREATE_BACKUP=true
                log_warning "Backup functionality not yet implemented"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if we're in the right directory
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_error "docker-compose.yml not found at $COMPOSE_FILE"
        log_error "Please run this script from the content-automation-stack directory"
        exit 1
    fi
    
    if [[ ! -f "$ENV_FILE" ]]; then
        log_error ".env file not found at $ENV_FILE"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 2
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not available"
        log_error "Please install Docker Compose v2 or ensure Docker Desktop is running"
        exit 2
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        log_error "Please start Docker Desktop or the Docker daemon"
        exit 2
    fi
    
    log_success "All prerequisites met"
}

# Load environment variables
load_environment() {
    log_step "Loading environment variables..."
    
    if [[ -f "$ENV_FILE" ]]; then
        # Source the .env file, but only export the variables we need
        set -a
        source "$ENV_FILE"
        set +a
        log_verbose "Loaded environment from $ENV_FILE"
    else
        log_warning ".env file not found, using defaults"
    fi
    
    # Set defaults if not provided
    OPENPROJECT_IMAGE_TAG="${OPENPROJECT_IMAGE_TAG:-16.4.1-slim}"
    
    # Override with custom tag if provided
    if [[ -n "$CUSTOM_TAG" ]]; then
        OPENPROJECT_IMAGE_TAG="$CUSTOM_TAG"
        log_info "Using custom image tag: $OPENPROJECT_IMAGE_TAG"
    fi
    
    log_verbose "OpenProject image tag: $OPENPROJECT_IMAGE_TAG"
}

# Confirm reset operation
confirm_reset() {
    if [[ "$SKIP_CONFIRMATION" == "true" ]]; then
        log_info "Skipping confirmation (--yes flag provided)"
        return 0
    fi
    
    echo
    log_warning "⚠️  DESTRUCTIVE OPERATION WARNING ⚠️"
    echo
    echo "This script will permanently delete:"
    echo "  • All OpenProject database data"
    echo "  • All OpenProject assets and uploads"
    echo "  • All user accounts and project data"
    echo "  • All OpenProject configuration"
    echo
    echo "The following containers and volumes will be removed:"
    echo "  • Container: openproject"
    echo "  • Container: openproject-db"
    echo "  • Container: openproject-db-init"
    echo "  • Volume: openproject_db_data"
    echo "  • Volume: openproject_assets"
    echo
    echo "OpenProject will be restarted with:"
    echo "  • Image: openproject/openproject:$OPENPROJECT_IMAGE_TAG"
    echo "  • Fresh database with no data"
    echo "  • 2FA disabled"
    echo "  • Default admin credentials"
    echo
    
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " -r
    if [[ ! $REPLY =~ ^yes$ ]]; then
        log_info "Operation cancelled by user"
        exit 3
    fi
    
    echo
    log_info "Proceeding with OpenProject reset..."
}

# Stop and remove OpenProject containers
cleanup_containers() {
    log_step "Stopping and removing OpenProject containers..."
    
    cd "$PROJECT_ROOT"
    
    # Stop containers gracefully first
    log_verbose "Stopping OpenProject containers..."
    if docker compose --profile openproject stop openproject openproject-db openproject-db-init 2>/dev/null; then
        log_verbose "Containers stopped successfully"
    else
        log_verbose "Some containers were not running"
    fi
    
    # Remove containers
    log_verbose "Removing OpenProject containers..."
    if docker compose --profile openproject rm -f openproject openproject-db openproject-db-init 2>/dev/null; then
        log_verbose "Containers removed successfully"
    else
        log_verbose "Some containers were already removed"
    fi
    
    # Clean up any orphaned containers
    log_verbose "Cleaning up orphaned containers..."
    docker container prune -f --filter "label=com.docker.compose.project=content-automation-stack" &>/dev/null || true
    
    log_success "Container cleanup completed"
}

# Remove OpenProject volumes
cleanup_volumes() {
    log_step "Removing OpenProject volumes..."
    
    # Remove named volumes
    local volumes=("content-automation-stack_openproject_db_data" "content-automation-stack_openproject_assets")
    
    for volume in "${volumes[@]}"; do
        if docker volume ls -q | grep -q "^${volume}$"; then
            log_verbose "Removing volume: $volume"
            if docker volume rm "$volume" 2>/dev/null; then
                log_verbose "Volume $volume removed successfully"
            else
                log_warning "Failed to remove volume $volume (may not exist)"
            fi
        else
            log_verbose "Volume $volume does not exist"
        fi
    done
    
    # Clean up any orphaned volumes
    log_verbose "Cleaning up orphaned volumes..."
    docker volume prune -f --filter "label=com.docker.compose.project=content-automation-stack" &>/dev/null || true
    
    log_success "Volume cleanup completed"
}

# Pull OpenProject image
pull_image() {
    if [[ "$SKIP_PULL" == "true" ]]; then
        log_info "Skipping image pull (--no-pull flag provided)"
        return 0
    fi
    
    log_step "Pulling OpenProject image..."
    
    local image="openproject/openproject:$OPENPROJECT_IMAGE_TAG"
    log_info "Pulling image: $image"
    
    if docker pull "$image"; then
        log_success "Image pulled successfully"
    else
        log_error "Failed to pull image: $image"
        log_error "Please check your internet connection and image tag"
        exit 4
    fi
}

# Start OpenProject services
start_services() {
    log_step "Starting OpenProject services..."
    
    cd "$PROJECT_ROOT"
    
    # Start database first
    log_info "Starting PostgreSQL database..."
    if docker compose --profile openproject up -d openproject-db; then
        log_verbose "Database container started"
    else
        log_error "Failed to start database container"
        exit 4
    fi
    
    # Wait for database to be healthy
    log_info "Waiting for database to be ready..."
    local max_attempts=30
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if docker compose --profile openproject ps openproject-db | grep -q "healthy"; then
            log_success "Database is ready"
            break
        fi
        
        attempt=$((attempt + 1))
        log_verbose "Database health check attempt $attempt/$max_attempts"
        sleep 2
    done
    
    if [[ $attempt -eq $max_attempts ]]; then
        log_error "Database failed to become healthy within timeout"
        exit 4
    fi
    
    # Run database initialization
    log_info "Initializing database extensions..."
    if docker compose --profile openproject up openproject-db-init; then
        log_success "Database initialization completed"
    else
        log_error "Database initialization failed"
        exit 4
    fi
    
    # Start OpenProject
    log_info "Starting OpenProject application..."
    if docker compose --profile openproject up -d openproject; then
        log_success "OpenProject container started"
    else
        log_error "Failed to start OpenProject container"
        exit 4
    fi
}

# Monitor startup logs
monitor_startup() {
    log_step "Monitoring OpenProject startup..."
    
    cd "$PROJECT_ROOT"
    
    log_info "Tailing OpenProject logs (press Ctrl+C to stop monitoring)..."
    log_info "This may take several minutes for first startup..."
    
    # Show logs for 60 seconds or until user interrupts
    timeout 60s docker compose --profile openproject logs -f openproject 2>/dev/null || {
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            log_info "Log monitoring timeout reached"
        else
            log_info "Log monitoring stopped"
        fi
    }
    
    echo
}

# Verify startup and configuration
verify_startup() {
    log_step "Verifying OpenProject startup..."
    
    cd "$PROJECT_ROOT"
    
    # Check container health
    log_info "Checking container health status..."
    local max_attempts=60  # 10 minutes with 10-second intervals
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        local health_status=$(docker compose --profile openproject ps openproject --format "table {{.State}}" | tail -n +2 | tr -d ' ')
        
        if [[ "$health_status" == "running" ]]; then
            log_success "OpenProject container is running"
            break
        elif [[ "$health_status" == "exited" ]] || [[ "$health_status" == "dead" ]]; then
            log_error "OpenProject container failed to start"
            log_error "Container status: $health_status"
            log_info "Check logs with: docker compose --profile openproject logs openproject"
            exit 5
        fi
        
        attempt=$((attempt + 1))
        log_verbose "Container health check attempt $attempt/$max_attempts (status: $health_status)"
        sleep 10
    done
    
    if [[ $attempt -eq $max_attempts ]]; then
        log_error "OpenProject container failed to become healthy within timeout"
        exit 5
    fi
    
    # Test HTTP connectivity
    log_info "Testing HTTP connectivity..."
    local max_http_attempts=30
    local http_attempt=0
    
    while [[ $http_attempt -lt $max_http_attempts ]]; do
        if curl -fsS -o /dev/null http://localhost:8082/ 2>/dev/null; then
            log_success "OpenProject is responding to HTTP requests"
            break
        fi
        
        http_attempt=$((http_attempt + 1))
        log_verbose "HTTP connectivity attempt $http_attempt/$max_http_attempts"
        sleep 10
    done
    
    if [[ $http_attempt -eq $max_http_attempts ]]; then
        log_warning "OpenProject is not responding to HTTP requests yet"
        log_warning "This is normal for first startup - it may take 10-15 minutes"
    fi
}

# Check environment variables in running container
check_environment_variables() {
    log_step "Verifying environment variables in running container..."
    
    cd "$PROJECT_ROOT"
    
    local env_vars=(
        "OPENPROJECT_2FA_ENFORCED"
        "OPENPROJECT_2FA_DISABLED"
        "OPENPROJECT_2FA_ACTIVE__STRATEGIES"
        "OPENPROJECT_EMERGENCY_DISABLE_2FA"
    )
    
    log_info "Checking 2FA-related environment variables..."
    
    for var in "${env_vars[@]}"; do
        local value=$(docker compose --profile openproject exec -T openproject printenv "$var" 2>/dev/null || echo "NOT_SET")
        log_verbose "$var = $value"
        
        case "$var" in
            "OPENPROJECT_2FA_ENFORCED")
                if [[ "$value" == "false" ]]; then
                    log_success "✓ 2FA enforcement is disabled"
                else
                    log_warning "⚠ 2FA enforcement setting: $value"
                fi
                ;;
            "OPENPROJECT_2FA_DISABLED")
                if [[ "$value" == "true" ]]; then
                    log_success "✓ 2FA is disabled"
                else
                    log_warning "⚠ 2FA disabled setting: $value"
                fi
                ;;
            "OPENPROJECT_EMERGENCY_DISABLE_2FA")
                if [[ "$value" == "true" ]]; then
                    log_success "✓ Emergency 2FA disable is active"
                else
                    log_warning "⚠ Emergency 2FA disable setting: $value"
                fi
                ;;
        esac
    done
}

# Display final status and instructions
show_final_status() {
    echo
    log_success "🎉 OpenProject reset completed successfully!"
    echo
    log_info "OpenProject is now running with:"
    echo "  • Fresh database (no existing data)"
    echo "  • 2FA disabled"
    echo "  • Image: openproject/openproject:$OPENPROJECT_IMAGE_TAG"
    echo
    log_info "Access OpenProject at: http://localhost:8082"
    echo
    log_info "Default admin credentials:"
    echo "  • Username: admin"
    echo "  • Password: admin"
    echo
    log_warning "Note: First startup may take 10-15 minutes to complete"
    log_info "Monitor progress with: docker compose --profile openproject logs -f openproject"
    echo
    log_info "If 2FA issues persist, try running with an older image:"
    log_info "  ./reset-openproject.sh -t 13.4.1-slim"
    echo
}

# Cleanup function for script interruption
cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]] && [[ $exit_code -ne 3 ]]; then
        echo
        log_error "Script interrupted or failed (exit code: $exit_code)"
        log_info "You may need to manually clean up containers and volumes"
        log_info "Use: docker compose --profile openproject down -v"
    fi
}

# Main execution function
main() {
    # Set up signal handlers
    trap cleanup_on_exit EXIT
    
    # Parse command line arguments
    parse_args "$@"
    
    # Show script header
    echo
    log_info "OpenProject Environment Reset Script"
    log_info "======================================"
    echo
    
    # Execute main workflow
    check_prerequisites
    load_environment
    confirm_reset
    cleanup_containers
    cleanup_volumes
    pull_image
    start_services
    monitor_startup
    verify_startup
    check_environment_variables
    show_final_status
    
    log_success "Reset operation completed successfully!"
    exit 0
}

# Run main function with all arguments
main "$@"
