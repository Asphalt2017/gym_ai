# Organizing 3 Repos on GitHub

## 🏗️ Repository Structure Options

You have two main approaches:

### Option 1: Under Your Personal Account ✅ (Recommended for Solo Projects)

```
github.com/Asphalt2017/gym-ai              (main orchestration)
github.com/Asphalt2017/gym-ai-backend      (backend service)
github.com/Asphalt2017/gym-ai-dashboard    (web dashboard)
```

**Pros:**

- Free for all public/private repos
- Simple to manage
- Good for personal/portfolio projects

**Cons:**

- Less professional for team projects
- No team permissions management

### Option 2: Create GitHub Organization 🏢 (Recommended for Teams)

```
github.com/gym-ai-org/gym-ai              (main)
github.com/gym-ai-org/backend             (backend)
github.com/gym-ai-org/dashboard           (dashboard)
```

**Pros:**

- Professional appearance
- Team management (add collaborators)
- Fine-grained permissions
- Better for open source projects

**Cons:**

- Slight learning curve
- Organization name can't be changed easily

## 🚀 Setup Steps

### Step 1: Create Repositories on GitHub

#### For Personal Account:

```bash
# On GitHub.com:
# 1. Click "+" → "New repository"
# 2. Create three repos:

Repository 1:
  Name: gym-ai
  Description: Gym AI Helper - Main orchestration and Docker setup
  Visibility: Public or Private
  Initialize: No (you already have code)

Repository 2:
  Name: gym-ai-backend
  Description: Gym AI Helper - FastAPI backend service
  Visibility: Public or Private
  Initialize: No

Repository 3:
  Name: gym-ai-dashboard
  Description: Gym AI Helper - Dash web dashboard
  Visibility: Public or Private
  Initialize: No
```

#### For GitHub Organization:

```bash
# On GitHub.com:
# 1. Click your profile → "Settings" → "Organizations" → "New organization"
# 2. Choose "Create a free organization"
# 3. Organization name: gym-ai-org (or similar)
# 4. Create three repos under the organization (same as above)
```

### Step 2: Connect Your Local Repos

```bash
# Main repo (gym_ai)
cd /home/roudra/Projects/gym_ai
git remote add origin https://github.com/Asphalt2017/gym-ai.git
git branch -M main
git push -u origin main

# Backend repo
cd /home/roudra/Projects/gym_ai/backend
git init  # If not already a git repo
git remote add origin https://github.com/Asphalt2017/gym-ai-backend.git
git add .
git commit -m "Initial commit: Backend service"
git branch -M main
git push -u origin main

# Dashboard repo
cd /home/roudra/Projects/gym_ai/web-dashboard
git init  # If not already a git repo
git remote add origin https://github.com/Asphalt2017/gym-ai-dashboard.git
git add .
git commit -m "Initial commit: Web dashboard"
git branch -M main
git push -u origin main
```

### Step 3: Setup Submodules in Main Repo

```bash
cd /home/roudra/Projects/gym_ai

# Remove current folders (they'll become submodules)
# Make sure you've pushed them first!
git rm -rf backend web-dashboard
git commit -m "Remove folders before adding as submodules"

# Add as submodules
git submodule add https://github.com/Asphalt2017/gym-ai-backend.git backend
git submodule add https://github.com/Asphalt2017/gym-ai-dashboard.git web-dashboard

# Commit and push
git add .gitmodules backend web-dashboard
git commit -m "Add backend and dashboard as submodules"
git push origin main
```

## 📋 Repository Configuration Best Practices

### 1. Repository Descriptions

**Main Repo (gym-ai):**

```
Gym AI Helper - AI-powered gym equipment recognition system
```

**Backend (gym-ai-backend):**

```
FastAPI backend with OpenAI/CLIP/LLaVA integration for gym equipment analysis
```

**Dashboard (gym-ai-dashboard):**

```
Dash web interface for testing and demonstrating gym equipment recognition
```

### 2. Add Topics/Tags

For each repo, add relevant topics:

**Main Repo:**

- `gym`
- `ai`
- `computer-vision`
- `docker`
- `microservices`

**Backend:**

