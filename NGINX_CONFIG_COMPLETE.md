# 🔧 Complete Nginx Configuration for easybasket.in

This is the complete Nginx configuration file you need on your EC2 instance.

---

## 📄 File Location

**On EC2:** `/etc/nginx/conf.d/easy-basket.conf`

---

## 📝 Complete Configuration

```nginx
server {
    listen 80;
    server_name api.easybasket.in;  # Your domain - change if using root domain

    access_log /var/log/nginx/easy-basket-access.log;
    error_log /var/log/nginx/easy-basket-error.log;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /health {
        proxy_pass http://localhost:3000/api/health;
        access_log off;  # Don't log health checks
    }
}
```

---

## 🔄 Alternative: Accept Both Domain and IP

If you want both domain and IP to work:

```nginx
server {
    listen 80;
    server_name api.easybasket.in 13.60.76.140;  # Both domain and IP

    access_log /var/log/nginx/easy-basket-access.log;
    error_log /var/log/nginx/easy-basket-error.log;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /health {
        proxy_pass http://localhost:3000/api/health;
        access_log off;
    }
}
```

---

## 🔐 After SSL Setup (HTTPS)

After running `certbot`, Certbot will automatically update your config. It will look like this:

```nginx
server {
    listen 80;
    server_name api.easybasket.in;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.easybasket.in;

    # SSL certificates (added by Certbot)
    ssl_certificate /etc/letsencrypt/live/api.easybasket.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.easybasket.in/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    access_log /var/log/nginx/easy-basket-access.log;
    error_log /var/log/nginx/easy-basket-error.log;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /health {
        proxy_pass http://localhost:3000/api/health;
        access_log off;
    }
}
```

**Note:** Certbot automatically creates this when you run `sudo certbot --nginx -d api.easybasket.in`

---

## 📋 How to Use This File

### Step 1: Connect to EC2

```bash
ssh -i your-key.pem ec2-user@13.60.76.140
```

### Step 2: Create/Edit the File

```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

### Step 3: Copy the Configuration

Copy the first configuration block above (the one with `server_name api.easybasket.in;`)

### Step 4: Paste into the File

- Paste the configuration
- Save: `Ctrl+X`, then `Y`, then `Enter`

### Step 5: Test Configuration

```bash
sudo nginx -t
```

**Should show:**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### Step 6: Reload Nginx

```bash
sudo systemctl reload nginx
```

---

## 🔍 Configuration Explained

### Key Settings:

- **`listen 80`:** Listens on port 80 (HTTP)
- **`server_name api.easybasket.in`:** Your domain name
- **`proxy_pass http://localhost:3000`:** Forwards requests to your Node.js backend
- **`proxy_set_header`:** Passes original request info to backend
- **`location /health`:** Special endpoint for health checks (no logging)

---

## 🎯 For Root Domain (easybasket.in)

If you want to use root domain instead of subdomain:

```nginx
server {
    listen 80;
    server_name easybasket.in www.easybasket.in;  # Root domain

    # ... rest of config same as above
}
```

---

## ✅ Verification

After setup, test:

```bash
# Test HTTP
curl http://api.easybasket.in/api/health

# Test HTTPS (after SSL)
curl https://api.easybasket.in/api/health
```

---

## 🐛 Troubleshooting

### Check Current Config:

```bash
sudo cat /etc/nginx/conf.d/easy-basket.conf
```

### Check Nginx Status:

```bash
sudo systemctl status nginx
```

### Check Logs:

```bash
# Access logs
sudo tail -f /var/log/nginx/easy-basket-access.log

# Error logs
sudo tail -f /var/log/nginx/easy-basket-error.log
```

### Restart Nginx (if needed):

```bash
sudo systemctl restart nginx
```

---

**This is the complete Nginx configuration you need! 🚀**

