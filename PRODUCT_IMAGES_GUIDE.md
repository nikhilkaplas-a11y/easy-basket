# Product Images & Adding Products Guide

## 📸 Where Product Images Are Stored

Currently, your app uses **image URLs** stored in the database. The `imageUrl` field in the `Product` entity stores a URL string that points to an image hosted online.

### Current Setup:
- **Storage Type**: URLs (external image hosting)
- **Current Source**: Unsplash images (from seed data)
- **Database Field**: `imageUrl` (nullable string in Product table)

### How Images Work:
1. **Backend**: Stores image URL as a string in the `imageUrl` column
2. **Frontend**: Fetches the URL and displays it using `cached_network_image`
3. **Display**: Images are loaded from the URL when products are shown

---

## 🖼️ Image Storage Options

You have **3 options** for storing product images:

### Option 1: External Image URLs (Current - Easiest)
**Best for**: Quick setup, testing, small scale

**How it works**:
- Upload images to a free image hosting service
- Copy the image URL
- Paste URL when adding products

**Free Image Hosting Services**:
- **Imgur**: https://imgur.com (free, no account needed)
- **Cloudinary**: https://cloudinary.com (free tier available)
- **ImgBB**: https://imgbb.com (free, simple)
- **Unsplash**: https://unsplash.com (free stock photos)

**Steps**:
1. Upload image to Imgur/Cloudinary
2. Copy the direct image URL (ends with .jpg, .png, etc.)
3. Paste URL in "Image URL" field when adding product

**Example URL**: `https://i.imgur.com/abc123.jpg`

---

### Option 2: Local File Storage (Requires Backend Changes)
**Best for**: Full control, no external dependencies

**How it works**:
- Store images in `backend/uploads/products/` folder
- Serve images via Express static file server
- Store relative path in database (e.g., `/uploads/products/image.jpg`)

**Pros**:
- Full control over images
- No external dependencies
- Free

**Cons**:
- Requires backend code changes
- Need to handle file uploads
- Images stored on server (uses disk space)

**Would need**:
- File upload middleware (multer)
- Static file serving
- Image upload endpoint

---

### Option 3: Cloud Storage (AWS S3, Google Cloud Storage)
**Best for**: Production, scalability, CDN benefits

**How it works**:
- Upload images to AWS S3 or Google Cloud Storage
- Get public URL from cloud storage
- Store URL in database

**Pros**:
- Scalable
- Fast delivery (CDN)
- Reliable
- Professional

**Cons**:
- Requires cloud account
- May have costs at scale
- More complex setup

---

## ➕ How to Add New Products

### Method 1: Via Admin Dashboard (Recommended)

1. **Login as Admin**:
   - Open the app
   - Login with an admin account (role: 'admin')

2. **Navigate to Products**:
   - Go to Admin Dashboard
   - Click "Products" button

3. **Add New Product**:
   - Click the "+" (Add) button
   - Fill in the form:
     - **Product Name*** (required)
     - **Category*** (required - select from dropdown)
     - **Description** (optional)
     - **Price*** (required - in ₹)
     - **Stock** (optional - default: 0)
     - **Unit** (select: piece, kg, g, liter, ml, pack, dozen)
     - **Image URL** (optional - paste image URL here)

4. **Save Product**:
   - Click "Create Product" button
   - Product will be added to database

---

### Method 2: Via Backend API (Direct)

**Endpoint**: `POST /api/admin/products`

**Headers**:
```
Authorization: Bearer <admin_token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "name": "Product Name",
  "description": "Product description",
  "price": 100.00,
  "categoryId": 1,
  "stock": 50,
  "unit": "kg",
  "imageUrl": "https://example.com/image.jpg"
}
```

**Example using curl**:
```bash
curl -X POST https://api.easybasket.in/api/admin/products \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Fresh Mangoes",
    "description": "Sweet and juicy mangoes",
    "price": 150,
    "categoryId": 1,
    "stock": 30,
    "unit": "kg",
    "imageUrl": "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400"
  }'
```

---

### Method 3: Via Database Seed Script (Bulk)

**File**: `backend/src/scripts/seed.ts`

1. **Edit the seed file**:
   ```typescript
   const products = [
     {
       name: 'New Product',


       description: 'Description here',
       price: 100,
       unit: 'kg',
       stock: 50,
       category: savedCategories[0], // Category index
       imageUrl: 'https://example.com/image.jpg'
     },
     // ... more products
   ];
   ```

2. **Run seed script**:
   ```bash
   cd backend
   npm run seed
   ```

**Note**: This will **delete all existing products** and create new ones. Use with caution!

---

## 📝 Step-by-Step: Adding a Product with Image

### Using Admin Dashboard:

1. **Prepare your image**:
   - Take/select a product photo
   - Image should be clear, square/rectangular format
   - Recommended size: 400x400px or larger

2. **Upload image to hosting service**:
   - Go to https://imgur.com
   - Click "New post"
   - Upload your image
   - Right-click image → "Copy image address"
   - You'll get a URL like: `https://i.imgur.com/xyz123.jpg`

3. **Add product in app**:
   - Login as admin
   - Go to Admin Dashboard → Products
   - Click "+" button
   - Fill in:
     - Name: "Fresh Mangoes"
     - Category: "Fruits & Vegetables"
     - Price: "150"
     - Stock: "30"
     - Unit: "kg"
     - Image URL: `https://i.imgur.com/xyz123.jpg`
   - Click "Create Product"

4. **Verify**:
   - Product should appear in the products list
   - Image should load on home screen and product details

---

## 🔍 Current Image URLs in Database

Your seed data uses **Unsplash** image URLs. These are free stock photos:

**Format**: `https://images.unsplash.com/photo-XXXXXXXX?w=400`

**Examples**:
- Tomatoes: `https://images.unsplash.com/photo-1546093354-7eef13592681?w=400`
- Milk: `https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400`
- Bread: `https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400`

**Note**: Unsplash URLs work but may be slower. For production, consider:
- Using your own image hosting
- Or implementing local file storage
- Or using cloud storage (AWS S3)

---

## 🛠️ Quick Tips

1. **Image URL Format**:
   - Must be a direct link to image file
   - Should end with `.jpg`, `.png`, `.webp`, etc.
   - Must be publicly accessible (no login required)

2. **Image Size**:
   - Recommended: 400x400px to 800x800px
   - Too large = slow loading
   - Too small = blurry on high-res screens

3. **Testing Image URLs**:
   - Paste URL in browser to verify it works
   - Should show image directly (not a webpage)

4. **Bulk Adding Products**:
   - Use Admin Dashboard for 1-10 products
   - Use seed script for 50+ products
   - Use API for automation/integration

---

## ❓ Troubleshooting

**Image not showing?**
- Check if URL is accessible in browser
- Verify URL is direct image link (not webpage)
- Check network connection
- Clear app cache

**Can't add product?**
- Verify you're logged in as admin
- Check all required fields are filled
- Ensure category exists
- Check backend is running

**Image URL too long?**
- Use image hosting service (Imgur, Cloudinary)
- Shorten URL if needed
- Database can handle long URLs

---

## 🚀 Next Steps

1. **For Testing**: Use Imgur or Unsplash URLs (easiest)
2. **For Production**: Consider implementing local file storage or cloud storage
3. **For Bulk Products**: Use seed script or API automation

Need help implementing file upload? Let me know!

