# AWS S3 Setup Guide for Production

## Quick Setup

To enable image upload functionality, you need to configure AWS S3 credentials.

### 1. Required Environment Variables

Add these to your production `.env` file:

```env
# AWS S3 Configuration
AWS_ACCESS_KEY_ID=your_access_key_id_here
AWS_SECRET_ACCESS_KEY=your_secret_access_key_here
AWS_S3_BUCKET_NAME=your-bucket-name
AWS_REGION=ap-south-1

# Public base URL for images returned to apps (DB stores path only after normalize)
# Use the same host as direct S3, or a CloudFront CDN URL when you migrate.
PUBLIC_MEDIA_BASE_URL=https://your-bucket-name.s3.ap-south-1.amazonaws.com
```

### 2. Create S3 Bucket

1. **Go to AWS Console** → S3 → Create bucket
2. **Bucket name:** `easy-basket-images` (or your preferred name, must be globally unique)
3. **AWS Region:** Select `ap-south-1` (Asia Pacific - Mumbai) ⚠️ **Important: Select Mumbai region!**
4. **Block Public Access settings:** 
   - Uncheck "Block all public access" (we need public read for images)
   - Acknowledge the warning
5. **Default encryption:** Enable (SSE-S3 is fine)
6. **Click "Create bucket"**

### 3. Configure Bucket Permissions

#### A. Bucket Policy (Public Read Access)

Go to your bucket → Permissions → Bucket Policy → Add:

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

Replace `your-bucket-name` with your actual bucket name.

#### B. CORS Configuration (Optional, for web access)

Go to Permissions → CORS → Add:

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

### 4. Create IAM User for Backend

1. **Go to AWS Console** → IAM → Users → Create user
2. **User name:** `easy-basket-s3-uploader`
3. **Attach policy:** Create custom policy with these permissions:

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

4. **Create Access Key:**
   - Go to Security credentials tab
   - Create access key
   - **Save the Access Key ID and Secret Access Key** (you'll only see the secret once!)

### 5. Add Credentials to Production Server

On your EC2 instance:

```bash
# Edit .env file
cd ~/easy-basket/backend
nano .env

# Add these lines:
AWS_ACCESS_KEY_ID=AKIA...your_key_here
AWS_SECRET_ACCESS_KEY=your_secret_here
AWS_S3_BUCKET_NAME=your-bucket-name
AWS_REGION=ap-south-1

# Save and exit (Ctrl+X, Y, Enter)

# Restart your backend
pm2 restart all
# OR
pm2 restart easy-basket-api
```

### 6. Verify Setup

After restarting, check the server logs:

```bash
pm2 logs easy-basket-api
```

You should see:
```
✅ AWS S3 client initialized
📦 Bucket: your-bucket-name
🌍 Region: ap-south-1
```

If you see:
```
⚠️  AWS S3 not configured - Image upload will be disabled
```

Then check your `.env` file and make sure all variables are set correctly.

### 7. Test Image Upload

1. Open your admin panel
2. Try uploading an image for a product or category
3. If successful, the image URL should be saved and visible

## Troubleshooting

### Error: "S3 client not initialized"

**Cause:** Missing or incorrect AWS credentials in `.env`

**Solution:**
1. Check `.env` file has all 4 required variables
2. Verify credentials are correct (no extra spaces, quotes, etc.)
3. Restart the backend server
4. Check server logs for initialization messages

### Error: "Access Denied" when uploading

**Cause:** IAM user doesn't have proper permissions

**Solution:**
1. Check IAM user has `s3:PutObject` permission
2. Verify bucket policy allows public read
3. Check bucket name matches in `.env`

### Images not displaying

**Cause:** Bucket policy not configured for public read

**Solution:**
1. Go to S3 bucket → Permissions → Bucket Policy
2. Add the public read policy (see step 3A above)
3. Make sure "Block public access" is disabled

## Security Best Practices

1. **Use IAM roles instead of access keys** (if using EC2)
   - Create IAM role with S3 permissions
   - Attach role to EC2 instance
   - Remove access keys from `.env`

2. **Restrict IAM permissions** to only the bucket you need:
   ```json
   "Resource": "arn:aws:s3:::your-bucket-name/*"
   ```

3. **Never commit `.env` file** to git
   - Add `.env` to `.gitignore`
   - Use environment variables or secrets manager in production

4. **Rotate access keys** regularly
   - Create new keys
   - Update `.env`
   - Delete old keys

## Cost Estimate

- **Storage:** ~$0.023 per GB/month
- **Uploads:** ~$0.005 per 1,000 requests
- **Downloads:** ~$0.0004 per 1,000 requests

For a typical grocery app:
- 1,000 products with images: ~$0.50/month
- 10,000 uploads/month: ~$0.05/month
- **Total: ~$0.55/month** (very affordable!)

