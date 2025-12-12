# 🔧 Fix GitHub Permission Error

## ❌ Error You're Seeing

```
remote: Permission to nikhilkaplas-a11y/easy-basket.git denied to nikhilkaplas-png.
fatal: unable to access 'https://github.com/nikhilkaplas-a11y/easy-basket.git/': 
The requested URL returned error: 403
```

**Problem:** You're authenticated as `nikhilkaplas-png` but trying to push to `nikhilkaplas-a11y` repository.

---

## ✅ Solution Options

### Option 1: Use Correct Repository (Recommended)

If you want to use `nikhilkaplas-png` account:

```bash
cd /Users/nikhil/Projects/easyBucket

# Remove wrong remote
git remote remove origin

# Add correct remote (your account)
git remote add origin https://github.com/nikhilkaplas-png/easy-basket.git

# Push
git push -u origin main
```

**Then create repository on GitHub:**
1. Go to https://github.com/nikhilkaplas-png
2. New repository → `easy-basket`
3. Don't initialize with README

---

### Option 2: Use Personal Access Token

If you want to use `nikhilkaplas-a11y` account:

1. **Create Personal Access Token:**
   - Go to GitHub → Settings → Developer settings
   - Personal access tokens → Tokens (classic)
   - Generate new token (classic)
   - Select scope: `repo` (full control)
   - Generate and **copy token**

2. **Update remote and push:**
   ```bash
   cd /Users/nikhil/Projects/easyBucket
   
   # Keep existing remote
   git remote set-url origin https://github.com/nikhilkaplas-a11y/easy-basket.git
   
   # Push (use token as password)
   git push -u origin main
   # Username: nikhilkaplas-a11y
   # Password: YOUR_PERSONAL_ACCESS_TOKEN
   ```

---

### Option 3: Use SSH (Most Secure)

1. **Check if you have SSH key:**
   ```bash
   ls -la ~/.ssh/id_*.pub
   ```

2. **If no SSH key, create one:**
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   # Press Enter for default location
   # Enter passphrase (optional)
   ```

3. **Copy public key:**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   # Copy the output
   ```

4. **Add to GitHub:**
   - GitHub → Settings → SSH and GPG keys → New SSH key
   - Paste your public key
   - Add SSH key

5. **Update remote to use SSH:**
   ```bash
   cd /Users/nikhil/Projects/easyBucket
   
   # Use SSH URL
   git remote set-url origin git@github.com:nikhilkaplas-a11y/easy-basket.git
   
   # Push
   git push -u origin main
   ```

---

### Option 4: Clear Cached Credentials

If credentials are cached incorrectly:

```bash
# Clear Git credential cache
git credential-osxkeychain erase
host=github.com
protocol=https
# Press Enter twice

# Or remove from Keychain (Mac)
# Keychain Access → Search "github.com" → Delete entries
```

Then try pushing again.

---

## 🎯 Quick Fix (Choose One)

### If using `nikhilkaplas-png` account:

```bash
cd /Users/nikhil/Projects/easyBucket
git remote remove origin
git remote add origin https://github.com/nikhilkaplas-png/easy-basket.git
git push -u origin main
```

### If using `nikhilkaplas-a11y` account with token:

```bash
cd /Users/nikhil/Projects/easyBucket
git remote set-url origin https://github.com/nikhilkaplas-a11y/easy-basket.git
git push -u origin main
# Use Personal Access Token as password
```

### If using SSH:

```bash
cd /Users/nikhil/Projects/easyBucket
git remote set-url origin git@github.com:nikhilkaplas-a11y/easy-basket.git
git push -u origin main
```

---

## 🔍 Check Current Configuration

```bash
# Check remote URL
git remote -v

# Check Git user
git config user.name
git config user.email

# Check credential helper
git config credential.helper
```

---

## ✅ Recommended: Use SSH

SSH is the most secure and convenient method:

1. **One-time setup** (5 minutes)
2. **No passwords needed** after setup
3. **More secure** than HTTPS with tokens

**Setup SSH:**
```bash
# Generate key (if needed)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy public key
cat ~/.ssh/id_ed25519.pub | pbcopy  # Mac - copies to clipboard

# Add to GitHub: Settings → SSH and GPG keys → New SSH key

# Update remote
git remote set-url origin git@github.com:YOUR_USERNAME/easy-basket.git

# Push
git push -u origin main
```

---

## 🐛 Still Having Issues?

1. **Verify repository exists** on GitHub
2. **Check you have access** to the repository
3. **Try creating new repository** with correct account
4. **Use SSH** (most reliable method)

---

**Choose the option that matches your GitHub account! 🚀**