- `fastapi`
- `python`
- `openai`
- `clip`
- `api`

**Dashboard:**

- `dash`
- `plotly`
- `python`
- `web-dashboard`

### 3. Create README.md for Each Repo

#### Main Repo README.md

```markdown
# Gym AI Helper

AI-powered gym equipment recognition and usage instruction system.

## 📦 Project Structure

This is the main orchestration repository containing:
- Docker Compose configuration
- Shared settings (YAML configs)
- Helper scripts
- Documentation

**Submodules:**
- [Backend](https://github.com/Asphalt2017/gym-ai-backend) - FastAPI service
- [Dashboard](https://github.com/Asphalt2017/gym-ai-dashboard) - Web interface

## 🚀 Quick Start

\`\`\`bash
# Clone with submodules
git clone --recurse-submodules https://github.com/Asphalt2017/gym-ai.git
cd gym-ai

# Start services
./scripts/services.sh start
docker-compose up -d

# Access dashboard at http://localhost:8100
\`\`\`

## 🏗️ Architecture

- **Backend**: FastAPI + PostgreSQL + Redis
- **AI Providers**: OpenAI GPT-4 Vision, CLIP, LLaVA
- **Dashboard**: Dash + Bootstrap
- **Infrastructure**: Docker Compose

## 📚 Documentation

- [Setup Guide](docs/GETTING_STARTED.md)
- [Submodules Guide](SUBMODULES_SETUP.md)
- [Architecture](docs/architecture.md)
```

#### Backend README.md

```markdown
# Gym AI Backend

FastAPI backend service for gym equipment recognition.

## Features

- AI-powered equipment identification (OpenAI, CLIP, LLaVA)
- Perceptual image hashing for caching
- PostgreSQL + Redis caching
- Async SQLAlchemy ORM

## 🚀 Quick Start

\`\`\`bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
cp .env.example .env
# Edit .env with your API keys

# Run locally
python -m app.main

# Or with Docker
docker build -t gym-ai-backend .
docker run -p 8000:8000 gym-ai-backend
\`\`\`

## 📖 API Documentation

Once running, visit: http://localhost:8000/docs

## 🔗 Main Project

This is a submodule of [Gym AI Helper](https://github.com/Asphalt2017/gym-ai)
```

#### Dashboard README.md

```markdown
# Gym AI Dashboard

Web interface for testing gym equipment recognition.

## Features

- Upload images via drag-and-drop
- Real-time analysis results
- Health monitoring
- YAML configuration support

## 🚀 Quick Start

\`\`\`bash
# Install dependencies
pip install -r requirements.txt

# Run dashboard
python -m web-dashboard.app --debug --port 8100

# Or with YAML config
python -m web-dashboard.app --setting config.yaml
\`\`\`

## 📖 Usage

Visit: http://localhost:8100

## 🔗 Main Project

This is a submodule of [Gym AI Helper](https://github.com/Asphalt2017/gym-ai)
```

### 4. Add LICENSE Files

Choose a license (MIT is common for open source):

```bash
# In each repo, create LICENSE file
# GitHub can generate this for you:
# Repo → Add file → Create new file → Name it "LICENSE"
# Click "Choose a license template" → Select MIT/Apache/GPL
```

### 5. Setup Branch Protection (Optional)

For main repos, protect the `main` branch:

1. Go to repo → Settings → Branches
1. Add rule for `main` branch:
   - ✅ Require pull request reviews
   - ✅ Require status checks to pass
   - ✅ Require branches to be up to date

## 🔗 Linking Repos Together

### 1. Add Links in README

In each repo's README, add links to related repos.

### 2. Use GitHub Topics

Add the same custom topic to all three repos:

- Topic: `gym-ai-helper`

This lets people find all related repos.

### 3. Add to Organization/Profile README

Create a profile README showcasing your project:

```markdown
## 🏋️ Gym AI Helper

Multi-repo project for AI-powered gym equipment recognition:

- [Main Repo](https://github.com/Asphalt2017/gym-ai) - Orchestration
- [Backend](https://github.com/Asphalt2017/gym-ai-backend) - API Service
- [Dashboard](https://github.com/Asphalt2017/gym-ai-dashboard) - Web UI
```

