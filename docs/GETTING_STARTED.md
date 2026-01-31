# Getting Started with Gym AI Helper

Complete step-by-step guide to get Gym AI Helper running on your system.

## Prerequisites

Before starting, ensure you have:

- **Docker** 20.10+ ([Install Docker](https://docs.docker.com/get-docker/))
- **Docker Compose** 2.0+ ([Install Docker Compose](https://docs.docker.com/compose/install/))
- **OpenAI API Key** (if using OpenAI provider) -
  [Get API Key](https://platform.openai.com/api-keys)
- **8GB+ RAM** recommended
- **Linux, macOS, or Windows with WSL2**

## Quick Start (5 minutes)

### 1. Clone Repository

```bash
git clone https://github.com/Asphalt2017/gym_ai.git
cd gym_ai
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example backend/.env

# Edit with your API key
nano backend/.env
```

Add your OpenAI API key:

```env
OPENAI_API_KEY=sk-proj-your-key-here
```

### 3. Start Services

```bash
# Build and start all containers
docker-compose up --build

# Or use the helper script
./scripts/dev.sh start
```

### 4. Access Services

- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Test Dashboard**: http://localhost:8050

### 5. Test the API

Open the dashboard at http://localhost:8050 and:

1. Upload a gym equipment photo
1. Click "Analyze Image"
1. View results with usage instructions!

## Detailed Setup Guide

### Step 1: System Requirements Check

```bash
# Check Docker version
docker --version
# Should be 20.10+

# Check Docker Compose version
docker-compose --version
# Should be 2.0+

# Check available RAM
free -h
# Recommended: 8GB+
```

### Step 2: Clone and Explore

```bash
# Clone repository
git clone https://github.com/Asphalt2017/gym_ai.git
cd gym_ai

# View project structure
ls -la

# Expected output:
# backend/          - FastAPI backend
# web-dashboard/    - Dash web interface
# database/         - PostgreSQL initialization
# scripts/          - Helper scripts
# docs/            - Documentation
# docker-compose.yml
# README.md
```

### Step 3: Configure Backend

#### Option A: Using OpenAI (Recommended for Testing)

```bash
# Copy template
cp .env.example backend/.env

# Edit configuration
nano backend/.env
```

Set these values:

```env
# Required
OPENAI_API_KEY=sk-proj-your-actual-key-here
AI_PROVIDER=openai
OPENAI_MODEL=gpt-4-vision-preview

# Optional (defaults are fine)
DATABASE_URL=postgresql+asyncpg://gym_user:gym_dev_password@postgres:5432/gym_ai
REDIS_URL=redis://redis:6379
DEBUG=true
LOG_LEVEL=INFO
```

#### Option B: Using CLIP (Free, No API Key)

```env
AI_PROVIDER=clip
CLIP_MODEL_NAME=ViT-B-32
CLIP_PRETRAINED=openai
USE_GPU=false  # Set to true if you have CUDA GPU
```

**Note**: CLIP downloads ~350MB model on first run.

### Step 4: Build Docker Images

```bash
# Build all services
docker-compose build

# This takes 5-10 minutes first time
# Downloads Python images, installs dependencies
```

### Step 5: Start Services

```bash
# Start in foreground (see logs)
docker-compose up

# Or start in background
docker-compose up -d

# Check status
docker-compose ps
```

Expected output:

```
NAME                    STATUS              PORTS
gym_ai_postgres         Up 10 seconds       0.0.0.0:5432->5432/tcp
gym_ai_redis            Up 10 seconds       0.0.0.0:6379->6379/tcp
gym_ai_backend          Up 10 seconds       0.0.0.0:8000->8000/tcp
gym_ai_dashboard        Up 10 seconds       0.0.0.0:8050->8050/tcp
```

### Step 6: Verify Health

#### Check Backend Health

```bash
curl http://localhost:8000/health
```

Expected response:

```json
{
  "status": "healthy",
  "service": "Gym AI Helper",
  "version": "1.0.0",
  "ai_provider": "openai",
  "ai_provider_healthy": true
}
```

#### Check API Documentation

Open browser: http://localhost:8000/docs

You should see interactive Swagger UI with:

- POST /api/v1/analyze
- GET /api/v1/health
- GET /api/v1/cache/stats

#### Check Dashboard

Open browser: http://localhost:8050

You should see:

- Green status: "Backend is healthy"
- Upload interface
- Preview section

### Step 7: Test Image Analysis

#### Method 1: Using Dashboard (Easiest)

1. Go to http://localhost:8050
1. Drag and drop an equipment photo OR click "Select an Image"
1. Click "Analyze Image"
1. Wait 2-5 seconds (longer on first request)
1. View results!

#### Method 2: Using curl

```bash
# Analyze image with curl
curl -X POST "http://localhost:8000/api/v1/analyze" \
  -H "accept: application/json" \
  -H "Content-Type: multipart/form-data" \
  -F "image=@/path/to/equipment_photo.jpg"
```

#### Method 3: Using Python

```python
import requests

url = "http://localhost:8000/api/v1/analyze"
files = {"image": open("bench_press.jpg", "rb")}
response = requests.post(url, files=files)

print(response.json())
```

## Common Issues & Solutions

### Issue: Backend fails to start

**Symptom**: Container exits immediately

**Solution**:

```bash
# Check logs
docker-compose logs backend

# Common causes:
# 1. Missing .env file
cp .env.example backend/.env

# 2. Invalid API key (if using OpenAI)
# Check your OpenAI API key is correct

# 3. Port already in use
# Change port in docker-compose.yml
ports:
  - "8001:8000"  # Change 8000 to 8001
```

### Issue: Database connection fails

**Symptom**: `asyncpg.exceptions.InvalidCatalogNameError`

**Solution**:

```bash
# Reset database
docker-compose down -v
docker-compose up postgres -d

# Wait for initialization
sleep 10

# Restart backend
docker-compose up backend -d
```

### Issue: OpenAI API errors

**Symptom**: `AuthenticationError` or `RateLimitError`

**Solution**:

```bash
# Verify API key format
# Should start with: sk-proj-...

# Check API key validity
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"

# If rate limited, switch to CLIP:
# Edit backend/.env
AI_PROVIDER=clip

# Restart backend
docker-compose restart backend
```

### Issue: CLIP model download fails

**Symptom**: Hangs on "Loading CLIP model"

**Solution**:

```bash
# Check internet connection
ping huggingface.co

# Increase timeout and retry
docker-compose restart backend

# Models cached in volume after first successful download
docker volume ls | grep model_cache
```

### Issue: Dashboard can't connect to backend

**Symptom**: Red alert "Cannot connect to backend"

**Solution**:

```bash
# Check backend is running
docker-compose ps backend

# Check backend logs
docker-compose logs backend

# Verify backend URL in dashboard
docker-compose exec dashboard env | grep BACKEND_URL
# Should be: http://backend:8000

# Restart dashboard
docker-compose restart dashboard
```

### Issue: Slow first request

**Symptom**: First analysis takes 20+ seconds

**Solution**: This is normal!

- OpenAI: Cold start + API call (3-5s after warmup)
- CLIP: Model loading + inference (fast after first request)
- Subsequent requests are much faster (cache + warm models)

## Development Workflow

### Making Code Changes

```bash
# Backend has hot reload enabled
# Edit files in backend/app/
nano backend/app/api/v1/endpoints/analysis.py

# Changes auto-reload (watch terminal logs)
# No restart needed!
```

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend

# Last 100 lines
docker-compose logs --tail=100 backend
```

### Database Access

```bash
# Open PostgreSQL shell
docker-compose exec postgres psql -U gym_user -d gym_ai

# View equipment
SELECT name, category FROM equipment LIMIT 5;

# Check cache
SELECT COUNT(*) FROM equipment_cache;

# Exit
\q
```

### Running Tests

```bash
# Run backend tests (when implemented)
docker-compose exec backend pytest

# With coverage
docker-compose exec backend pytest --cov=app tests/
```

### Stopping Services

```bash
# Stop all services (keep data)
docker-compose down

# Stop and remove volumes (fresh start)
docker-compose down -v

# Using helper script
./scripts/dev.sh stop
```

## Production Deployment

### 1. Use Production Compose File

```bash
# Create secrets
echo "your_openai_key" | docker secret create openai_api_key -
echo "secure_db_password" | docker secret create db_password -

# Deploy with production config
docker-compose -f docker-compose.prod.yml up -d
```

### 2. Environment Configuration

```bash
# Production settings
DEBUG=false
LOG_LEVEL=WARNING
USE_DOCKER_SECRETS=true
```

### 3. Resource Limits

Edit `docker-compose.prod.yml`:

```yaml
backend:
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 4G
```

### 4. Enable HTTPS

Use reverse proxy (Nginx/Traefik) with SSL certificate.

## Next Steps

### 1. Explore API Documentation

Visit http://localhost:8000/docs to:

- Try different endpoints
- See request/response schemas
- Test with Swagger UI

### 2. Customize Equipment Database

```bash
# Edit seed data
nano database/seed.sql

# Add more equipment entries
# Restart to apply changes
docker-compose restart postgres
```

### 3. Switch AI Providers

Edit `backend/.env`:

```env
# Try CLIP (free)
AI_PROVIDER=clip

# Or keep OpenAI
AI_PROVIDER=openai
```

### 4. Monitor Performance

```bash
# Check cache stats
curl http://localhost:8000/api/v1/cache/stats

# View response times in logs
docker-compose logs backend | grep "processing_time"
```

### 5. Read Documentation

- [Backend API](backend/README.md)
- [Database Schema](database/README.md)
- [Dashboard Guide](web-dashboard/README.md)
- [Architecture](docs/architecture.md)
- [Security](docs/docker-secrets.md)

## Helper Script Usage

The `scripts/dev.sh` script provides shortcuts:

```bash
# Make executable (first time only)
chmod +x scripts/dev.sh

# View available commands
./scripts/dev.sh help

# Common commands
./scripts/dev.sh start          # Start all services
./scripts/dev.sh stop           # Stop services
./scripts/dev.sh logs           # View logs
./scripts/dev.sh db-shell       # Open database
./scripts/dev.sh status         # Check status
./scripts/dev.sh reset          # Fresh start
```

## Tips & Best Practices

### 1. Use Dashboard for Testing

The dashboard is perfect for:

- Quick visual testing
- Debugging AI responses
- Checking cache behavior
- Monitoring backend health

### 2. Monitor First Request

First analysis is always slower:

- OpenAI: API cold start (~2-3s)
- CLIP: Model loading (~10-30s)
- Cached requests: \<100ms

### 3. Manage Disk Space

```bash
# Check Docker disk usage
docker system df

# Clean unused resources
docker system prune -a

# Keep model cache volume
docker volume ls | grep model_cache
```

### 4. Update Dependencies

```bash
# Pull latest images
docker-compose pull

# Rebuild with latest
docker-compose build --no-cache

# Restart services
docker-compose up -d
```

## Getting Help

### Check Logs First

```bash
# Backend errors
docker-compose logs backend | grep ERROR

# Database issues
docker-compose logs postgres | grep ERROR

# All errors
docker-compose logs | grep ERROR
```

### Health Check

```bash
# Quick health check
curl http://localhost:8000/health

# Detailed status
./scripts/dev.sh status
```

### Reset Everything

```bash
# Nuclear option - fresh start
./scripts/dev.sh clean
./scripts/dev.sh start
```

### Community Support

- Review [README.md](README.md)
- Check [Architecture docs](docs/architecture.md)
- Search GitHub Issues
- Open new issue with logs

## Success Checklist

- [ ] Docker and Docker Compose installed
- [ ] Repository cloned
- [ ] `.env` file configured with API key
- [ ] All containers running (`docker-compose ps`)
- [ ] Backend health check passes
- [ ] Dashboard accessible at localhost:8050
- [ ] Successfully analyzed at least one image
- [ ] Cache working (second request faster)
- [ ] Logs show no errors

**Congratulations!** You've successfully set up Gym AI Helper! 🎉

Now you can:

- Upload equipment photos
- Get instant usage instructions
- Build mobile apps using the API
- Customize for your gym's equipment
- Deploy to production

Happy coding! 🏋️‍♂️
