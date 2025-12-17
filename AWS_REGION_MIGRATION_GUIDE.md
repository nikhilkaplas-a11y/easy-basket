# AWS Region Migration Guide: EU to India (ap-south-1)

## Why Change Region?

Since you're located in India, using AWS resources in the **Mumbai region (ap-south-1)** provides:
- ✅ **Lower latency** - Faster response times for Indian users
- ✅ **Better performance** - Reduced network distance
- ✅ **Lower data transfer costs** - Data stays within India
- ✅ **Compliance** - Data residency in India

## What Has Been Updated

The codebase default region has been changed from `eu-north-1` (Stockholm) to `ap-south-1` (Mumbai):

### Code Files Updated:
- ✅ `backend/src/services/s3.service.ts` - Default region changed to `ap-south-1`
- ✅ `backend/ecosystem.config.js` - Default region changed to `ap-south-1`
- ✅ `backend/src/index.ts` - Log messages updated to show Mumbai region
- ✅ `backend/S3_SETUP_GUIDE.md` - Documentation updated

## Migration Steps

### 1. Update Your .env File

On your production server, update the `.env` file:

```bash
cd ~/easy-basket/backend
nano .env
```

Change:
```env
AWS_REGION=eu-north-1
```

To:
```env
AWS_REGION=ap-south-1
```

### 2. Create New S3 Bucket in Mumbai Region

**Important:** We'll create a **new S3 bucket** in Mumbai region. We **cannot migrate** existing data, so we'll create a fresh bucket. The old bucket in `eu-north-1` can remain (for existing images) or be deleted later.

#### Step-by-Step: Create New Bucket

1. **Go to AWS Console** → S3 → Create bucket

2. **Bucket Configuration:**
   - **Bucket name:** `easy-basket-images` (or `easy-basket-images-mumbai` if name is taken)
   - **AWS Region:** Select `ap-south-1` (Asia Pacific - Mumbai) ⚠️ **Important: Select Mumbai!**
   - **Object Ownership:** ACLs disabled (recommended)
   - **Block Public Access settings:** 
     - ✅ Uncheck "Block all public access" (we need public read for images)
     - ✅ Acknowledge the warning
   - **Bucket Versioning:** Disable (unless you need it)
   - **Default encryption:** Enable (SSE-S3 is fine)
   - **Object Lock:** Disable

3. **Click "Create bucket"**

4. **Configure Bucket Policy** (for public read access):
   - Go to your new bucket → **Permissions** → **Bucket Policy**
   - Click **Edit** and add:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "PublicReadGetObject",
         "Effect": "Allow",
         "Principal": "*",
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::your-bucket-name/*"
       }
     ]
   }
   ```
   - Replace `your-bucket-name` with your actual bucket name
   - Click **Save changes**

5. **Configure CORS** (optional, for web access):
   - Go to **Permissions** → **Cross-origin resource sharing (CORS)**
   - Click **Edit** and add:
   ```json
   [
     {
       "AllowedHeaders": ["*"],
       "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
       "AllowedOrigins": ["*"],
       "ExposeHeaders": ["ETag"]
     }
   ]
   ```
   - Click **Save changes**

6. **Update .env file:**
   ```env
   AWS_S3_BUCKET_NAME=your-new-bucket-name
   AWS_REGION=ap-south-1
   ```

#### What About Existing Images?

Since we're **creating a new bucket** (not migrating):
- **Old bucket in EU:** Can remain active (existing image URLs will still work)
- **New images:** Will be uploaded to Mumbai bucket (faster for Indian users)
- **Existing images:** Will continue to work from EU bucket
- **Gradual update:** As you update products/categories, new images will go to Mumbai
- **Or delete old bucket:** Once you've re-uploaded all images through admin panel (if needed)

**Note:** You cannot migrate S3 data between regions automatically. You'll need to manually re-upload images through your admin panel as you update products/categories.

### 3. Update Existing Resources (If Applicable)

#### RDS Database
If your RDS database is in `eu-north-1`, you have two options:

**Option 1: Keep Database in EU** (Easier, but higher latency)
- Keep `DB_HOST` pointing to EU RDS
- Only S3 will be in Mumbai
- Acceptable if database queries are fast enough

**Option 2: Migrate Database to Mumbai** (Better performance, but more work)
- Create RDS snapshot in EU
- Restore snapshot in Mumbai region
- Update `DB_HOST` in `.env`
- Update DNS/connection strings

**Note:** The database connection scripts (`fix-db-*.sh`) still reference EU RDS. If you migrate RDS, update those scripts.

#### EC2 Instance
If your EC2 instance is in `eu-north-1`:
- **Option 1:** Keep EC2 in EU (acceptable if only serving API)
- **Option 2:** Launch new EC2 in Mumbai and migrate application

#### Application Load Balancer (ALB)
If your ALB is in `eu-north-1`:
- You'll need to create a new ALB in Mumbai
- Update DNS records to point to new ALB
- Migrate SSL certificates to Mumbai region

### 4. Rebuild and Restart Backend

After updating `.env`:

```bash
cd ~/easy-basket/backend

# Rebuild TypeScript
npm run build

# Restart PM2
pm2 restart easy-basket-api

# Check logs
pm2 logs easy-basket-api --lines 50
```

You should see:
```
✅ AWS S3 client initialized
📦 Bucket: your-bucket-name
🌍 Region: ap-south-1 (Mumbai, India)
```

### 5. Verify Everything Works

1. **Test image upload** in admin panel
2. **Check image URLs** - should point to `s3.ap-south-1.amazonaws.com`
3. **Monitor latency** - should be lower for Indian users
4. **Check logs** - no region-related errors

## Cost Comparison

### Data Transfer Costs (India → India vs EU → India)

- **Within Mumbai region:** ~$0.00/GB (free)
- **EU → India:** ~$0.09/GB (expensive!)

For a grocery app with 1,000 images (avg 200KB each = 200MB):
- **Mumbai region:** ~$0.00/month
- **EU region:** ~$0.02/month (minimal, but adds up with traffic)

### Storage Costs

- **Mumbai (ap-south-1):** ~$0.023/GB/month
- **Stockholm (eu-north-1):** ~$0.023/GB/month
- **Same price**, but better performance in Mumbai

## Important Notes

1. **Existing Images:** 
   - Images in the old EU bucket will continue to work (URLs remain valid)
   - New images will be uploaded to the Mumbai bucket
   - You can keep both buckets active, or delete the old one once you've re-uploaded images
   - If you want to move existing images, you'll need to manually re-upload them through the admin panel

2. **Database Location:** If your database is still in EU, that's okay - database queries are usually fast enough. But for best performance, consider migrating.

3. **Mixed Regions:** It's okay to have:
   - S3 in Mumbai (ap-south-1)
   - RDS in EU (eu-north-1) - if already set up
   - EC2 in EU (eu-north-1) - if already set up

4. **Future Setup:** For new deployments, use Mumbai region for all resources.

## Rollback Plan

If you need to rollback to EU region:

1. Update `.env`:
   ```env
   AWS_REGION=eu-north-1
   AWS_S3_BUCKET_NAME=your-eu-bucket-name
   ```

2. Rebuild and restart:
   ```bash
   npm run build
   pm2 restart easy-basket-api
   ```

## Summary

✅ **Code updated** to use `ap-south-1` (Mumbai) as default
✅ **Update your `.env`** file with `AWS_REGION=ap-south-1`
✅ **Create new S3 bucket** in Mumbai region (fresh start, no migration)
✅ **Rebuild and restart** backend
✅ **Verify** everything works

Your application will now serve Indian users with lower latency and better performance! 🚀

