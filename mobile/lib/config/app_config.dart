import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // Backend API Configuration
  // Automatically selects the right URL based on platform
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api'; // Web uses localhost
    }
    return 'http://10.0.2.2:3000/api'; // Android emulator (default)
    // For iOS Simulator: 'http://localhost:3000/api'
    // For Physical Device: 'http://YOUR_IP:3000/api'
  }
  
  // App Configuration
  static const String appName = 'Easy Basket';
  static const String appVersion = '1.0.0';
  
  // Development OTP (for testing)
  static const String devOTP = '1234';
}

