import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // Backend API Configuration
  // Production API URL - Using HTTPS (SSL should be set up)
  static const String apiBaseUrl = 'https://api.easybasket.in/api';
  
  // For development/testing, you can use:
  // static const String apiBaseUrl = 'http://localhost:3000/api'; // Local development
  // static const String apiBaseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String apiBaseUrl = 'http://api.easybasket.in/api'; // HTTP (if SSL not set up)
  
  // App Configuration
  static const String appName = 'Easy Basket';
  static const String appVersion = '1.0.0';
  
  // Development OTP (for testing)
  static const String devOTP = '1234';
}

