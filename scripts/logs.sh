#!/bin/bash

# Content Automation Stack Logs Script
# This script shows logs for all services or specific services

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

# Function to show logs
show_logs() {
    local docker_compose_cmd=$(get_docker_compose_cmd)
    local follow_flag=""
    local tail_lines=""
    local services=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --follow|-f)
                follow_flag="--follow"
                shift
                ;;
            --tail|-t)
                tail_lines="--tail $2"
                shift 2
                ;;
            --api)
                services="$services content-automation-api"
                shift
                ;;
            --ui)
                services="$services content-automation-ui"
                shift
                ;;
            --mcp)
                services="$services content-automation-mcp-ingestion"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_warning "Unknown option: $1"
                shift
                ;;
        esac
    done

    # If no specific services selected, show all
    if [ -z "$services" ]; then
        services="content-automation-api content-automation-ui content-automation-mcp-ingestion"
    fi

    print_status "Showing logs for: $services"
    
    if [ -n "$follow_flag" ]; then
        print_status "Following logs (Press Ctrl+C to stop)..."
    fi
    
    # Show logs
    $docker_compose_cmd logs $follow_flag $tail_lines $services
}

# Function to display usage
show_usage() {
    echo "Content Automation Stack - Logs Script"
    echo "======================================"
    echo ""
    echo "Usage: $0 [OPTIONS] [SERVICES]"
    echo ""
    echo "Options:"
    echo "  --follow, -f    Follow log output"
    echo "  --tail, -t N    Show last N lines (default: all)"
    echo "  --api           Show only API service logs"
    echo "  --ui            Show only UI service logs"
    echo "  --mcp           Show only MCP ingestion service logs"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Show all logs"
    echo "  $0 --follow           # Follow all logs"
    echo "  $0 --tail 100         # Show last 100 lines"
    echo "  $0 --api --follow     # Follow API logs only"
    echo "  $0 --ui --mcp         # Show UI and MCP logs"
    echo "  $0 --tail 50 --api    # Show last 50 lines of API logs"
    echo ""
    echo "Services:"
    echo "  content-automation-api           - API service"
    echo "  content-automation-ui            - UI service"
    echo "  content-automation-mcp-ingestion - MCP ingestion service"
}

# Function to check if stack is running
check_stack_running() {
    local docker_compose_cmd=$(get_docker_compose_cmd)
    local running_services=$($docker_compose_cmd ps --services --filter "status=running" 2>/dev/null || echo "")
    
    if [ -z "$running_services" ]; then
        print_warning "No services are currently running."
        echo "Use './scripts/start.sh' to start the stack first."
        exit 1
    fi
}

# Function to show service status
show_service_status() {
    local docker_compose_cmd=$(get_docker_compose_cmd)
    
    print_status "Service Status:"
    $docker_compose_cmd ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    echo ""
}

# Main execution
main() {
    # Check if help is requested
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_usage
        exit 0
    fi

    check_stack_running
    show_service_status
    show_logs "$@"
}

# Run main function with all arguments
main "$@"
