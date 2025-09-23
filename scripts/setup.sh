#!/bin/bash

# Content Automation Stack Setup Script
# This script initializes git submodules, checks prerequisites, and prepares the environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Docker version
check_docker() {
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi

    local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    print_success "Docker found: $docker_version"

    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
}

# Function to check Docker Compose version
check_docker_compose() {
    if ! command_exists "docker compose"; then
        if command_exists "docker-compose"; then
            print_warning "Found legacy docker-compose (V1). Docker Compose V2 is recommended."
            print_warning "V1 stopped receiving updates in July 2023 and has security concerns."
            echo ""
            print_status "To upgrade to Docker Compose V2:"
            echo "1. Update Docker Desktop (recommended): https://docs.docker.com/desktop/"
            echo "2. Or install manually on Linux: https://docs.docker.com/compose/install/linux/"
            echo "3. See docs/docker-compose-v2-upgrade.md for detailed instructions"
            echo ""
            print_warning "Using legacy docker-compose for now..."
            export DOCKER_COMPOSE_CMD="docker-compose"
        else
            print_error "Docker Compose is not installed. Please install Docker Compose V2."
            echo "Visit: https://docs.docker.com/compose/install/"
            exit 1
        fi
    else
        local compose_version=$(docker compose version --short 2>/dev/null || echo "unknown")
        print_success "Docker Compose V2 found: $compose_version"
        export DOCKER_COMPOSE_CMD="docker compose"
    fi
}

# Function to check Git
check_git() {
    if ! command_exists git; then
        print_error "Git is not installed. Please install Git first."
        exit 1
    fi

    local git_version=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    print_success "Git found: $git_version"
}

# Function to initialize git repository if needed
init_git_repo() {
    if [ ! -d ".git" ]; then
        print_status "Initializing Git repository..."
        git init
        print_success "Git repository initialized"
    else
        print_status "Git repository already exists"
    fi
}

# Function to add git submodules
add_submodules() {
    print_status "Setting up git submodules..."

    # Create services directory
    mkdir -p services

    # Add submodules if they don't exist
    if [ ! -d "services/content-automation-api/.git" ]; then
        print_status "Adding content-automation-api submodule..."
        git submodule add https://github.com/leeray75/content-automation-api.git services/content-automation-api
        print_success "Added content-automation-api submodule"
    else
        print_status "content-automation-api submodule already exists"
    fi

    if [ ! -d "services/content-automation-ui/.git" ]; then
        print_status "Adding content-automation-ui submodule..."
        git submodule add https://github.com/leeray75/content-automation-ui.git services/content-automation-ui
        print_success "Added content-automation-ui submodule"
    else
        print_status "content-automation-ui submodule already exists"
    fi

    if [ ! -d "services/content-automation-mcp-ingestion/.git" ]; then
        print_status "Adding content-automation-mcp-ingestion submodule..."
        git submodule add https://github.com/leeray75/content-automation-mcp-ingestion.git services/content-automation-mcp-ingestion
        print_success "Added content-automation-mcp-ingestion submodule"
    else
        print_status "content-automation-mcp-ingestion submodule already exists"
    fi

    # Initialize and update submodules
    print_status "Initializing and updating submodules..."
    git submodule init
    git submodule update --recursive
    print_success "Submodules initialized and updated"
}

# Function to setup environment file
setup_env_file() {
    if [ ! -f ".env" ]; then
        print_status "Creating .env file from .env.example..."
        cp .env.example .env
        print_success "Created .env file"
        print_warning "Please review and update .env file with your specific configuration"
    else
        print_status ".env file already exists"
    fi
}

# Function to build images (optional)
build_images() {
    if [ "$1" = "--build" ]; then
        print_status "Building Docker images..."
        $DOCKER_COMPOSE_CMD build
        print_success "Docker images built successfully"
    fi
}

# Function to display final instructions
display_instructions() {
    echo ""
    print_success "Setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Review and update the .env file with your configuration"
    echo "2. Run './scripts/start.sh' to start the stack"
    echo "3. Run './scripts/logs.sh' to view logs"
    echo "4. Run './scripts/stop.sh' to stop the stack"
    echo ""
    echo "Services will be available at:"
    echo "- API: http://localhost:3000"
    echo "- UI: http://localhost:3001"
    echo "- MCP Ingestion: http://localhost:3002"
    echo ""
    echo "For troubleshooting, see README.md"
}

# Main execution
main() {
    echo "Content Automation Stack Setup"
    echo "=============================="
    echo ""

    print_status "Checking prerequisites..."
    check_git
    check_docker
    check_docker_compose

    print_status "Setting up project..."
    init_git_repo
    add_submodules
    setup_env_file

    build_images "$1"

    display_instructions
}

# Run main function with all arguments
main "$@"
