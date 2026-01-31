# Gym AI Helper

A Docker-based gym equipment recognition system that uses AI vision models to identify gym equipment
from photos, provides usage instructions, and recommends instructional videos.

## 📋 Table of Contents

- [Quick Start](#-quick-start-5-minutes) - Get running in 5 minutes
- [Architecture](#%EF%B8%8F-architecture) - System overview
- [Project Structure](#-project-structure) - Codebase organization
- [Development Workflow](#-development-workflow) - Local development guide
- [Testing](#-testing--quality-assurance) - Running and writing tests
- [Debugging](#-debugging--troubleshooting) - Common issues and solutions
- [AI Providers](#-ai-provider-configuration) - OpenAI, CLIP, LLaVA setup
- [Caching](#-caching-strategy) - Performance optimization
- [Security](#-security--production-deployment) - Production deployment
- [Documentation](#-additional-documentation) - Detailed guides
- [Contributing](#-contributing) - How to contribute

## 🚀 Quick Reference

```bash
# Start everything
docker-compose up --build

# Check health
curl http://localhost:8000/health

# View logs
docker-compose logs -f backend

# Run tests
docker-compose exec backend pytest

# Access services
# API: http://localhost:8000/docs
# Dashboard: http://localhost:8050

# Stop everything
docker-compose down

# Fresh start (removes all data)
docker-compose down -v && docker-compose up --build
```

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│   Flutter   │────▶│  FastAPI Backend │────▶│ PostgreSQL  │
│  Mobile App │     │   (Container)    │     │ (Container) │
└─────────────┘     └──────────────────┘     └─────────────┘
                            │  
                            ├──────────────┐  
                            ▼              ▼  
                    ┌─────────────┐  ┌─────────┐  
                    │ AI Services │  │  Redis  │  
                    │ OpenAI/CLIP │  │  Cache  │  
                    └─────────────┘  └─────────┘  

┌─────────────┐  
│    Dash     │────▶ Testing & Development
│  Dashboard  │  
└─────────────┘  
```

## 🚀 Quick Start (5 Minutes)

### Prerequisites

- **Docker** 20.10+ ([Install Docker](https://docs.docker.com/get-docker/))
- **Docker Compose** 2.0+ ([Install Compose](https://docs.docker.com/compose/install/))
- **OpenAI API Key** (or use free CLIP model) - [Get API Key](https://platform.openai.com/api-keys)
- **8GB+ RAM** recommended
- **Linux, macOS, or Windows with WSL2**

### 1. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/Asphalt2017/gym_ai.git
cd gym_ai

# Copy environment template
cp .env.example backend/.env

# Edit backend/.env and add your OpenAI API key
nano backend/.env
# OR use your preferred editor:
# code backend/.env  (VS Code)
# vim backend/.env   (Vim)
```

**Required Configuration in `backend/.env`:**

```env
# OpenAI Configuration (Recommended for accuracy)
OPENAI_API_KEY=sk-proj-your-actual-key-here  # Required if using OpenAI
AI_PROVIDER=openai                             # Or: clip, llava

# Database (defaults work for development)
DATABASE_URL=postgresql+asyncpg://gym_user:gym_dev_password@postgres:5432/gym_ai
REDIS_URL=redis://redis:6379

# Optional Settings
DEBUG=true
LOG_LEVEL=INFO
MAX_IMAGE_SIZE_MB=10
CACHE_TTL_DAYS=30
```

**Alternative: Use Free CLIP (No API Key Required)**

```env
AI_PROVIDER=clip
CLIP_MODEL_NAME=ViT-B-32
USE_GPU=false  # Set true if you have NVIDIA GPU with CUDA
```

### 2. Start All Services

```bash
# Option 1: Build and start all containers (recommended first time)
docker-compose up --build

# Option 2: Run in detached mode (background)
docker-compose up -d --build

# Option 3: Use helper script for convenience
chmod +x scripts/dev.sh
./scripts/dev.sh start
```

**What Happens During Startup:**

1. PostgreSQL initializes database (15-30 seconds)
1. Redis starts (5 seconds)
1. Backend downloads dependencies and starts (30-60 seconds)
1. Dashboard starts (10 seconds)
1. If using CLIP: Downloads ~350MB model on first run (2-5 minutes)

**Verify Everything Started:**

```bash
# Check container status
docker-compose ps

# Expected output:
# NAME                    STATUS              PORTS
# gym_ai_postgres         Up 10 seconds       0.0.0.0:5432->5432/tcp
# gym_ai_redis            Up 10 seconds       0.0.0.0:6379->6379/tcp
# gym_ai_backend          Up 10 seconds       0.0.0.0:8000->8000/tcp
# gym_ai_dashboard        Up 10 seconds       0.0.0.0:8050->8050/tcp
```

### 3. Access Services

- **Backend API**: http://localhost:8000
- **API Documentation (Swagger)**: http://localhost:8000/docs
- **Dash Dashboard** (Best for testing): http://localhost:8050
- **PostgreSQL**: localhost:5432 (user: gym_user, password: gym_dev_password)
- **Redis**: localhost:6379

### 4. Verify Installation

```bash
# Health check (should return "healthy")
curl http://localhost:8000/health

# Expected response:
# {
#   "status": "healthy",
#   "service": "Gym AI Helper",
#   "version": "1.0.0",
#   "ai_provider": "openai",
#   "ai_provider_healthy": true
# }

# Test image analysis (replace with your image path)
curl -X POST "http://localhost:8000/api/v1/analyze" \
  -H "accept: application/json" \
  -H "Content-Type: multipart/form-data" \
  -F "image=@path/to/gym_equipment.jpg"
```

### 5. Using the Test Dashboard (Easiest Way)

1. Open http://localhost:8050 in your browser
1. You should see a green "Backend is healthy" message
1. Click "Select an Image" or drag-and-drop a gym equipment photo
1. Click "Analyze Image"
1. View detailed results including:
   - Equipment name and category
   - Muscles worked
   - Step-by-step instructions
   - Common mistakes to avoid
   - Video tutorial keywords

**First Request Note**: The first analysis may take 10-30 seconds (model loading). Subsequent
requests are much faster (\<2 seconds).

## ✅ Success Checklist

After setup, verify everything is working:

- [ ] All containers running: `docker-compose ps` shows 4 services "Up"
- [ ] Backend healthy: `curl http://localhost:8000/health` returns `"healthy"`
- [ ] Dashboard accessible: http://localhost:8050 shows green status
- [ ] PostgreSQL ready: `docker-compose exec postgres pg_isready -U gym_user`
- [ ] Redis responding: `docker-compose exec redis redis-cli PING` returns `PONG`
- [ ] API docs loaded: http://localhost:8000/docs shows Swagger UI
- [ ] Successfully analyzed image via dashboard or API
- [ ] Second request faster than first (cache working)
- [ ] No errors in logs: `docker-compose logs | grep -i error`

**If all checkboxes are ✅, you're ready to develop!** 🎉

## 🎓 Learning Path

### For First-Time Users:

1. **Read** [Getting Started Guide](docs/GETTING_STARTED.md) (15 min)
1. **Start** services: `docker-compose up --build` (5 min)
1. **Test** via dashboard: http://localhost:8050 (5 min)
1. **Explore** API docs: http://localhost:8000/docs (10 min)
1. **Check** logs: `docker-compose logs -f backend` (5 min)

### For Developers:

1. **Understand** [Architecture](docs/architecture.md) (30 min)
1. **Review** codebase structure (20 min)
1. **Run** tests: `pytest` (10 min)
1. **Read** [Testing Guide](docs/TESTING.md) (20 min)
1. **Make** a test change and see hot reload (10 min)

### For DevOps/Deployment:

1. **Review** [Docker Secrets](docs/docker-secrets.md) (15 min)
1. **Study** production compose file (10 min)
1. **Understand** caching strategy (15 min)
1. **Plan** monitoring and backups (variable)

## 📊 Project Status

- ✅ **Core Features**: Complete

  - Image upload and validation
  - OpenAI/CLIP AI providers
  - Perceptual hashing cache
  - PostgreSQL + Redis storage
  - REST API with FastAPI
  - Test dashboard

- 🚧 **In Progress**:

  - LLaVA provider optimization
  - Enhanced test coverage (target: 90%+)
  - API rate limiting
  - User authentication

- 📋 **Planned**:

  - Flutter mobile app
  - Multi-equipment detection (YOLO)
  - Workout plan generation
  - Video tutorial integration
  - Real-time feedback

## 📁 Project Structure

```
gym_ai/
├── backend/                    # FastAPI application
│   ├── app/
│   │   ├── api/               # API endpoints
│   │   ├── core/              # Configuration & database
│   │   ├── models/            # SQLAlchemy models
│   │   ├── schemas/           # Pydantic schemas
│   │   ├── services/          # Business logic
│   │   │   ├── ai/           # AI provider abstraction
│   │   │   └── ...
│   │   └── main.py           # FastAPI entry point
│   ├── Dockerfile
│   ├── requirements.txt
│   └── README.md
│
├── web-dashboard/             # Dash web interface
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
│
├── database/                  # Database initialization
│   ├── init.sql              # Schema definition
│   ├── seed.sql              # Initial data
│   └── README.md
│
├── scripts/                   # Utility scripts
│   └── dev.sh
│
├── docs/                      # Documentation
│   ├── architecture.md
│   ├── docker-secrets.md
│   └── api.md
│
├── docker-compose.yml         # Development setup
├── docker-compose.prod.yml    # Production setup
└── .env.example              # Environment template
```

## 🔧 Development Workflow

### Local Development Setup

#### Option 1: Docker Development (Recommended)

```bash
# Start all services with hot reload
docker-compose up

# Backend auto-reloads when you edit files in backend/app/
# No need to rebuild or restart!

# Edit code in your favorite editor
code backend/app/api/v1/endpoints/analysis.py
vim backend/app/services/cache_service.py

# Changes are reflected immediately in running container
```

#### Option 2: Local Python Development

```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# OR: venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-test.txt

# Start PostgreSQL and Redis in Docker
docker-compose up postgres redis -d

# Run backend locally (with hot reload)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# In another terminal, run tests
pytest --cov=app tests/
```

### Making Code Changes

#### 1. Adding a New AI Provider

```bash
# 1. Create provider class
touch backend/app/services/ai/providers/new_provider.py

# 2. Implement BaseAIProvider interface
# See backend/app/services/ai/base.py for interface
# See openai_provider.py or clip_provider.py for examples

# 3. Add to factory
nano backend/app/services/ai/factory.py
# Add case in _create_provider() method

# 4. Add configuration
nano backend/app/core/config.py
# Add provider-specific settings

# 5. Write tests
nano backend/tests/test_ai_providers.py

# 6. Test your changes
pytest tests/test_ai_providers.py -v
```

**Example new provider structure:**

```python
# backend/app/services/ai/providers/new_provider.py
from app.services.ai.base import BaseAIProvider, AnalysisResult


class NewProvider(BaseAIProvider):
    async def initialize(self) -> None:
        """Load models, setup connections."""
        pass

    async def analyze_image(
        self, image_data: bytes, prompt: str | None = None
    ) -> AnalysisResult:
        """Analyze gym equipment image."""
        # Your implementation here
        pass

    async def health_check(self) -> bool:
        """Check provider health."""
        return True
```

#### 2. Adding a New API Endpoint

```bash
# 1. Add endpoint to router
nano backend/app/api/v1/endpoints/analysis.py

# 2. Add Pydantic schemas (if needed)
nano backend/app/schemas/analysis.py

# 3. Add business logic to service
nano backend/app/services/cache_service.py

# 4. Write tests
nano backend/tests/test_api_endpoints.py

# 5. Test endpoint
pytest tests/test_api_endpoints.py::test_new_endpoint -v

# 6. Manual test via Swagger
# Open http://localhost:8000/docs
```

**Example new endpoint:**

```python
@router.get("/equipment/{equipment_id}")
async def get_equipment_by_id(
    equipment_id: str, db: AsyncSession = Depends(get_db)
) -> EquipmentSchema:
    """Get equipment details by ID."""
    equipment = await db.get(Equipment, equipment_id)
    if not equipment:
        raise HTTPException(status_code=404, detail="Equipment not found")
    return equipment
```

#### 3. Modifying Database Schema

```bash
# 1. Update SQLAlchemy models
nano backend/app/models/analysis.py

# 2. Create Alembic migration (future feature)
# alembic revision --autogenerate -m "Add new column"

# 3. For now: Update init.sql
nano database/init.sql

# 4. Recreate database
docker-compose down -v
docker-compose up postgres -d
sleep 10
docker-compose up backend -d

# 5. Verify schema
docker-compose exec postgres psql -U gym_user -d gym_ai -c "\d+ equipment"
```

### Code Quality & Pre-commit Hooks

#### Setting Up Pre-commit

Pre-commit hooks automatically check code quality before each commit. The project is configured for
Python 3.13 with the `llm13` conda environment.

```bash
# Activate llm13 environment
source .activate-llm13.sh
# OR manually
conda activate llm13

# Verify environment
which python    # Should show: /home/roudra/anaconda3/envs/llm13/bin/python
which pre-commit

# Run pre-commit on all files
pre-commit run --all-files

# Run pre-commit on specific files
pre-commit run --files backend/app/main.py

# Update hooks to latest versions
pre-commit autoupdate
```

#### What Pre-commit Checks

The configuration (`.pre-commit-config.yaml`) includes:

**General Checks:**

- Trailing whitespace removal
- End-of-file fixing
- YAML, JSON, TOML validation
- Large file detection (>10MB)
- Merge conflict detection
- Private key detection

**Python Code Quality:**

- **Black** - Code formatting (100 char lines)
- **isort** - Import sorting
- **flake8** - Linting and style
- **mypy** - Type checking
- **bandit** - Security vulnerability scanning
- **pyupgrade** - Python 3.13+ syntax upgrades
- **pydocstyle** - Docstring validation

**Documentation:**

- **YAML** formatting
- **Markdown** formatting

#### Using Pre-commit

```bash
# Pre-commit runs automatically on git commit
git add backend/app/main.py
git commit -m "Update main.py"
# Hooks will run automatically

# To skip hooks (not recommended)
git commit --no-verify -m "Skip hooks"

# Manual run before committing
pre-commit run --all-files

# Run specific hook
pre-commit run black --all-files
pre-commit run flake8 --all-files
```

**Note:** Always work in the `llm13` conda environment when using pre-commit to ensure Python 3.13
compatibility.

### Running Individual Services

```bash
# Start only specific services
docker-compose up postgres redis  # Just database and cache
docker-compose up backend         # Just backend (requires postgres/redis)
docker-compose up dashboard       # Just dashboard (requires backend)

# Rebuild specific service
docker-compose up --build backend

# Restart without rebuilding
docker-compose restart backend

# Stop specific service
docker-compose stop backend

# Remove and recreate service
docker-compose rm -f backend
docker-compose up backend
```

### Viewing Logs & Debugging

```bash
# Real-time logs (all services)
docker-compose logs -f

# Specific service
docker-compose logs -f backend

# Last N lines
docker-compose logs --tail=50 backend

# Save logs to file
docker-compose logs backend > backend_logs.txt

# Filter logs by level
docker-compose logs backend | grep ERROR
docker-compose logs backend | grep -E "INFO|WARNING"

# Follow logs with grep
docker-compose logs -f backend | grep "Cache"
```

### Database Management

#### Accessing PostgreSQL

```bash
# Method 1: psql command
docker-compose exec postgres psql -U gym_user -d gym_ai

# Common psql commands:
\dt                           # List tables
\d+ equipment                 # Describe table
\l                            # List databases
\du                           # List users
\q                            # Quit

# Method 2: Direct SQL
docker-compose exec postgres psql -U gym_user -d gym_ai -c "SELECT * FROM equipment LIMIT 5;"
```

#### Useful Database Queries

```sql
-- View all equipment
SELECT id, name, category FROM equipment;

-- Check cache entries
SELECT image_hash, created_at, ttl_expires_at
FROM equipment_cache
ORDER BY created_at DESC
LIMIT 10;

-- Count cache entries by day
SELECT DATE(created_at), COUNT(*)
FROM equipment_cache
GROUP BY DATE(created_at);

-- Find expired cache entries
SELECT COUNT(*) FROM equipment_cache
WHERE ttl_expires_at < NOW();

-- Clear expired cache
DELETE FROM equipment_cache WHERE ttl_expires_at < NOW();

-- Check database size
SELECT pg_size_pretty(pg_database_size('gym_ai'));
```

#### Database Backup & Restore

```bash
# Backup database
docker-compose exec postgres pg_dump -U gym_user gym_ai > backup_$(date +%Y%m%d).sql

# Restore database
cat backup_20260117.sql | docker-compose exec -T postgres psql -U gym_user -d gym_ai

# Backup specific table
docker-compose exec postgres pg_dump -U gym_user -d gym_ai -t equipment_cache > cache_backup.sql
```

### Redis Cache Management

```bash
# Access Redis CLI
docker-compose exec redis redis-cli

# Common Redis commands:
PING                    # Test connection
KEYS *                  # List all keys (dev only!)
GET key_name           # Get value
TTL key_name           # Check time-to-live
FLUSHALL               # Clear all keys (careful!)
INFO                   # Server info
DBSIZE                 # Number of keys

# From command line
docker-compose exec redis redis-cli PING
docker-compose exec redis redis-cli KEYS "cache:*"
docker-compose exec redis redis-cli FLUSHALL  # Clear cache
```

### Testing Workflow

```bash
# 1. Run tests before making changes
pytest -v

# 2. Make code changes
nano backend/app/services/image_service.py

# 3. Run related tests
pytest tests/test_image_service.py -v

# 4. Run all tests to ensure nothing broke
pytest

# 5. Check coverage
pytest --cov=app --cov-report=html
open htmlcov/index.html

# 6. Run linters
black backend/app backend/tests
isort backend/app backend/tests
flake8 backend/app

# 7. Commit changes
git add .
git commit -m "feat: improve image validation"
git push
```

### Helper Scripts

The `scripts/dev.sh` provides convenient shortcuts:

```bash
# Make executable (first time only)
chmod +x scripts/dev.sh

# View available commands
./scripts/dev.sh help

# Start services
./scripts/dev.sh start          # Start all services in background
./scripts/dev.sh stop           # Stop all services
./scripts/dev.sh restart        # Restart all services

# View logs
./scripts/dev.sh logs           # All service logs
./scripts/dev.sh logs-backend   # Backend logs only
./scripts/dev.sh logs-dashboard # Dashboard logs only

# Database
./scripts/dev.sh db-shell       # Open PostgreSQL shell

# Backend
./scripts/dev.sh backend-shell  # Open backend container shell
./scripts/dev.sh test          # Run backend tests

# Maintenance
./scripts/dev.sh clean          # Remove all containers & volumes
./scripts/dev.sh reset          # Clean + rebuild + start
./scripts/dev.sh status         # Show container status
```

### Environment Variables

Key configuration options in `backend/.env`:

```bash
# AI Provider Selection
AI_PROVIDER=openai              # Options: openai, clip, llava

# OpenAI Settings
OPENAI_API_KEY=sk-proj-...     # Your API key
OPENAI_MODEL=gpt-4-vision-preview

# CLIP Settings
CLIP_MODEL_NAME=ViT-B-32       # Model architecture
CLIP_PRETRAINED=openai         # Weights source
USE_GPU=false                  # Enable GPU acceleration

# Database
DATABASE_URL=postgresql+asyncpg://gym_user:gym_dev_password@postgres:5432/gym_ai

# Cache
REDIS_URL=redis://redis:6379
ENABLE_REDIS_CACHE=true
CACHE_TTL_DAYS=30
CACHE_SIMILARITY_THRESHOLD=5   # Hamming distance for similar images

# Image Processing
MAX_IMAGE_SIZE_MB=10
SUPPORTED_IMAGE_FORMATS=jpg,jpeg,png,webp

# Application
DEBUG=true
LOG_LEVEL=INFO                 # DEBUG, INFO, WARNING, ERROR, CRITICAL
APP_NAME=Gym AI Helper

# Security (production)
SECRET_KEY=change-this-in-production
USE_DOCKER_SECRETS=false       # Enable for production
```

### Hot Reload Development

The Docker setup includes hot reload for rapid development:

```bash
# Start services
docker-compose up

# Edit any file in backend/app/
nano backend/app/api/v1/endpoints/analysis.py

# Backend automatically reloads!
# Watch terminal for: "Reloading..."
# No need to restart container

# If hot reload stops working:
docker-compose restart backend
```

**What triggers reload:**

- Python files in `backend/app/`
- Changes to `.py` files
- Saved changes (not just edits)

**What doesn't trigger reload:**

- Changes to `requirements.txt` (need rebuild)
- Changes to `.env` (need restart)
- Changes to Docker files (need rebuild)

### Code Style & Formatting

```bash
cd backend

# Auto-format code with Black
black app tests

# Sort imports
isort app tests

# Check style compliance
flake8 app --count --statistics

# Type checking
mypy app

# Run all formatting
black app tests && isort app tests && flake8 app
```

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/new-provider

# Make changes and commit frequently
git add backend/app/services/ai/providers/new_provider.py
git commit -m "feat: add new AI provider"

# Run tests before pushing
pytest

# Push to remote
git push -u origin feature/new-provider

# Create pull request on GitHub
# CI/CD will automatically run tests
```

### Performance Profiling

```bash
# Profile API endpoint
docker-compose exec backend python -m cProfile -o profile.stats -m pytest tests/test_api_endpoints.py

# Analyze profile
docker-compose exec backend python -c "
import pstats
p = pstats.Stats('profile.stats')
p.sort_stats('cumulative')
p.print_stats(20)
"

# Memory profiling (install memory_profiler)
pip install memory_profiler
python -m memory_profiler backend/app/services/image_service.py
```

## 🤖 AI Provider Configuration

### Option 1: OpenAI (Recommended for Production)

```env
AI_PROVIDER=openai
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4-vision-preview
```

**Pros**: High accuracy, detailed instructions, no GPU required\
**Cons**: Pay-per-token cost
(~$0.01-0.03 per image)

### Option 2: Open-Source CLIP (Cost-Effective)

```env
AI_PROVIDER=clip
CLIP_MODEL_NAME=ViT-B-32
CLIP_PRETRAINED=openai
USE_GPU=false
```

**Pros**: Free inference, good equipment classification\
**Cons**: Requires pre-trained categories,
less detailed instructions

### Option 3: LLaVA (Self-Hosted)

```env
AI_PROVIDER=llava
USE_GPU=true
GPU_DEVICE=cuda:0
```

**Pros**: Multimodal understanding, detailed text generation\
**Cons**: Requires GPU, higher
resource usage

## 🔒 Security & Production Deployment

### Using Docker Secrets (Recommended for Production)

```bash
# Create secrets
echo "your_openai_key" | docker secret create openai_api_key -
echo "secure_db_password" | docker secret create db_password -

# Deploy with production config
docker-compose -f docker-compose.prod.yml up -d
```

### Environment Variables

Never commit `.env` files to version control. Use `.env.example` as a template.

### Network Isolation

Production setup uses separate networks:

- `backend_network`: Internal (Postgres, Redis, Backend)
- `frontend_network`: Public-facing (Dashboard, API Gateway)

See [docs/docker-secrets.md](docs/docker-secrets.md) for detailed security configuration.

## 📊 Caching Strategy

The system implements multi-layer caching to minimize AI API costs:

1. **PostgreSQL Cache**: Permanent storage of analysis results

   - Uses perceptual image hashing (pHash) to detect similar images
   - 30-day TTL for cache entries
   - Indexed for fast lookups

1. **Redis Cache**: In-memory caching for frequent requests

   - TTL: 1 hour
   - Stores recent API responses

1. **Model Cache**: Persistent volume for AI model weights

   - Prevents re-downloading models on container restart
   - Mounted at `/app/model_cache`

## 🐛 Debugging & Troubleshooting

### Quick Debugging Commands

```bash
# View all logs in real-time
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f postgres
docker-compose logs -f redis
docker-compose logs -f dashboard

# View last 100 lines
docker-compose logs --tail=100 backend

# Check container status
docker-compose ps

# Restart specific service
docker-compose restart backend

# Stop everything
docker-compose down

# Nuclear option: Clean everything and restart
docker-compose down -v
docker-compose up --build
```

### Common Issues & Solutions

#### ❌ Issue 1: Backend Fails to Start

**Symptoms:**

- Container exits immediately
- Error: "Failed to connect to database"
- Health check returns 404

**Debug Steps:**

```bash
# 1. Check backend logs
docker-compose logs backend

# 2. Look for specific errors
docker-compose logs backend | grep ERROR
docker-compose logs backend | grep CRITICAL

# 3. Verify .env file exists
ls -la backend/.env

# 4. Check environment variables
docker-compose exec backend env | grep OPENAI
docker-compose exec backend env | grep DATABASE
```

**Solutions:**

**Missing .env file:**

```bash
cp .env.example backend/.env
nano backend/.env  # Add OPENAI_API_KEY
docker-compose restart backend
```

**Invalid OpenAI API key:**

```bash
# Test API key directly
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"

# If invalid, update backend/.env with correct key
# Then restart: docker-compose restart backend
```

**Database not ready:**

```bash
# Wait for database initialization
docker-compose logs postgres | grep "ready to accept connections"

# If not ready, restart postgres
docker-compose restart postgres
sleep 10
docker-compose restart backend
```

**Port conflict:**

```bash
# Check if port 8000 is in use
lsof -i :8000  # Linux/Mac
netstat -ano | findstr :8000  # Windows

# Kill conflicting process or change port in docker-compose.yml
# Change: "8000:8000" to "8001:8000"
```

______________________________________________________________________

#### ❌ Issue 2: Database Connection Errors

**Symptoms:**

- Error: `asyncpg.exceptions.InvalidCatalogNameError`
- Error: `FATAL: database "gym_ai" does not exist`
- Connection refused errors

**Debug Steps:**

```bash
# 1. Check if PostgreSQL is running
docker-compose ps postgres

# 2. Check PostgreSQL logs
docker-compose logs postgres | tail -50

# 3. Try connecting directly
docker-compose exec postgres psql -U gym_user -d gym_ai
```

**Solutions:**

**Database not initialized:**

```bash
# Stop everything and remove volumes
docker-compose down -v

# Start only PostgreSQL
docker-compose up postgres -d

# Wait for initialization (check logs)
docker-compose logs -f postgres
# Look for: "database system is ready to accept connections"

# Once ready, start other services
docker-compose up -d
```

**Connection string error:**

```bash
# Verify DATABASE_URL in backend/.env
# Should be: postgresql+asyncpg://gym_user:gym_dev_password@postgres:5432/gym_ai
# Note: Use 'postgres' as hostname (Docker service name), not 'localhost'

# Restart backend after fixing
docker-compose restart backend
```

**Check database contents:**

```bash
# Open PostgreSQL shell
docker-compose exec postgres psql -U gym_user -d gym_ai

# List tables
\dt

# Check equipment table
SELECT COUNT(*) FROM equipment;

# Check cache table
SELECT COUNT(*) FROM equipment_cache;

# Exit
\q
```

______________________________________________________________________

#### ❌ Issue 3: OpenAI API Errors

**Symptoms:**

- Error: `openai.error.AuthenticationError`
- Error: `openai.error.RateLimitError`
- Error: `openai.error.Timeout`

**Debug Steps:**

```bash
# 1. Verify API key in container
docker-compose exec backend python -c "import os; print(os.getenv('OPENAI_API_KEY')[:20])"

# 2. Check OpenAI provider logs
docker-compose logs backend | grep -i openai

# 3. Test API key validity
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer YOUR_OPENAI_KEY"
```

**Solutions:**

**Invalid API key:**

```bash
# Get new key from: https://platform.openai.com/api-keys
# Update backend/.env
nano backend/.env  # Set OPENAI_API_KEY=sk-proj-...
docker-compose restart backend
```

**Rate limit exceeded:**

```bash
# Option 1: Wait (rate limits reset)
# Option 2: Switch to CLIP (free, no API limits)

# Edit backend/.env
AI_PROVIDER=clip
CLIP_MODEL_NAME=ViT-B-32
USE_GPU=false

# Restart backend
docker-compose restart backend
```

**Network timeout:**

```bash
# Increase timeout in backend/app/services/ai/providers/openai_provider.py
# Or check internet connection:
ping api.openai.com

# Check Docker network
docker network inspect gym_ai_default
```

______________________________________________________________________

#### ❌ Issue 4: CLIP Model Download Issues

**Symptoms:**

- Hangs on "Loading CLIP model..."
- Error: "Failed to download model"
- Timeout during model initialization

**Debug Steps:**

```bash
# 1. Check backend logs during initialization
docker-compose logs backend | grep -i clip

# 2. Check model cache volume
docker volume ls | grep model_cache
docker volume inspect gym_ai_model_cache

# 3. Check available disk space
df -h
```

**Solutions:**

**Download timeout:**

```bash
# Increase Docker build timeout
# Or manually pre-download model:
docker-compose exec backend python -c "
import clip
model, preprocess = clip.load('ViT-B-32', device='cpu')
print('Model loaded successfully')
"

# Restart backend after successful download
docker-compose restart backend
```

**No internet connection:**

```bash
# Test connection to Hugging Face
ping huggingface.co

# Check Docker DNS settings
docker-compose exec backend cat /etc/resolv.conf
```

**Insufficient disk space:**

```bash
# Check space
df -h

# Clean Docker resources
docker system prune -a
docker volume prune

# Keep model_cache volume (don't delete)
```

______________________________________________________________________

#### ❌ Issue 5: Dashboard Can't Connect to Backend

**Symptoms:**

- Red alert: "Cannot connect to backend"
- Dashboard loads but analysis fails
- Network error in browser console

**Debug Steps:**

```bash
# 1. Verify backend is running
curl http://localhost:8000/health

# 2. Check dashboard logs
docker-compose logs dashboard | grep -i error

# 3. Check backend URL setting
docker-compose exec dashboard env | grep BACKEND_URL
```

**Solutions:**

**Backend not running:**

```bash
docker-compose restart backend
docker-compose logs -f backend  # Wait for "Application startup complete"
```

**Wrong backend URL:**

```bash
# In docker-compose.yml, dashboard should have:
# environment:
#   - BACKEND_URL=http://backend:8000
# NOT http://localhost:8000 (that's from outside Docker)

# Restart dashboard
docker-compose restart dashboard
```

**Browser access issue:**

```bash
# Verify you can access from host machine:
curl http://localhost:8000/health

# If not, check port mapping in docker-compose.yml:
# ports:
#   - "8000:8000"  # Should map host 8000 to container 8000
```

______________________________________________________________________

#### ❌ Issue 6: Slow First Request

**Symptoms:**

- First image analysis takes 20+ seconds
- Timeout errors on first request
- Subsequent requests are fast

**This is Normal!** Here's why:

**OpenAI Provider:**

- Cold start of AI service: ~2-3 seconds
- API call to OpenAI: ~1-2 seconds
- Database initialization: ~0.5 seconds
- **Total first request: 3-5 seconds** ✅

**CLIP Provider:**

- Model loading: ~10-30 seconds (first time only)
- Model inference: ~0.5 seconds
- **Total first request: 10-30 seconds** ✅
- **Subsequent requests: \<1 second** 🚀

**LLaVA Provider:**

- Model loading: ~30-60 seconds (first time only, large model)
- Inference: ~2-5 seconds
- **Total first request: 30-60 seconds** ✅

**Solutions:**

**Increase dashboard timeout:**

```python
# In web-dashboard/app.py, increase timeout:
response = httpx.post(API_ENDPOINT, files=files, timeout=60.0)  # 60 seconds
```

**Pre-warm models:**

```bash
# After starting services, make a test request
curl -X POST "http://localhost:8000/api/v1/analyze" \
  -F "image=@test_image.jpg"

# Now models are loaded, subsequent requests are fast
```

______________________________________________________________________

#### ❌ Issue 7: Cache Not Working

**Symptoms:**

- Every request shows `"cached": false`
- AI API called for identical images
- High OpenAI costs

**Debug Steps:**

```bash
# 1. Check cache service logs
docker-compose logs backend | grep -i cache

# 2. Check database cache table
docker-compose exec postgres psql -U gym_user -d gym_ai -c "SELECT COUNT(*) FROM equipment_cache;"

# 3. Verify Redis is running
docker-compose ps redis
redis-cli ping  # Should return "PONG"
```

**Solutions:**

**Cache disabled:**

```bash
# Check backend/.env
grep CACHE backend/.env
# Should have: ENABLE_REDIS_CACHE=true (or omit for default true)

# Restart backend
docker-compose restart backend
```

**Database cache issues:**

```bash
# Check cache entries
docker-compose exec postgres psql -U gym_user -d gym_ai

SELECT image_hash, created_at, ttl_expires_at
FROM equipment_cache
ORDER BY created_at DESC
LIMIT 5;

# If TTL expired, cache won't be used
# Check: CACHE_TTL_DAYS in backend/.env (default 30)
```

**Redis connection issues:**

```bash
# Test Redis connection
docker-compose exec backend python -c "
import redis
r = redis.from_url('redis://redis:6379')
print(r.ping())  # Should print True
"

# Check REDIS_URL in backend/.env
# Should be: redis://redis:6379
```

______________________________________________________________________

### Debugging Tools & Techniques

#### 1. Interactive Shell Access

```bash
# Backend Python shell
docker-compose exec backend python

# Then in Python:
>>> from app.core.database import engine
>>> from app.services.ai.factory import AIServiceFactory
>>> factory = AIServiceFactory()
>>> # Test your code interactively
```

```bash
# Backend Bash shell
docker-compose exec backend /bin/bash

# Now you're inside container, can run:
ls -la
cat .env
python -m pytest
```

```bash
# PostgreSQL shell
docker-compose exec postgres psql -U gym_user -d gym_ai

# Common queries:
\dt                    # List tables
\d+ equipment         # Describe equipment table
SELECT * FROM equipment LIMIT 5;
```

#### 2. Enable Debug Logging

```bash
# In backend/.env
DEBUG=true
LOG_LEVEL=DEBUG

# Restart backend
docker-compose restart backend

# View detailed logs
docker-compose logs -f backend
```

#### 3. Test Individual Components

```bash
# Test image service
docker-compose exec backend python -c "
from app.services.image_service import ImageService
svc = ImageService()
print('ImageService initialized:', svc)
"

# Test database connection
docker-compose exec backend python -c "
from app.core.database import engine
print('Database engine:', engine)
"

# Test AI provider
docker-compose exec backend python -c "
import asyncio
from app.services.ai.factory import AIServiceFactory

async def test():
    factory = AIServiceFactory()
    provider = await factory.get_provider('openai')
    healthy = await provider.health_check()
    print(f'Provider healthy: {healthy}')

asyncio.run(test())
"
```

#### 4. Monitor Resource Usage

```bash
# Container resource usage
docker stats

# Specific container
docker stats gym_ai_backend

# Disk usage
docker system df

# Volume usage
docker volume ls
docker volume inspect gym_ai_model_cache
```

#### 5. Network Debugging

```bash
# Check Docker network
docker network ls
docker network inspect gym_ai_default

# Test connectivity between containers
docker-compose exec backend ping postgres
docker-compose exec backend ping redis

# Check listening ports
docker-compose exec backend netstat -tlnp
```

______________________________________________________________________

### Getting Help

#### 1. Collect Diagnostic Information

```bash
# Run this script to collect debug info
cat > debug_info.sh << 'EOF'
#!/bin/bash
echo "=== Docker Compose Version ==="
docker-compose version

echo "=== Container Status ==="
docker-compose ps

echo "=== Backend Logs (last 50 lines) ==="
docker-compose logs --tail=50 backend

echo "=== PostgreSQL Status ==="
docker-compose exec postgres pg_isready -U gym_user

echo "=== Environment Check ==="
docker-compose exec backend env | grep -E "AI_PROVIDER|OPENAI_API_KEY|DATABASE_URL"

echo "=== Disk Space ==="
df -h

echo "=== Docker Disk Usage ==="
docker system df
EOF

chmod +x debug_info.sh
./debug_info.sh > debug_output.txt
```

#### 2. Check Documentation

- [Architecture](docs/architecture.md) - System design and components
- [Testing Guide](docs/TESTING.md) - Comprehensive testing documentation
- [Getting Started](docs/GETTING_STARTED.md) - Step-by-step setup
- [Docker Secrets](docs/docker-secrets.md) - Security configuration
- [Backend README](backend/README.md) - Backend-specific details
- [Database README](database/README.md) - Schema and queries

#### 3. Common Log Patterns to Look For

```bash
# Successful startup
docker-compose logs backend | grep "Application startup complete"

# OpenAI API calls
docker-compose logs backend | grep "OpenAI"

# Cache operations
docker-compose logs backend | grep -E "Cache hit|Cache miss"

# Errors
docker-compose logs backend | grep -E "ERROR|CRITICAL|Exception"

# Database queries
docker-compose logs backend | grep "SELECT"
```

#### 4. Reset to Fresh State

```bash
# Complete reset (loses all data)
docker-compose down -v              # Stop and remove volumes
docker system prune -a --volumes    # Clean everything (optional)
rm -rf backend/__pycache__          # Clean Python cache
docker-compose up --build           # Rebuild and start fresh
```

______________________________________________________________________

### Performance Optimization Tips

#### 1. Speed Up Development

```bash
# Use mounted volumes for hot reload (already configured)
# Edit files in backend/app/ - changes auto-reload!

# Skip rebuilding unchanged services
docker-compose up backend  # Only start what changed
```

#### 2. Reduce Docker Build Time

```bash
# Use BuildKit for faster builds
DOCKER_BUILDKIT=1 docker-compose build

# Or set in environment permanently:
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
```

#### 3. Optimize AI Provider

```bash
# For faster responses (trade accuracy for speed):
# OpenAI: Use GPT-3.5 instead of GPT-4
OPENAI_MODEL=gpt-3.5-turbo-vision

# CLIP: Use smaller model
CLIP_MODEL_NAME=ViT-B-32  # Good balance
# Or: ViT-B-16 (faster, less accurate)
```

#### 4. Monitor and Tune Cache

```bash
# Check cache hit rate
docker-compose logs backend | grep -c "Cache hit"
docker-compose logs backend | grep -c "Cache miss"

# Calculate hit rate percentage
# High hit rate (>80%) = good caching
```

______________________________________________________________________

### Still Having Issues?

1. **Search existing issues**: [GitHub Issues](https://github.com/Asphalt2017/gym_ai/issues)
1. **Check logs first**: `docker-compose logs -f`
1. **Try fresh start**: `docker-compose down -v && docker-compose up --build`
1. **Open new issue**: Include `debug_output.txt` from diagnostic script above

**Include in your bug report:**

- OS and Docker version
- Full error message and logs
- Steps to reproduce
- Output of `docker-compose ps`
- Content of `backend/.env` (hide API keys!)

______________________________________________________________________

## ❓ Frequently Asked Questions (FAQ)

### General Questions

**Q: Do I need an OpenAI API key?**\
A: No! You can use the free CLIP model. Set `AI_PROVIDER=clip`
in `backend/.env`. OpenAI is more accurate but costs ~$0.01-0.03 per image.

**Q: How much does it cost to run?**\
A: **Free** if using CLIP. With OpenAI: ~$0.01-0.03 per image
(cached results are free). Infrastructure: Free locally, ~$50-100/month on cloud.

**Q: Can I use this without Docker?**\
A: Yes, but not recommended. You'll need to manually install
PostgreSQL, Redis, Python 3.11+, and all dependencies. Docker is much easier.

**Q: How accurate is the equipment identification?**\
A: **OpenAI GPT-4 Vision**: 95%+ accuracy.
**CLIP**: 85-90% accuracy for common equipment. **LLaVA**: 90%+ accuracy (experimental).

### Setup & Performance

**Q: First request takes 30+ seconds, is this normal?**\
A: **Yes!** First request loads AI models.
OpenAI: 2-5s, CLIP: 10-30s, LLaVA: 30-60s. **Subsequent requests**: \<1s ✅

**Q: How do I know everything is working?**\
A: Run: `curl http://localhost:8000/health` → should
return `{"status": "healthy"}`. Check dashboard at http://localhost:8050 for green status.

**Q: Do I need a GPU?**\
A: **No** for OpenAI (cloud-based). **No** for CLIP (runs on CPU).
**Recommended** for LLaVA (faster).

### Troubleshooting

**Q: I get "port already in use" error**\
A: Change port in `docker-compose.yml`: `"8000:8000"` →
`"8001:8000"`

**Q: Database won't initialize**\
A: Run: `docker-compose down -v && docker-compose up postgres -d`
then wait 30 seconds.

**Q: Tests are failing**\
A: Run `cd backend && pytest -v` to see details. Check logs with
`docker-compose logs backend`.

**Q: Hot reload stopped working**\
A: Restart: `docker-compose restart backend`

For more FAQs, see [Getting Started Guide](docs/GETTING_STARTED.md).

______________________________________________________________________

## 🧪 Testing & Quality Assurance

### Quick Test Overview

```bash
cd backend

# Activate virtual environment (if testing locally)
python -m venv venv
source venv/bin/activate  # Linux/Mac
# OR: venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-test.txt

# Run all tests
pytest

# Run with coverage report
pytest --cov=app --cov-report=html --cov-report=term
```

### Test Categories & Markers

The test suite uses pytest markers for organized test execution:

```bash
# Unit tests - Fast, isolated, no external dependencies (23 tests)
pytest -m unit -v

# Integration tests - Require DB/Redis/AI services (18 tests)
pytest -m integration -v

# Database tests - SQLAlchemy model operations (12 tests)
pytest -m db -v

# Cache tests - Perceptual hashing and cache logic (13 tests)
pytest -m cache -v

# API tests - Full endpoint workflows (15 tests)
pytest -m api -v

# AI provider tests - OpenAI/CLIP/LLaVA integration (18 tests)
pytest -m ai -v

# Exclude slow tests (recommended for quick feedback)
pytest -m "not slow" -v

# Run only failed tests from last run
pytest --lf

# Run failed tests first, then all others
pytest --ff
```

### Running Tests in Docker

```bash
# Run tests inside backend container
docker-compose exec backend pytest

# With coverage
docker-compose exec backend pytest --cov=app --cov-report=html

# Specific test file
docker-compose exec backend pytest tests/test_image_service.py

# Specific test
docker-compose exec backend pytest tests/test_image_service.py::TestImageService::test_validate_image_success

# Verbose output with print statements
docker-compose exec backend pytest -v -s
```

### Test Structure

```
backend/tests/
├── conftest.py                 # Shared fixtures (db, client, mocks, samples)
│                               # - test_settings, db_session, client
│                               # - sample_image, mock_ai_provider
│                               # - equipment_database_entries
│
├── test_image_service.py       # Image validation & preprocessing
│   ├── test_validate_image_success
│   ├── test_validate_image_too_large
│   ├── test_validate_image_invalid_format
│   ├── test_preprocess_converts_rgba_to_rgb
│   └── ... (19 more tests)
│
├── test_cache_service.py       # Perceptual hashing & cache logic
│   ├── test_compute_image_hash
│   ├── test_cache_hit_exact_match
│   ├── test_cache_hit_similar_image
│   ├── test_hamming_distance_calculation
│   └── ... (9 more tests)
│
├── test_ai_providers.py        # AI provider implementations
│   ├── test_openai_provider_initialization
│   ├── test_clip_provider_encoding
│   ├── test_factory_get_provider
│   ├── test_provider_health_check
│   └── ... (14 more tests)
│
├── test_api_endpoints.py       # FastAPI endpoint integration
│   ├── test_health_endpoint_success
│   ├── test_analyze_endpoint_success
│   ├── test_analyze_endpoint_cache_hit
│   ├── test_analyze_endpoint_invalid_image
│   └── ... (11 more tests)
│
└── test_database.py            # SQLAlchemy models & queries
    ├── test_equipment_model_creation
    ├── test_equipment_cache_model
    ├── test_cache_ttl_expiration
    └── ... (9 more tests)
```

**Total: 81+ comprehensive tests** with >80% code coverage

### Coverage Requirements

- **Overall Target**: 80% minimum (enforced in CI/CD)
- **Unit Tests**: 90%+ coverage expected
- **Integration Tests**: 80%+ coverage expected
- **Critical Paths**: 100% coverage (auth, data loss prevention)

**View Coverage Report:**

```bash
# Generate HTML coverage report
pytest --cov=app --cov-report=html

# Open in browser
open htmlcov/index.html  # Mac
xdg-open htmlcov/index.html  # Linux
start htmlcov/index.html  # Windows
```

### CI/CD Pipeline

Every push and pull request triggers automated testing:

1. **Linting & Formatting**

   - `flake8` - PEP 8 style enforcement
   - `black` - Code formatting check
   - `isort` - Import sorting validation
   - `mypy` - Static type checking

1. **Unit Tests**

   - Fast, isolated component tests
   - Mocked external dependencies
   - Target: \<1 minute execution

1. **Integration Tests**

   - Database operations
   - API endpoint workflows
   - Cache functionality

1. **Coverage Analysis**

   - Minimum 80% coverage required
   - Reports uploaded to Codecov
   - Pull requests blocked if coverage drops

1. **Security Scanning**

   - `bandit` - Python security linter
   - `trivy` - Docker image vulnerability scan
   - Dependency vulnerability checks

1. **Code Quality**

   - `pylint` - Code quality analysis
   - `radon` - Complexity metrics
   - Maintainability index checks

### Running CI Checks Locally

```bash
cd backend

# Install linting tools
pip install flake8 black isort mypy bandit pylint radon

# Run all linters (like CI does)
flake8 app --count --select=E9,F63,F7,F82 --show-source --statistics
black --check app tests
isort --check-only app tests
mypy app

# Security check
bandit -r app

# Code quality
pylint app
radon cc app -a

# Run tests with coverage threshold
pytest --cov=app --cov-report=term --cov-fail-under=80
```

### Test Fixtures Available

From `conftest.py`, you can use these fixtures in your tests:

- `test_settings` - Test configuration instance
- `engine` - Async SQLAlchemy engine
- `db_session` - Database session (auto-rollback)
- `client` - AsyncClient for API testing
- `sample_image` - PNG image bytes (800x600)
- `sample_jpeg_image` - JPEG image bytes (1024x768)
- `sample_large_image` - Large PNG (>10MB)
- `sample_invalid_image` - Invalid binary data
- `mock_ai_provider` - Mock BaseAIProvider instance
- `mock_analysis_result` - Sample AnalysisResult
- `equipment_database_entries` - Sample equipment data
- `test_image_hash` - Test perceptual hash string

### Writing New Tests

**Example Unit Test:**

```python
import pytest
from app.services.image_service import ImageService


@pytest.mark.unit
class TestImageService:
    def test_validate_image_success(self, sample_image):
        """Test that valid image passes validation."""
        service = ImageService()
        is_valid, error = await service.validate_image(sample_image, "test.jpg")
        assert is_valid is True
        assert error == ""
```

**Example Integration Test:**

```python
import pytest
from httpx import AsyncClient


@pytest.mark.integration
@pytest.mark.api
class TestAnalysisEndpoint:
    async def test_analyze_endpoint_success(
        self, client: AsyncClient, sample_image: bytes
    ):
        """Test successful image analysis."""
        files = {"image": ("test.jpg", sample_image, "image/jpeg")}
        response = await client.post("/api/v1/analyze", files=files)

        assert response.status_code == 200
        data = response.json()
        assert "equipment_name" in data
        assert "confidence" in data
        assert data["confidence"] > 0.7
```

**See [docs/TESTING.md](docs/TESTING.md) for complete testing guide.**

## 📚 Additional Documentation

- [Backend API Documentation](backend/README.md) - FastAPI implementation details
- [Database Schema](database/README.md) - PostgreSQL schema and queries
- [Dash Dashboard Guide](web-dashboard/README.md) - Web interface
- [Architecture Deep Dive](docs/architecture.md) - Detailed system design
- [**Testing Guide**](docs/TESTING.md) - Comprehensive testing documentation
- [**Getting Started**](docs/GETTING_STARTED.md) - Step-by-step setup guide
- [Docker Secrets Guide](docs/docker-secrets.md) - Production secret management
- [Security Best Practices](docs/docker-secrets.md) - Secure deployment

## 📝 Quick Troubleshooting Cheatsheet

| Problem             | Quick Fix                                                        |
| ------------------- | ---------------------------------------------------------------- |
| Backend won't start | `docker-compose logs backend` → check .env file → verify API key |
| Database error      | `docker-compose down -v && docker-compose up postgres -d`        |
| Port conflict       | Change `"8000:8000"` to `"8001:8000"` in docker-compose.yml      |
| Slow first request  | Normal! Wait 10-30s for model loading                            |
| Cache not working   | Check Redis: `docker-compose ps redis`                           |
| Out of disk space   | `docker system prune -a`                                         |
| Tests failing       | `cd backend && pytest -v` → check error messages                 |
| Dashboard 404       | Verify backend: `curl http://localhost:8000/health`              |
| OpenAI auth error   | Update OPENAI_API_KEY in backend/.env → restart                  |
| Can't connect to DB | Use `postgres` not `localhost` in DATABASE_URL                   |

**Emergency Reset:**

```bash
docker-compose down -v
docker system prune -a --volumes
docker-compose up --build
```

## 🎯 Common Commands Cheatsheet

```bash
# === Service Management ===
docker-compose up              # Start all services (foreground)
docker-compose up -d           # Start all services (background)
docker-compose down            # Stop all services
docker-compose restart backend # Restart specific service
docker-compose ps              # Check status

# === Logs ===
docker-compose logs -f         # Follow all logs
docker-compose logs backend    # View backend logs
docker-compose logs --tail=50  # Last 50 lines

# === Database ===
docker-compose exec postgres psql -U gym_user -d gym_ai
# Then: \dt (list tables), \q (quit)

# === Testing ===
docker-compose exec backend pytest              # All tests
docker-compose exec backend pytest -v           # Verbose
docker-compose exec backend pytest -m unit      # Unit only
docker-compose exec backend pytest --cov=app    # With coverage

# === Debugging ===
docker-compose exec backend /bin/bash           # Backend shell
docker-compose exec backend python              # Python REPL
curl http://localhost:8000/health               # Health check

# === Cleanup ===
docker-compose down -v                          # Remove volumes
docker system prune -a                          # Clean unused
docker volume prune                             # Remove volumes
```

## 🤝 Contributing

1. Fork the repository
1. Create a feature branch (`git checkout -b feature/amazing-feature`)
1. Commit your changes (`git commit -m 'Add amazing feature'`)
1. Push to the branch (`git push origin feature/amazing-feature`)
1. Open a Pull Request

## 📝 License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for
details.

## 🙏 Acknowledgments

- OpenAI for GPT-4 Vision API
- OpenCLIP for open-source vision models
- FastAPI and Pydantic teams
- PostgreSQL and Redis communities
