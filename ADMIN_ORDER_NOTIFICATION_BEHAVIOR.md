# Admin Dashboard - Order Notification Behavior

## Current State
- ✅ Backend sends FCM notification to admin when order is created
- ❌ No FCM handling in Flutter app (Firebase commented out)
- ❌ Admin dashboard only refreshes on manual refresh or init
- ❌ No auto-refresh mechanism
- ❌ No real-time updates

## Recommended Behavior (Senior Product Manager Perspective)

### 1. **Auto-Refresh Dashboard Stats**
- **When**: Admin is on dashboard screen
- **Frequency**: Every 30-60 seconds
- **Why**: Keep stats current without manual refresh
- **Implementation**: Timer-based polling when screen is active

### 2. **FCM Notification Handling** (Future Enhancement)
- **When**: Admin receives push notification
- **Action**: 
  - Show in-app notification (SnackBar/Toast)
  - Auto-refresh stats immediately
  - Update pending orders count
  - Navigate to orders page if notification tapped
- **Why**: Instant awareness of new orders

### 3. **Visual Indicators**
- **Pending Orders Badge**: Show count on dashboard stat card
- **New Order Indicator**: Highlight new orders in orders list
- **Stats Update Animation**: Subtle animation when stats refresh
- **Why**: Quick visual feedback

### 4. **Smart Refresh Strategy**
- **On Dashboard**: Auto-refresh every 30 seconds
- **On Orders Page**: Auto-refresh every 20 seconds (more frequent for active management)
- **Background**: Stop auto-refresh when app is backgrounded
- **Why**: Balance between freshness and battery/network usage

### 5. **User Experience Flow**
```
Customer Places Order
    ↓
Backend Creates Order
    ↓
Backend Sends FCM to Admin
    ↓
Admin Dashboard (if open):
    - Auto-refresh stats (if timer fires)
    - Show notification (if FCM received)
    - Update pending orders count
    - Highlight new order in list
    ↓
Admin Clicks Notification:
    - Navigate to Orders page
    - Show order details
    - Mark as viewed
```

## Implementation Priority

### Phase 1: Auto-Refresh (High Priority - Implement Now)
- ✅ Timer-based auto-refresh on dashboard
- ✅ Auto-refresh on orders page
- ✅ Stop refresh when screen not visible

### Phase 2: Visual Indicators (Medium Priority)
- ✅ Pending orders badge
- ✅ Stats update animation
- ✅ New order highlight

### Phase 3: FCM Integration (Lower Priority - Requires Firebase Setup)
- ⏳ FCM notification handling
- ⏳ In-app notification display
- ⏳ Deep linking to orders

## Best Practices
1. **Battery Optimization**: Use reasonable refresh intervals (30-60s)
2. **Network Efficiency**: Only refresh when screen is active
3. **User Control**: Allow manual refresh anytime
4. **Error Handling**: Gracefully handle network failures
5. **Visual Feedback**: Show loading states during refresh

