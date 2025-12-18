import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // Backend API Configuration
  
  // Production API URL (for testing with friends and deployment)
  // static const String apiBaseUrl = 'https://api.easybasket.in/api';
  
  // Alternative URLs (uncomment if needed):
  // For local development (web only):
  
  static const String apiBaseUrl = 'http://localhost:3000/api';
  
  // For Android emulator:
  // static const String apiBaseUrl = 'http://10.0.2.2:3000/api';
  
  // For physical device on same WiFi (replace with your Mac's IP):
  // static const String apiBaseUrl = 'http://192.168.1.29:3000/api';
  
  // App Configuration
  static const String appName = 'Easy Basket';
  static const String appVersion = '1.0.0';
  
  // Development OTP (for testing)
  static const String devOTP = '1234';
}