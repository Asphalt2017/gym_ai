# YAML Configuration Files for Gym AI Helper

This folder stores **YAML configuration files** for all services in the Gym AI Helper project.

> **Note**: Python settings modules (`.py` files) are located in their respective service
> folders.\
> This folder is for YAML/JSON configuration files only.

## 📁 Structure

```
settings/
├── backend.yaml          # Backend service configuration
├── dashboard.yaml        # Web dashboard configuration  
├── database.yaml         # PostgreSQL configuration
├── redis.yaml            # Redis cache configuration
├── ai/                   # AI provider configurations
│   ├── openai.yaml      # OpenAI settings
│   ├── clip.yaml        # CLIP model settings
│   └── llava.yaml       # LLaVA/Ollama settings
├── docker/               # Docker-specific configs
│   ├── development.yaml # Dev environment
│   ├── staging.yaml     # Staging environment
│   └── production.yaml  # Production environment
├── .env.example         # Environment variables template
└── README.md            # This file
```

## 🎯 Purpose

Store YAML configuration files for:

- **Service Configuration**: Backend, dashboard, database settings
- **Environment-Specific Config**: Dev, staging, production
- **AI Provider Settings**: Model configs, API endpoints
- **Docker Overrides**: Service-specific Docker Compose overrides

## 📝 YAML Configuration Examples

### Backend Configuration (backend.yaml)

```yaml
# Backend Service Configuration
app:
  name: Gym AI Helper
  debug: false
  log_level: INFO

server:
  host: 0.0.0.0
  port: 8000
  workers: 4

database:
  url: postgresql+asyncpg://user:pass@postgres:5432/gym_ai
  pool_size: 20
  max_overflow: 10

cache:
  ttl_days: 30
  similarity_threshold: 5

ai:
  provider: openai
  model_cache_dir: /app/model_cache
```

### Dashboard Configuration (dashboard.yaml)

```yaml
# Dashboard Configuration
backend:
  url: http://backend:8000
  api_version: v1

server:
  host: 0.0.0.0
  port: 8100
  debug: false

timeouts:
  health_check: 5.0
  analyze: 30.0

image:
  max_size_mb: 10
  supported_formats:
    - jpg
    - jpeg
    - png
    - webp
```

### AI Provider Configuration (ai/openai.yaml)

```yaml
# OpenAI Provider Configuration
provider: openai

api:
  key: ${OPENAI_API_KEY}  # Load from environment
  model: gpt-4-vision-preview
  max_tokens: 1000
  temperature: 0.7

prompts:
  system: |
    You are an expert gym equipment analyzer.
    Identify equipment and provide usage instructions.

  user_template: |
    Analyze this gym equipment image and provide:
    1. Equipment name
    2. Muscle groups
    3. Usage instructions
```

## 🚀 Usage

### Loading YAML in Python

#### Backend (FastAPI)

```python
# backend/app/core/config.py
import yaml
from pathlib import Path

config_path = Path(__file__).parent.parent.parent.parent / "settings" / "backend.yaml"

with open(config_path) as f:
    config = yaml.safe_load(f)

# Access values
app_name = config["app"]["name"]
port = config["server"]["port"]
```

#### Dashboard (Dash)

```python
# web-dashboard/app.py
python -m web-dashboard.app --setting /path/to/settings/dashboard.yaml
```

Dashboard already supports loading from YAML via CLI:

```bash
python -m web-dashboard.app --setting settings/dashboard.yaml
```

### Loading from Environment Variable

```bash
# Set config path
export BACKEND_CONFIG=settings/backend.yaml
export DASH_SETTING=settings/dashboard.yaml

# Start services
docker-compose up
```

### Docker Compose Integration

```yaml
# docker-compose.yml
services:
  backend:
    volumes:
      - ./settings:/app/settings:ro
    environment:
      - CONFIG_PATH=/app/settings/backend.yaml

  dashboard:
    volumes:
      - ./settings:/app/settings:ro
    command: python -m web-dashboard.app --setting /app/settings/dashboard.yaml
```

## 📂 Python Settings Modules Location

Python configuration modules (`.py` files) are in their respective service folders:

| Service     | Python Settings Location              |
| ----------- | ------------------------------------- |
| Backend     | `backend/app/core/config.py`          |
| Dashboard   | `web-dashboard/settings/dashboard.py` |
| Database    | `backend/app/core/database.py`        |
| AI Services | `backend/app/services/ai/`            |

## 🔄 Configuration Priority

