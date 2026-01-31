#!/bin/bash

# Helper script for development workflow
# Usage: ./scripts/dev.sh [start|stop|restart|build|status|logs]

set -e

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.dev.yml"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    color=$1
    message=$2
    echo -e "${color}${message}${NC}"
}

# Check if docker-compose is available
check_docker() {
    if ! command -v docker-compose &> /dev/null; then
        print_message "$RED" "Error: docker-compose not found. Please install Docker Compose."
        exit 1
    fi
}

# Check if services are running
check_services() {
    if ! docker network ls | grep -q gym_ai_network; then
        print_message "$YELLOW" "⚠️  Infrastructure services not running!"
        echo "Start them first: ./scripts/services.sh start"
        return 1
    fi
    return 0
}

# Show usage
show_usage() {
    echo "Development Services Manager"
    echo ""
    echo "Usage: ./scripts/dev.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start          - Start development services (backend + dashboard)"
    echo "  stop           - Stop development services"
    echo "  restart        - Restart development services"
    echo "  build          - Build development services"
    echo "  rebuild        - Rebuild and restart services"
    echo "  logs           - View logs from all services"
    echo "  logs-backend   - View backend logs"
    echo "  logs-dashboard - View dashboard logs"
    echo "  shell          - Open shell in container (default: backend)"
    echo "  test           - Run backend tests"
    echo "  status         - Show status of all services"
    echo ""
    echo "Note: Infrastructure services must be running first!"
    echo "      Start with: ./scripts/services.sh start"
    echo ""
    echo "Examples:"
    echo "  ./scripts/dev.sh start"
    echo "  ./scripts/dev.sh logs backend"
    echo "  ./scripts/dev.sh shell backend"
    echo "  ./scripts/dev.sh test -v"
    echo ""
}

# Start services
start_services() {
    if ! check_services; then
        exit 1
    fi
    print_message "$BLUE" "Starting development services..."
    cd "${SCRIPT_DIR}/.."
    docker-compose -f $COMPOSE_FILE up -d
    print_message "$GREEN" "Development services started!"
    echo ""
    echo "📱 Access points:"
    echo "   Backend:    http://localhost:8000"
    echo "   API Docs:   http://localhost:8000/docs"
    echo "   Dashboard:  http://localhost:8050"
}

# Stop services
stop_services() {
    print_message "$BLUE" "Stopping development services..."
    cd "${SCRIPT_DIR}/.."
    docker-compose -f $COMPOSE_FILE down
    print_message "$GREEN" "Development services stopped!"
}

# Restart services
restart_services() {
    print_message "$BLUE" "Restarting development services..."
    cd "${SCRIPT_DIR}/.."
    docker-compose -f $COMPOSE_FILE restart
    print_message "$GREEN" "Development services restarted!"
}

# Build images
build_images() {
    print_message "$BLUE" "Building development services..."
    cd "${SCRIPT_DIR}/.."
    docker-compose -f $COMPOSE_FILE build "${@}"
    print_message "$GREEN" "Build complete!"
}

# Rebuild and restart
rebuild_services() {
    print_message "$BLUE" "Rebuilding and restarting..."
    cd "${SCRIPT_DIR}/.."
    docker-compose -f $COMPOSE_FILE up -d --build
    print_message "$GREEN" "Rebuild complete!"
}

# View logs
view_logs() {
    cd "${SCRIPT_DIR}/.."
    docker-compose -f $COMPOSE_FILE logs -f
}

# View backend logs
view_backend_logs() {
    cd "${SCRIPT_DIR}/.."
    docker-compose -f $COMPOSE_FILE logs -f backend
}

# View dashboard logs
view_dashboard_logs() {
    cd "${SCRIPT_DIR}/.."
    docker-compose -f $COMPOSE_FILE logs -f dashboard
}

# Open shell
open_shell() {
    SERVICE="${1:-backend}"
    print_message "$BLUE" "Opening shell in $SERVICE..."
    cd "${SCRIPT_DIR}/.."
    docker-compose -f $COMPOSE_FILE exec $SERVICE /bin/bash
}

# Run tests
run_tests() {
    print_message "$BLUE" "Running backend tests..."
    cd "${SCRIPT_DIR}/.."
    docker-compose -f $COMPOSE_FILE exec backend pytest "${@}"
}

# Show status
show_status() {
    print_message "$BLUE" "Development Service Status:"
    cd "${SCRIPT_DIR}/.."
    docker-compose -f $COMPOSE_FILE ps
}

# Main script logic
check_docker

case "${1:-}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    build)
        shift
        build_images "$@"
        ;;
    rebuild)
        rebuild_services
        ;;
    logs)
        view_logs
        ;;
    logs-backend)
        view_backend_logs
        ;;
    logs-dashboard)
        view_dashboard_logs
        ;;
    shell)
        open_shell "${2:-backend}"
        ;;
    test)
        shift
        run_tests "$@"
        ;;
    status|ps)
        show_status
        ;;
    help|--help|-h|"")
        show_usage
        ;;
    *)
        print_message "$RED" "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
