#!/bin/bash

# Setup Ollama in Docker with GPU support

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Ollama Docker Setup (with GPU)       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not found. Please install Docker first.${NC}"
    exit 1
fi

# Check if nvidia-smi is available (GPU support)
if command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓ NVIDIA GPU detected${NC}"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    echo ""
else
    echo -e "${YELLOW}⚠ No NVIDIA GPU detected. Ollama will use CPU (slower).${NC}"
    echo ""
fi

# Check if nvidia-docker runtime is available
if docker info 2>/dev/null | grep -q nvidia; then
    echo -e "${GREEN}✓ NVIDIA Docker runtime available${NC}"
else
    echo -e "${YELLOW}⚠ NVIDIA Docker runtime not detected.${NC}"
    echo -e "${YELLOW}   Install nvidia-container-toolkit if you have a GPU:${NC}"
    echo -e "${YELLOW}   https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html${NC}"
    echo ""
fi

# Start Ollama container
echo -e "${BLUE}Starting Ollama container...${NC}"
docker-compose up -d ollama

# Wait for Ollama to be ready
echo -e "${BLUE}Waiting for Ollama to start...${NC}"
for i in {1..30}; do
    if docker-compose exec -T ollama curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Ollama is running${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}✗ Ollama failed to start${NC}"
        echo "Check logs: docker-compose logs ollama"
        exit 1
    fi
    sleep 2
    echo -n "."
done
echo ""

# Pull LLaVA model
echo -e "${BLUE}Pulling LLaVA model (~4.7GB)...${NC}"
echo -e "${YELLOW}This may take several minutes depending on your internet speed.${NC}"
echo ""

docker-compose exec ollama ollama pull llava

echo ""
echo -e "${GREEN}✓ LLaVA model installed successfully${NC}"

# List installed models
echo ""
echo -e "${BLUE}Installed models:${NC}"
docker-compose exec ollama ollama list

# Test the model
echo ""
echo -e "${BLUE}Testing model...${NC}"
if docker-compose exec -T ollama ollama run llava "Hello" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Model is working${NC}"
else
    echo -e "${YELLOW}⚠ Model test had issues (may still work)${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Setup Complete! 🎉               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Container status:${NC}"
docker-compose ps ollama
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Start all services:"
echo -e "   ${YELLOW}docker-compose up -d${NC}"
echo ""
echo "2. Check backend health:"
echo -e "   ${YELLOW}curl http://localhost:8000/health${NC}"
echo ""
echo "3. Open dashboard:"
echo -e "   ${YELLOW}http://localhost:8050${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "   ${YELLOW}docker-compose logs ollama${NC}           # View Ollama logs"
echo -e "   ${YELLOW}docker-compose exec ollama ollama list${NC}  # List models"
echo -e "   ${YELLOW}docker-compose restart ollama${NC}        # Restart Ollama"
echo -e "   ${YELLOW}docker-compose down${NC}                  # Stop all services"
echo ""
