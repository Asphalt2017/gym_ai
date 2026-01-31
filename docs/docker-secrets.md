# Docker Secrets Management Guide

Comprehensive guide for securely managing API keys and sensitive configuration in Docker
deployments.

## Overview

Docker Secrets provides a secure way to store and manage sensitive data like API keys, passwords,
and certificates. Secrets are encrypted at rest and in transit, and are only available to authorized
containers.

## Development vs Production

### Development (docker-compose.yml)

For local development, use environment variables with `.env` files:

```yaml
# docker-compose.yml
services:
  backend:
    env_file:
      - ./backend/.env
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
```

**Advantages:**

- Easy to use and modify
- Quick iteration during development
- No additional setup required

**Disadvantages:**

- Less secure (plaintext in .env files)
- Not suitable for production
- Risk of accidentally committing secrets

### Production (docker-compose.prod.yml)

For production, use Docker Secrets or cloud secret managers:

```yaml
# docker-compose.prod.yml
services:
  backend:
    secrets:
      - openai_api_key
      - db_password
    environment:
      - USE_DOCKER_SECRETS=true

secrets:
  openai_api_key:
    external: true
  db_password:
    external: true
```

## Using Docker Secrets

### 1. Create Secrets

```bash
# From file
echo "sk-proj-abc123..." | docker secret create openai_api_key -

# From stdin
docker secret create db_password -
# Type password and press Ctrl+D

# From file
docker secret create openai_api_key ./secrets/openai_key.txt
```

### 2. List Secrets

```bash
docker secret ls
```

### 3. Inspect Secret Metadata

```bash
docker secret inspect openai_api_key
```

Note: You cannot view the actual secret value after creation.

### 4. Remove Secrets

```bash
docker secret rm openai_api_key
```

### 5. Update Secrets

Secrets are immutable. To update:

```bash
# Remove old secret
docker secret rm openai_api_key

# Create new secret
echo "new_key_value" | docker secret create openai_api_key -

# Restart services
docker stack deploy -c docker-compose.prod.yml gym_ai
```

## Backend Integration

### Reading Docker Secrets

The backend automatically reads secrets from `/run/secrets/` when `USE_DOCKER_SECRETS=true`:

```python
# app/core/config.py
if self.use_docker_secrets:
    openai_secret_path = "/run/secrets/openai_api_key"
    if os.path.exists(openai_secret_path):
        with open(openai_secret_path, "r") as f:
            self.openai_api_key = SecretStr(f.read().strip())
```

### Available Secrets

| Secret Name      | Description                     | Required                 |
| ---------------- | ------------------------------- | ------------------------ |
| `openai_api_key` | OpenAI API key for GPT-4 Vision | If using OpenAI provider |
| `db_password`    | PostgreSQL database password    | Yes                      |

### Adding New Secrets

1. Create secret file handler in `config.py`:

```python
# In _load_docker_secrets method
my_secret_path = os.path.join(secrets_dir, "my_secret_name")
if os.path.exists(my_secret_path):
    with open(my_secret_path, "r") as f:
        self.my_secret = SecretStr(f.read().strip())
```

2. Add to `docker-compose.prod.yml`:

```yaml
services:
  backend:
    secrets:
      - my_secret_name

secrets:
  my_secret_name:
    external: true
```

3. Create the secret:

```bash
echo "secret_value" | docker secret create my_secret_name -
```

## Cloud Secret Managers

### AWS Secrets Manager

#### Setup

```bash
# Install AWS CLI
pip install awscli

# Configure credentials
aws configure
```

#### Create Secret

```bash
aws secretsmanager create-secret \
    --name gym-ai/openai-api-key \
    --secret-string "sk-proj-abc123..."
```

#### Backend Integration

```python
import boto3
from botocore.exceptions import ClientError


def get_secret(secret_name):
    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager", region_name="us-east-1")

    try:
        response = client.get_secret_value(SecretId=secret_name)
        return response["SecretString"]
    except ClientError as e:
        raise Exception(f"Failed to retrieve secret: {e}")


# Usage
openai_key = get_secret("gym-ai/openai-api-key")
```

#### Docker Integration

```yaml
# docker-compose.yml
services:
  backend:
    environment:
      - AWS_REGION=us-east-1
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - SECRET_MANAGER=aws
```

### Azure Key Vault

#### Setup

```bash
# Install Azure CLI
pip install azure-cli

# Login
az login
```

#### Create Secret

```bash
az keyvault secret set \
    --vault-name gym-ai-vault \
    --name openai-api-key \
    --value "sk-proj-abc123..."
```

#### Backend Integration

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient


def get_azure_secret(vault_url, secret_name):
    credential = DefaultAzureCredential()
    client = SecretClient(vault_url=vault_url, credential=credential)
    secret = client.get_secret(secret_name)
    return secret.value


