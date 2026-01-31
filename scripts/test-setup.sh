#!/bin/bash

# Quick test script for LLaVA setup

echo "🧪 Testing Gym AI Helper with LLaVA"
echo "===================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test 1: Ollama
echo "1. Testing Ollama..."
if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
    VERSION=$(curl -s http://localhost:11434/api/version | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    echo -e "   ${GREEN}✓ Ollama running (version $VERSION)${NC}"
else
    echo -e "   ${RED}✗ Ollama not responding${NC}"
    echo -e "   ${YELLOW}Start with: ollama serve${NC}"
    exit 1
fi

# Test 2: LLaVA model
echo "2. Checking LLaVA model..."
if ollama list | grep -q "llava"; then
    echo -e "   ${GREEN}✓ LLaVA model installed${NC}"
else
    echo -e "   ${RED}✗ LLaVA model not found${NC}"
    echo -e "   ${YELLOW}Install with: ollama pull llava${NC}"
    exit 1
fi

# Test 3: Backend
echo "3. Testing backend..."
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "   ${GREEN}✓ Backend is running${NC}"

    # Check AI provider
    PROVIDER=$(curl -s http://localhost:8000/health | grep -o '"ai_provider":"[^"]*"' | cut -d'"' -f4)
    if [ "$PROVIDER" = "llava" ]; then
        echo -e "   ${GREEN}✓ Backend configured for LLaVA${NC}"
    else
        echo -e "   ${YELLOW}⚠ Backend using provider: $PROVIDER (expected: llava)${NC}"
    fi
else
    echo -e "   ${RED}✗ Backend not responding${NC}"
    echo -e "   ${YELLOW}Start with: docker-compose up -d${NC}"
    exit 1
fi

# Test 4: GPU
echo "4. Checking GPU..."
if command -v nvidia-smi &> /dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
    GPU_MEM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -1)
    echo -e "   ${GREEN}✓ GPU detected: $GPU_NAME ($GPU_MEM)${NC}"
else
    echo -e "   ${YELLOW}⚠ nvidia-smi not found (GPU may still work)${NC}"
fi

# Test 5: Dashboard
echo "5. Checking dashboard..."
if curl -s http://localhost:8050 > /dev/null 2>&1; then
    echo -e "   ${GREEN}✓ Dashboard is running${NC}"
else
    echo -e "   ${YELLOW}⚠ Dashboard not responding${NC}"
    echo -e "   ${YELLOW}Start with: docker-compose up -d dashboard${NC}"
fi

echo ""
echo "===================================="
echo -e "${GREEN}✓ All core components are working!${NC}"
echo ""
echo "📱 Access points:"
echo "   Dashboard:  http://localhost:8050"
echo "   API Docs:   http://localhost:8000/docs"
echo "   Health:     http://localhost:8000/health"
echo ""
echo "🚀 Next steps:"
echo "   1. Open dashboard: http://localhost:8050"
echo "   2. Upload a gym equipment photo"
echo "   3. Click 'Analyze Image'"
echo "   4. View results in 2-5 seconds!"
echo ""
echo "📖 Documentation: SETUP_COMPLETE.md"
echo ""
