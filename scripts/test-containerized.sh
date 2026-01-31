#!/bin/bash

# Complete system test for containerized setup

echo "🧪 Testing Containerized Gym AI Helper"
echo "======================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

test_service() {
    NAME=$1
    COMMAND=$2

    echo -n "Testing $NAME... "
    if eval "$COMMAND" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((FAIL++))
        return 1
    fi
}

# Test 1: Docker is running
test_service "Docker daemon" "docker ps"

# Test 2: GPU access
if command -v nvidia-smi &> /dev/null; then
    test_service "NVIDIA GPU" "nvidia-smi"
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
    echo -e "   ${YELLOW}└─ GPU: $GPU_NAME${NC}"
else
    echo -e "${YELLOW}⚠ No GPU detected (will use CPU)${NC}"
fi

# Test 3: PostgreSQL
test_service "PostgreSQL" "docker-compose exec -T postgres pg_isready -U gym_user"

# Test 4: Redis
test_service "Redis" "docker-compose exec -T redis redis-cli ping"

# Test 5: Ollama
test_service "Ollama service" "curl -s http://localhost:11434/api/version"
if [ $? -eq 0 ]; then
    VERSION=$(curl -s http://localhost:11434/api/version | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    echo -e "   ${YELLOW}└─ Version: $VERSION${NC}"

    # Check if model is installed
    if docker-compose exec -T ollama ollama list | grep -q "llava"; then
        echo -e "   ${GREEN}└─ LLaVA model: installed${NC}"
        ((PASS++))
    else
        echo -e "   ${RED}└─ LLaVA model: NOT installed${NC}"
        echo -e "   ${YELLOW}   Run: docker-compose exec ollama ollama pull llava${NC}"
        ((FAIL++))
    fi
fi

# Test 6: Backend
test_service "Backend API" "curl -s http://localhost:8000/health"
if [ $? -eq 0 ]; then
    PROVIDER=$(curl -s http://localhost:8000/health | grep -o '"ai_provider":"[^"]*"' | cut -d'"' -f4)
    if [ ! -z "$PROVIDER" ]; then
        echo -e "   ${YELLOW}└─ AI Provider: $PROVIDER${NC}"
    fi
fi

# Test 7: Dashboard (optional)
if test_service "Dashboard" "curl -s http://localhost:8050" 2>/dev/null; then
    :
else
    echo -e "   ${YELLOW}└─ Start with: docker-compose up -d dashboard${NC}"
fi

# Test 8: Ollama GPU detection (inside container)
echo -n "Testing Ollama GPU access... "
if docker-compose exec -T ollama nvidia-smi > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    echo -e "   ${YELLOW}└─ GPU accessible inside container${NC}"
    ((PASS++))
else
    echo -e "${YELLOW}⚠ WARN${NC}"
    echo -e "   ${YELLOW}└─ GPU not accessible (will use CPU)${NC}"
fi

# Test 9: Network connectivity
echo -n "Testing container networking... "
if docker-compose exec -T backend curl -s http://ollama:11434/api/version > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    echo -e "   ${YELLOW}└─ Backend can reach Ollama${NC}"
    ((PASS++))
else
    echo -e "${RED}✗ FAIL${NC}"
    echo -e "   ${RED}└─ Backend cannot reach Ollama${NC}"
    ((FAIL++))
fi

# Summary
echo ""
echo "======================================="
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All systems operational!${NC}"
    echo ""
    echo "📱 Access Points:"
    echo "   Dashboard:  http://localhost:8050"
    echo "   API Docs:   http://localhost:8000/docs"
    echo "   Ollama:     http://localhost:11434"
    echo ""
    echo "🚀 Next Steps:"
    echo "   1. Open dashboard: http://localhost:8050"
    echo "   2. Upload gym equipment photo"
    echo "   3. Click 'Analyze Image'"
    echo "   4. Results in 2-5 seconds!"
    echo ""
    echo "📊 Monitor Performance:"
    echo "   docker stats              # Container resources"
    echo "   nvidia-smi -l 1          # GPU usage"
    echo "   docker-compose logs -f   # All logs"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some components need attention${NC}"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   docker-compose logs <service>  # Check logs"
    echo "   docker-compose restart         # Restart all"
    echo "   docker-compose ps              # Check status"
    echo ""
    exit 1
fi