# Usage
vault_url = "https://gym-ai-vault.vault.azure.net/"
openai_key = get_azure_secret(vault_url, "openai-api-key")
```

### Google Cloud Secret Manager

#### Setup

```bash
# Install gcloud CLI
pip install google-cloud-secret-manager

# Authenticate
gcloud auth login
```

#### Create Secret

```bash
echo "sk-proj-abc123..." | gcloud secrets create openai-api-key \
    --data-file=-
```

#### Backend Integration

```python
from google.cloud import secretmanager


def get_gcp_secret(project_id, secret_id):
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")


# Usage
openai_key = get_gcp_secret("gym-ai-project", "openai-api-key")
```

### HashiCorp Vault

#### Setup

```bash
# Start Vault (development mode)
vault server -dev

# Set environment
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='dev-token'
```

#### Create Secret

```bash
vault kv put secret/gym-ai/openai-api-key value="sk-proj-abc123..."
```

#### Backend Integration

```python
import hvac


def get_vault_secret(vault_url, token, path):
    client = hvac.Client(url=vault_url, token=token)
    secret = client.secrets.kv.v2.read_secret_version(path=path)
    return secret["data"]["data"]


# Usage
vault_client = hvac.Client(url="http://vault:8200", token=os.getenv("VAULT_TOKEN"))
secret = vault_client.secrets.kv.v2.read_secret_version(path="gym-ai/openai-api-key")
openai_key = secret["data"]["data"]["value"]
```

## Best Practices

### 1. Never Commit Secrets to Git

```bash
# .gitignore
.env
.env.local
*.pem
*.key
secrets/
```

### 2. Rotate Secrets Regularly

```bash
# Rotation script
#!/bin/bash
NEW_KEY=$(generate_new_key)
echo "$NEW_KEY" | docker secret create openai_api_key_v2 -
docker service update --secret-rm openai_api_key --secret-add openai_api_key_v2 backend
docker secret rm openai_api_key
docker secret create openai_api_key - <<< "$NEW_KEY"
```

### 3. Use Different Secrets Per Environment

```
Development: gym-ai-dev/openai-key
Staging: gym-ai-staging/openai-key
Production: gym-ai-prod/openai-key
```

### 4. Implement Least Privilege

```bash
# Only grant necessary permissions
aws secretsmanager put-resource-policy \
    --secret-id gym-ai/openai-key \
    --resource-policy '{
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Principal": {"AWS": "arn:aws:iam::123456:role/gym-ai-backend"},
        "Action": "secretsmanager:GetSecretValue",
        "Resource": "*"
      }]
    }'
```

### 5. Monitor Secret Access

Enable audit logging for secret access:

```yaml
# CloudWatch Logs for AWS
aws secretsmanager update-secret \
    --secret-id gym-ai/openai-key \
    --enable-automatic-rotation
```

### 6. Use Secret Versioning

```bash
# Create versioned secret
aws secretsmanager put-secret-value \
    --secret-id gym-ai/openai-key \
    --secret-string "new_key_value" \
    --version-stages AWSCURRENT AWSPENDING
```

## Troubleshooting

### Secret Not Found

```bash
# Check if secret exists
docker secret ls | grep openai_api_key

# Recreate if missing
echo "your_key" | docker secret create openai_api_key -
```

### Permission Denied

```bash
# Check container has access
docker-compose exec backend ls -la /run/secrets/

# Verify secret is mounted
docker-compose exec backend cat /run/secrets/openai_api_key
```

### Secret Not Updating

```bash
# Secrets are immutable - must recreate
docker secret rm openai_api_key
echo "new_key" | docker secret create openai_api_key -
docker-compose up -d --force-recreate backend
```

## Migration Guide

### From Environment Variables to Docker Secrets

1. Export current secrets:

   ```bash
   echo $OPENAI_API_KEY > /tmp/openai_key.txt
   ```

1. Create Docker secrets:

   ```bash
   docker secret create openai_api_key /tmp/openai_key.txt
   rm /tmp/openai_key.txt  # Clean up
   ```

1. Update docker-compose.prod.yml

1. Set `USE_DOCKER_SECRETS=true`

1. Redeploy application

## Security Checklist

- [ ] Secrets never committed to version control
- [ ] `.env` files in `.gitignore`
- [ ] Different secrets for dev/staging/prod
- [ ] Secrets rotated every 90 days
- [ ] Audit logging enabled
- [ ] Least privilege access configured
- [ ] Secrets encrypted at rest and in transit
- [ ] Backup/recovery plan documented
- [ ] Team trained on secret management
- [ ] Automated secret scanning in CI/CD

## Additional Resources

- [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/)
- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [Azure Key Vault](https://azure.microsoft.com/en-us/services/key-vault/)
- [Google Secret Manager](https://cloud.google.com/secret-manager)
- [HashiCorp Vault](https://www.vaultproject.io/)
