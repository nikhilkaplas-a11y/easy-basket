// Notification Service - Firebase removed
// Push notifications are disabled until Firebase is re-added
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiService _apiService = ApiService();
  
  BuildContext? _context;
  AdminProvider? _adminProvider;
  AuthProvider? _authProvider;
  bool _isInitialized = false;

  String? get fcmToken => null; // No FCM token without Firebase
  
  /// Manually trigger FCM token generation and send to backend
  /// Stub - does nothing without Firebase
  Future<void> ensureTokenSent() async {
    if (kIsWeb) return;
    debugPrint('⚠️ [NOTIFICATION] Firebase removed - notifications disabled');
  }

  /// Initialize Notification Service
  /// Stub - does nothing without Firebase
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
      debugPrint('⚠️ [NOTIFICATION] Service already initialized');
      return;
    }

    _context = context;
    _adminProvider = adminProvider;
    _authProvider = authProvider;
    _isInitialized = true;

    debugPrint('⚠️ [NOTIFICATION] Firebase removed - push notifications are disabled');
    debugPrint('⚠️ [NOTIFICATION] To enable notifications, add Firebase back to the project');
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
