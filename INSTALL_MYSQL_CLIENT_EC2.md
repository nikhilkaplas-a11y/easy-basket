# 🔧 Install MySQL Client on Amazon Linux 2023

## ❌ Error You're Seeing

```
No match for argument: mysql
Error: Unable to find a match: mysql
```

**Problem:** Amazon Linux 2023 doesn't have a package called `mysql`. Use MariaDB instead (it's MySQL compatible).

---

## ✅ Solution: Install MariaDB Client

### Option 1: MariaDB 10.5 (Recommended)

```bash
sudo yum install -y mariadb105
```

### Option 2: Latest MariaDB

```bash
sudo yum install -y mariadb
```

### Option 3: If Above Don't Work

```bash
# Enable EPEL repository
sudo yum install -y epel-release

# Install MariaDB
sudo yum install -y mariadb
```

---

## ✅ Verify Installation

```bash
mysql --version
```

Should show: `mysql Ver 15.1 Distrib 10.5.x-MariaDB` or similar

---

## 🔌 Test Database Connection

```bash
mysql -h easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com \
      -P 3306 \
      -u admin \
      -p
```

When prompted, enter password: `nikhilkaplas`

---

## 📋 Alternative: Use MySQL from MySQL Repository

If you specifically need MySQL (not MariaDB):

```bash
# Download MySQL repository
sudo yum install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm

# Install MySQL client
sudo yum install -y mysql-community-client
```

But **MariaDB works perfectly** and is easier to install!

---

## ✅ Quick Install Command

```bash
sudo yum install -y mariadb105
```

Then test:
```bash
mysql --version
```

---

## 🎯 Why MariaDB?

- **Fully compatible** with MySQL
- **Same commands** (`mysql`, `mysqldump`, etc.)
- **Easier to install** on Amazon Linux 2023
- **Works with RDS MySQL** without any issues

---

**MariaDB client is the easiest solution! ✅**

