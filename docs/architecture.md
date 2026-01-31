# System Architecture

Detailed technical architecture documentation for Gym AI Helper.

## Overview

Gym AI Helper is a microservices-based application for identifying gym equipment from photos and
providing usage instructions. The system uses Docker containers for all services, AI vision models
for equipment recognition, and PostgreSQL for caching to minimize API costs.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                             │
├─────────────┬────────────────────────┬───────────────────────────┤
│   Flutter   │   Dash Dashboard       │   API Clients             │
│   Mobile    │   (Testing Interface)  │   (curl, Postman, etc.)   │
└──────┬──────┴───────────┬────────────┴──────────┬────────────────┘
       │                  │                       │
       │                  │                       │
       │                  └───────────────────────┘
       │                            │
       │                            ▼
┌──────┴────────────────────────────────────────────────────────────┐
│                      API GATEWAY / LOAD BALANCER                   │
│                         (Optional: Nginx/Traefik)                  │
└────────────────────────────┬───────────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────────────┐
│                      FASTAPI BACKEND (Container)                   │
├────────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────────┐  ┌─────────────┐  ┌───────────┐  │
│  │   API    │  │   Business   │  │   AI        │  │  Cache    │  │
│  │  Layer   │─▶│   Logic      │─▶│  Services   │  │  Service  │  │
│  │          │  │   Services   │  │             │  │           │  │
│  └──────────┘  └──────────────┘  └─────────────┘  └───────────┘  │
│       │               │                  │               │         │
└───────┼───────────────┼──────────────────┼───────────────┼─────────┘
        │               │                  │               │
        │               ▼                  │               ▼
        │         ┌──────────────┐         │         ┌──────────┐
        │         │  Image       │         │         │  Redis   │
        │         │  Processing  │         │         │  Cache   │
        │         └──────────────┘         │         └──────────┘
        │                                  │
        │                                  ▼
        │                     ┌────────────────────────┐
        │                     │   AI Provider Layer    │
        │                     ├────────────────────────┤
        │                     │  ┌──────┐  ┌───────┐  │
        │                     │  │OpenAI│  │ CLIP  │  │
        │                     │  │ API  │  │ Local │  │
        │                     │  └──────┘  └───────┘  │
        │                     │  ┌───────┐           │
        │                     │  │LLaVA  │           │
        │                     │  │ GPU   │           │
        │                     │  └───────┘           │
        │                     └────────────────────────┘
        │
        ▼
