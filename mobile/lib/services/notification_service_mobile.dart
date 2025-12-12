import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  
  String? _fcmToken;
  BuildContext? _context;
  AdminProvider? _adminProvider;
  AuthProvider? _authProvider;

  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging
  Future<void> initialize({
    required BuildContext context,
    required AdminProvider adminProvider,
    required AuthProvider authProvider,
  }) async {
    if (kIsWeb) {
      debugPrint('⚠️ FCM not supported on web');
      return;
    }

    _context = context;
    _adminProvider = adminProvider;
    _authProvider = authProvider;

    try {
      // Request permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('📱 Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ [FCM] Permission granted, proceeding...');
        
        // Get FCM token (will send to backend if auth token available)
        await _getFCMToken();
        
        // If token was generated but auth token wasn't available, retry after delay
        if (_fcmToken != null && _authProvider?.token == null) {
          debugPrint('⏳ [FCM] Token generated but auth not ready, will retry in 3 seconds...');
          Future.delayed(const Duration(seconds: 3), () {
            if (_fcmToken != null && _authProvider?.token != null) {
              debugPrint('🔄 [FCM] Retrying token send to backend...');
              _sendTokenToBackend(_fcmToken!);
            }
          });
        }

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        debugPrint('✅ [FCM] Foreground message handler registered');

        // Handle background messages (when app is in background)
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
        debugPrint('✅ [FCM] Background message handler registered');

        // Handle notification when app is opened from terminated state
        RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('📱 [FCM] App opened from notification');
          _handleMessageOpenedApp(initialMessage);
        }

        // Set up background message handler
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
        debugPrint('✅ [FCM] Background message handler set');

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
        debugPrint('✅ [FCM] Token refresh listener registered');
        
        debugPrint('✅ [FCM] Initialization complete');
      } else {
        debugPrint('⚠️ [FCM] Permission not granted: ${settings.authorizationStatus}');
      }
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  /// Get FCM token and send to backend
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('📱 [FCM] Token generated: $_fcmToken');

      if (_fcmToken != null) {
        debugPrint('📱 [FCM] Token length: ${_fcmToken!.length}');
        if (_authProvider?.token != null) {
          debugPrint('📱 [FCM] Auth token available, sending FCM token to backend...');
          // Send token to backend
          await _sendTokenToBackend(_fcmToken!);
        } else {
          debugPrint('⚠️ [FCM] Auth token not available yet, will retry later');
          // Retry after a delay if token not available
          Future.delayed(const Duration(seconds: 2), () {
            if (_fcmToken != null && _authProvider?.token != null) {
              _sendTokenToBackend(_fcmToken!);
            }
          });
        }
      } else {
        debugPrint('❌ [FCM] Failed to get FCM token');
      }
    } catch (e) {
      debugPrint('❌ [FCM] Error getting FCM token: $e');
    }
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      if (_authProvider?.token == null) {
        debugPrint('⚠️ [FCM] Cannot send token: Auth token not available');
        return;
      }

      debugPrint('📤 [FCM] Sending token to backend: ${token.substring(0, 20)}...');
      await _apiService.put(
        '/auth/profile',
        {'fcmToken': token},
        token: _authProvider!.token!,
      );
      debugPrint('✅ [FCM] Token sent to backend successfully');
    } catch (e) {
      debugPrint('❌ [FCM] Error sending token to backend: $e');
      debugPrint('❌ [FCM] Error details: ${e.toString()}');
    }
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String newToken) async {
    debugPrint('🔄 FCM token refreshed: $newToken');
    _fcmToken = newToken;
    await _sendTokenToBackend(newToken);
  }

  /// Handle foreground messages (app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message received: ${message.messageId}');
    
    if (_context == null || !_context!.mounted) return;

    // Show in-app notification
    final notification = message.notification;
    if (notification != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title ?? 'New Notification',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (notification.body != null)
                      Text(
                        notification.body!,
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () => _navigateToOrders(message.data),
          ),
        ),
      );
    }

    // Auto-refresh if admin is logged in
    if (_authProvider?.user?.role == 'admin') {
      _refreshAdminData();
    }
  }

  /// Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('📱 App opened from notification: ${message.messageId}');
    debugPrint('Data: ${message.data}');

    // Navigate to orders page
    if (_context != null && _context!.mounted) {
      _navigateToOrders(message.data);
      // Refresh data after navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        _refreshAdminData();
      });
    }
  }

  /// Navigate to orders page based on notification data
  void _navigateToOrders(Map<String, dynamic> data) {
    if (_context == null || !_context!.mounted) return;

    final type = data['type'] as String?;
    final orderId = data['orderId'] as String?;

    if (type == 'new_order' || type == 'order_status_update') {
      // Navigate to admin orders page
      _context!.go('/admin/orders');
      
      // If specific order ID, could navigate to order details
      // if (orderId != null) {
      //   _context!.push('/admin/orders/$orderId');
      // }
    }
  }

  /// Refresh admin data when notification received
  void _refreshAdminData() {
    if (_authProvider?.token == null || _adminProvider == null) return;

    // Refresh stats
    _adminProvider!.fetchStats(token: _authProvider!.token);
    
    // Refresh orders
    _adminProvider!.fetchOrders(token: _authProvider!.token);
  }

  /// Update context and providers (call when navigating)
  void updateContext(BuildContext context) {
    _context = context;
  }

  /// Update providers
  void updateProviders({
    AdminProvider? adminProvider,
    AuthProvider? authProvider,
  }) {
    if (adminProvider != null) _adminProvider = adminProvider;
    if (authProvider != null) _authProvider = authProvider;
  }
}

