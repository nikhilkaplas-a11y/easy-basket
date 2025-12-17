# Quick Guide: Create New S3 Bucket in Mumbai (ap-south-1)

## Why Mumbai Region?

Since you're in India, using **Mumbai region (ap-south-1)** provides:
- ✅ Lower latency for Indian users
- ✅ Better performance
- ✅ Lower data transfer costs
- ✅ Data residency in India

## Step-by-Step: Create S3 Bucket

### 1. Go to AWS Console

1. Log in to [AWS Console](https://console.aws.amazon.com)
2. Make sure you're in the **Mumbai region** (ap-south-1)
   - Check top-right corner of AWS Console
   - If not, click region dropdown → Select "Asia Pacific (Mumbai) ap-south-1"

### 2. Create Bucket

1. Go to **S3** service
2. Click **"Create bucket"** button

### 3. Configure Bucket Settings

**General Configuration:**
- **Bucket name:** `easy-basket-images` (or `easy-basket-images-mumbai` if taken)
  - Must be globally unique across all AWS accounts
  - Use lowercase letters, numbers, and hyphens only
- **AWS Region:** `ap-south-1` (Asia Pacific - Mumbai) ⚠️ **VERY IMPORTANT!**
- **Object Ownership:** 
  - Select "ACLs disabled (recommended)"

**Block Public Access settings:**
- ✅ **Uncheck** "Block all public access"
- ✅ Check the acknowledgment checkbox
- This allows public read access to images

**Bucket Versioning:**
- Leave as "Disable" (unless you need versioning)

**Default encryption:**
- ✅ Enable encryption
- Select "Amazon S3 managed keys (SSE-S3)" (free option)

**Object Lock:**
- Leave as "Disable"

### 4. Create Bucket

Click **"Create bucket"** at the bottom

### 5. Configure Bucket Policy (Public Read Access)

1. Click on your new bucket name
2. Go to **Permissions** tab
3. Scroll to **Bucket Policy**
4. Click **Edit**
5. Paste this policy (replace `your-bucket-name` with your actual bucket name):

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

6. Click **Save changes**

### 6. Configure CORS (Optional)

1. Still in **Permissions** tab
2. Scroll to **Cross-origin resource sharing (CORS)**
3. Click **Edit**
4. Paste this configuration:

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

5. Click **Save changes**

### 7. Create IAM User for Backend (If Not Already Done)

1. Go to **IAM** → **Users** → **Create user**
2. **User name:** `easy-basket-s3-uploader`
3. **Access type:** Select "Programmatic access"
4. Click **Next: Permissions**

5. **Attach policies:** Click "Create policy"
   - Go to **JSON** tab
   - Paste this policy (replace `your-bucket-name`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::your-bucket-name/*"
    }
  ]
}
```

   - Click **Next** → Give policy a name: `EasyBasketS3Policy`
   - Click **Create policy**
   - Go back to user creation, refresh, and attach the policy

6. Click **Next** → **Create user**

7. **IMPORTANT:** Save the **Access Key ID** and **Secret Access Key** immediately!
   - You'll only see the secret key once
   - Copy both values

### 8. Update Your .env File

On your production server:

```bash
cd ~/easy-basket/backend
nano .env
```

Add or update these lines:

```env
# AWS S3 Configuration (Mumbai Region)
AWS_ACCESS_KEY_ID=AKIA...your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_access_key_here
AWS_S3_BUCKET_NAME=your-bucket-name
AWS_REGION=ap-south-1
```

Save and exit (Ctrl+X, Y, Enter)

### 9. Rebuild and Restart Backend

```bash
cd ~/easy-basket/backend

# Rebuild TypeScript
npm run build

# Restart PM2
pm2 restart easy-basket-api

# Check logs to verify
pm2 logs easy-basket-api --lines 50
```

You should see:
```
✅ AWS S3 client initialized
📦 Bucket: your-bucket-name
🌍 Region: ap-south-1 (Mumbai, India)
```

### 10. Test Image Upload

1. Open your admin panel
2. Try uploading an image for a product or category
3. Check the image URL - it should be:
   ```
   https://your-bucket-name.s3.ap-south-1.amazonaws.com/products/...
   ```
   Notice `ap-south-1` in the URL (Mumbai region)

## Verification Checklist

- [ ] Bucket created in `ap-south-1` (Mumbai) region
- [ ] Bucket name is globally unique
- [ ] Public access is enabled (bucket policy configured)
- [ ] CORS is configured (optional)
- [ ] IAM user created with S3 permissions
- [ ] Access keys saved securely
- [ ] `.env` file updated with new bucket name and region
- [ ] Backend rebuilt and restarted
- [ ] Logs show Mumbai region
- [ ] Image upload test successful
- [ ] Image URL contains `ap-south-1`

## Troubleshooting

### Error: "Bucket name already exists"
- S3 bucket names must be globally unique
- Try: `easy-basket-images-mumbai`, `easy-basket-images-2024`, etc.

### Error: "Access Denied" when uploading
- Check IAM user has correct permissions
- Verify bucket policy allows public read
- Check access keys are correct in `.env`

### Images not displaying
- Verify bucket policy is configured
- Check "Block public access" is disabled
- Verify image URL contains `ap-south-1` region

### Wrong region in logs
- Double-check `.env` file has `AWS_REGION=ap-south-1`
- Rebuild and restart backend
- Check PM2 is using updated `.env` file

## What About Old Bucket?

If you have an old bucket in `eu-north-1`:
- ✅ **Keep it** - Existing image URLs will still work
- ✅ **New images** will go to Mumbai bucket
- ✅ **Gradual migration** - Update images as you edit products
- ❌ **Or delete it** - Once you've re-uploaded all images (if needed)

## Cost Estimate (Mumbai Region)

- **Storage:** ~₹1.7 per GB/month (~$0.023/GB)
- **Uploads:** ~₹0.37 per 1,000 requests (~$0.005)
- **Downloads:** ~₹0.03 per 1,000 requests (~$0.0004)

For typical grocery app:
- 1,000 products with images: ~₹40/month (~$0.50)
- Very affordable! 💰

---

**Done!** Your S3 bucket is now in Mumbai region, optimized for Indian users! 🚀🇮🇳