┌────────────────────────┐
│   PostgreSQL Database  │
├────────────────────────┤
│  - equipment           │
│  - equipment_cache     │
│  - user_identifications│
└────────────────────────┘
```

## Component Details

### 1. Backend API (FastAPI)

**Technology Stack:**

- Python 3.11
- FastAPI 0.109
- Uvicorn (ASGI server)
- Pydantic 2.5 (validation)

**Responsibilities:**

- HTTP API endpoint management
- Request validation and response formatting
- Authentication (future)
- Rate limiting (future)
- Error handling and logging

**Key Endpoints:**

- `POST /api/v1/analyze` - Image analysis
- `GET /api/v1/health` - Health check
- `GET /api/v1/cache/stats` - Cache statistics

**Scalability:**

- Stateless design allows horizontal scaling
- Multiple worker processes (4 in production)
- Async SQLAlchemy for non-blocking database operations

### 2. AI Service Layer

**Architecture Pattern:** Strategy + Factory

**Components:**

#### a) BaseAIProvider (Abstract Interface)

- Defines common interface for all AI providers
- Methods: `analyze_image()`, `initialize()`, `health_check()`
- Ensures consistent behavior across providers

#### b) AIServiceFactory

- Singleton pattern for provider instances
- Dynamic provider selection based on configuration
- Provider caching to avoid reinitialization

#### c) Provider Implementations

**OpenAI Provider:**

- Uses GPT-4 Vision API
- High accuracy, detailed instructions
- Cost: ~$0.01-0.03 per image
- No GPU required
- Latency: 1-3 seconds

**CLIP Provider:**

- Open-source zero-shot classification
- Free inference
- Requires predefined categories
- Cost: $0 (self-hosted)
- Latency: 100-300ms (CPU), 50-100ms (GPU)
- Model size: ~350MB

**LLaVA Provider (Future):**

- Multimodal LLM (text + vision)
- Self-hosted, no API costs
- Requires GPU (8GB+ VRAM)
- Latency: 2-5 seconds
- Model size: ~7GB

### 3. Caching System

**Multi-Layer Caching:**

#### Layer 1: PostgreSQL (Persistent)

- Perceptual image hashing (pHash)
- 30-day TTL
- Indexed for fast lookups
- Handles similar images (Hamming distance \< 5)
- Stores complete analysis results as JSONB

#### Layer 2: Redis (In-Memory) \[Future\]

- Hot data caching
- 1-hour TTL
- LRU eviction policy
- Reduces database queries

**Cache Hit Rate:**

- Expected: 95%+ after initial population
- Reduces AI API costs by ~95%
- Average response time: \<50ms (cache hit)

**Hashing Algorithm:**

- pHash (Perceptual Hash)
- 64-bit hash (8x8 DCT)
- Robust to minor variations
- Hamming distance for similarity

### 4. Database Schema

**Equipment Table:**

```sql
equipment (
    id UUID PRIMARY KEY,
    name VARCHAR(200) UNIQUE NOT NULL,
    category VARCHAR(50) NOT NULL,
    muscle_groups TEXT[],
    instructions_text TEXT NOT NULL,
    video_urls TEXT[],
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

**Equipment Cache Table:**

```sql
equipment_cache (
    id UUID PRIMARY KEY,
    image_hash VARCHAR(100) UNIQUE NOT NULL,
    equipment_id UUID REFERENCES equipment(id),
    ai_response JSONB NOT NULL,
    created_at TIMESTAMP,
    ttl_expires_at TIMESTAMP NOT NULL
)
```

**Indexes:**

- `idx_cache_image_hash` - O(1) hash lookup
- `idx_cache_ttl` - Efficient TTL queries
- `idx_equipment_name` - Fast name searches

### 5. Image Processing Pipeline

**Workflow:**

1. **Upload & Validation**

   - Max size: 10MB
   - Formats: JPG, PNG, WebP
   - Dimensions: 50x50 to 10000x10000
   - MIME type verification

1. **Preprocessing**

   - Convert to RGB
   - Resize (maintain aspect ratio)
   - Optional enhancement (contrast, sharpness)
   - Re-encode as JPEG (quality 95)

1. **Perceptual Hashing**

   - Compute pHash (8x8 DCT)
   - Generate 64-bit hash string
   - Store for cache lookup

1. **AI Analysis**

   - Send to selected provider
   - Parse structured response
   - Extract equipment details

1. **Cache Storage**

   - Store analysis with hash
   - Set TTL (30 days default)
   - Link to equipment table if matched

## Data Flow

### Analyze Image Request

```
Client                Backend              Cache              AI Provider         Database
  │                     │                    │                    │                  │
  │──── POST /analyze ──▶│                   │                    │                  │
  │                     │                    │                    │                  │
  │                     │─── Validate ───────┤                    │                  │
  │                     │                    │                    │                  │
  │                     │─── Hash Image ─────┤                    │                  │
  │                     │                    │                    │                  │
  │                     │──── Cache Lookup ──┤───── Query ────────┼──────────────────▶│
  │                     │                    │◀─── Result ────────┼──────────────────│
  │                     │                    │                    │                  │
  │                     │◀─── Cache Miss ────┤                    │                  │
  │                     │                    │                    │                  │
  │                     │──── Analyze Image ─┼────────────────────▶│                 │
  │                     │                    │                    │                  │
  │                     │◀─── AI Response ───┼────────────────────│                 │
  │                     │                    │                    │                  │
  │                     │──── Store Cache ───┤──── Insert ────────┼──────────────────▶│
  │                     │                    │                    │                  │
  │◀─── Analysis Result │                    │                    │                  │
  │                     │                    │                    │                  │
```

### Cache Hit Flow

```
Client                Backend              Cache              Database
  │                     │                    │                  │
  │──── POST /analyze ──▶│                   │                  │
  │                     │                    │                  │
  │                     │─── Hash Image ─────┤                  │
  │                     │                    │                  │
  │                     │──── Cache Lookup ──┤─── Query ────────▶│
  │                     │                    │◀── Result ────────│
  │                     │◀─── Cache Hit ─────┤                  │
  │                     │                    │                  │
  │◀─── Cached Result ──│                    │                  │
  │                     │                    │                  │
```

## Security Architecture

### Authentication & Authorization (Future)

```
┌────────────┐
│   Client   │
└─────┬──────┘
      │
      │ 1. Request with JWT
      ▼
┌────────────────────┐
│  API Gateway       │
│  (Rate Limiting)   │
└─────┬──────────────┘
      │
      │ 2. Verify JWT
      ▼
┌────────────────────┐
│  FastAPI Backend   │
│  (Auth Middleware) │
└─────┬──────────────┘
      │
      │ 3. Authorized Request
      ▼
┌────────────────────┐
│  Business Logic    │
└────────────────────┘
```

### Secret Management

**Development:**

- Environment variables in `.env`
- Not committed to version control

**Production:**

- Docker Secrets (swarm mode)
- AWS Secrets Manager
- Azure Key Vault
- HashiCorp Vault

### Network Security

**Development:**

- Single Docker network
- All services accessible

**Production:**

- Separate internal/external networks
- Database not exposed publicly
- Backend accessible via API gateway only
- TLS/SSL encryption in transit

## Performance Optimization

### Database Optimization

1. **Connection Pooling**

   - Pool size: 20 connections
   - Max overflow: 10
   - Pool pre-ping: Enabled
   - Connection recycle: 1 hour

1. **Query Optimization**

   - Indexed columns for lookups
   - JSONB for flexible schema
   - Lazy loading relationships
   - Bulk operations for inserts

1. **Caching Strategy**

   - Redis for hot data (future)
   - PostgreSQL for persistent cache
   - In-memory LRU for model outputs

### API Performance

1. **Async Operations**

   - Non-blocking database queries
   - Concurrent request handling
   - Async AI provider calls

1. **Response Optimization**

   - Pydantic serialization
   - Gzip compression
   - HTTP/2 support

1. **Scalability**

   - Horizontal scaling (multiple containers)
   - Load balancing (Nginx/Traefik)
   - Auto-scaling based on CPU/memory

### AI Model Optimization

1. **CLIP Optimization**

   - Model quantization (INT8)
   - Batch processing
   - GPU acceleration (CUDA)
   - Model caching in volume

1. **OpenAI Optimization**

   - Response caching
   - Batch requests (future)
   - Rate limit management

## Monitoring & Observability

### Metrics (Future Implementation)

```python
from prometheus_client import Counter, Histogram

# Request metrics
api_requests = Counter("api_requests_total", "Total API requests")
api_errors = Counter("api_errors_total", "Total API errors")

# Performance metrics
analysis_duration = Histogram("analysis_duration_seconds", "Analysis duration")
cache_hits = Counter("cache_hits_total", "Cache hits")
cache_misses = Counter("cache_misses_total", "Cache misses")
```

### Logging

**Log Levels:**

- DEBUG: Development only
- INFO: Normal operations
- WARNING: Degraded performance
- ERROR: Failures requiring attention

**Log Format:**

```json
{
  "timestamp": "2026-01-17T10:30:45.123Z",
  "level": "INFO",
  "service": "backend",
  "message": "Analysis complete",
  "equipment_name": "Bench Press",
  "processing_time_ms": 1234,
  "cached": false
}
```

### Health Checks

**Backend Health:**

```
GET /health
Response: {
  "status": "healthy",
  "service": "Gym AI Helper",
  "version": "1.0.0",
  "ai_provider": "openai",
  "ai_provider_healthy": true
}
```

**Docker Health Checks:**

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s \
  CMD curl -f http://localhost:8000/health || exit 1
```

## Deployment Architecture

### Development

```yaml
# Single machine
Docker Compose:
  - PostgreSQL
  - Redis
  - Backend (hot reload)
  - Dashboard
```

### Production

```yaml
# Cloud deployment
Load Balancer (Nginx/ALB)
  ├── Backend Instance 1
  ├── Backend Instance 2
  └── Backend Instance 3

Managed Services:
  - RDS (PostgreSQL)
  - ElastiCache (Redis)
  - S3 (image storage)
  - CloudWatch (logging)
```

### Container Resources

**Backend:**

- CPU: 1-2 cores
- Memory: 2-4GB
- Disk: 10GB (model cache)

**PostgreSQL:**

- CPU: 2 cores
- Memory: 4GB
- Disk: 50GB+

**Redis:**

- CPU: 1 core
- Memory: 2GB
- Disk: 1GB

## Disaster Recovery

### Backup Strategy

1. **Database Backups**

   - Daily automated backups
   - Point-in-time recovery (7 days)
   - Cross-region replication

1. **Configuration Backups**

   - Environment variables
   - Docker secrets
   - Application config

### Recovery Procedures

1. **Database Restore**

   ```bash
   docker exec -i postgres psql -U gym_user < backup.sql
   ```

1. **Service Recovery**

   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Future Enhancements

### Phase 2: Flutter Mobile App

- Camera integration
- Offline caching
- Push notifications
- User profiles

### Phase 3: Advanced Features

- Multi-equipment detection (YOLO)
- Workout plan generation
- Progress tracking
- Social features (share workouts)

### Phase 4: ML Improvements

- Custom model fine-tuning
- Active learning pipeline
- A/B testing for models
- Edge deployment (TFLite)

## Technology Decisions

| Choice     | Reason                                   |
| ---------- | ---------------------------------------- |
| FastAPI    | Async support, auto docs, type safety    |
| PostgreSQL | ACID compliance, JSONB, extensions       |
| Docker     | Consistent environments, easy deployment |
| Pydantic   | Runtime validation, IDE support          |
| CLIP       | Free, accurate, offline capable          |
| pHash      | Robust to minor image variations         |

## References

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [OpenCLIP](https://github.com/mlfoundations/open_clip)
- [PostgreSQL JSONB](https://www.postgresql.org/docs/current/datatype-json.html)
- [Docker Compose](https://docs.docker.com/compose/)
- [Perceptual Hashing](https://www.phash.org/)
