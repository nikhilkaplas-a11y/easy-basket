// Web stub for NotificationService - Firebase Messaging not supported on web
import 'package:flutter/foundation.dart';
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
}

