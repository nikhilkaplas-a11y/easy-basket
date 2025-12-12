# 🔄 Reset Backend - Commands

## Quick Reset

### Stop Backend
```bash
# Find and kill process on port 3000
lsof -ti:3000 | xargs kill -9
```

### Start Backend
```bash
cd backend
npm run dev
```

---

## Complete Reset (Stop + Start)

### Option 1: One Command
```bash
cd /Users/nikhil/Projects/easyBucket/backend && lsof -ti:3000 | xargs kill -9 2>/dev/null; npm run dev
```

### Option 2: Step by Step
```bash
# 1. Stop backend
lsof -ti:3000 | xargs kill -9

# 2. Navigate to backend
cd backend

# 3. Start backend
npm run dev
```

---

## Reset Database (Optional)

If you want to reset the database data:

```bash
# Connect to MySQL
mysql -u root -p

# Then run:
DROP DATABASE easy_basket;
CREATE DATABASE easy_basket;

# Exit MySQL
exit

# Seed sample data again
cd backend
npm run seed
```

---

## Check Backend Status

```bash
# Check if backend is running
curl http://localhost:3000/

# Should return: "Easy Basket Backend is running"
```

---

## Troubleshooting

### Port 3000 already in use?
```bash
# Find what's using port 3000
lsof -i :3000

# Kill it
kill -9 <PID>
```

### Backend not starting?
```bash
cd backend
# Check for errors
npm run dev

# Or check logs
tail -f logs/*.log
```

---

**Backend reset complete! ✅**