Settings are loaded with this priority (highest to lowest):

1. **Environment variables** - `BACKEND_DEBUG=true`
1. **YAML config files** - `settings/backend.yaml`
1. **Python defaults** - In respective service modules
1. **`.env` file** - Project root `.env`

Example:

```bash
# Environment variable wins
BACKEND_PORT=9000 python backend/app/main.py  # Uses port 9000

# YAML config
python backend/app/main.py --config settings/backend.yaml  # Uses YAML port

# Default from Python module
python backend/app/main.py  # Uses default port 8000
```

## 🎨 YAML Best Practices

### 1. Use Environment Variable Substitution

```yaml
# Good: Load secrets from environment
database:
  password: ${DB_PASSWORD}

# Bad: Hardcode secrets
database:
  password: mysecretpassword123
```

### 2. Organize by Concern

```yaml
# Good: Grouped logically
app:
  name: My App
  debug: false

server:
  host: 0.0.0.0
  port: 8000

# Bad: Flat structure
app_name: My App
debug: false
host: 0.0.0.0
port: 8000
```

### 3. Document with Comments

```yaml
# Server Configuration
server:
  host: 0.0.0.0        # Bind to all interfaces
  port: 8000           # Default HTTP port
  workers: 4           # Number of worker processes
```

### 4. Use Anchors for Reusability

```yaml
# Define once
defaults: &defaults
  timeout: 30
  retries: 3

production:
  <<: *defaults
  environment: prod

staging:
  <<: *defaults
  environment: staging
```

## 🔐 Security

### Never Commit Secrets

```yaml
# ❌ BAD: Hardcoded secrets
api_key: sk-proj-abc123...

# ✅ GOOD: Reference environment variable
api_key: ${OPENAI_API_KEY}
```

### Use .gitignore

```gitignore
# In .gitignore
settings/*-local.yaml
settings/*.secret.yaml
settings/production-*.yaml
```

### Separate Sensitive Configs

```
settings/
├── backend.yaml              # ✅ Safe to commit
├── backend-secrets.yaml      # ❌ Never commit
└── backend-local.yaml        # ❌ Never commit (in .gitignore)
```

## 📖 Example Configurations

### Development Environment (docker/development.yaml)

```yaml
# Development Settings
environment: development

backend:
  debug: true
  log_level: DEBUG
  workers: 1

database:
  url: postgresql+asyncpg://gym_user:gym_dev_password@postgres:5432/gym_ai

ai:
  provider: clip  # Use free local model for dev
  use_gpu: false
```

### Production Environment (docker/production.yaml)

```yaml
# Production Settings
environment: production

backend:
  debug: false
  log_level: WARNING
  workers: 4

database:
  url: ${DATABASE_URL}  # Load from secure environment
  pool_size: 50

ai:
  provider: openai
  api_key: ${OPENAI_API_KEY}  # Load from secrets
```

## 🧪 Testing

### Test Configuration Loading

```python
# tests/test_config.py
import yaml


def test_load_backend_config():
    with open("settings/backend.yaml") as f:
        config = yaml.safe_load(f)

    assert "app" in config
    assert "server" in config
    assert config["server"]["port"] > 0
```

### Validate YAML Syntax

```bash
# Install yamllint
pip install yamllint

# Validate all YAML files
yamllint settings/

# Or specific file
yamllint settings/backend.yaml
```

## 🔄 Migration Guide

### Moving from .env to YAML

**Before (.env):**

```bash
BACKEND_PORT=8000
BACKEND_WORKERS=4
BACKEND_LOG_LEVEL=INFO
```

**After (settings/backend.yaml):**

```yaml
server:
  port: 8000
  workers: 4

logging:
  level: INFO
```

### Combining Multiple Sources

```python
import os
import yaml
from typing import Any, Dict


def load_config(yaml_path: str) -> Dict[str, Any]:
    """Load config from YAML with environment variable overrides."""
    with open(yaml_path) as f:
        config = yaml.safe_load(f)

    # Override with environment variables
    if "BACKEND_PORT" in os.environ:
        config["server"]["port"] = int(os.environ["BACKEND_PORT"])

    return config
```

## 📚 References

