#!/bin/bash

# Content Automation Stack Stop Script
# This script brings down the entire stack and removes containers

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
        print_error "Docker Compose is not installed."
        exit 1
    fi
}

# Function to stop the stack
stop_stack() {
    local docker_compose_cmd=$(get_docker_compose_cmd)
    local remove_volumes=""
    local remove_images=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --volumes|-v)
                remove_volumes="--volumes"
                shift
                ;;
            --images)
                remove_images="--rmi all"
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --volumes   Remove named volumes"
                echo "  --images    Remove all images"
                echo "  --help      Show this help message"
                exit 0
                ;;
            *)
                print_warning "Unknown option: $1"
                shift
                ;;
        esac
    done

    print_status "Stopping Content Automation Stack..."
    
    # Stop and remove containers
    $docker_compose_cmd down $remove_volumes $remove_images
    
    print_success "Stack stopped successfully"
    
    if [ -n "$remove_volumes" ]; then
        print_status "Named volumes removed"
    fi
    
    if [ -n "$remove_images" ]; then
        print_status "Images removed"
    fi
    
    # Show remaining containers (if any)
    local running_containers=$(docker ps -q --filter "name=content-automation")
    if [ -n "$running_containers" ]; then
        print_warning "Some containers are still running:"
        docker ps --filter "name=content-automation" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    fi
}

# Function to display usage
show_usage() {
    echo "Content Automation Stack - Stop Script"
    echo "======================================"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --volumes   Remove named volumes (data will be lost)"
    echo "  --images    Remove all images (will need to rebuild)"
    echo "  --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                # Stop stack, keep volumes and images"
    echo "  $0 --volumes      # Stop stack and remove volumes"
    echo "  $0 --images       # Stop stack and remove images"
    echo "  $0 --volumes --images  # Stop stack, remove volumes and images"
    echo ""
    echo "Note: Use --volumes with caution as it will remove all data"
}

# Function to confirm destructive operations
confirm_destructive_action() {
    if [[ "$*" == *"--volumes"* ]] || [[ "$*" == *"--images"* ]]; then
        echo ""
        print_warning "This operation will remove data/images. Are you sure? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_status "Operation cancelled"
            exit 0
        fi
    fi
}

# Main execution
main() {
    # Check if help is requested
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_usage
        exit 0
    fi

    # Confirm destructive actions
    confirm_destructive_action "$@"
    
    stop_stack "$@"
    
    echo ""
    print_success "Content Automation Stack stopped"
    echo "Use './scripts/start.sh' to start the stack again"
}

# Run main function with all arguments
main "$@"
