# ✅ Fix: Server Block in Main nginx.conf

**Problem Found:** There's a server block in `/etc/nginx/nginx.conf` that's serving static files and taking precedence over your config.

---

## 🔧 The Fix

The main `nginx.conf` has this server block that needs to be commented out:

```nginx
server {
    listen       80;
    listen       [::]:80;
    server_name  _;
    root         /usr/share/nginx/html;
    # ... serving static files ...
}
```

---

## 🔧 Step 1: Comment Out the Server Block

```bash
sudo nano /etc/nginx/nginx.conf
```

**Find this section (around line 30-50):**

```nginx
    include /etc/nginx/conf.d/*.conf;

    server {                    # <-- COMMENT THIS OUT
        listen       80;
        listen       [::]:80;
        server_name  _;
        root         /usr/share/nginx/html;

        include /etc/nginx/default.d/*.conf;

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
    }
```

**Change it to (add # at the start of each line):**

```nginx
    include /etc/nginx/conf.d/*.conf;

    # server {                    # <-- COMMENTED OUT
    #     listen       80;
    #     listen       [::]:80;
    #     server_name  _;
    #     root         /usr/share/nginx/html;
    #
    #     include /etc/nginx/default.d/*.conf;
    #
    #     error_page 404 /404.html;
    #     location = /404.html {
    #     }
    #
    #     error_page 500 502 503 504 /50x.html;
    #     location = /50x.html {
    #     }
    # }
```

**Save:** `Ctrl+X`, `Y`, `Enter`

---

## 🧪 Step 2: Test and Restart

```bash
# Test configuration
sudo nginx -t

# Should show NO warnings now!

# Restart Nginx
sudo systemctl restart nginx

# Test
curl http://localhost/api/health
```

**Should now return JSON!**

---

## 🔧 Alternative: Quick One-Liner Fix

If you want to do it with sed (backup first):

```bash
# Backup
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Comment out the server block (from "server {" to closing "}")
sudo sed -i '/^    server {/,/^    }/s/^/#&/' /etc/nginx/nginx.conf

# Test
sudo nginx -t
sudo systemctl restart nginx
```

**But manual edit is safer!**

---

## ✅ Expected Result

After commenting out the server block:

1. ✅ No "conflicting server name" warning
2. ✅ `curl http://localhost/api/health` returns JSON
3. ✅ Your config in `conf.d/easy-basket.conf` is used
4. ✅ Requests are proxied to backend, not serving static files

---

## 🔍 Verify It Worked

```bash
# Check no warnings
sudo nginx -t

# Should show: syntax is ok, test is successful (NO warnings)

# Test endpoint
curl http://localhost/api/health

# Should return: {"status":"ok","message":"Easy Basket Backend is running",...}
```

---

**Comment out that server block in main nginx.conf and it will work! 🚀**

