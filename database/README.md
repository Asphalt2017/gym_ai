# Database

PostgreSQL database schema and initialization scripts for Gym AI Helper.

## Schema Overview

### Tables

#### 1. **equipment**

Stores gym equipment information with usage instructions.

| Column            | Type         | Description               |
| ----------------- | ------------ | ------------------------- |
| id                | UUID         | Primary key               |
| name              | VARCHAR(200) | Equipment name (unique)   |
| category          | VARCHAR(50)  | Muscle group category     |
| muscle_groups     | TEXT\[\]     | Array of targeted muscles |
| instructions_text | TEXT         | Step-by-step usage guide  |
| video_urls        | TEXT\[\]     | Tutorial video links      |
| created_at        | TIMESTAMP    | Record creation time      |
| updated_at        | TIMESTAMP    | Last modification time    |

**Indexes:**

- `idx_equipment_name` on `name`
- `idx_equipment_category` on `category`

#### 2. **equipment_cache**

Caches AI analysis results using perceptual image hashing.

| Column         | Type         | Description                         |
| -------------- | ------------ | ----------------------------------- |
| id             | UUID         | Primary key                         |
| image_hash     | VARCHAR(100) | Perceptual hash (pHash)             |
| equipment_id   | UUID         | Foreign key to equipment (nullable) |
| ai_response    | JSONB        | Complete analysis result            |
| created_at     | TIMESTAMP    | Analysis timestamp                  |
| ttl_expires_at | TIMESTAMP    | Cache expiration time               |

**Indexes:**

- `idx_cache_image_hash` on `image_hash` (unique)
- `idx_cache_ttl` on `ttl_expires_at`
- `idx_cache_equipment_id` on `equipment_id`

#### 3. **user_identifications**

Tracks user query history for analytics (optional).

| Column       | Type         | Description                 |
| ------------ | ------------ | --------------------------- |
| id           | UUID         | Primary key                 |
| user_id      | VARCHAR(100) | User identifier (optional)  |
| equipment_id | UUID         | Foreign key to equipment    |
| image_url    | VARCHAR(500) | Stored image URL (optional) |
| confidence   | INTEGER      | AI confidence (0-100)       |
| timestamp    | TIMESTAMP    | Query timestamp             |

**Indexes:**

- `idx_user_id` on `user_id`
- `idx_timestamp` on `timestamp`
- `idx_equipment_id` on `equipment_id`

## Database Initialization

The database is automatically initialized when the PostgreSQL container starts:

1. **init.sql** - Creates schema and tables
1. **seed.sql** - Populates with ~20 common gym equipment entries

### Manual Initialization

If needed, run initialization manually:

```bash
# Connect to PostgreSQL container
docker exec -it gym_ai_postgres psql -U gym_user -d gym_ai

# Run initialization script
\i /docker-entrypoint-initdb.d/01-init.sql
\i /docker-entrypoint-initdb.d/02-seed.sql
```

## Querying the Database

### Get all equipment

```sql
SELECT name, category, muscle_groups
FROM equipment
ORDER BY category, name;
```

### Check cache statistics

```sql
SELECT
    COUNT(*) as total_entries,
    COUNT(*) FILTER (WHERE ttl_expires_at > CURRENT_TIMESTAMP) as active_entries,
    COUNT(*) FILTER (WHERE ttl_expires_at <= CURRENT_TIMESTAMP) as expired_entries
FROM equipment_cache;
```

### Find cached analyses for specific equipment

```sql
SELECT
    ec.image_hash,
    eq.name,
    ec.ai_response->>'confidence' as confidence,
    ec.created_at,
    ec.ttl_expires_at
FROM equipment_cache ec
LEFT JOIN equipment eq ON ec.equipment_id = eq.id
WHERE ec.ttl_expires_at > CURRENT_TIMESTAMP
ORDER BY ec.created_at DESC;
```

### Get usage statistics

```sql
SELECT
    eq.name,
    eq.category,
    COUNT(ui.id) as identification_count
FROM equipment eq
LEFT JOIN user_identifications ui ON eq.id = ui.equipment_id
GROUP BY eq.id, eq.name, eq.category
ORDER BY identification_count DESC
LIMIT 10;
```

## Cache Management

### Clear expired cache entries

```sql
DELETE FROM equipment_cache
WHERE ttl_expires_at <= CURRENT_TIMESTAMP;
```

### Clear all cache (useful for testing)

```sql
TRUNCATE equipment_cache;
```

### Update cache TTL

```sql
-- Extend TTL by 30 days for specific hash
UPDATE equipment_cache
SET ttl_expires_at = CURRENT_TIMESTAMP + INTERVAL '30 days'
WHERE image_hash = 'your_hash_here';
```

## Backup and Restore

### Backup database

```bash
# Backup to file
docker exec gym_ai_postgres pg_dump -U gym_user gym_ai > backup.sql

# Backup specific table
docker exec gym_ai_postgres pg_dump -U gym_user -t equipment gym_ai > equipment_backup.sql
```

### Restore database

```bash
# Restore from backup
docker exec -i gym_ai_postgres psql -U gym_user -d gym_ai < backup.sql
```

## Migrations

For production deployments, use Alembic for schema migrations:

```bash
# Generate migration
docker-compose exec backend alembic revision --autogenerate -m "Description"

# Apply migrations
docker-compose exec backend alembic upgrade head

# Rollback one version
docker-compose exec backend alembic downgrade -1
```

## Performance Optimization

### Add pgvector extension (for future semantic search)

```sql
CREATE EXTENSION IF NOT EXISTS vector;

-- Add embedding column to equipment
ALTER TABLE equipment
ADD COLUMN embedding vector(512);

-- Create index for similarity search
CREATE INDEX equipment_embedding_idx
ON equipment
USING ivfflat (embedding vector_cosine_ops);
```

### Analyze query performance

```sql
EXPLAIN ANALYZE
SELECT * FROM equipment_cache
WHERE image_hash = 'test_hash'
AND ttl_expires_at > CURRENT_TIMESTAMP;
```

## Troubleshooting

### Connection issues

```bash
# Test connection
docker exec gym_ai_postgres pg_isready -U gym_user

# Check logs
docker logs gym_ai_postgres
```

### Reset database

```bash
# Stop containers and remove volumes
docker-compose down -v

# Restart (will reinitialize)
docker-compose up postgres
```

### Check table sizes

```sql
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```
