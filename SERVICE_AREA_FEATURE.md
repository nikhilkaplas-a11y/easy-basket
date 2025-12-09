# Service Area Feature Documentation

## Overview
This feature allows the app to check if delivery service is available in a specific location (pincode) and show a "Service Not Available" screen when the user's location is not in the service area.

## Database Structure

### ServiceArea Entity
- **id**: Primary key
- **pincode**: 6-digit pincode (for India) or postal code
- **city**: City name
- **state**: State name
- **country**: Country (default: 'India')
- **isActive**: Boolean to enable/disable service area
- **notes**: Optional notes about the service area
- **createdAt**: Timestamp
- **updatedAt**: Timestamp

## Backend API Endpoints

### Public Endpoints

#### Check Service Availability
```
GET /api/service-area/check?pincode=123456&country=India
```
**Response:**
```json
{
  "success": true,
  "available": true,
  "serviceArea": {
    "id": 1,
    "pincode": "123456",
    "city": "Delhi",
    "state": "Delhi",
    "country": "India"
  }
}
```

### Admin Endpoints (Requires Authentication)

#### Get All Service Areas
```
GET /api/service-area?page=1&limit=50&search=delhi
```

#### Create Service Area
```
POST /api/service-area
Body: {
  "pincode": "123456",
  "city": "Delhi",
  "state": "Delhi",
  "country": "India",
  "isActive": true,
  "notes": "Optional notes"
}
```

#### Update Service Area
```
PUT /api/service-area/:id
Body: {
  "pincode": "123456",
  "city": "New Delhi",
  "state": "Delhi",
  "isActive": false
}
```

#### Delete Service Area
```
DELETE /api/service-area/:id
```

## Frontend Integration

### Service Area Check Flow

1. **When User Adds Address:**
   - User enters pincode in address form
   - Before saving, app checks service availability
   - If not available, redirects to "Service Not Available" screen
   - If available, address is saved normally

2. **Service Not Available Screen:**
   - Shows location information
   - Provides options to:
     - Try different location
     - Go to home
   - Displays contact information for service requests

### Usage in Code

```dart
// Check service availability
final serviceAreaProvider = Provider.of<ServiceAreaProvider>(context, listen: false);
final isAvailable = await serviceAreaProvider.checkServiceAvailability(
  pincode: '123456',
  country: 'India',
);

if (!isAvailable) {
  // Navigate to service not available screen
  context.push('/service-not-available', extra: {
    'pincode': '123456',
    'city': 'Delhi',
    'state': 'Delhi',
  });
}
```

## Adding Service Areas

### Via API (Admin)
Use the admin endpoints to add service areas programmatically.

### Via Database (Direct)
```sql
INSERT INTO service_area (pincode, city, state, country, isActive, createdAt, updatedAt)
VALUES ('110001', 'New Delhi', 'Delhi', 'India', true, NOW(), NOW());
```

### Example Service Areas for India
- **Delhi**: 110001-110096
- **Mumbai**: 400001-400107
- **Bangalore**: 560001-560103
- **Hyderabad**: 500001-500090
- **Chennai**: 600001-600119

## Admin UI (To Be Implemented)

The admin dashboard should include:
1. **Service Areas Management Page**
   - List all service areas with pagination
   - Search by pincode, city, state
   - Add new service area
   - Edit existing service area
   - Delete service area
   - Toggle active/inactive status

2. **Bulk Import**
   - Import service areas from CSV
   - Format: pincode, city, state, country

## Testing

### Test Service Availability
```bash
# Check if service is available
curl "http://localhost:3000/api/service-area/check?pincode=110001&country=India"

# Add a service area (requires admin auth)
curl -X POST "http://localhost:3000/api/service-area" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pincode": "110001",
    "city": "New Delhi",
    "state": "Delhi",
    "country": "India",
    "isActive": true
  }'
```

## Next Steps

1. ✅ Database entity created
2. ✅ Backend API endpoints created
3. ✅ Frontend provider created
4. ✅ Service not available screen created
5. ✅ Integration into address flow
6. ⏳ Admin UI for managing service areas
7. ⏳ Bulk import functionality
8. ⏳ Email notification when user requests service in new area

