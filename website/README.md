# Easy Basket Landing Page

A beautiful, modern landing page for Easy Basket - Instant Grocery Delivery app.

## 📁 Files

- `index.html` - Main HTML file
- `styles.css` - All styling and responsive design
- `script.js` - Interactive features and animations
- `DEPLOYMENT_GUIDE.md` - Complete deployment instructions

## 🎨 Features

- ✅ Modern, responsive design
- ✅ Mobile-friendly
- ✅ Smooth animations
- ✅ Live Google Play download link, iOS "coming soon" badge
- ✅ Feature highlights
- ✅ How it works section
- ✅ Download section
- ✅ SEO optimized

## 🚀 Quick Start

### Local Testing

1. Open `index.html` in your browser
2. Or use a local server:
   ```bash
   # Python
   python3 -m http.server 8000
   
   # Node.js
   npx serve .
   
   # PHP
   php -S localhost:8000
   ```
3. Visit `http://localhost:8000`

## 📝 Customization

### Update Download Links

When your apps are published, update the download buttons in `index.html`:

```html
<!-- Find these lines and update href -->
<a href="YOUR_GOOGLE_PLAY_LINK" class="download-btn google-play">
<a href="YOUR_APP_STORE_LINK" class="download-btn app-store">
```

### Change Colors

Edit CSS variables in `styles.css`:

```css
:root {
    --primary-green: #2ECC71;  /* Change this */
    --primary-green-dark: #27AE60;
    --primary-green-light: #58D68D;
}
```

### Update Content

Edit text directly in `index.html`:
- Hero section title and description
- Features section
- How it works steps
- Footer information

## 🌐 Deployment

See `DEPLOYMENT_GUIDE.md` for complete instructions.

**Quick deploy to AWS S3:**
```bash
aws s3 sync . s3://your-bucket-name --delete
```

## 📱 Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile browsers (iOS Safari, Chrome Mobile)

## 📄 License

Part of Easy Basket project.
