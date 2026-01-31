# Docker Compose Split Architecture Guide

## 📁 File Structure

```
gym_ai/
├── docker-compose.yml              # Default - all services
└── scripts/
    ├── docker-compose.services.yml # Infrastructure only
    ├── docker-compose.dev.yml      # App layer only
    ├── docker-compose.all.yml      # Explicit all-in-one
    ├── services.sh                 # Manage infrastructure
    └── dev.sh                      # Manage development
```

## 🎯 Use Cases

### 1. Full Stack (Everything Together)

**When to use:**

- Quick start/testing
- Single developer
- Simple deployments

```bash
# Start everything
docker-compose up -d

# Stop everything
docker-compose down

# Status
docker-compose ps
```

### 2. Split Workflow (Services + Dev)

**When to use:**

- Multiple developers sharing infrastructure
- Keep services running while restarting app
- Better resource management
- Production-like local environment

```bash
# Start infrastructure (once)
./scripts/services.sh start

# Start development services
./scripts/dev.sh start

# Restart app without touching DB/Redis/Ollama
./scripts/dev.sh restart

# Stop app but keep services running
./scripts/dev.sh stop
```

## 📋 Service Breakdown

### Infrastructure Services (services.yml)

- **PostgreSQL** - Database
- **Redis** - Cache
- **Ollama** - AI Model Server (with GPU)

**Characteristics:**

- Long-running
- Shared across projects
- Data persistence
- Rarely restarted

### Development Services (dev.yml)

- **Backend** - FastAPI application
- **Dashboard** - Test interface

**Characteristics:**

- Frequently restarted
- Code hot-reload
- Rapid iteration
- Depends on infrastructure

## 🚀 Workflow Examples

### Daily Development

```bash
# Morning - start services (if not running)
./scripts/services.sh status
# If not running:
./scripts/services.sh start

# Start your app
./scripts/dev.sh start

# Code changes (auto-reload)
# Edit backend/app/...

# Restart app after dependency changes
./scripts/dev.sh rebuild

# View logs
./scripts/dev.sh logs backend

# Evening - stop app, keep services
./scripts/dev.sh stop
```

### Team Collaboration

```bash
# Team member 1: Working on backend
./scripts/dev.sh start
./scripts/dev.sh logs backend

# Team member 2: Working on different feature (same machine)
# Services already running, just start another app instance
# (requires port changes or different project)
```

### Testing Different Models

```bash
# Keep app running
./scripts/services.sh restart ollama

# Pull new model
docker-compose -f docker-compose.services.yml exec ollama ollama pull llava:13b

# Update .env
# OLLAMA_MODEL=llava:13b

# Restart backend only
./scripts/dev.sh restart
```

### Clean Slate

```bash
# Stop everything
./scripts/dev.sh stop
./scripts/services.sh stop

# Remove all data
./scripts/services.sh clean

# Fresh start
./scripts/services.sh start
./scripts/dev.sh start
```

## 🔧 Script Commands

### services.sh (Infrastructure)

```bash
./scripts/services.sh start      # Start all services
./scripts/services.sh stop       # Stop all services
./scripts/services.sh restart    # Restart all services
./scripts/services.sh status     # Show status
./scripts/services.sh logs       # View logs
./scripts/services.sh pull       # Pull Ollama model
./scripts/services.sh clean      # Remove volumes
```

### dev.sh (Application)

```bash
./scripts/dev.sh start          # Start app services
./scripts/dev.sh stop           # Stop app services
./scripts/dev.sh restart        # Restart app services
./scripts/dev.sh build          # Build images
./scripts/dev.sh rebuild        # Build and restart
./scripts/dev.sh status         # Show status
./scripts/dev.sh logs           # View logs
./scripts/dev.sh shell          # Open shell (default: backend)
./scripts/dev.sh test           # Run tests
```

## 📊 Comparison

| Aspect             | Full Stack         | Split Workflow           |
| ------------------ | ------------------ | ------------------------ |
| **Startup**        | All at once        | Services first, then app |
| **Restart**        | Restart everything | Restart only app         |
| **Resource Usage** | Higher             | Lower (can stop app)     |
| **Data Safety**    | Coupled            | Services isolated        |
| **Team Work**      | Single instance    | Shared services          |
| **Complexity**     | Simple             | More control             |

## 🎯 Best Practices

### For Development

1. **Keep services running** between coding sessions

   ```bash
   ./scripts/services.sh start  # Run once per day
   ./scripts/dev.sh start       # Start when coding
   ./scripts/dev.sh stop        # Stop when done
   ```

1. **Use logs effectively**

   ```bash
   ./scripts/dev.sh logs backend    # Watch backend
   ./scripts/services.sh logs ollama # Watch AI
   ```

1. **Quick restart** after config changes

   ```bash
   ./scripts/dev.sh restart  # Fast, keeps services
   ```

### For Production

Use split files with orchestration tools:

```bash
# Production services
docker-compose -f scripts/docker-compose.services.yml up -d

# Production app (with different config)
docker-compose -f docker-compose.prod.yml up -d
```

## 🔍 Troubleshooting

### "Network not found" error

```bash
# Services not running - start them first
./scripts/services.sh start
```

### "Port already in use"

```bash
# Check what's using the port
lsof -i :8000

# Stop conflicting service
./scripts/dev.sh stop
```

### Services won't start

```bash
# Check status
./scripts/services.sh status

# View logs
./scripts/services.sh logs

# Clean restart
./scripts/services.sh stop
./scripts/services.sh start
```

### App can't connect to services

```bash
# Verify network
docker network inspect gym_ai_network

# Restart services
./scripts/services.sh restart

# Restart app
./scripts/dev.sh restart
```

## 🔄 Migration from Old Setup

If you have the old single docker-compose running:

```bash
# Stop old setup
docker-compose down

# Start new split setup
./scripts/services.sh start
./scripts/dev.sh start

# Or use default (works the same)
docker-compose up -d
```

## 📝 Environment Variables

### Services (docker-compose.services.yml)

- Database credentials
- Port mappings
- Volume paths

### Dev (docker-compose.dev.yml)

- Backend configuration (from .env)
- Service URLs (auto-configured)
- Development flags

## 🎓 Quick Reference

```bash
# First time setup
./scripts/services.sh start
./scripts/services.sh pull      # Pull Ollama model
./scripts/dev.sh start

# Daily workflow
./scripts/dev.sh start          # Morning
# ... code ...
./scripts/dev.sh restart        # After changes
./scripts/dev.sh logs backend   # Debug
./scripts/dev.sh stop           # Evening

# Maintenance
./scripts/services.sh logs ollama   # Check AI
./scripts/dev.sh test               # Run tests
./scripts/dev.sh shell backend      # Debug

# Clean slate
./scripts/dev.sh stop
./scripts/services.sh clean
./scripts/services.sh start
./scripts/dev.sh start
```

## ✨ Benefits

### Split Architecture

✅ Faster app restarts (don't touch DB/Redis/Ollama) ✅ Better resource management ✅ Safer data
handling ✅ Team collaboration ready ✅ Production-like workflow ✅ Clear service boundaries

### Helper Scripts

✅ Simplified commands ✅ Error checking ✅ Status feedback ✅ Quick access to common tasks

______________________________________________________________________

**Choose your workflow:**

- **Simple**: Use default `docker-compose up -d`
- **Advanced**: Use split files with helper scripts

Both work perfectly! 🚀