- [YAML Specification](https://yaml.org/spec/1.2.2/)
- [PyYAML Documentation](https://pyyaml.org/wiki/PyYAMLDocumentation)
- [12-Factor App Config](https://12factor.net/config)
- [Docker Compose Config Files](https://docs.docker.com/compose/compose-file/)

## 🎯 Next Steps

1. **Create YAML configs**: Use templates above for your services
1. **Update Python modules**: Have them load from YAML files
1. **Test locally**: Validate configs work with your services
1. **Document**: Add service-specific YAML docs
1. **CI/CD**: Add YAML validation to pipelines

## 📁 Structure

```
settings/
├── __init__.py           # Package initialization
├── backend.py            # Backend (FastAPI) settings
├── dashboard.py          # Dashboard (Dash) settings
├── database.py           # PostgreSQL connection settings
├── redis.py              # Redis cache settings
├── ai.py                 # AI provider settings
├── .env.example          # Example environment configuration
└── README.md            # This file
```

## 🎯 Purpose

Centralized settings management provides:

- **Single Source of Truth**: All configuration in one place
- **Type Safety**: Pydantic validation for all settings
- **Environment Variables**: Load from `.env` files
- **Defaults**: Sensible defaults for development
- **Validation**: Automatic validation of configuration values
- **Documentation**: Clear field descriptions

## 🚀 Usage

### Backend Settings

```python
from settings.backend import get_backend_settings

settings = get_backend_settings()
print(settings.database_url)
print(settings.ai_provider)
```

### Dashboard Settings

```python
from settings.dashboard import get_dashboard_settings

settings = get_dashboard_settings()
print(settings.backend_url)
print(settings.port)
```

### Database Settings

```python
from settings.database import get_database_settings

settings = get_database_settings()
print(settings.database_url)
```

### Redis Settings

```python
from settings.redis import get_redis_settings

settings = get_redis_settings()
print(settings.redis_url)
```

### AI Provider Settings

```python
from settings.ai import get_ai_settings

settings = get_ai_settings()
print(settings.provider)
print(settings.openai_model)
```

## 📝 Environment Variables

Each settings module uses a specific prefix:

| Module    | Prefix     | Example              |
| --------- | ---------- | -------------------- |
| Backend   | `BACKEND_` | `BACKEND_DEBUG=true` |
| Dashboard | `DASH_`    | `DASH_PORT=8100`     |
| Database  | `DB_`      | `DB_HOST=postgres`   |
| Redis     | `REDIS_`   | `REDIS_PORT=6379`    |
| AI        | `AI_`      | `AI_PROVIDER=openai` |

### Example `.env` File

```bash
# Backend
BACKEND_DEBUG=true
BACKEND_AI_PROVIDER=openai
BACKEND_OPENAI_API_KEY=sk-proj-your-key

# Dashboard
DASH_DEBUG=false
DASH_PORT=8100

# Database
DB_HOST=postgres
DB_USER=gym_user
DB_PASSWORD=gym_dev_password

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# AI
AI_PROVIDER=openai
AI_USE_GPU=false
```

## 🔧 Integration

### Migrating from Existing Settings

#### Backend (backend/app/core/config.py)

**Before:**

```python
from app.core.config import settings

print(settings.database_url)
```

**After:**

```python
from settings.backend import get_backend_settings

settings = get_backend_settings()
print(settings.database_url)
```

#### Dashboard (web-dashboard/settings/dashboard.py)

**Before:**

```python
from settings import get_settings

settings = get_settings()
```

**After:**

```python
from settings.dashboard import get_dashboard_settings

settings = get_dashboard_settings()
```

### Docker Integration

Mount the settings folder and .env file:

```yaml
# docker-compose.yml
services:
  backend:
    volumes:
      - ./settings:/app/settings
      - ./.env:/app/.env
    environment:
      - PYTHONPATH=/app
```

## 🎨 Features

### Validation

All settings include validation:

```python
# Port must be between 1024-65535
port: int = Field(default=8000, ge=1024, le=65535)


# Log level must be valid
@field_validator("log_level")
@classmethod
def validate_log_level(cls, v: str) -> str:
    valid_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
    if v.upper() not in valid_levels:
        raise ValueError(f"Invalid log level")
    return v.upper()
```

### Computed Properties

Settings provide convenient computed properties:

```python
# Backend
settings.supported_formats_list  # ['jpg', 'jpeg', 'png']
settings.max_image_size_bytes  # 10485760 (10MB in bytes)

# Dashboard
settings.api_endpoint  # http://localhost:8000/api/v1/analyze
settings.health_endpoint  # http://localhost:8000/health

# Database
settings.database_url  # postgresql+asyncpg://user:pass@host/db
```

### Singleton Pattern

Each settings module uses singleton pattern:

```python
# First call loads settings
settings1 = get_backend_settings()

# Subsequent calls return cached instance
settings2 = get_backend_settings()

assert settings1 is settings2  # Same instance
```

To reload settings:

```python
from settings.backend import reload_backend_settings

settings = reload_backend_settings()  # Force reload
```

## 🧪 Testing

Settings can be easily mocked in tests:

```python
import pytest
from settings.backend import BackendSettings


@pytest.fixture
def test_settings():
    return BackendSettings(
        debug=True, database_url="sqlite:///test.db", ai_provider="clip"
    )


def test_something(test_settings):
    assert test_settings.debug is True
```

## 📊 Configuration Priority

Settings are loaded with this priority (highest to lowest):

1. **Explicit constructor arguments**

   ```python
   settings = BackendSettings(debug=True)
   ```

1. **Environment variables**

   ```bash
   BACKEND_DEBUG=true python app.py
   ```

1. **`.env` file**

   ```
   BACKEND_DEBUG=true
   ```

1. **Default values**

   ```python
   debug: bool = Field(default=False)
   ```

## 🔐 Security

### Sensitive Values

Use `SecretStr` for sensitive data:

```python
from pydantic import SecretStr

openai_api_key: SecretStr | None = Field(default=None)

# Access value
api_key = settings.openai_api_key.get_secret_value()

# Printing won't reveal value
print(settings.openai_api_key)  # SecretStr('**********')
```

### Docker Secrets

For production, use Docker secrets:

```python
# Set flag
BACKEND_USE_DOCKER_SECRETS = true

# Settings will load from /run/secrets/
# - /run/secrets/openai_api_key
# - /run/secrets/db_password
```

## 📚 Best Practices

1. **Use Environment Prefixes**: Prevents conflicts between services

   ```bash
   BACKEND_PORT=8000   # Backend port
   DASH_PORT=8100      # Dashboard port
   ```

1. **Provide Defaults**: Always include sensible defaults

   ```python
   port: int = Field(default=8000)
   ```

1. **Add Descriptions**: Document what each field does

   ```python
   port: int = Field(default=8000, description="Server port")
   ```

1. **Validate Values**: Use validators for complex rules

   ```python
   @field_validator("port")
   @classmethod
   def validate_port(cls, v: int) -> int:
       if v < 1024 or v > 65535:
           raise ValueError("Port must be 1024-65535")
       return v
   ```

1. **Use Computed Properties**: Derive values from other settings

   ```python
   @property
   def api_url(self) -> str:
       return f"{self.base_url}/api/{self.version}"
   ```

## 🔄 Migration Guide

### Step 1: Copy .env.example

```bash
cp settings/.env.example .env
# Edit .env with your values
```

### Step 2: Update Imports

Replace old imports:

```python
# Old (backend)
from app.core.config import settings

# New
from settings.backend import get_backend_settings

settings = get_backend_settings()
```

```python
# Old (dashboard)
from utils.config import BACKEND_URL

# New
from settings.dashboard import get_dashboard_settings

settings = get_dashboard_settings()
backend_url = settings.backend_url
```

### Step 3: Update Docker Compose

Add environment file:

```yaml
services:
  backend:
    env_file:
      - .env
```

### Step 4: Test

```bash
# Backend
python -c "from settings.backend import get_backend_settings; print(get_backend_settings().database_url)"

# Dashboard
python -c "from settings.dashboard import get_dashboard_settings; print(get_dashboard_settings().port)"
```

## 🐛 Troubleshooting

### Import Errors

```bash
# Ensure settings folder is in PYTHONPATH
export PYTHONPATH=/path/to/gym_ai:$PYTHONPATH
```

### Validation Errors

```python
# Check which field failed
try:
    settings = BackendSettings()
except ValidationError as e:
    print(e.json())
```

### Environment Not Loaded

```python
# Check .env file location
from pydantic_settings import BaseSettings

print(BaseSettings.model_config["env_file"])  # Should be '.env'
```

## 🎯 Next Steps

1. **Migrate Backend**: Update `backend/app/core/config.py` to use centralized settings
1. **Migrate Dashboard**: Update `web-dashboard/settings/` to use centralized settings
1. **Add Tests**: Create `tests/test_settings.py` for validation tests
1. **Documentation**: Update README.md to reference centralized settings
1. **CI/CD**: Update workflows to use .env.example

## 📖 References

- [Pydantic Settings Documentation](https://docs.pydantic.dev/latest/concepts/pydantic_settings/)
- [Environment Variables Best Practices](https://12factor.net/config)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
