# Serve S3 images through CloudFront

This gives you a **CDN** (edge caching, lower latency, optional custom domain) while objects stay in S3. Your backend already uses **`PUBLIC_MEDIA_BASE_URL`** for all image URLs returned to apps; point that value at CloudFront instead of the S3 website URL.

## 1. What you configure in the app

In **`backend/.env`** (same value everywhere: API responses + upload preview URL):

```env
PUBLIC_MEDIA_BASE_URL=https://dxxxxxxxxxxxxxx.cloudfront.net
```

Use your real distribution domain from CloudFront (or a custom domain like `https://media.yourdomain.com` after step 5).

Restart the API after changing env.

## 2. Create a CloudFront distribution (AWS Console)

1. Open **CloudFront** → **Create distribution**.
2. **Origin domain**  
   - Choose your **S3 bucket’s REST API endpoint** (e.g. `your-bucket.s3.ap-south-1.amazonaws.com`).  
   - Do **not** pick the “website endpoint” unless you intentionally use static website hosting.
3. **Origin access**  
   - Recommended: **Origin access control settings (recommended)** → **Create new OAC** → allow CloudFront to read from the bucket.  
   - This keeps the bucket **private**; only CloudFront can fetch objects (more secure than public bucket).
4. After creation, CloudFront shows a **bucket policy** snippet — **copy it into S3** → Bucket → **Permissions** → **Bucket policy** (merge with existing policy if any).
5. **Default cache behavior**  
   - **Viewer protocol policy**: Redirect HTTP to HTTPS.  
   - **Allowed HTTP methods**: GET, HEAD (enough for images).  
   - **Cache policy**: `CachingOptimized` is fine to start; tune later for longer TTL on immutable filenames.
6. **Settings**  
   - **Price class**: e.g. “Use only North America and Europe” or include Asia/India as needed.  
   - **Alternate domain name (CNAME)** — optional; see section 5.
7. **Create** and wait until status is **Deployed** (can take several minutes).

## 3. Bucket policy (OAC)

If you use OAC, the bucket must allow **`s3:GetObject`** for your distribution’s service principal. AWS shows the exact JSON when you create the origin; it looks like:

```json
{
  "Sid": "AllowCloudFrontServicePrincipal",
  "Effect": "Allow",
  "Principal": { "Service": "cloudfront.amazonaws.com" },
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*",
  "Condition": {
    "StringEquals": {
      "AWS:SourceArn": "arn:aws:cloudfront::ACCOUNT_ID:distribution/DISTRIBUTION_ID"
    }
  }
}
```

Replace `YOUR-BUCKET-NAME`, `ACCOUNT_ID`, and `DISTRIBUTION_ID` with your values.

**Alternative (simpler, less secure):** keep the bucket **publicly readable** (your current bucket policy) and use CloudFront as a cache in front. OAC is still recommended for new setups.

## 4. Test

```bash
# Replace with your object key and CloudFront domain
curl -I "https://dxxxxxxxxxxxxxx.cloudfront.net/products/your-image.jpg"
```

Expect **HTTP/2 200** and `x-cache: Hit from cloudfront` or `Miss from cloudfront` on first request.

## 5. Custom domain (optional)

1. **ACM certificate** in **us-east-1** (N. Virginia) — CloudFront only accepts certs from that region for alternate domain names.
2. Validate the cert (DNS).
3. In the distribution → **General** → **Edit** → add **Alternate domain name (CNAME)** — e.g. `media.easyBasket.in` — attach the ACM certificate.
4. In **DNS** (Route 53 or GoDaddy), add a **CNAME** from `media.easyBasket.in` to `dxxxxxxxxxxxxxx.cloudfront.net`.
5. Set **`PUBLIC_MEDIA_BASE_URL=https://media.easyBasket.in`**.

## 6. Invalidate cache (when you overwrite an image at the same key)

CloudFront caches by URL. If you replace the same key in S3, clients may see old bytes until TTL expires. Options:

- Use **versioned filenames** (your app already does product/category slugs — new uploads usually get new keys).
- Or run **Create invalidation** in CloudFront for paths like `/products/*` when needed.

## 7. Backend behavior (already implemented)

- **`PUBLIC_MEDIA_BASE_URL`** — all JSON `imageUrl` fields use `base + path`.
- **Upload response** — `url` in `POST /api/admin/upload-image` uses the same base when set, so the admin UI preview matches what users see.

No code change is required beyond env and AWS; uploads use the same logic as read APIs.
