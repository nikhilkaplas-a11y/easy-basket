# Image Upload Implementation Plan

## 🎯 Goal

Allow admins to upload product and category images directly from the app instead of manually entering URLs.

---

## 📋 Architecture Overview

### Current Flow (Manual URL)
```
Admin → Enter Image URL → Save Product → Backend stores URL → Display image
```

### New Flow (Image Upload)
```
Admin → Select Image → Preview → Upload → Backend → AWS S3 → Get URL → Save Product → Display image
```

---

## 🏗️ Implementation Components

### 1. **Frontend (Flutter)**

#### A. Image Picker
- **Package:** `image_picker` (already in pubspec.yaml)
- **Features:**
  - Select from gallery
  - Take photo with camera
  - Support both Android and iOS

#### B. Image Processing
- **Package:** `image` (for compression/resizing)
- **Features:**
  - Resize large images (max 1024x1024)
  - Compress to reduce file size (max 500KB)
  - Maintain aspect ratio
  - Convert to JPEG/PNG format

#### C. UI Components
- **Image Preview Widget:**
  - Show selected image before upload
  - Allow user to change image
  - Show image dimensions and size
- **Upload Progress Indicator:**
  - Circular progress bar
  - Percentage display
  - Upload speed (optional)
- **Error Handling:**
  - Network errors
  - File size errors
  - Upload failures

#### D. Integration Points
- **Add/Edit Product Screen:**
  - Replace URL input with image picker button
  - Show image preview
  - Upload on save
- **Add/Edit Category Screen:**
  - Same as product screen

---

### 2. **Backend (Node.js/Express)**

#### A. File Upload Endpoint
- **Route:** `POST /api/admin/upload-image`
- **Method:** Multipart form data
- **Middleware:** `multer` for file handling
- **Validation:**
  - File type (jpg, jpeg, png, webp)
  - File size (max 5MB)
  - Image dimensions (optional)

#### B. AWS S3 Integration
- **Package:** `@aws-sdk/client-s3`
- **Configuration:**
  - S3 bucket name
  - AWS region
  - IAM credentials (Access Key, Secret Key)
- **Upload Process:**
  1. Receive admin-provided image name (or auto-generate from product/category name)
  2. Generate structured filename: `{type}-{id}-{slug}.{ext}`
  3. Sanitize slug (remove special chars, lowercase, hyphens)
  4. Upload to S3 with proper content type
  5. Set public read permissions
  6. Return S3 URL
- **Filename Generation:**
  - Format: `product-{id}-{admin-slug}.jpg`
  - Example: `product-123-tomato-fresh.jpg`
  - **Benefits:** Identifiable, searchable, human-readable

#### C. Image Organization
- **Folder Structure:**
  ```
  s3://easy-basket-bucket/
    ├── products/
    │   ├── product-123-tomato-fresh.jpg
    │   ├── product-456-onion-red.jpg
    │   └── product-789-potato.jpg
    └── categories/
        ├── category-1-fruits-vegetables.jpg
        └── category-2-beverages.jpg
  ```

- **Filename Format:**
  - Products: `product-{id}-{admin-slug}.{ext}`
  - Categories: `category-{id}-{admin-slug}.{ext}`
  - Example: `product-123-tomato-fresh.jpg`
  - **Admin provides image name** (with auto-suggestion from product name)
  - **ID ensures uniqueness** and makes it searchable

#### D. Request Format
```typescript
POST /api/admin/upload-image
Content-Type: multipart/form-data

{
  file: <image file>,
  type: "product" | "category",
  id: 123,  // Product or Category ID
  name: "tomato-fresh"  // Admin-provided name (optional, auto-suggested from product name)
}
```

#### E. Response Format
```json
{
  "success": true,
  "url": "https://easy-basket-bucket.s3.amazonaws.com/products/product-123-tomato-fresh.jpg",
  "filename": "product-123-tomato-fresh.jpg",
  "path": "products/product-123-tomato-fresh.jpg",
  "size": 245678,
  "mimetype": "image/jpeg"
}
```

---

### 3. **AWS S3 Setup**

