# How to Edit Nginx Config File - Step by Step

## Option 1: Using Nano (Easiest - Recommended)

```bash
# Open the file
sudo nano /etc/nginx/conf.d/easy-basket.conf

# Edit the file:
# 1. Delete all existing content (Ctrl+K repeatedly, or select all and delete)
# 2. Copy the entire content from nginx-production-load-balancer.conf
# 3. Paste it (Right-click or Shift+Insert)

# Save and exit:
# - Press Ctrl+O (to save)
# - Press Enter (to confirm filename)
# - Press Ctrl+X (to exit)
```

## Option 2: Using Vim

```bash
# Open the file
sudo vim /etc/nginx/conf.d/easy-basket.conf

# To edit:
# - Press 'i' to enter INSERT mode
# - Delete old content and paste new content

# To save and exit:
# - Press Esc (to exit INSERT mode)
# - Type :wq and press Enter
#   OR
# - Type :x and press Enter
```

## Option 3: Direct File Replacement (Easiest)

```bash
# Copy the new config file to your EC2 server first, then:

# Backup current config
sudo cp /etc/nginx/conf.d/easy-basket.conf /etc/nginx/conf.d/easy-basket.conf.backup

# Replace with new config (copy content from nginx-production-load-balancer.conf)
sudo tee /etc/nginx/conf.d/easy-basket.conf > /dev/null << 'EOF'
# Paste the entire content from nginx-production-load-balancer.conf here
EOF
```

## Option 4: Using SCP to Copy File (From Your Mac)

```bash
# From your local machine (Mac)
cd /Users/nikhil/Projects/easyBucket

# Copy the config file to EC2
scp -i your-key.pem nginx-production-load-balancer.conf ec2-user@13.60.76.140:/tmp/easy-basket.conf

# Then on EC2 server:
ssh -i your-key.pem ec2-user@13.60.76.140

# Backup and replace
sudo cp /etc/nginx/conf.d/easy-basket.conf /etc/nginx/conf.d/easy-basket.conf.backup
sudo cp /tmp/easy-basket.conf /etc/nginx/conf.d/easy-basket.conf
```

## Quick Fix: If You're Stuck in an Editor

### If in Nano:
- Press `Ctrl+X` to exit
- If it asks to save, press `Y` then `Enter`

### If in Vim:
- Press `Esc` (to make sure you're not in INSERT mode)
- Type `:q!` and press `Enter` (quit without saving)
- Or type `:wq` and press `Enter` (save and quit)

### If in another editor:
- Try `Ctrl+C` to cancel
- Or close the terminal and start over

## Recommended: Use Nano (Easiest)

```bash
# 1. Open file
sudo nano /etc/nginx/conf.d/easy-basket.conf

# 2. In nano:
#    - Use arrow keys to navigate
#    - Delete old content
#    - Paste new content (Right-click or Shift+Insert)
#    - Ctrl+O to save (then Enter)
#    - Ctrl+X to exit

# 3. Test config
sudo nginx -t

# 4. Reload
sudo systemctl reload nginx
```

