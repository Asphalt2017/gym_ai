# Git Submodules Setup Guide

## What Are Git Submodules?

Git submodules allow you to include external Git repositories inside your main repository while
keeping them as separate, independent repositories. Each submodule:

- Has its own `.git` folder and history
- Points to a specific commit in the external repo
- Can be updated independently
- Requires explicit commands to sync changes

## 📋 Initial Setup

### Step 1: Ensure Repos Are Pushed to GitHub

Make sure your backend and web-dashboard repos are on GitHub:

```bash
# Backend repo
cd /path/to/backend
git remote -v
# Should show: origin  https://github.com/youruser/backend.git

# Dashboard repo
cd /path/to/web-dashboard
git remote -v
# Should show: origin  https://github.com/youruser/web-dashboard.git
```

### Step 2: Add Submodules to Main Repo

```bash
cd /home/roudra/Projects/gym_ai

# Remove existing folders (backup first if needed!)
mv backend backend-backup
mv web-dashboard web-dashboard-backup

# Add as submodules (replace with your actual GitHub URLs)
git submodule add https://github.com/Asphalt2017/gym-ai-backend.git backend
git submodule add https://github.com/Asphalt2017/gym-ai-dashboard.git web-dashboard

# This creates:
# - backend/ folder (linked to backend repo)
# - web-dashboard/ folder (linked to dashboard repo)
# - .gitmodules file (config)
```

### Step 3: Commit the Submodule Configuration

```bash
git add .gitmodules backend web-dashboard
git commit -m "Add backend and web-dashboard as submodules"
git push origin main
```

## 🔄 Daily Workflow

### Cloning the Main Repo (Fresh Start)

```bash
# Clone main repo
git clone https://github.com/Asphalt2017/gym_ai.git
cd gym_ai

# Initialize and fetch submodules
git submodule init
git submodule update

# Or do it in one command:
git clone --recurse-submodules https://github.com/Asphalt2017/gym_ai.git
```

### Working on Submodule Code

```bash
# Navigate to submodule
cd backend

# Create branch and make changes
git checkout -b feature/new-endpoint
# ... edit files ...
git add .
git commit -m "Add new endpoint"

# Push to submodule repo
git push origin feature/new-endpoint

# Go back to main repo
cd ..

# Main repo sees backend submodule has changed
git status
# Shows: modified:   backend (new commits)

# Commit the submodule pointer update
git add backend
git commit -m "Update backend submodule to latest"
git push origin main
```

### Updating Submodules to Latest

```bash
cd /home/roudra/Projects/gym_ai

# Update all submodules to their latest commits
git submodule update --remote --merge

# Or update specific submodule
git submodule update --remote backend

# Commit the update
git add backend web-dashboard
git commit -m "Update submodules to latest"
git push
```

### Pulling Changes with Submodules

```bash
# Pull main repo changes
git pull origin main

# Update submodules to match main repo's pointers
git submodule update --init --recursive
```

## 📊 Submodule Status Commands

```bash
# Check submodule status
git submodule status

# Output example:
# +abc123 backend (heads/main)
# +def456 web-dashboard (heads/main)
# The '+' means the submodule has uncommitted changes

# See which commit each submodule points to
git ls-tree main backend web-dashboard

# Check for submodule updates
git submodule update --remote --dry-run
```

## 🎯 Common Scenarios

### Scenario 1: Fix Bug in Backend

```bash
# 1. Go to backend submodule
cd backend

# 2. Create branch
git checkout -b fix/bug-123

# 3. Make changes
nano app/main.py
git add app/main.py
git commit -m "Fix bug #123"

# 4. Push to backend repo
git push origin fix/bug-123

# 5. Merge on GitHub, then update locally
git checkout main
git pull origin main

# 6. Update main repo to use new backend version
cd ..
git add backend
git commit -m "Update backend: fix bug #123"
git push origin main
```

### Scenario 2: Update Dashboard Dependencies

```bash
cd web-dashboard

git checkout -b update/deps
pip install --upgrade dash
pip freeze > requirements.txt

git add requirements.txt
git commit -m "Update dash to latest version"
git push origin update/deps

# Merge on GitHub
git checkout main
git pull origin main

cd ..
git add web-dashboard
git commit -m "Update dashboard dependencies"
git push origin main
```

### Scenario 3: Reset Submodule to Clean State

```bash
# Discard all changes in backend
cd backend
git reset --hard HEAD
git clean -fdx

cd ..

# Or reset all submodules
git submodule foreach --recursive git reset --hard
git submodule foreach --recursive git clean -fdx
```

### Scenario 4: Someone Else Updated Submodules