#### A. Create S3 Bucket
- **Bucket Name:** `easy-basket-images` (or similar)
- **Region:** Same as EC2 (e.g., `eu-north-1`)
- **Public Access:** Block all public access (we'll use public read for specific objects)
- **Versioning:** Disabled (for now)
- **Encryption:** Enabled (SSE-S3)

#### B. Configure CORS
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

#### C. Bucket Policy (Public Read)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::easy-basket-images/*"
    }
  ]
}
```

#### D. IAM User/Role for Backend
- **Create IAM User:** `easy-basket-s3-uploader`
- **Permissions:** 
  - `s3:PutObject` (upload images)
  - `s3:GetObject` (read images)
  - `s3:DeleteObject` (delete images - optional)
- **Scope:** Only to `easy-basket-images` bucket
- **Generate Access Keys:** Store in backend `.env`

---

## 🔄 Complete Flow

### Step 1: User Selects Image
```
Admin opens Add Product screen
→ Clicks "Select Image" button
→ Image picker opens (gallery/camera)
→ User selects image
→ Image is loaded into memory
```

### Step 2: Image Processing
```
Selected image
→ Check file size (if > 5MB, show error)
→ Resize if needed (max 1024x1024)
→ Compress (reduce quality to ~80%)
→ Convert to JPEG/PNG
→ Show preview to user
```

### Step 3: Upload to Backend
```
User clicks "Upload Image"
→ Show upload progress indicator
→ Send multipart/form-data to /api/admin/upload-image
  - file: <image>
  - type: "product"
  - id: 123
  - name: "tomato-fresh" (admin-provided)
→ Backend receives file
→ Validate file (type, size)
→ Generate structured filename: product-123-tomato-fresh.jpg
→ Upload to S3: products/product-123-tomato-fresh.jpg
→ Return S3 URL
```

### Step 4: Save Product
```
Backend returns S3 URL
→ Frontend receives URL
→ Save product with image URL
→ Update UI with uploaded image
→ Hide progress indicator
```

---

## 📦 Required Packages

### Frontend (Flutter)
```yaml
dependencies:
  image_picker: ^1.0.0  # Already in pubspec.yaml
  image: ^4.0.0         # For compression/resizing
  http: ^1.0.0          # Already in pubspec.yaml (for multipart upload)
```

### Backend (Node.js)
```json
{
  "dependencies": {
    "multer": "^1.4.5-lts.1",           # File upload middleware
    "@aws-sdk/client-s3": "^3.0.0",     # AWS S3 SDK
    "@aws-sdk/s3-request-presigner": "^3.0.0"  # Optional: for presigned URLs
  }
}
```

---

## 🎨 UI/UX Design

### Add/Edit Product Screen

**Current:**
```
[Image URL Input Field]
```

**New:**
```
[Image Preview Card]
  ┌─────────────────────┐
  │   [Image Preview]   │
  │                     │
  │  [Change Image]     │
  └─────────────────────┘

[Select Image Button]
  - "Choose from Gallery"
  - "Take Photo"

[Image Name Input]
  ┌─────────────────────┐
  │ tomato-fresh        │ ← Auto-filled from product name
  └─────────────────────┘   Admin can edit
  ℹ️ Filename: product-123-tomato-fresh.jpg

