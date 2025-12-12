# Remove Secret from Git History

## Current Issue
Commit `22f32e6` contains `backend/.env.bak` with Firebase credentials. GitHub is blocking the push.

## Solution Options

### Option 1: Amend Last Commit (if it's the most recent)
If `22f32e6` is your most recent commit and hasn't been pushed yet:

```bash
# Remove the file from the last commit
git reset --soft HEAD~1
git reset HEAD backend/.env.bak backend/.env.backup backend/.env.bak2 backend/.env.bak3 backend/.env.bak4
git commit -m "Your original commit message"
```

### Option 2: Use BFG Repo-Cleaner (Recommended)
This is the safest way to remove secrets from history:

```bash
# Install BFG (if not installed)
# brew install bfg  # on Mac

# Clone a fresh copy
cd /tmp
git clone --mirror https://github.com/nikhilkaplas-a11y/easy-basket.git

# Remove the files
bfg --delete-files .env.bak easy-basket.git
bfg --delete-files .env.backup easy-basket.git
bfg --delete-files .env.bak2 easy-basket.git
bfg --delete-files .env.bak3 easy-basket.git
bfg --delete-files .env.bak4 easy-basket.git

# Clean up
cd easy-basket.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Push
git push --force
```

### Option 3: Use git filter-branch (Manual)
```bash
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch backend/.env.bak backend/.env.backup backend/.env.bak2 backend/.env.bak3 backend/.env.bak4" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (WARNING: Rewrites history!)
git push origin --force --all
```

### Option 4: Use GitHub's Secret Unblock (Quick Fix)
1. Visit: https://github.com/nikhilkaplas-a11y/easy-basket/security/secret-scanning/unblock-secret/36jJF0d2lbnwGCNMxKcEV3hfznJ
2. Review and allow the secret (only if it's safe to expose)
3. Push again

**⚠️ WARNING**: This exposes your Firebase credentials publicly. **NOT RECOMMENDED** for production secrets.

## Recommended Approach

1. **Rotate the Firebase credentials** (since they may be exposed)
2. **Remove from history** using Option 2 (BFG) or Option 3 (filter-branch)
3. **Update `.env` with new credentials**
4. **Push again**

## After Fixing

1. Verify secrets are removed:
   ```bash
   git log --all --full-history -- backend/.env.bak
   # Should return nothing
   ```

2. Push again:
   ```bash
   git push origin main
   ```

3. Update Firebase credentials in your backend `.env` file with new ones from Firebase Console

