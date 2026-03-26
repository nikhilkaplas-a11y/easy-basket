import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';

// Background message handler — must be top-level function (not inside class)
// Kyun: Flutter requires background handlers to be top-level
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 [FCM] Background message received: ${message.notification?.title}');
  // System automatically shows notification in notification bar
  // No extra code needed here
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiService _apiService = ApiService();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  BuildContext? _context;
  AdminProvider? _adminProvider;
  AuthProvider? _authProvider;
  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  // ── Notification Channel (Generic — sab type ki notifications isme aayengi) ──
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'easy_basket_notifications', // same as AndroidManifest mein
    'Easy Basket Notifications', // user ko dikhne wala naam
    description: 'Order updates, offers, and more',
    importance: Importance.high, // high = sound + popup
  );

  /// Initialize Notification Service
  /// Kyun: App start hote hi FCM setup karna zaroori hai
  Future<void> initialize({
    required BuildContext context,
    required AdminProvider adminProvider,
    required AuthProvider authProvider,
  }) async {
    if (kIsWeb) {
      debugPrint('⚠️ Notifications not supported on web');
      return;
    }

    if (_isInitialized) {
      debugPrint('⚠️ [FCM] Service already initialized');
      return;
    }

    _context = context;
    _adminProvider = adminProvider;
    _authProvider = authProvider;

    // 1. Notification permission maango (Android 13+ ke liye zaroori)
    await _requestPermission();

    // 2. Local notifications setup karo (foreground mein dikhane ke liye)
    await _setupLocalNotifications();

    // 3. FCM token lo (device ka unique address)
    await _getToken();

    // 4. Token refresh listener lagao (agar Firebase token change kare)
    _listenTokenRefresh();

    // 5. Foreground listener — app khuli hai tab
    _listenForeground();

    // 6. Background handler — app band hai tab
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 7. Tap handler — user notification tap kare tab
    _listenNotificationTap();

    // 8. Check — agar app notification tap se khuli hai (cold start)
    _handleInitialMessage();

    _isInitialized = true;
    debugPrint('✅ [FCM] Notification service initialized');
    await _sendTokenToBackend();
  }

  // ── 1. Permission maango ──
  // Kyun: Android 13+ mein bina permission ke notification nahi dikhegi
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,    // notification dikhao
      badge: true,    // app icon pe badge dikhao
      sound: true,    // sound bajao
    );
    debugPrint('📋 [FCM] Permission status: ${settings.authorizationStatus}');
  }

  // ── 2. Local notifications setup ──
  // Kyun: Jab app foreground mein ho tab in-app banner dikhane ke liye
  Future<void> _setupLocalNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // Notification channel create karo
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Foreground mein Firebase ki default notification BAND karo
    // Kyun: Hum khud in-app banner dikhayenge, phone bar mein nahi
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
  }

  // ── 3. FCM Token lo ──
  // Kyun: Ye device ka unique address hai — backend ko ye dena padta hai
  Future<void> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('🔑 [FCM] Token: ${_fcmToken?.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ [FCM] Error getting token: $e');
    }
  }

  // ── 4. Token refresh listener ──
  // Kyun: Kabhi kabhi Firebase token change karta hai — naya token backend ko bhejte raho
  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 [FCM] Token refreshed');
      _fcmToken = newToken;
      _sendTokenToBackend();
    });
  }

  // ── 5. Foreground listener ──
  // Kyun: Jab app KHULI hai tab notification aaye toh in-app banner dikhao
  // + agar order related notification hai toh orders refresh karo (active order bar update hoga)
  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 [FCM] Foreground message: ${message.notification?.title}');

      // Refresh bar even for data-only messages (notification can be null)
      _maybeRefreshOrdersFromPayload(message.data);

      final notification = message.notification;
      if (notification == null) return;

      _showInAppBanner(
        title: notification.title ?? 'Easy Basket',
        body: notification.body ?? '',
        data: message.data,
      );
    });
  }

  /// Any backend payload that signals an order lifecycle change → refetch active orders bar.
  void _maybeRefreshOrdersFromPayload(Map<String, dynamic> data) {
    final type = (data['type'] as String? ?? '').toLowerCase();
    final orderIdRaw = data['orderId']?.toString();
    final hasOrderId = orderIdRaw != null && orderIdRaw.isNotEmpty;
    final shouldRefresh =
        type.contains('order') || (hasOrderId && type.isEmpty);
    if (shouldRefresh) {
      _refreshOrders();
    }
  }

  // ── Orders refresh karo (FCM trigger pe) ──
  // Kyun: Jab order status change ho toh active order bar turant update ho
  void _refreshOrders() {
    if (_context == null || _authProvider?.token == null) return;

    try {
      final orderProvider = Provider.of<OrderProvider>(_context!, listen: false);
      orderProvider.fetchActiveOrders(
        _authProvider!.token!,
        getUpdatedToken: () => _authProvider?.token,
      );
      debugPrint('🔄 [FCM] Orders refreshed after order notification');
    } catch (e) {
      debugPrint('❌ [FCM] Error refreshing orders: $e');
    }
  }

  // ── 6. Notification tap handler ──
  // Kyun: User notification tap kare toh sahi screen pe le jao
  void _listenNotificationTap() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 [FCM] Notification tapped: ${message.notification?.title}');
      _maybeRefreshOrdersFromPayload(message.data);
      _navigateFromNotification(message.data);
    });
  }

  // ── 7. Cold start check ──
  // Kyun: Agar app band thi aur user ne notification tap karke kholi toh navigate karo
  Future<void> _handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      debugPrint('🚀 [FCM] App opened from notification: ${message.notification?.title}');
      Future.delayed(const Duration(seconds: 1), () {
        _maybeRefreshOrdersFromPayload(message.data);
        _navigateFromNotification(message.data);
      });
    }
  }

  // ── In-app banner dikhao (foreground) ──
  void _showInAppBanner({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    if (_context == null) return;

    final type = data?['type'] as String? ?? '';
    final isAdmin = _authProvider?.user?.role == 'admin';
    final isAdminOrderAction = isAdmin && type == 'new_order';

    final overlay = Overlay.of(_context!);
    late OverlayEntry entry;

    if (isAdminOrderAction) {
      // Admin ke liye action banner — Accept/Reject buttons ke saath
      // Tab tak rahega jab tak action na le ya dismiss na kare
      entry = OverlayEntry(
        builder: (context) => _AdminActionBanner(
          title: title,
          body: body,
          onAccept: () async {
            entry.remove();
            final orderId = data?['orderId'] as String?;
            if (orderId != null && _adminProvider != null && _authProvider?.token != null) {
              await _adminProvider!.updateOrderStatus(
                token: _authProvider!.token!,
                orderId: int.parse(orderId),
                status: 'accepted',
              );
            }
          },
          onReject: () async {
            entry.remove();
            final orderId = data?['orderId'] as String?;
            if (orderId != null && _adminProvider != null && _authProvider?.token != null) {
              await _adminProvider!.updateOrderStatus(
                token: _authProvider!.token!,
                orderId: int.parse(orderId),
                status: 'cancelled',
                notes: 'Rejected by admin',
              );
            }
          },
          onDismiss: () => entry.remove(),
          onTap: () {
            entry.remove();
            if (data != null) _navigateFromNotification(data);
          },
        ),
      );
      overlay.insert(entry);
      // No auto-dismiss — admin ko action lena hai
    } else {
      // Normal banner — 6 sec ke liye
      entry = OverlayEntry(
        builder: (context) => _NotificationBanner(
          title: title,
          body: body,
          onTap: () {
            entry.remove();
            if (data != null) _navigateFromNotification(data);
          },
          onDismiss: () => entry.remove(),
        ),
      );
      overlay.insert(entry);
      Future.delayed(const Duration(seconds: 6), () {
        if (entry.mounted) entry.remove();
      });
    }
  }

  // ── Navigate based on notification type ──
  // Kyun: Har notification type ke liye alag screen pe le jaana hai
  void _navigateFromNotification(Map<String, dynamic> data) {
    if (_context == null) return;

    final type = data['type'] as String? ?? '';
    final orderId = data['orderId'] as String?;
    final productId = data['productId'] as String?;
    final categoryId = data['categoryId'] as String?;

    debugPrint('🧭 [FCM] Navigate — type: $type, orderId: $orderId');

    // Type ke prefix se decide karo kahan jaana hai
    if (type.startsWith('ORDER_') && orderId != null) {
      _context!.push('/order/$orderId');
    } else if (type.startsWith('PAYMENT_') && orderId != null) {
      _context!.push('/order/$orderId');
    } else if (type.startsWith('PROMO_') && categoryId != null) {
      _context!.push('/categories/$categoryId/products', extra: {
        'parentCategoryName': data['categoryName'] ?? 'Offers',
      });
    } else if (type.startsWith('STOCK_') && productId != null) {
      _context!.push('/product/$productId');
    } else {
      // Default — orders screen pe le jao
      _context!.push('/orders');
    }
  }

  // ── Local notification response handler ──
  void _handleNotificationResponse(NotificationResponse response) {
    _onNotificationTap(response.payload);
  }

  // ── Local notification tap handler ──
  void _onNotificationTap(String? payload) {
    if (payload == null || _context == null) return;
    // payload mein orderId ya route aata hai
    _context!.push(payload);
  }

  // ── Backend ko FCM token bhejo ──
  // Kyun: Backend ko token chahiye taki wo notification bhej sake is device pe
  Future<void> _sendTokenToBackend() async {
    if (_fcmToken == null) return;
    final jwt = _authProvider?.token;
    if (jwt == null || jwt.isEmpty) {
      debugPrint('⚠️ [FCM] Skipping /auth/fcm-token — no access token yet');
      return;
    }

    try {
      await _apiService.post(
        '/auth/fcm-token',
        {'fcmToken': _fcmToken},
        token: jwt,
      );
      debugPrint('✅ [FCM] Token sent to backend');
    } catch (e) {
      debugPrint('❌ [FCM] Error sending token to backend: $e');
    }
  }

  /// Login ke baad call karo — token backend ko bhejta hai
  Future<void> ensureTokenSent() async {
    if (kIsWeb) return;
    await _getToken();
    await _sendTokenToBackend();
  }

  /// Context update karo (navigation ke liye zaroori)
  void updateContext(BuildContext context) {
    _context = context;
  }

  /// Providers update karo
  void updateProviders({
    AdminProvider? adminProvider,
    AuthProvider? authProvider,
  }) {
    if (adminProvider != null) _adminProvider = adminProvider;
    if (authProvider != null) _authProvider = authProvider;
  }
}

