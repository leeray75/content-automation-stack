#!/bin/bash

# Content Automation Stack Start Script
# This script brings up the entire stack using Docker Compose

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

# Function to determine Docker Compose command
get_docker_compose_cmd() {
    if command_exists "docker compose"; then
        echo "docker compose"
    elif command_exists "docker-compose"; then
        echo "docker-compose"
    else
        print_error "Docker Compose is not installed. Please run ./scripts/setup.sh first."
        exit 1
    fi
}

# Function to check if .env file exists
check_env_file() {
    if [ ! -f ".env" ]; then
        print_warning ".env file not found. Creating from .env.example..."
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_success "Created .env file from .env.example"
        else
            print_error ".env.example file not found. Please run ./scripts/setup.sh first."
            exit 1
        fi
    fi
}

# Function to check if submodules are initialized
check_submodules() {
    if [ ! -d "services/content-automation-api" ] || [ ! -d "services/content-automation-ui" ] || [ ! -d "services/content-automation-mcp-ingestion" ]; then
        print_error "Git submodules not found. Please run ./scripts/setup.sh first."
        exit 1
    fi
}

# Function to start the stack
start_stack() {
    local docker_compose_cmd=$(get_docker_compose_cmd)
    local build_flag=""
    local detach_flag=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --build)
                build_flag="--build"
                shift
                ;;
            --detach|-d)
                detach_flag="--detach"
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --build     Build images before starting"
                echo "  --detach    Run in detached mode"
                echo "  --help      Show this help message"
                exit 0
                ;;
            *)
                print_warning "Unknown option: $1"
                shift
                ;;
        esac
    done

    print_status "Starting Content Automation Stack..."
    
    if [ -n "$build_flag" ]; then
        print_status "Building images..."
    fi
    
    # Start the stack
    $docker_compose_cmd up $build_flag $detach_flag
    
    if [ -n "$detach_flag" ]; then
        print_success "Stack started in detached mode"
        echo ""
        echo "Services are available at:"
        echo "- API: http://localhost:$(grep API_PORT .env | cut -d'=' -f2 | tr -d ' ' || echo '3000')"
        echo "- UI: http://localhost:$(grep UI_PORT .env | cut -d'=' -f2 | tr -d ' ' || echo '3001')"
        echo "- MCP Ingestion: http://localhost:$(grep MCP_PORT .env | cut -d'=' -f2 | tr -d ' ' || echo '3002')"
        echo ""
        echo "Use './scripts/logs.sh' to view logs"
        echo "Use './scripts/stop.sh' to stop the stack"
    fi
}

# Function to display usage
show_usage() {
    echo "Content Automation Stack - Start Script"
    echo "======================================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --build     Build images before starting"
    echo "  --detach    Run in detached mode"
    echo "  --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Start stack in foreground"
    echo "  $0 --build           # Build and start stack"
    echo "  $0 --detach          # Start stack in background"
    echo "  $0 --build --detach  # Build and start in background"
}

# Main execution
main() {
    # Check if help is requested
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_usage
        exit 0
    fi

    print_status "Checking prerequisites..."
    check_env_file
    check_submodules
    
    start_stack "$@"
}

# Run main function with all arguments
main "$@"
