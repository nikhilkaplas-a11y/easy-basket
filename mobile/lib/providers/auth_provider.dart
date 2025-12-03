import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService authService;
  final SharedPreferences prefs;

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;

  AuthProvider({
    required this.authService,
    required this.prefs,
  }) {
    _loadAuthData();
  }

  void _loadAuthData() {
    _token = prefs.getString('auth_token');
    final userJson = prefs.getString('user_data');
    if (userJson != null && _token != null) {
      try {
        // Parse user data from stored JSON string
        // Note: user_data is stored as JSON string, need to parse it
        // For now, user will be loaded on next login/verify
        // This ensures fresh role data
      } catch (e) {
        // If parsing fails, clear stored data
        prefs.remove('auth_token');
        prefs.remove('user_data');
      }
    }
  }

  Future<void> sendOTP(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await authService.sendOTP(phoneNumber);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otp, {String? fcmToken}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await authService.verifyOTP(phoneNumber, otp, fcmToken: fcmToken);
      _token = result['token'] as String;
      _user = result['user'] as UserModel;

      await prefs.setString('auth_token', _token!);
      // Store user data as JSON string for later retrieval
      final userJsonString = _user!.toJson().toString();
      await prefs.setString('user_data', userJsonString);
      
      // Debug: Print user role to verify
      print('User logged in with role: ${_user!.role}');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({String? name, String? email, String? fcmToken}) async {
    if (_token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await authService.updateProfile(
        token: _token!,
        name: name,
        email: email,
        fcmToken: fcmToken,
      );
      await prefs.setString('user_data', _user!.toJson().toString());
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

