#!/bin/bash

# Helper script to manage infrastructure services
# Usage: ./scripts/services.sh [start|stop|restart|status|logs]

set -e

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.services.yml"

case "${1:-help}" in
    start)
        echo "🚀 Starting infrastructure services..."
        cd "${SCRIPT_DIR}/.."
        docker-compose -f $COMPOSE_FILE up -d
        echo "✓ Services started"
        docker-compose -f $COMPOSE_FILE ps
        ;;

    stop)
        echo "🛑 Stopping infrastructure services..."
        cd "${SCRIPT_DIR}/.."
        docker-compose -f $COMPOSE_FILE down
        echo "✓ Services stopped"
        ;;

    restart)
        echo "🔄 Restarting infrastructure services..."
        cd "${SCRIPT_DIR}/.."
        docker-compose -f $COMPOSE_FILE restart
        echo "✓ Services restarted"
        ;;

    status|ps)
        cd "${SCRIPT_DIR}/.."
        docker-compose -f $COMPOSE_FILE ps
        ;;

    logs)
        cd "${SCRIPT_DIR}/.."
        docker-compose -f $COMPOSE_FILE logs -f "${@:2}"
        ;;

    pull)
        echo "📥 Pulling model in Ollama..."
        cd "${SCRIPT_DIR}/.."
        docker-compose -f $COMPOSE_FILE exec ollama ollama pull llava
        ;;

    clean)
        echo "⚠️  This will remove all data volumes!"
        read -p "Are you sure? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "${SCRIPT_DIR}/.."
            docker-compose -f $COMPOSE_FILE down -v
            echo "✓ Cleaned"
        fi
        ;;

    help|*)
        echo "Infrastructure Services Manager"
        echo ""
        echo "Usage: ./scripts/services.sh [command]"
        echo ""
        echo "Commands:"
        echo "  start      Start all infrastructure services"
        echo "  stop       Stop all infrastructure services"
        echo "  restart    Restart all infrastructure services"
        echo "  status     Show service status"
        echo "  logs       Follow service logs (add service name for specific)"
        echo "  pull       Pull LLaVA model into Ollama"
        echo "  clean      Stop and remove all data volumes"
        echo ""
        echo "Examples:"
        echo "  ./scripts/services.sh start"
        echo "  ./scripts/services.sh logs ollama"
        echo "  ./scripts/services.sh pull"
        ;;
esac
