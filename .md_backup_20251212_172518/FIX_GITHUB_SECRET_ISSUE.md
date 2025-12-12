# Fix GitHub Secret Detection Issue

## Problem
GitHub detected Firebase service account credentials in `backend/.env.bak` file and blocked the push.

## Solution

### Step 1: Remove Backup Files from Git
```bash
cd /Users/nikhil/Projects/easyBucket
git rm --cached backend/.env.bak backend/.env.backup backend/.env.bak2 backend/.env.bak3 backend/.env.bak4
```

### Step 2: Update .gitignore
Already done - added `*.bak`, `*.backup`, etc. to `.gitignore`

### Step 3: Commit the Changes
```bash
git add .gitignore
git commit -m "Remove .env backup files and update .gitignore"
```

### Step 4: Remove from Commit History (if already pushed)
If the files were already in a previous commit, you need to remove them from history:

```bash
# Check which commit has the secret
git log --all --full-history -- backend/.env.bak

# Remove from history (use with caution!)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch backend/.env.bak backend/.env.backup backend/.env.bak2 backend/.env.bak3 backend/.env.bak4" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (WARNING: This rewrites history!)
git push origin --force --all
```

### Alternative: Use GitHub's Unblock URL
GitHub provided an unblock URL in the error message. You can:
1. Visit: https://github.com/nikhilkaplas-a11y/easy-basket/security/secret-scanning/unblock-secret/36jJF0d2lbnwGCNMxKcEV3hfznJ
2. Review the secret
3. If it's a test/development secret, you can allow it
4. **BUT**: It's better to remove it from git history

## Best Practice
- Never commit `.env` files or backup files
- Always add backup patterns to `.gitignore`
- Use environment variables in CI/CD instead of committing secrets
- Rotate secrets if they were accidentally committed

## Current Status
✅ `.gitignore` updated to exclude `.bak` files
✅ Backup files removed from git tracking
⏳ Need to commit and push

