# 🔌 Connect to RDS Database from Local Machine

## Your Database Details
- **Endpoint:** `easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com`
- **Region:** `eu-north-1`
- **Port:** `3306` (default MySQL port)
- **Username:** `admin` (or whatever you set)
- **Password:** `nikhilkaplas` (as per your note)

---

## ⚠️ Step 1: Configure Security Group (REQUIRED)

Before connecting, you MUST allow your local IP in the RDS security group:

1. **Go to AWS Console** → **RDS** → **Databases** → Select `easy-basket-db`
2. Click on **VPC security groups** link
3. Click on the security group
4. **Inbound rules** → **Edit inbound rules** → **Add rule:**
   - **Type:** MySQL/Aurora
   - **Port:** 3306
   - **Source:** 
     - **My IP** (recommended - only your current IP)
     - OR `0.0.0.0/0` (allows all IPs - less secure, only for testing)
   - **Description:** Allow local connection
5. **Save rules**

---

## 🔧 Step 2: Install MySQL Client (if not installed)

### On Mac:
```bash
# Using Homebrew
brew install mysql-client

# Or use MySQL from MySQL installer
# Download from: https://dev.mysql.com/downloads/mysql/
```

### On Linux (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install mysql-client
```

### On Windows:
- Download MySQL Installer from: https://dev.mysql.com/downloads/installer/
- Or use WSL (Windows Subsystem for Linux)

---

## 🔌 Step 3: Connect to Database

### Option 1: Using MySQL Command Line

```bash
mysql -h easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com \
      -P 3306 \
      -u admin \
      -p
```

When prompted, enter password: `nikhilkaplas`

### Option 2: One-line command (with password)

```bash
mysql -h easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com \
      -P 3306 \
      -u admin \
      -pnikhilkaplas
```

**Note:** This is less secure as password is visible in command history.

### Option 3: Using Connection String

```bash
mysql -h easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com \
      -P 3306 \
      -u admin \
      -pnikhilkaplas \
      easybasket
```

---

## ✅ Step 4: Test Connection

Once connected, test with these commands:

```sql
-- Show databases
SHOW DATABASES;

-- Create database (if not exists)
CREATE DATABASE IF NOT EXISTS easybasket;

-- Use database
USE easybasket;

-- Show tables
SHOW TABLES;

-- Exit
EXIT;
```

---

## 🔧 Step 5: Update Backend .env File

Update your local `backend/.env` file:

```env
# Database Configuration
DB_HOST=easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASS=nikhilkaplas
DB_NAME=easybasket
```

**Note:** The backend uses `DB_USER` and `DB_PASS` (not `DB_USERNAME` and `DB_PASSWORD`)

---

## 🧪 Step 6: Test Backend Connection

Test if your backend can connect:

```bash
cd backend

# Make sure .env is configured
# Then test connection (if you have a test script)
npm run build
npm start
```

Or create a simple test script:

**File:** `backend/test-db-connection.js`
```javascript
const mysql = require('mysql2/promise');
require('dotenv').config();

async function testConnection() {
  try {
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      user: process.env.DB_USERNAME,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME || 'easybasket',
    });
    
    console.log('✅ Successfully connected to RDS database!');
    const [rows] = await connection.execute('SELECT 1 as test');
    console.log('✅ Database query successful:', rows);
    
    await connection.end();
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
  }
}

testConnection();
```

Run it:
```bash
node test-db-connection.js
```

---

## 🔒 Security Best Practices

1. **Don't commit .env file to Git**
   - Add `.env` to `.gitignore`
   - Use environment variables in production

2. **Use My IP instead of 0.0.0.0/0**
   - Only allow your specific IP address
   - More secure

3. **Change default password**
   - Use a strong, unique password
   - Store it securely (password manager)

4. **Use SSL connection** (optional but recommended)
   ```bash
   mysql -h easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com \
         -P 3306 \
         -u admin \
         -p \
         --ssl-mode=REQUIRED
   ```

---

## 🐛 Troubleshooting

### Error: "Can't connect to MySQL server"

**Solutions:**
1. Check security group allows your IP
2. Verify database is publicly accessible
3. Check if database is in "Available" state
4. Verify endpoint and port are correct

### Error: "Access denied for user"

**Solutions:**
1. Verify username is correct
2. Check password (case-sensitive)
3. Ensure user has proper permissions

### Error: "Unknown database"

**Solutions:**
1. Create database first:
   ```sql
   CREATE DATABASE easybasket;
   ```

---

## 📝 Quick Reference Commands

```bash
# Connect to database
mysql -h easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com -P 3306 -u admin -p

# Connect to specific database
mysql -h easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com -P 3306 -u admin -p easybasket

# Export database
mysqldump -h easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com -P 3306 -u admin -p easybasket > backup.sql

# Import database
mysql -h easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com -P 3306 -u admin -p easybasket < backup.sql
```

---

## ✅ Checklist

- [ ] Security group configured to allow your IP
- [ ] MySQL client installed locally
- [ ] Successfully connected via MySQL command line
- [ ] Database `easybasket` created
- [ ] Backend `.env` file updated
- [ ] Backend can connect to database
- [ ] Test connection successful

---

**You're now ready to use your RDS database from local! 🚀**