[Upload Image Button]
```

**States:**
1. **No Image:** Show placeholder + "Select Image" button
2. **Image Selected:** Show preview + "Change Image" button + Image name input
3. **Uploading:** Show progress bar + "Uploading..." text
4. **Uploaded:** Show image + "Image uploaded successfully" checkmark + filename preview
5. **Error:** Show error message + "Retry" button

**Image Name Input:**
- Auto-filled from product/category name (slugified)
- Admin can edit to customize
- Shows preview of final filename
- Validates: no special chars, max 50 chars

---

## 🔒 Security Considerations

### 1. File Validation
- **File Type:** Only allow jpg, jpeg, png, webp
- **File Size:** Max 5MB before compression
- **File Content:** Verify it's actually an image (not just extension)

### 2. S3 Security
- **Bucket Policy:** Public read only for uploaded objects
- **IAM Permissions:** Minimal permissions (only PutObject, GetObject)
- **Access Keys:** Store in `.env`, never commit to git

### 3. Rate Limiting
- **Upload Limit:** Max 10 uploads per minute per user
- **Prevent Abuse:** Check file size and type server-side

### 4. Image Optimization
- **Compress:** Reduce file size to save S3 storage costs
- **Resize:** Prevent huge images from being uploaded
- **Format:** Convert to efficient formats (JPEG for photos, PNG for graphics)

---

## 💰 Cost Considerations

### AWS S3 Costs
- **Storage:** ~$0.023 per GB/month
- **Requests:** 
  - PUT requests: $0.005 per 1,000 requests
  - GET requests: $0.0004 per 1,000 requests
- **Data Transfer:** Free for first 100GB/month (outbound)

### Estimated Monthly Cost
- **1,000 products with images:** ~$0.50/month (storage)
- **10,000 uploads/month:** ~$0.05/month (requests)
- **Total:** ~$0.55/month (very affordable!)

---

## 🚀 Implementation Steps

### Phase 1: Backend Setup (30 minutes)
1. ✅ Install packages (`multer`, `@aws-sdk/client-s3`)
2. ✅ Create S3 bucket
3. ✅ Configure IAM user and permissions
4. ✅ Add S3 credentials to `.env`
5. ✅ Create upload endpoint (`POST /api/admin/upload-image`)
6. ✅ Test upload manually (Postman/curl)

### Phase 2: Frontend Setup (1 hour)
1. ✅ Install/verify packages (`image_picker`, `image`)
2. ✅ Create image picker widget
3. ✅ Create image preview widget
4. ✅ Create upload progress widget
5. ✅ Integrate into Add/Edit Product screen
6. ✅ Integrate into Add/Edit Category screen

### Phase 3: Testing (30 minutes)
1. ✅ Test image selection (gallery/camera)
2. ✅ Test image compression
3. ✅ Test upload to S3
4. ✅ Test error handling
5. ✅ Test on both Android and iOS

---

## 📝 Code Structure

### Backend Structure
```
backend/src/
  ├── controllers/
  │   └── upload.controller.ts    # New: Handle image upload
  ├── services/
  │   └── s3.service.ts          # New: S3 upload logic
  ├── routes/
  │   └── upload.routes.ts       # New: Upload routes
  └── middleware/
      └── upload.middleware.ts   # New: Multer configuration
```

### Frontend Structure
```
mobile/lib/
  ├── screens/
  │   └── admin/
  │       ├── add_edit_product_screen.dart  # Modify: Add image picker + name input
  │       └── add_edit_category_screen.dart # Modify: Add image picker + name input
  ├── widgets/
  │   ├── image_picker_widget.dart         # New: Image picker
  │   ├── image_preview_widget.dart        # New: Image preview
  │   ├── image_name_input_widget.dart     # New: Image name input with auto-suggest
  │   └── upload_progress_widget.dart      # New: Upload progress
  ├── services/
  │   ├── image_upload_service.dart        # New: Upload service
  │   └── slug_service.dart                # New: Slug generation utility
  └── utils/
      └── slug_utils.dart                   # New: Slug helper functions
