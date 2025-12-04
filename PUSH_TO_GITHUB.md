# 🚀 Push Code to GitHub with Personal Access Token

## Step 1: Create Personal Access Token

1. **Go to GitHub Token Settings:**
   - Direct link: https://github.com/settings/tokens
   - Or: GitHub → Your Profile (top right) → Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **Generate New Token:**
   - Click: **"Generate new token"** → **"Generate new token (classic)"**

3. **Configure Token:**
   - **Note:** `easy-basket` (or any name you prefer)
   - **Expiration:** Choose duration (90 days, 1 year, or no expiration)
   - **Select scopes:** Check **"repo"** (this gives full control of repositories)
     - This includes: repo:status, repo_deployment, public_repo, repo:invite, security_events

4. **Generate:**
   - Scroll down and click **"Generate token"**

5. **⚠️ COPY THE TOKEN IMMEDIATELY!**
   - It will look like: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   - You won't be able to see it again!
   - Save it somewhere safe (password manager, notes, etc.)

---

## Step 2: Push Your Code

Once you have the token:

```bash
cd /Users/nikhil/Projects/easyBucket

# Push to GitHub
git push -u origin main
```

**When prompted:**
- **Username:** `nikhilkaplas-a11y`
- **Password:** `[Paste your personal access token here]`

**Note:** Don't type your GitHub password - use the token you just created!

---

## ✅ Success!

If successful, you'll see:
```
Enumerating objects: X, done.
Counting objects: 100% (X/X), done.
Writing objects: 100% (X/X), done.
To https://github.com/nikhilkaplas-a11y/easy-basket.git
 * [new branch]      main -> main
Branch 'main' set up to track remote branch 'main' from 'origin'.
```

---

## 🔍 Verify on GitHub

1. Go to: https://github.com/nikhilkaplas-a11y/easy-basket
2. You should see all your files!

---

## 🐛 Troubleshooting

### Error: "Authentication failed"

- Make sure you're using the **token** as password, not your GitHub password
- Verify the token has `repo` scope
- Check if token expired

### Error: "Permission denied"

- Verify you have access to `nikhilkaplas-a11y/easy-basket` repository
- Make sure you're using the correct username: `nikhilkaplas-a11y`

### Token Not Working?

- Create a new token
- Make sure `repo` scope is selected
- Try using SSH instead (see Option 2 in main guide)

---

## 🔒 Security Tips

1. **Don't share your token** with anyone
2. **Don't commit tokens** to Git (they're in .gitignore ✅)
3. **Revoke old tokens** if compromised
4. **Use token expiration** for better security

---

## 📝 Quick Reference

```bash
# Check remote
git remote -v

# Push code
git push -u origin main

# Username: nikhilkaplas-a11y
# Password: [Your Personal Access Token]
```

---

**Ready to push! Create the token, then run `git push -u origin main` 🚀**