```bash
# You pull main repo
git pull origin main

# You see: "modified: backend" but you haven't changed it
# This means the submodule pointer changed

# Update submodules to match
git submodule update --init --recursive

# Now backend/ is at the correct commit
```

## 🔧 Configuration Tips

### Auto-Update Submodules on Pull

```bash
git config submodule.recurse true
# Now 'git pull' automatically updates submodules
```

### Set Default Branch for Submodules

```bash
# In .gitmodules file
[submodule "backend"]
    path = backend
    url = https://github.com/Asphalt2017/gym-ai-backend.git
    branch = main

[submodule "web-dashboard"]
    path = web-dashboard
    url = https://github.com/Asphalt2017/gym-ai-dashboard.git
    branch = main
```

### Useful Aliases

```bash
# Add to ~/.gitconfig or .git/config
[alias]
    sup = submodule update --remote --merge
    spush = push --recurse-submodules=on-demand
    sclone = clone --recurse-submodules
```

## ⚠️ Common Pitfalls

### 1. Detached HEAD State

When you `cd` into a submodule, you're often in detached HEAD state:

```bash
cd backend
git status
# HEAD detached at abc123

# Fix: checkout a branch
git checkout main
```

### 2. Forgetting to Push Submodule Changes

You commit in submodule but forget to push:

```bash
cd backend
git commit -m "Add feature"
cd ..
git commit -m "Update backend"
git push  # Main repo pushes, but backend changes aren't pushed!

# Fix: push submodule first
cd backend
git push origin main
cd ..
git push origin main
```

### 3. Submodule Pointer Conflicts

If two people update the same submodule:

```bash
git pull origin main
# CONFLICT in backend (submodule pointer)

# Resolve:
cd backend
git fetch origin
git checkout main
git pull origin main
cd ..
git add backend
git commit
```

## 🚀 Docker Compose Integration

Update your `docker-compose.yml`:

```yaml
services:
  backend:
    build:
      context: ./backend  # Now points to submodule
      dockerfile: Dockerfile
    volumes:
      - ./backend:/app  # Mount submodule directory

  dashboard:
    build:
      context: ./web-dashboard  # Now points to submodule
      dockerfile: Dockerfile
    volumes:
      - ./web-dashboard:/app
```

No changes needed! Submodules work like regular directories.

## 📚 Quick Reference

| Task                          | Command                                 |
| ----------------------------- | --------------------------------------- |
| Add submodule                 | `git submodule add <url> <path>`        |
| Clone with submodules         | `git clone --recurse-submodules <url>`  |
| Initialize submodules         | `git submodule init`                    |
| Update submodules             | `git submodule update --remote`         |
| Update specific submodule     | `git submodule update --remote backend` |
| Check status                  | `git submodule status`                  |
| Run command in all submodules | `git submodule foreach <command>`       |
| Remove submodule              | See removal section below               |

## 🗑️ Removing a Submodule

```bash
# 1. Deinitialize
git submodule deinit -f backend

# 2. Remove from git
git rm -f backend

# 3. Remove leftover files
rm -rf .git/modules/backend

# 4. Commit
git commit -m "Remove backend submodule"
```

## 🎓 Best Practices

1. **Always commit and push submodule changes BEFORE updating main repo**
1. **Document submodule URLs in README**
1. **Use branches, not detached HEAD**
1. **Run `git submodule update` after pulling main repo**
1. **Use `--recurse-submodules` flag for operations**
1. **Keep submodules shallow if possible**: `git submodule update --depth 1`

## 🔗 Alternative: Git Subtree

If submodules seem complex, consider `git subtree`:

```bash
# Add backend as subtree (not submodule)
git subtree add --prefix=backend https://github.com/user/backend.git main --squash

# Push changes back
git subtree push --prefix=backend https://github.com/user/backend.git main

# Pull updates
git subtree pull --prefix=backend https://github.com/user/backend.git main --squash
```

Subtree is simpler but less flexible than submodules.

## 📖 Learn More

- [Git Submodules Documentation](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [GitHub Submodules Guide](https://github.blog/2016-02-01-working-with-submodules/)
- [Atlassian Submodules Tutorial](https://www.atlassian.com/git/tutorials/git-submodule)

______________________________________________________________________

## ✅ Setup Checklist

- [ ] Backend repo pushed to GitHub
- [ ] Dashboard repo pushed to GitHub
- [ ] Backup existing backend/ and web-dashboard/ folders
- [ ] Add backend as submodule
- [ ] Add web-dashboard as submodule
- [ ] Commit .gitmodules and submodule references
- [ ] Test: Clone main repo fresh and initialize submodules
- [ ] Configure submodule.recurse = true
- [ ] Update team documentation
- [ ] Update CI/CD pipelines if needed
