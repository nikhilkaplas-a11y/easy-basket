# Push Notifications (FCM) — Implementation Plan

## Cost: FREE (₹0)
Firebase Cloud Messaging is completely free. Our own backend sends notifications, Firebase only delivers them.

---

## 1. One-Time Setup

- Create a Firebase project on console.firebase.google.com
- Register our Android app in Firebase and download the config file
- Download a private key from Firebase for our backend server
- Set the private key as an environment variable on our backend server

---

## 2. How It Works

### When the user opens the app:
- App asks Firebase for a unique device token (like a phone number for that device)
- App sends this token to our backend
- Backend saves it against that user in the database

### When an order status changes:
- Backend looks up the relevant user's device token from the database
- Backend sends a message to Firebase saying "deliver this notification to this token"
- Firebase delivers the notification to the user's phone
- Phone shows the notification even if the app is closed

---

## 3. Who Gets Notified and When

### Customer places a new order
- All admins receive: "New order #123 received from Riya"

### Admin confirms the order
- Customer receives: "Your order #123 has been confirmed"

### Admin starts preparing the order
- Customer receives: "Your order #123 is being packed"

### Admin assigns a delivery boy
- Delivery boy receives: "You have a new delivery assigned"

### Delivery boy picks up the order
- Customer receives: "Your order #123 is on the way!"

### Delivery boy delivers the order
- Customer receives: "Your order #123 has been delivered. Enjoy!"

### Order is cancelled
- Customer receives: "Your order #123 has been cancelled"

---

## 4. What Happens When User Taps the Notification

- If app is open → navigates directly to that order's tracking page
- If app is in background → opens app and goes to order tracking page
- If app is killed → launches app and goes to order tracking page

---

## 5. What Already Exists in Our Code

- User table already has a field to store the device token
- FCM service is already written in the backend with functions to:
  - Send notification to a specific user
  - Send notification to all users of a role (e.g., all admins)
- Order lifecycle (pending → accepted → preparing → out for delivery → delivered) already works
- Admin can already update order status and assign delivery boys
- Delivery boy can already update order status

---

## 6. What Needs to Be Done

### Backend (Minimal — just connecting existing pieces)
- Add the Firebase private key to server environment
- Add one API endpoint for the app to send its device token after login
- Add notification triggers at each order status change point (the notification function already exists, we just need to call it at the right places)

### Flutter App
- Add Firebase packages to the app
- Add the Firebase config file to the Android project
- Initialize Firebase when app starts
- Request notification permission from the user (required on Android 13+)
- Get device token and send it to backend after login
- Handle incoming notifications — show them and navigate to correct screen on tap

---

## 7. Edge Cases Handled

- If user logs out → token is cleared so they stop receiving notifications
- If user reinstalls app → new token is generated and sent to backend
- If notification delivery fails (e.g., user uninstalled) → Firebase returns error, backend logs it
- If Firebase is not configured → notifications are silently skipped, app works normally without them
- Multiple devices → only the last logged-in device receives notifications (one token per user)

---

## 8. Testing Plan

- Place order → verify admin gets notification
- Admin accepts → verify customer gets notification
- Assign delivery boy → verify delivery boy gets notification
- Delivery boy picks up → verify customer gets notification
- Delivery boy delivers → verify customer gets notification
- Cancel order → verify customer gets notification
- Tap on notification → verify it opens the correct order
- Test with app open, app in background, and app killed
