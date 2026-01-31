# 🐳 Containerized Setup (Recommended)

Run everything in Docker containers including Ollama with GPU support.

## Quick Start

### 1. Ensure Prerequisites

```bash
# Check Docker
docker --version

# Check Docker Compose
docker-compose --version

# Check NVIDIA GPU (if you have one)
nvidia-smi

# Check NVIDIA Container Toolkit
docker info | grep nvidia
```

### 2. Install NVIDIA Container Toolkit (GPU Users)

```bash
# Ubuntu/Debian
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# Verify
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

### 3. Start Everything

```bash
# Option A: Automated setup (runs Ollama + pulls model)
./scripts/setup-ollama-docker.sh

# Option B: Manual setup
docker-compose up -d
docker-compose exec ollama ollama pull llava
```

### 4. Verify

```bash
# Check all services
docker-compose ps

# Should show:
# ✓ gym_ai_postgres  - healthy
# ✓ gym_ai_redis     - healthy  
# ✓ gym_ai_ollama    - healthy
# ✓ gym_ai_backend   - running
# ✓ gym_ai_dashboard - running

# Test backend
curl http://localhost:8000/health
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│           Docker Compose Network                │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────┐  ┌──────────┐  ┌─────────────┐  │
│  │PostgreSQL│  │  Redis   │  │   Ollama    │  │
│  │   :5432  │  │  :6379   │  │   :11434    │  │
│  │          │  │          │  │  (with GPU) │  │
│  └──────────┘  └──────────┘  └─────────────┘  │
│       │             │              │           │
│       └─────────────┴──────────────┘           │
│                     │                          │
│              ┌──────▼───────┐                  │
│              │   Backend    │                  │
│              │   FastAPI    │                  │
│              │    :8000     │                  │
│              └──────┬───────┘                  │
│                     │                          │
│              ┌──────▼───────┐                  │
│              │  Dashboard   │                  │
│              │    Dash      │                  │
│              │    :8050     │                  │
│              └──────────────┘                  │
│                                                 │
└─────────────────────────────────────────────────┘
         │                    │
    Host GPU              Host Network
  (RTX 3060)         (localhost:8000, :8050)
```

## Service Management

### Start/Stop All Services

```bash
# Start everything
docker-compose up -d

# Stop everything
docker-compose down

# Stop and remove volumes (fresh start)
docker-compose down -v
```

### Individual Service Control

```bash
# Restart specific service
docker-compose restart backend
docker-compose restart ollama

# View logs
docker-compose logs -f backend
docker-compose logs -f ollama

# Execute commands in container
docker-compose exec ollama ollama list
docker-compose exec backend curl http://ollama:11434/api/version
```

### Resource Monitoring

```bash
# Monitor all containers
docker stats

# Check GPU usage
nvidia-smi -l 1

# View Ollama GPU usage
docker-compose exec ollama nvidia-smi
```

## Ollama Management

### Model Operations

```bash
# List installed models
docker-compose exec ollama ollama list

# Pull new models
docker-compose exec ollama ollama pull llava:13b
docker-compose exec ollama ollama pull bakllava

# Remove model
docker-compose exec ollama ollama rm llava:7b

# Test model
docker-compose exec ollama ollama run llava "What is in this image?"
```

### Switch Models

```bash
# Edit docker-compose.yml or .env
# Update: OLLAMA_MODEL=llava:13b

# Restart backend
docker-compose restart backend
```

### Available Models

| Model        | Size  | VRAM    | Best For                   |
| ------------ | ----- | ------- | -------------------------- |
| `llava`      | 4.7GB | 6-8GB   | Balanced (default)         |
| `llava:13b`  | 8GB   | 10-12GB | Better quality             |
| `llava:34b`  | 19GB  | 24GB+   | Best quality (needs A100)  |
| `bakllava`   | 4.7GB | 6-8GB   | Alternative implementation |
| `llava-phi3` | 3GB   | 4-6GB   | Lighter weight             |

## GPU Configuration

### Verify GPU Access

```bash
# From Ollama container
docker-compose exec ollama nvidia-smi

# Should show your RTX 3060
```

### Adjust GPU Settings

Edit `docker-compose.yml`:

```yaml
ollama:
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1              # Number of GPUs
            device_ids: ['0']     # Specific GPU (optional)
            capabilities: [gpu]
```

### CPU-Only Mode

If you don't have a GPU, remove the deploy section:

```yaml
ollama:
  image: ollama/ollama:latest
  # Remove deploy section for CPU-only
```

## Data Persistence

### Volumes

```bash
# List volumes
docker volume ls | grep gym_ai

# Expected volumes:
# gym_ai_postgres_data  - Database data
# gym_ai_redis_data     - Cache data
# gym_ai_model_cache    - Backend ML models
# gym_ai_ollama_data    - Ollama models

# Inspect volume
docker volume inspect gym_ai_ollama_data

# Backup volume
docker run --rm -v gym_ai_ollama_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/ollama_backup.tar.gz -C /data .

# Restore volume
docker run --rm -v gym_ai_ollama_data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/ollama_backup.tar.gz -C /data
```

## Troubleshooting

### Ollama Container Won't Start

```bash
# Check logs
docker-compose logs ollama