// ── Admin Action Banner Widget ──
// Kyun: Admin ko new order aaye toh Accept/Reject buttons dikhane ke liye
class _AdminActionBanner extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _AdminActionBanner({
    required this.title,
    required this.body,
    required this.onAccept,
    required this.onReject,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_AdminActionBanner> createState() => _AdminActionBannerState();
}

class _AdminActionBannerState extends State<_AdminActionBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: EdgeInsets.only(top: topPadding + 4, left: 12, right: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row — icon, title, close
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFFFF9800), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.body,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Action buttons
              if (_isLoading)
                const SizedBox(
                  height: 36,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                Row(
                  children: [
                    // Reject button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _isLoading = true);
                          widget.onReject();
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: const Center(
                            child: Text(
                              'Reject',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Accept button
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _isLoading = true);
                          widget.onAccept();
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A5C18), Color(0xFF1B8A2E), Color(0xFF0A5C18)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              stops: [0.0, 0.5, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Accept',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── In-App Notification Banner Widget ──
// Kyun: Jab app foreground mein ho tab ye banner top pe slide hoke aata hai
class _NotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationBanner({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Slide animation — upar se neeche aata hai
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // upar se
      end: Offset.zero,           // apni jagah pe
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          onVerticalDragEnd: (details) {
            // Upar swipe kare toh dismiss
            if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
              widget.onDismiss();
            }
          },
          child: Container(
            margin: EdgeInsets.only(top: topPadding + 4, left: 12, right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Green icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFF4CAF50),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Title + Body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.body,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
