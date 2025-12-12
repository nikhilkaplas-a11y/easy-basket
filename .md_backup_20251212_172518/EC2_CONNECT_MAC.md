# 🔌 Connect to EC2 Instance on Mac

## Quick Commands for Mac

### Step 1: Set Key File Permissions

```bash
chmod 400 easy-basket-key.pem
```

**Why:** SSH requires the key file to have restricted permissions (read-only for owner).

---

### Step 2: Connect to EC2 Instance

```bash
ssh -i easy-basket-key.pem ec2-user@YOUR_PUBLIC_IP
```

**Replace `YOUR_PUBLIC_IP` with your actual EC2 public IP address.**

---

### Step 3: Find Your Public IP

1. Go to **AWS Console** → **EC2** → **Instances**
2. Select your EC2 instance (`easy-basket-backend`)
3. Copy the **Public IPv4 address** (e.g., `54.123.45.67`)

---

## Complete Example

```bash
# Step 1: Set permissions
chmod 400 easy-basket-key.pem

# Step 2: Connect (replace with your actual IP)
ssh -i easy-basket-key.pem ec2-user@54.123.45.67
```

---

## Different AMI Types

### Amazon Linux 2023 / Amazon Linux 2
```bash
ssh -i easy-basket-key.pem ec2-user@YOUR_PUBLIC_IP
```

### Ubuntu
```bash
ssh -i easy-basket-key.pem ubuntu@YOUR_PUBLIC_IP
```

### Debian
```bash
ssh -i easy-basket-key.pem admin@YOUR_PUBLIC_IP
```

---

## Troubleshooting

### Error: "Permission denied (publickey)"

**Solutions:**
1. Check key file permissions: `chmod 400 easy-basket-key.pem`
2. Verify you're using the correct username (`ec2-user` for Amazon Linux, `ubuntu` for Ubuntu)
3. Make sure the key file path is correct
4. Verify security group allows SSH (port 22) from your IP

### Error: "Connection timed out"

**Solutions:**
1. Check security group allows SSH (port 22) from your IP
2. Verify EC2 instance is running
3. Check if you're using the correct public IP
4. Verify your internet connection

### Error: "WARNING: UNPROTECTED PRIVATE KEY FILE!"

**Solution:**
```bash
chmod 400 easy-basket-key.pem
```

---

## After Connecting

Once connected, you'll see something like:

```
       __|  __|_  )
       _|  (     /   Amazon Linux 2023 AMI
      ___|\___|___|

[ec2-user@ip-xxx-xxx-xxx-xxx ~]$
```

You're now connected to your EC2 instance! 🎉

---

## Next Steps After Connection

1. **Update system:**
   ```bash
   sudo yum update -y  # For Amazon Linux
   # OR
   sudo apt update && sudo apt upgrade -y  # For Ubuntu
   ```

2. **Run setup script:**
   ```bash
   # Upload ec2-setup.sh first, then:
   bash ec2-setup.sh
   ```

3. **Deploy backend:**
   ```bash
   # After uploading code:
   bash deploy.sh
   ```

---

## Quick Reference

```bash
# Connect
ssh -i easy-basket-key.pem ec2-user@YOUR_PUBLIC_IP

# Disconnect
exit

# Copy file to EC2
scp -i easy-basket-key.pem file.txt ec2-user@YOUR_PUBLIC_IP:~/

# Copy directory to EC2
scp -i easy-basket-key.pem -r backend/ ec2-user@YOUR_PUBLIC_IP:~/easy-basket/
```

---

**You're ready to connect! 🚀**