## 📊 Repository Settings

### Main Repo (gym-ai)

**Settings:**

```
Features:
  ✅ Issues
  ✅ Projects
  ✅ Wiki
  ✅ Discussions (optional)

Security:
  ✅ Dependabot alerts
  ✅ Code scanning (if public)
```

### Backend & Dashboard

**Settings:**

```
Features:
  ✅ Issues (link to main repo issues)
  ❌ Projects (use main repo)
  ❌ Wiki (centralize in main repo)
```

## 🎯 Workflow Example

### Developer Workflow

```bash
# 1. Clone main repo with submodules
git clone --recurse-submodules https://github.com/Asphalt2017/gym-ai.git
cd gym-ai

# 2. Work on backend
cd backend
git checkout -b feature/new-endpoint
# ... make changes ...
git commit -m "Add new endpoint"
git push origin feature/new-endpoint

# 3. Create PR on backend repo
# Merge on GitHub

# 4. Update main repo
git checkout main
git pull origin main
cd ..
git submodule update --remote backend
git add backend
git commit -m "Update backend submodule"
git push origin main
```

### CI/CD Integration

Each repo can have its own `.github/workflows/`:

**Backend: `.github/workflows/test.yml`**

```yaml
name: Backend Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: pytest
```

**Main Repo: `.github/workflows/integration.yml`**

```yaml
name: Integration Tests
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: recursive
      - name: Start services
        run: docker-compose up -d
      - name: Run integration tests
        run: ./scripts/integration-test.sh
```

## 🎨 Visual Organization

### Main Repo

```
gym-ai/
├── README.md                 ← Links to backend & dashboard
├── docker-compose.yml
├── settings/                 ← Shared YAML configs
├── scripts/                  ← Helper scripts
├── docs/                     ← Main documentation
├── backend/                  ← Git submodule
└── web-dashboard/            ← Git submodule
```

### Backend Repo

```
gym-ai-backend/
├── README.md                 ← Links back to main repo
├── app/
├── tests/
├── requirements.txt
└── Dockerfile
```

### Dashboard Repo

```
gym-ai-dashboard/
├── README.md                 ← Links back to main repo
├── pages/
├── templates/
├── requirements.txt
└── Dockerfile
```

## ✅ Final Checklist

### Initial Setup

- [ ] Create 3 repos on GitHub
- [ ] Push each codebase to its repo
- [ ] Add descriptive README to each
- [ ] Add LICENSE files
- [ ] Setup .gitignore files
- [ ] Add topics/tags

### Submodule Setup

- [ ] Remove folders from main repo
- [ ] Add backend as submodule
- [ ] Add dashboard as submodule
- [ ] Commit .gitmodules
- [ ] Test fresh clone works

### Documentation

- [ ] Update all READMEs with links
- [ ] Add SUBMODULES_SETUP.md to main repo
- [ ] Document environment variables
- [ ] Add architecture diagram

### Optional

- [ ] Setup branch protection
- [ ] Enable Dependabot
- [ ] Add CI/CD workflows
- [ ] Create GitHub Organization
- [ ] Setup project boards

## 🔒 Security Considerations

**Never commit:**

- `.env` files
- API keys
- Passwords
- SSH keys

**Always use:**

- `.gitignore` files
- GitHub Secrets for CI/CD
- Environment variables
- Docker secrets in production

## 📚 Additional Resources

- [GitHub Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [Organizing Repos](https://docs.github.com/en/repositories)
- [GitHub Organizations](https://docs.github.com/en/organizations)
- [Monorepo vs Multi-repo](https://kinsta.com/blog/monorepo-vs-multi-repo/)

______________________________________________________________________

## 🎯 Recommended Setup for You

Based on your project being solo/portfolio:

1. **Use your personal account** (Asphalt2017)
1. **Repo names:**
   - `gym-ai` (main)
   - `gym-ai-backend`
   - `gym-ai-dashboard`
1. **Keep all repos public** (good for portfolio)
1. **Use submodules** for linking
1. **Add comprehensive READMEs** to showcase your work
