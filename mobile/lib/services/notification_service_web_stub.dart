// Web stub for NotificationService - Firebase Messaging not supported on web
import 'package:flutter/material.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  String? get fcmToken => null;

  Future<void> initialize({
    required BuildContext context,
    required AdminProvider adminProvider,
    required AuthProvider authProvider,
  }) async {
    debugPrint('⚠️ FCM not supported on web platform');
  }

  void updateContext(BuildContext context) {
    // No-op for web
  }

  void updateProviders({
    AdminProvider? adminProvider,
    AuthProvider? authProvider,
  }) {
    // No-op for web
  }

  /// Manually trigger FCM token generation and send to backend
  /// No-op for web since FCM is not supported
  Future<void> ensureTokenSent() async {
    debugPrint('⚠️ NotificationService: ensureTokenSent() called but FCM not supported on web.');
    // No-op for web
  }
}

