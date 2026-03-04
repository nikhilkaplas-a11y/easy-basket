# Fix 403 Forbidden on S3 Privacy Policy Bucket

Your bucket: `easybasket-policy`  
URL: `http://easybasket-policy.s3-website.ap-south-1.amazonaws.com`

## Step 1: Turn off "Block public access" for this bucket

1. AWS Console → **S3** → bucket **easybasket-policy**
2. Go to **Permissions** tab
3. Under **Block public access (bucket settings)** click **Edit**
4. **Uncheck** "Block all public access" (or at least uncheck "Block public access to buckets and objects granted through new public bucket or access point policies")
5. Confirm and save

## Step 2: Add a bucket policy to allow public read

1. Still in **Permissions** → **Bucket policy** → **Edit**
2. Paste the policy below (replace `easybasket-policy` if your bucket name is different):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::easybasket-policy/*"
    }
  ]
}
```

3. Save changes

## Step 3: Make sure the file is in the bucket

1. Go to **Objects** tab
2. You should have either:
   - **index.html** (and set index document to `index.html` in Static website hosting), or
   - **privacy-policy.html** (then use the full URL below)

## Step 4: Use the correct URL

**If you have index.html as the main page:**
- `http://easybasket-policy.s3-website.ap-south-1.amazonaws.com/`

**If you only have privacy-policy.html:**
- Set **Static website hosting** → Index document to **privacy-policy.html**,  
  **or** open the file directly:
- `http://easybasket-policy.s3-website.ap-south-1.amazonaws.com/privacy-policy.html`

## Step 5: (Optional) Use HTTPS

S3 website endpoints are HTTP only. For HTTPS:
- Use **CloudFront** in front of this bucket and use the CloudFront URL, or
- Use the **object URL** instead of website URL:  
  `https://easybasket-policy.s3.ap-south-1.amazonaws.com/privacy-policy.html`  
  (You must still allow public read via bucket policy for this to work.)

## Quick checklist

- [ ] Block public access turned off for bucket
- [ ] Bucket policy added (Principal "*", Action s3:GetObject, Resource bucket/*)
- [ ] privacy-policy.html (or index.html) uploaded
- [ ] Open URL: .../privacy-policy.html or set index to that file

After this, the link should load and you can use it in Google Play Console as your privacy policy URL.