# Common issues:
# 1. GPU not available
docker run --rm --gpus all ubuntu nvidia-smi

# 2. Port conflict
lsof -i :11434

# 3. Volume permissions
docker volume rm gym_ai_ollama_data
docker-compose up -d ollama
```

### Backend Can't Connect to Ollama

```bash
# Test from backend container
docker-compose exec backend curl http://ollama:11434/api/version

# Should return: {"version":"0.9.6"}

# If fails, check network
docker network inspect gym_ai_default
```

### GPU Not Detected in Container

```bash
# Check NVIDIA runtime
docker info | grep nvidia

# If not found, install nvidia-container-toolkit
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# Test GPU in container
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

### Model Not Found After Restart

```bash
# Models should persist in volume
docker volume ls | grep ollama_data

# Re-pull if needed
docker-compose exec ollama ollama pull llava
```

### Out of Memory

```bash
# Check GPU memory
nvidia-smi

# Use smaller model
docker-compose exec ollama ollama pull llava:7b

# Or increase Docker memory limit
# Edit /etc/docker/daemon.json
```

## Performance Optimization

### Use RAM Disk for Temporary Files

```yaml
backend:
  volumes:
    - ./backend/app:/app/app
    - model_cache:/app/model_cache
    - type: tmpfs
      target: /tmp
      tmpfs:
        size: 1G
```

### Adjust Container Resources

```yaml
backend:
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 4G
      reservations:
        cpus: '1'
        memory: 2G
```

### Enable Model Caching

Models are already cached in `ollama_data` volume. To keep warm:

```bash
# Keep model loaded (in background)
docker-compose exec -d ollama ollama run llava "warmup"
```

## Development Workflow

### Hot Reload Backend Code

Backend code is mounted as volume - changes auto-reload:

```bash
# Edit any file in backend/app/
nano backend/app/services/ai/providers/llava_provider.py

# Backend automatically reloads
# Watch logs: docker-compose logs -f backend
```

### Run Tests

```bash
# Run backend tests
docker-compose exec backend pytest

# With coverage
docker-compose exec backend pytest --cov=app tests/

# Specific test
docker-compose exec backend pytest tests/test_ai_providers.py -v
```

### Interactive Shell

```bash
# Backend shell
docker-compose exec backend /bin/bash

# Ollama shell
docker-compose exec ollama /bin/bash

# Python shell (backend)
docker-compose exec backend python
```

## Production Deployment

### Use Production Compose File

```bash
# Copy and edit
cp docker-compose.yml docker-compose.prod.yml

# Remove development features:
# - Hot reload volumes
# - Debug ports
# - Development environment variables

# Deploy
docker-compose -f docker-compose.prod.yml up -d
```

### Security Considerations

1. **Change default passwords**
1. **Use Docker secrets** for sensitive data
1. **Enable HTTPS** with reverse proxy
1. **Restrict network access**
1. **Regular security updates**

### Scaling

```bash
# Scale backend (load balancing)
docker-compose up -d --scale backend=3

# Use Nginx/Traefik for load balancing
```

## Comparison: Containerized vs Host

| Aspect               | Containerized ✓         | Host             |
| -------------------- | ----------------------- | ---------------- |
| **Isolation**        | ✓ Excellent             | Limited          |
| **Portability**      | ✓ Move anywhere         | OS-specific      |
| **Updates**          | ✓ Easy rollback         | Manual           |
| **GPU Support**      | ✓ With toolkit          | Native           |
| **Resource Control** | ✓ Docker limits         | OS limits        |
| **Cleanup**          | ✓ `docker-compose down` | Manual uninstall |
| **Development**      | ✓ Consistent            | Variable         |

## Migration from Host Ollama

If you already have Ollama running on host:

```bash
# 1. Stop host Ollama
sudo systemctl stop ollama

# 2. Copy models (optional - or let Docker pull fresh)
sudo cp -r ~/.ollama/* /var/lib/docker/volumes/gym_ai_ollama_data/_data/

# 3. Start containerized version
./scripts/setup-ollama-docker.sh

# 4. Disable host Ollama (optional)
sudo systemctl disable ollama
```

## Quick Reference

```bash
# Start everything
docker-compose up -d

# View all logs
docker-compose logs -f

# Stop everything
docker-compose down

# Rebuild and restart
docker-compose up -d --build

# Pull new model
docker-compose exec ollama ollama pull llava:13b

# Test setup
./scripts/test-setup.sh

# Monitor GPU
nvidia-smi -l 1

# Check health
curl http://localhost:8000/health
```

## Next Steps

1. ✓ Run `./scripts/setup-ollama-docker.sh`
1. ✓ Verify all services: `docker-compose ps`
1. ✓ Open dashboard: http://localhost:8050
1. ✓ Test with gym photos
1. Monitor performance
1. Explore different models
1. Customize prompts
1. Build your mobile app!

______________________________________________________________________

**Benefits of Containerized Setup:**

- ✅ One-command start/stop
- ✅ Isolated environments
- ✅ GPU support included
- ✅ Easy backups (volumes)
- ✅ Consistent across machines
- ✅ Simple scaling
- ✅ Clean uninstall

**Perfect for your RTX 3060 setup! 🚀**
