# Location & Navigation Guide for Easy Basket

## Overview
Easy Basket uses high-precision GPS location tracking for instant delivery. This guide explains how location is captured, stored, and used for navigation.

## Location Accuracy

### For Customers (Address Selection)
- **Accuracy Level**: `LocationAccuracy.bestForNavigation`
- **Purpose**: Ensures delivery agents can find exact locations
- **Timeout**: 15 seconds maximum wait time
- **Fallback**: If GPS fails, users can manually enter address (with warning)

### Location Capture Process
1. Customer opens "Add Address" screen
2. Clicks "Use Current Location" or "Pick from Map"
3. System requests location permission
4. GPS fetches coordinates with best accuracy
5. Coordinates are reverse-geocoded to get address
6. Both coordinates AND address are saved

## Storage

### Database Fields
- `latitude`: String (e.g., "28.704059")
- `longitude`: String (e.g., "77.102490")
- Stored in `Address` entity
- Included in `Order.deliveryAddress` relation

### Why Both?
- **Coordinates**: Exact location for navigation
- **Address Text**: Human-readable fallback

## Navigation Features

### For Delivery Agents

#### 1. Order Detail Screen
- **"Get Directions" Button**: Opens Google Maps with turn-by-turn navigation
  - Uses exact coordinates if available
  - Falls back to text search if coordinates missing
  - Opens in external Google Maps app
  
- **"View Map" Button**: Shows location on map (no navigation)
  - Useful for quick location check
  - Opens in external Google Maps app

#### 2. Order Cards (Dashboard)
- **Quick Navigation Icon**: One-tap access to directions
- Only shown if coordinates are available
- Opens Google Maps directly with navigation

#### 3. Customer Contact
- **Call Button**: Direct phone call to customer
- Available on order detail screen

## Google Maps Integration

### URL Formats Used

#### Turn-by-Turn Navigation (Get Directions)
```
https://www.google.com/maps/dir/?api=1&destination=LAT,LNG&travelmode=driving
```
- Opens Google Maps with navigation
- Shows route from current location to destination
- Includes traffic, ETA, and turn-by-turn directions

#### View Location (View Map)
```
https://www.google.com/maps/search/?api=1&query=LAT,LNG
```
- Shows location on map
- No navigation, just viewing

#### Fallback (Text Search)
```
https://www.google.com/maps/search/?api=1&query=ADDRESS_TEXT
```
- Used when coordinates not available
- Less accurate but still functional

## Best Practices

### For Customers
1. **Always use location picker** when adding addresses
2. **Allow location permissions** for best accuracy
3. **Verify address** after selecting location
4. **Add landmarks** for easier finding

### For Delivery Agents
1. **Use "Get Directions"** for navigation
2. **Call customer** if location unclear
3. **Check coordinates** are available before starting delivery
4. **Report missing coordinates** to admin

## Troubleshooting

### Location Not Accurate
- **Check GPS signal**: Move to open area
- **Wait for fix**: GPS can take 10-30 seconds
- **Check permissions**: Ensure location permission granted
- **Restart app**: Sometimes helps refresh GPS

### Navigation Not Opening
- **Check Google Maps installed**: Required for navigation
- **Check internet connection**: Needed for map loading
- **Try "View Map" instead**: May work when navigation doesn't

### Coordinates Missing
- **Customer didn't use location picker**: Address saved manually
- **GPS failed**: System fell back to text address
- **Solution**: Contact customer for exact location or use address text

## Technical Details

### Location Accuracy Levels
- `bestForNavigation`: Highest accuracy, uses GPS + network
- `high`: Good accuracy, faster but less precise
- `medium`: Moderate accuracy, faster
- `low`: Basic accuracy, fastest

### Coordinate Precision
- Stored as strings with 6+ decimal places
- Example: "28.704059" (accurate to ~10cm)
- Sufficient for instant delivery within 1-2km radius

### Permissions Required
- **Android**: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
- **iOS**: `NSLocationWhenInUseUsageDescription`
- Handled by `permission_handler` package

## Future Enhancements

### Planned Features
1. **Real-time tracking**: Show delivery agent location to customer
2. **Route optimization**: Multiple deliveries in one trip
3. **ETA calculation**: Based on distance and traffic
4. **Geofencing**: Auto-update status when near customer
5. **Offline maps**: Work without internet connection

## API Endpoints

### Address Creation
```
POST /api/addresses
Body: {
  "addressLine1": "...",
  "latitude": "28.704059",
  "longitude": "77.102490",
  ...
}
```

### Order Details (includes deliveryAddress with coordinates)
```
GET /api/delivery/orders/:id
Response: {
  "deliveryAddress": {
    "latitude": "28.704059",
    "longitude": "77.102490",
    ...
  }
}
```

## Support

If you encounter issues with location or navigation:
1. Check this guide first
2. Verify permissions are granted
3. Test with Google Maps app directly
4. Contact support with order ID and error details