```

---

## 🔄 Alternative Approaches Considered

### Option 1: Direct S3 Upload (Presigned URLs) ⭐ Recommended
**How it works:**
- Backend generates presigned URL
- Frontend uploads directly to S3
- No backend bandwidth usage
- Faster uploads

**Pros:**
- ✅ Faster (direct to S3)
- ✅ Less backend load
- ✅ Better for large files

**Cons:**
- ❌ More complex (presigned URL generation)
- ❌ Need to handle S3 errors in frontend

### Option 2: Backend Proxy Upload (Current Plan)
**How it works:**
- Frontend uploads to backend
- Backend uploads to S3
- Backend returns S3 URL

**Pros:**
- ✅ Simpler frontend code
- ✅ Better error handling (centralized)
- ✅ Can validate/process on backend

**Cons:**
- ❌ Uses backend bandwidth
- ❌ Slower (double upload)

**Decision:** Start with Option 2 (simpler), can upgrade to Option 1 later.

---

## 🎯 Success Criteria

### Functional Requirements
- ✅ Admin can select image from gallery
- ✅ Admin can take photo with camera
- ✅ Image is compressed before upload
- ✅ Upload progress is shown
- ✅ Image URL is saved to product/category
- ✅ Image displays correctly in app

### Non-Functional Requirements
- ✅ Upload completes in < 10 seconds (for 1MB image)
- ✅ Supports images up to 5MB (before compression)
- ✅ Works on both Android and iOS
- ✅ Handles network errors gracefully
- ✅ Shows clear error messages

---

## 🐛 Error Handling

### Frontend Errors
1. **Image too large:** "Image is too large. Please select a smaller image."
2. **Invalid format:** "Please select a valid image (JPG, PNG, or WebP)."
3. **Upload failed:** "Failed to upload image. Please try again."
4. **Network error:** "Network error. Please check your connection."

### Backend Errors
1. **File validation failed:** Return 400 with error message
2. **S3 upload failed:** Return 500 with error message
3. **Invalid credentials:** Return 500 with error message

---

## 📊 Monitoring & Logging

### Backend Logging
- Log all upload attempts
- Log S3 upload success/failure
- Log file sizes and types
- Monitor S3 costs

### Frontend Logging
- Log image selection
- Log upload progress
- Log errors

---

## 🔄 Future Enhancements

### Phase 2 (Optional)
- **Image Cropping:** Allow users to crop images before upload
- **Multiple Images:** Support multiple images per product
- **Image Gallery:** Show all uploaded images
- **Image Deletion:** Delete old images when updating
- **CDN Integration:** Use CloudFront for faster image delivery

### Phase 3 (Optional)
- **Direct S3 Upload:** Use presigned URLs for faster uploads
- **Image Optimization Service:** Use AWS Lambda for automatic optimization
- **Image CDN:** CloudFront for global delivery

---

## ✅ Implementation Checklist

### Backend
- [ ] Install `multer` and `@aws-sdk/client-s3`
- [ ] Create S3 bucket
- [ ] Configure IAM user and permissions
- [ ] Add S3 credentials to `.env`
- [ ] Create `s3.service.ts` (S3 upload logic)
- [ ] Create `upload.middleware.ts` (Multer config)
- [ ] Create `upload.controller.ts` (Upload endpoint)
- [ ] Create `upload.routes.ts` (Route definition)
- [ ] Add route to main app
- [ ] Test upload endpoint

### Frontend
- [ ] Verify `image_picker` package
- [ ] Install `image` package (if not exists)
- [ ] Create `image_upload_service.dart`
- [ ] Create `image_picker_widget.dart`
- [ ] Create `image_preview_widget.dart`
- [ ] Create `upload_progress_widget.dart`
- [ ] Modify `add_edit_product_screen.dart`
- [ ] Modify `add_edit_category_screen.dart`
- [ ] Test on Android
- [ ] Test on iOS

### Testing
- [ ] Test image selection (gallery)
- [ ] Test image selection (camera)
- [ ] Test image compression
- [ ] Test upload to S3
- [ ] Test error handling
- [ ] Test on different image sizes
- [ ] Test on slow network

---

## 🎓 Summary

**Architecture:**
- Frontend: Image picker → Compression → Upload to backend
- Backend: Receive file → Validate → Upload to S3 → Return URL
- S3: Store images → Public read access → Return URL

**Key Features:**
- Image selection (gallery/camera)
- Image compression (reduce size)
- Upload progress indicator
- Error handling
- S3 storage (scalable, cost-effective)

**Estimated Time:**
- Backend setup: 30 minutes
- Frontend implementation: 1 hour
- Testing: 30 minutes
- **Total: ~2 hours**

**Cost:**
- AWS S3: ~$0.50-1/month (very affordable!)

---

## ❓ Questions to Consider

1. **Image Size Limit:** What's the maximum file size? (Recommend: 5MB before compression)
2. **Image Dimensions:** Should we enforce max dimensions? (Recommend: 1024x1024)
3. **Image Format:** Which formats to support? (Recommend: JPG, PNG, WebP)
4. **Storage Location:** S3 bucket region? (Recommend: Same as EC2)
5. **CDN:** Do we need CloudFront? (Recommend: Not needed initially, can add later)
6. **Filename Strategy:** ✅ **SOLVED** - Structured filenames with admin input (see `IMAGE_UPLOAD_NAMING_STRATEGY.md`)
   - Format: `product-{id}-{admin-slug}.jpg`
   - Admin provides name (with auto-suggestion)
   - Makes images identifiable and searchable

---

**Ready to implement?** This plan covers all aspects. Should I proceed with implementation? 🚀

