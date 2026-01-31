# Gym AI Helper - AI Agent Instructions

This codebase is a Docker-based gym equipment recognition system using FastAPI backend with
pluggable AI vision providers (OpenAI GPT-4 Vision, CLIP, LLaVA).

## Architecture Overview

**3-layer strategy pattern with caching**:

- **API Layer** ([backend/app/api/v1/endpoints/](../backend/app/api/v1/endpoints/)): FastAPI
  endpoints with async SQLAlchemy
- **Service Layer** ([backend/app/services/](../backend/app/services/)): Business logic, caching,
  image processing
- **AI Provider Layer**
  ([backend/app/services/ai/providers/](../backend/app/services/ai/providers/)): Strategy pattern
  via `BaseAIProvider` interface

**Key flow**: Image upload → Perceptual hash → Cache check (PostgreSQL + Redis) → AI provider (if
miss) → Store result → Return analysis

**Provider switching**: All AI providers implement `BaseAIProvider.analyze_image()` returning
standardized `AnalysisResult`. Factory pattern in
[services/ai/factory.py](../backend/app/services/ai/factory.py) manages singleton instances.
Provider selected via `AI_PROVIDER` env var.

## Development Workflows

### Running the stack

```bash
# Primary method - all services (backend, postgres, redis, dashboard)
./scripts/dev.sh start

# Or direct Docker Compose
docker-compose up --build

# Tests (must be in backend/ directory with venv activated)
cd backend
pytest -m unit           # Fast isolated tests
pytest -m integration    # Requires services
pytest --cov=app         # With coverage report
```

### Adding a new AI provider

1. Create class in [backend/app/services/ai/providers/](../backend/app/services/ai/providers/)
   implementing `BaseAIProvider`
1. Implement `async initialize()` (model loading) and
   `async analyze_image(image_bytes) -> AnalysisResult`
1. Add to factory in [services/ai/factory.py](../backend/app/services/ai/factory.py)
   `_create_provider()`
1. Must return all `AnalysisResult` fields: `equipment_name`, `category`, `muscles_worked`,
   `instructions`, `common_mistakes`, `video_keywords`, `confidence`, `provider`

### Configuration pattern

- Settings in [backend/app/core/config.py](../backend/app/core/config.py) using Pydantic
  `BaseSettings`
- Loads from `.env` file AND Docker secrets (if `USE_DOCKER_SECRETS=true`)
- Critical: `DATABASE_URL` uses `postgresql+asyncpg://` (async driver), `REDIS_URL` for cache

## Code Conventions

### Dependency injection

All endpoints use FastAPI `Depends()` for services
([core/dependencies.py](../backend/app/core/dependencies.py)):

```python
async def my_endpoint(
    db: AsyncSession = Depends(get_db),
    ai_factory: AIServiceFactory = Depends(get_ai_service),
    cache_svc: CacheService = Depends(get_cache_service),
    image_svc: ImageService = Depends(get_image_service)
):
```

### Database operations

- **Always** use async patterns: `async with engine.begin()`, `await session.execute()`
- Models in [models/](../backend/app/models/), Pydantic schemas in
  [schemas/](../backend/app/schemas/)
- Cache table stores perceptual hash (`image_hash`) for similar image detection

### Error handling

- Raise `HTTPException` from FastAPI in endpoints with proper status codes
- Custom `AIProviderError` in [services/ai/base.py](../backend/app/services/ai/base.py) for provider
  failures
- All functions have docstrings with Args/Returns/Raises/Side Effects

### Testing markers

Must use pytest markers in test files ([pytest.ini](../backend/pytest.ini)):

- `@pytest.mark.unit` - Fast, no external services
- `@pytest.mark.integration` - Requires DB/Redis/AI providers
- `@pytest.mark.db` - Database-specific tests
- `@pytest.mark.ai` - AI provider interaction tests
- `@pytest.mark.slow` - Tests taking >1s

Fixtures in [tests/conftest.py](../backend/tests/conftest.py) provide: `test_db` (in-memory SQLite),
`client` (AsyncClient), `mock_ai_provider`, `sample_image_bytes`

## Critical Integration Points

### Cache service workflow

[services/cache_service.py](../backend/app/services/cache_service.py) uses **two-tier caching**:

1. Perceptual hash lookup in PostgreSQL (`equipment_cache` table) for similar images
1. Redis cache for fast repeated lookups (TTL from `CACHE_TTL_DAYS`)
1. Threshold: `CACHE_SIMILARITY_THRESHOLD` (default 5) for perceptual hash distance

### Image processing

[services/image_service.py](../backend/app/services/image_service.py):

- Validates: format (JPG/PNG/WebP), size (`MAX_IMAGE_SIZE_MB`), PIL decodability
- Computes perceptual hash using `imagehash.phash()` for cache lookups
- Returns `(bool, str)` tuple: `(is_valid, error_message)`

### Environment variables

Required in [backend/.env](../backend/.env):

- `OPENAI_API_KEY` - If using OpenAI provider
- `DATABASE_URL` - Async PostgreSQL URL (must have `asyncpg` driver)
- `AI_PROVIDER` - One of: `openai`, `clip`, `llava`

Optional but important:

- `USE_GPU=true` and `GPU_DEVICE=cuda:0` for CLIP/LLaVA
- `MODEL_CACHE_DIR=/app/model_cache` for downloaded models
- `ENABLE_REDIS_CACHE=false` to disable Redis (falls back to DB only)

## Helper Scripts

- [scripts/dev.sh](../scripts/dev.sh): Wrapper for docker-compose with shortcuts (`start`, `stop`,
  `logs`, `test`, `db-shell`, `clean`)
- [web-dashboard/app.py](../web-dashboard/app.py): Dash web UI for manual testing at
  http://localhost:8050

## Documentation References

- [docs/architecture.md](../docs/architecture.md): Detailed system design, scalability
  considerations
- [docs/TESTING.md](../docs/TESTING.md): Full testing guide with coverage targets (80% minimum)
- [docs/GETTING_STARTED.md](../docs/GETTING_STARTED.md): Step-by-step setup for new developers
- [docs/docker-secrets.md](../docs/docker-secrets.md): Production secret management
