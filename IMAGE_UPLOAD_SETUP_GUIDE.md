# Image Upload Setup Guide

## ✅ Implementation Complete

The image upload feature has been fully implemented with the **hybrid approach** (structured filenames with admin input).

---

## 📋 What's Implemented

### Backend
- ✅ **S3 Service** (`backend/src/services/s3.service.ts`)
  - AWS S3 client initialization
  - Structured filename generation: `product-{id}-{slug}.jpg`
  - Image upload to S3
  - Image deletion from S3
  - URL extraction from S3 URLs

- ✅ **Upload Controller** (`backend/src/controllers/upload.controller.ts`)
  - Upload image endpoint
  - Delete image endpoint
  - Validation and error handling

- ✅ **Upload Routes** (`backend/src/routes/upload.routes.ts`)
  - `POST /api/admin/upload-image`
  - `DELETE /api/admin/delete-image`
  - Admin authentication required

- ✅ **Slug Utilities** (`backend/src/utils/slug.util.ts`)
  - Generate slug from product/category name
  - Sanitize admin-provided names
  - File extension extraction

- ✅ **Multer Middleware** (`backend/src/middleware/upload.middleware.ts`)
  - File upload handling
  - File type validation (JPG, PNG, WebP)
  - File size limit (5MB)

### Frontend
- ✅ **Image Upload Service** (`mobile/lib/services/image_upload_service.dart`)
  - Image picker integration
  - Image compression (max 1024x1024, quality 80%)
  - Multipart upload to backend
  - Progress tracking

- ✅ **Image Picker Widget** (`mobile/lib/widgets/image_picker_widget.dart`)
  - Gallery selection
  - Camera capture
  - Image preview
  - Current image display (for editing)

- ✅ **Image Name Input Widget** (`mobile/lib/widgets/image_name_input_widget.dart`)
  - Auto-suggestion from product/category name
  - Admin can edit
  - Filename preview
  - Validation

- ✅ **Product Screen Integration** (`mobile/lib/screens/admin/add_edit_product_screen.dart`)
  - Image picker UI
  - Image name input
  - Upload button with progress
  - Fallback to manual URL input

- ✅ **Category Screen Integration** (`mobile/lib/screens/admin/add_edit_category_screen.dart`)
  - Same features as product screen

- ✅ **Slug Utilities** (`mobile/lib/utils/slug_utils.dart`)
  - Slug generation
  - Slug sanitization

---

## 🔧 Setup Required

### 1. Backend Environment Variables

Add to `backend/.env`:

```env
# AWS S3 Configuration
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
AWS_REGION=eu-north-1
AWS_S3_BUCKET_NAME=your-bucket-name
```

### 2. AWS S3 Setup

1. **Create S3 Bucket:**
   ```bash
   # Via AWS Console or CLI
   aws s3 mb s3://easy-basket-images --region eu-north-1
   ```

2. **Configure Bucket Permissions:**
   - Enable public read access for images
   - Set CORS policy (if needed for web)

3. **Create IAM User:**
   - Create IAM user with S3 access
   - Attach policy: `AmazonS3FullAccess` (or custom policy)
   - Generate Access Key ID and Secret Access Key

4. **Bucket Structure:**
   ```
   s3://easy-basket-images/
     ├── products/
     │   ├── product-123-tomato-fresh.jpg
     │   └── product-456-onion-red.jpg
     └── categories/
         ├── category-1-fruits.jpg
         └── category-2-vegetables.jpg
   ```

### 3. Install Backend Packages

Already installed:
- ✅ `multer` - File upload handling
- ✅ `@aws-sdk/client-s3` - AWS S3 SDK
- ✅ `@types/multer` - TypeScript types

### 4. Install Frontend Packages

Already installed:
- ✅ `image_picker` - Image selection
- ✅ `image` - Image compression

---

## 🚀 Usage

### For Admins

1. **Add/Edit Product:**
   - Navigate to Add/Edit Product screen
   - Tap "Select Image" → Choose from gallery or camera
   - Image name auto-fills from product name (can edit)
   - Tap "Upload Image" → Image uploads to S3
   - Product automatically updated with image URL

2. **Add/Edit Category:**
   - Same flow as products

### Filename Format

- **Products:** `product-{id}-{admin-slug}.jpg`
  - Example: `product-123-tomato-fresh.jpg`

- **Categories:** `category-{id}-{admin-slug}.jpg`
  - Example: `category-1-fruits-vegetables.jpg`

### Benefits

- ✅ **Identifiable:** Know which product/category from filename
- ✅ **Searchable:** Can search by name in S3
- ✅ **Organized:** Clear structure
- ✅ **Human-readable:** Easy to understand
- ✅ **Unique:** ID ensures no conflicts

---

## 🧪 Testing

### Backend Test

```bash
# Test upload endpoint
curl -X POST http://localhost:3000/api/admin/upload-image \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@test-image.jpg" \
  -F "type=product" \
  -F "id=123" \
  -F "name=tomato-fresh"
```

### Frontend Test

1. Login as admin
2. Go to Add Product
3. Enter product name: "Fresh Tomato"
4. Select image
5. Image name auto-fills: "fresh-tomato"
6. Upload image
7. Verify image appears in product

---

## 📝 Notes

- **File Size Limit:** 5MB (before compression)
- **Image Dimensions:** Auto-resized to max 1024x1024
- **Supported Formats:** JPG, PNG, WebP
- **Compression:** Quality 80% (JPEG)
- **Storage:** AWS S3 (public read access)

---

## 🔍 Troubleshooting

### Backend Issues

1. **S3 Client Not Initialized:**
   - Check AWS credentials in `.env`
   - Verify bucket name is correct
   - Check AWS region

2. **Upload Fails:**
   - Check IAM permissions
   - Verify bucket exists
   - Check CORS policy (if web)

### Frontend Issues

1. **Image Picker Not Working:**
   - Check permissions (camera/gallery)
   - Verify `image_picker` package installed

2. **Upload Fails:**
   - Check network connection
   - Verify backend is running
   - Check authentication token

---

## ✅ Next Steps

1. **Configure AWS S3:**
   - Create bucket
   - Set up IAM user
   - Add credentials to `.env`

2. **Test Upload:**
   - Try uploading a product image
   - Verify image appears in S3
   - Check product displays image correctly

3. **Optional Enhancements:**
   - Add image deletion from UI
   - Add multiple images per product
   - Add image cropping/editing
   - Add CDN (CloudFront) for faster delivery

---

## 📚 Related Files

- `IMAGE_UPLOAD_IMPLEMENTATION_PLAN.md` - Full implementation plan
- `IMAGE_UPLOAD_NAMING_STRATEGY.md` - Filename strategy details
- Backend: `backend/src/services/s3.service.ts`
- Frontend: `mobile/lib/services/image_upload_service.dart`

---

**Status:** ✅ **Ready for Testing** (after AWS S3 setup)

