#!/bin/bash

# Ollama Setup Script for Gym AI Helper
# Automates Ollama installation and LLaVA model setup for self-hosted AI

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Gym AI Helper - Ollama Setup         ║${NC}"
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo ""

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo -e "${YELLOW}Warning: This script is designed for Linux.${NC}"
    echo -e "${YELLOW}For macOS: brew install ollama${NC}"
    echo -e "${YELLOW}For Windows: Download from https://ollama.com/download${NC}"
    exit 1
fi

# Check if Ollama is already installed
if command -v ollama &> /dev/null; then
    echo -e "${GREEN}✓ Ollama is already installed${NC}"
    ollama --version
else
    echo -e "${BLUE}Installing Ollama...${NC}"
    curl -fsSL https://ollama.com/install.sh | sh
    echo -e "${GREEN}✓ Ollama installed successfully${NC}"
fi

# Check GPU
echo ""
echo -e "${BLUE}Checking GPU...${NC}"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    echo -e "${GREEN}✓ NVIDIA GPU detected${NC}"
else
    echo -e "${YELLOW}⚠ No NVIDIA GPU detected. Ollama will use CPU (slower).${NC}"
fi

# Start Ollama service
echo ""
echo -e "${BLUE}Starting Ollama service...${NC}"

# Check if systemd is available
if command -v systemctl &> /dev/null; then
    # Try to start as systemd service
    if systemctl is-active --quiet ollama; then
        echo -e "${GREEN}✓ Ollama service is already running${NC}"
    else
        echo "Starting Ollama service..."
        sudo systemctl start ollama 2>/dev/null || {
            echo -e "${YELLOW}Note: Could not start as service, running manually...${NC}"
            ollama serve &
            OLLAMA_PID=$!
            sleep 3
        }
    fi
else
    # Start manually
    echo "Starting Ollama server..."
    ollama serve &
    OLLAMA_PID=$!
    sleep 3
fi

# Verify Ollama is running
echo ""
echo -e "${BLUE}Verifying Ollama connection...${NC}"
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo -e "${GREEN}✓ Ollama is running at http://localhost:11434${NC}"
else
    echo -e "${RED}✗ Cannot connect to Ollama${NC}"
    echo "Please start Ollama manually: ollama serve"
    exit 1
fi

# Pull LLaVA model
echo ""
echo -e "${BLUE}Pulling LLaVA model (~4.5GB)...${NC}"
echo -e "${YELLOW}This may take several minutes depending on your internet speed.${NC}"

if ollama list | grep -q "llava"; then
    echo -e "${GREEN}✓ LLaVA model already installed${NC}"
else
    ollama pull llava
    echo -e "${GREEN}✓ LLaVA model installed successfully${NC}"
fi

# Test the model
echo ""
echo -e "${BLUE}Testing LLaVA model...${NC}"
echo "Running test prompt..."

if ollama run llava "Hello" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ LLaVA model is working${NC}"
else
    echo -e "${RED}✗ LLaVA model test failed${NC}"
fi

# Show installed models
echo ""
echo -e "${BLUE}Installed models:${NC}"
ollama list

# Update .env file
echo ""
echo -e "${BLUE}Configuring backend...${NC}"

ENV_FILE="backend/.env"
if [ -f "$ENV_FILE" ]; then
    # Update AI_PROVIDER
    if grep -q "^AI_PROVIDER=" "$ENV_FILE"; then
        sed -i 's/^AI_PROVIDER=.*/AI_PROVIDER=llava/' "$ENV_FILE"
        echo -e "${GREEN}✓ Updated AI_PROVIDER=llava in .env${NC}"
    else
        echo "AI_PROVIDER=llava" >> "$ENV_FILE"
        echo -e "${GREEN}✓ Added AI_PROVIDER=llava to .env${NC}"
    fi

    # Ensure Ollama settings exist
    if ! grep -q "^OLLAMA_URL=" "$ENV_FILE"; then
        echo "" >> "$ENV_FILE"
        echo "# Ollama/LLaVA settings (self-hosted)" >> "$ENV_FILE"
        echo "OLLAMA_URL=http://host.docker.internal:11434" >> "$ENV_FILE"
        echo "OLLAMA_MODEL=llava" >> "$ENV_FILE"
        echo -e "${GREEN}✓ Added Ollama settings to .env${NC}"
    fi
else
    echo -e "${YELLOW}⚠ backend/.env not found. Please create it manually.${NC}"
fi

# Display next steps
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Setup Complete! 🎉            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo ""
echo "1. Verify Ollama is running:"
echo -e "   ${YELLOW}curl http://localhost:11434/api/tags${NC}"
echo ""
echo "2. Restart your backend:"
echo -e "   ${YELLOW}docker-compose restart backend${NC}"
echo ""
echo "3. Check backend health:"
echo -e "   ${YELLOW}curl http://localhost:8000/health${NC}"
echo ""
echo "4. Test with the dashboard:"
echo -e "   ${YELLOW}http://localhost:8050${NC}"
echo ""
echo -e "${BLUE}Ollama commands:${NC}"
echo -e "   ${YELLOW}ollama list${NC}              # Show installed models"
echo -e "   ${YELLOW}ollama pull llava:13b${NC}    # Install larger model (if you have VRAM)"
echo -e "   ${YELLOW}ollama run llava 'test'${NC}  # Test the model"
echo -e "   ${YELLOW}ollama serve${NC}             # Start Ollama server"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo -e "   ${YELLOW}docs/OLLAMA_SETUP.md${NC}    # Detailed setup guide"
echo ""

# Cleanup
if [ ! -z "$OLLAMA_PID" ]; then
    echo -e "${YELLOW}Note: Ollama is running in background (PID: $OLLAMA_PID)${NC}"
    echo "To stop: kill $OLLAMA_PID"
fi

echo -e "${GREEN}Happy self-hosting! 🚀${NC}"
