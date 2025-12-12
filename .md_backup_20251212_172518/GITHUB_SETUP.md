# 📤 Push Code to GitHub - Step by Step Guide

Complete guide to push your Easy Basket code to GitHub.

---

## 🎯 Step 1: Create GitHub Repository

1. **Go to GitHub:** https://github.com
2. **Sign in** (or create account)
3. **Click** the **"+"** icon (top right) → **"New repository"**
4. **Repository details:**
   - **Repository name:** `easy-basket` (or your choice)
   - **Description:** "Easy Basket - Instant Grocery Delivery App"
   - **Visibility:** 
     - **Public** (free, anyone can see)
     - **Private** (requires GitHub Pro, or free for students)
   - **DO NOT** check "Initialize with README" (we already have code)
5. **Click** "Create repository"

6. **Copy the repository URL:**
   - HTTPS: `https://github.com/YOUR_USERNAME/easy-basket.git`
   - SSH: `git@github.com:YOUR_USERNAME/easy-basket.git`

---

## 🔧 Step 2: Initialize Git (if not already done)

### Check if Git is initialized:

```bash
cd /Users/nikhil/Projects/easyBucket
git status
```

### If you see "not a git repository", initialize:

```bash
git init
```

---

## 📝 Step 3: Create/Update .gitignore

Make sure sensitive files are NOT committed:

**File:** `.gitignore` (in project root)

```gitignore
# Dependencies
node_modules/
backend/node_modules/
mobile/.dart_tool/
mobile/build/
mobile/.flutter-plugins
mobile/.flutter-plugins-dependencies

# Environment variables (IMPORTANT!)
.env
backend/.env
*.env
.env.local
.env.production

# Build outputs
backend/dist/
backend/build/
mobile/build/
mobile/.dart_tool/

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# AWS Keys (IMPORTANT!)
*.pem
*.key
*.p12
*.p8

# Firebase
firebase-debug.log
.firebase/

# Flutter
mobile/.flutter-plugins
mobile/.flutter-plugins-dependencies
mobile/.packages
mobile/.pub-cache/
mobile/.pub/
mobile/pubspec.lock

# TypeScript
*.tsbuildinfo

# Database
*.sql
*.db
*.sqlite
```

---

## 📦 Step 4: Add Files to Git

```bash
cd /Users/nikhil/Projects/easyBucket

# Add all files
git add .

# Or add specific files/folders
git add backend/
git add mobile/
git add *.md
```

---

## 💾 Step 5: Commit Changes

```bash
# First commit
git commit -m "Initial commit: Easy Basket MVP"

# Or for updates
git commit -m "Add AWS deployment guide and database setup"
```

---

## 🔗 Step 6: Connect to GitHub

```bash
# Add remote repository (replace with your GitHub URL)
git remote add origin https://github.com/YOUR_USERNAME/easy-basket.git

# Verify remote
git remote -v
```

---

## 🚀 Step 7: Push to GitHub

### First time push:

```bash
# Push to main branch
git branch -M main
git push -u origin main
```

### If you get authentication error:

**Option 1: Use Personal Access Token (Recommended)**

1. **GitHub** → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. **Generate new token (classic)**
3. **Select scopes:** `repo` (full control)
4. **Generate token** and **copy it** (save it, you won't see it again!)
5. **Use token as password** when pushing:
   ```bash
   git push -u origin main
   # Username: YOUR_GITHUB_USERNAME
   # Password: YOUR_PERSONAL_ACCESS_TOKEN
   ```

**Option 2: Use SSH (More Secure)**

1. **Generate SSH key:**
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   # Press Enter for default location
   # Enter passphrase (optional)
   ```

2. **Copy public key:**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   # Copy the output
   ```

3. **Add to GitHub:**
   - GitHub → **Settings** → **SSH and GPG keys** → **New SSH key**
   - Paste your public key
   - **Add SSH key**

4. **Use SSH URL:**
   ```bash
   git remote set-url origin git@github.com:YOUR_USERNAME/easy-basket.git
   git push -u origin main
   ```

---

## 📋 Complete Command Sequence

```bash
# Navigate to project
cd /Users/nikhil/Projects/easyBucket

# Initialize git (if not done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit: Easy Basket MVP"

# Add remote (replace with your GitHub URL)
git remote add origin https://github.com/YOUR_USERNAME/easy-basket.git

# Push to GitHub
git branch -M main
git push -u origin main
```

---

## 🔄 Future Updates

After making changes:

```bash
# Check what changed
git status

# Add changes
git add .

# Commit
git commit -m "Description of changes"

# Push
git push
```

---

## ⚠️ Important: Don't Commit These!

**NEVER commit:**
- `.env` files (contains passwords, API keys)
- `*.pem` files (AWS keys)
- `node_modules/` (dependencies)
- `build/` folders (generated files)
- Personal access tokens
- Database credentials

**Check before committing:**
```bash
git status
# Review the list before adding
```

---

## 🔍 Verify What Will Be Committed

```bash
# See what files will be added
git status

# See what changes will be committed
git diff --cached

# Remove file from staging (if needed)
git reset HEAD filename
```

---

## 🛠️ Troubleshooting

### Error: "remote origin already exists"

```bash
# Remove existing remote
git remote remove origin

# Add new remote
git remote add origin https://github.com/YOUR_USERNAME/easy-basket.git
```

### Error: "Authentication failed"

- Use Personal Access Token instead of password
- Or set up SSH keys

### Error: "Permission denied"

- Check repository URL is correct
- Verify you have access to the repository
- Check if repository is private and you're authenticated

### Undo last commit (before pushing)

```bash
git reset --soft HEAD~1
```

### Remove file from Git (but keep locally)

```bash
git rm --cached filename
```

---

## 📚 GitHub Best Practices

1. **Commit often** with clear messages
2. **Don't commit** sensitive data (.env, keys)
3. **Use .gitignore** properly
4. **Write good commit messages:**
   - `"Add user authentication"`
   - `"Fix payment redirect issue"`
   - `"Update responsive UI"`
5. **Create branches** for features:
   ```bash
   git checkout -b feature/new-feature
   git push -u origin feature/new-feature
   ```

---

## ✅ Quick Checklist

- [ ] GitHub repository created
- [ ] Git initialized
- [ ] .gitignore created/updated
- [ ] Sensitive files excluded (.env, *.pem)
- [ ] Files added to git
- [ ] Changes committed
- [ ] Remote repository added
- [ ] Code pushed to GitHub
- [ ] Verified on GitHub website

---

## 🎉 After Pushing

1. **Visit your repository:** `https://github.com/YOUR_USERNAME/easy-basket`
2. **Verify all files are there**
3. **Check .env is NOT visible** (should be in .gitignore)
4. **Add README.md** (optional, but recommended)

---

**Your code is now on GitHub! 🚀**

