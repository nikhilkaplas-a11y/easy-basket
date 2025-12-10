import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  
  // Callback to refresh token when it expires
  Future<bool> Function()? onTokenExpired;
  
  // Prevent multiple simultaneous refresh attempts
  bool _isRefreshing = false;
  
  ApiService({this.onTokenExpired});

  Future<dynamic> get(String endpoint, {String? token, bool retryOnExpired = true, String? Function()? getUpdatedToken}) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      String? currentToken = token ?? getUpdatedToken?.call();
      if (currentToken != null) {
        headers['Authorization'] = 'Bearer $currentToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30), // 30 second timeout for API calls
        onTimeout: () {
          throw Exception('Request timeout: Server took too long to respond. Please check if backend is running and database is connected.');
        },
      );

      return _handleResponse(response);
    } on TokenExpiredException catch (e) {
      // Try to refresh token and retry once
      if (retryOnExpired && await _handleTokenExpiration()) {
        // Get updated token and retry
        final newToken = getUpdatedToken?.call();
        if (newToken != null && newToken != token) {
          final headers = <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          };
          final response = await http.get(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout: Server took too long to respond.');
            },
          );
          return _handleResponse(response);
        }
      }
      rethrow;
    } catch (e) {
      // Re-throw if it's already a TokenExpiredException
      if (e is TokenExpiredException) rethrow;
      // Provide more detailed error information
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('failed host lookup') || errorString.contains('connection refused')) {
        throw Exception('Cannot connect to server. Check if backend is running at $baseUrl');
      }
      if (errorString.contains('failed to fetch') || errorString.contains('networkerror')) {
        throw Exception('Network error: Cannot reach server at $baseUrl. Check:\n1. Backend is running\n2. CORS is enabled\n3. No firewall blocking connection');
      }
      if (errorString.contains('timeout')) {
        throw Exception('Request timeout: Server took too long to respond');
      }
      if (errorString.contains('certificate') || errorString.contains('ssl') || errorString.contains('tls')) {
        throw Exception('SSL certificate error. Please check if HTTPS is properly configured on the server.');
      }
      // Otherwise wrap in generic exception with more context
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(
        const Duration(seconds: 30), // 30 second timeout for API calls
        onTimeout: () {
          throw Exception('Request timeout: Server took too long to respond. Please check if backend is running and database is connected.');
        },
      );

      return _handleResponse(response);
    } catch (e) {
      // Re-throw if it's already a TokenExpiredException
      if (e is TokenExpiredException) rethrow;
      // Provide more detailed error information
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('failed host lookup') || errorString.contains('connection refused')) {
        throw Exception('Cannot connect to server. Check if backend is running at $baseUrl');
      }
      if (errorString.contains('failed to fetch') || errorString.contains('networkerror')) {
        throw Exception('Network error: Cannot reach server at $baseUrl. Check:\n1. Backend is running\n2. CORS is enabled\n3. No firewall blocking connection');
      }
      if (errorString.contains('timeout')) {
        throw Exception('Request timeout: Server took too long to respond');
      }
      // Otherwise wrap in generic exception with more context
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(
        const Duration(seconds: 30), // 30 second timeout for API calls
        onTimeout: () {
          throw Exception('Request timeout: Server took too long to respond. Please check if backend is running and database is connected.');
        },
      );

      return _handleResponse(response);
    } catch (e) {
      // Re-throw if it's already a TokenExpiredException
      if (e is TokenExpiredException) rethrow;
      // Provide more detailed error information
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('failed host lookup') || errorString.contains('connection refused')) {
        throw Exception('Cannot connect to server. Check if backend is running at $baseUrl');
      }
      if (errorString.contains('failed to fetch') || errorString.contains('networkerror')) {
        throw Exception('Network error: Cannot reach server at $baseUrl. Check:\n1. Backend is running\n2. CORS is enabled\n3. No firewall blocking connection');
      }
      if (errorString.contains('timeout')) {
        throw Exception('Request timeout: Server took too long to respond');
      }
      if (errorString.contains('certificate') || errorString.contains('ssl') || errorString.contains('tls')) {
        throw Exception('SSL certificate error. Please check if HTTPS is properly configured on the server.');
      }
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> delete(String endpoint, {String? token}) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30), // 30 second timeout for API calls
        onTimeout: () {
          throw Exception('Request timeout: Server took too long to respond. Please check if backend is running and database is connected.');
        },
      );

      return _handleResponse(response);
    } catch (e) {
      // Re-throw if it's already a TokenExpiredException
      if (e is TokenExpiredException) rethrow;
      // Provide more detailed error information
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('failed host lookup') || errorString.contains('connection refused')) {
        throw Exception('Cannot connect to server. Check if backend is running at $baseUrl');
      }
      if (errorString.contains('failed to fetch') || errorString.contains('networkerror')) {
        throw Exception('Network error: Cannot reach server at $baseUrl. Check:\n1. Backend is running\n2. CORS is enabled\n3. No firewall blocking connection');
      }
      if (errorString.contains('timeout')) {
        throw Exception('Request timeout: Server took too long to respond');
      }
      if (errorString.contains('certificate') || errorString.contains('ssl') || errorString.contains('tls')) {
        throw Exception('SSL certificate error. Please check if HTTPS is properly configured on the server.');
      }
      throw Exception('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return [];
      }
      try {
        final decoded = jsonDecode(response.body);
        // Backend returns arrays directly (products, categories, orders, addresses)
        // or objects (single product, order, etc.)
        return decoded;
      } catch (e) {
        throw Exception('Invalid JSON response: $e');
      }
    } else if (response.statusCode == 401) {
      // Unauthorized - token expired or invalid
      try {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw TokenExpiredException(error['message'] ?? 'Authentication required');
      } catch (e) {
        if (e is TokenExpiredException) rethrow;
        throw TokenExpiredException('Authentication required');
      }
    } else {
      try {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['message'] ?? 'Request failed');
      } catch (e) {
        throw Exception('Request failed with status ${response.statusCode}: ${response.body}');
      }
    }
  }
  
  /// Handle token expiration with automatic refresh
  Future<bool> _handleTokenExpiration() async {
    // Prevent multiple simultaneous refresh attempts
    if (_isRefreshing) {
      // Wait a bit and check if refresh completed
      await Future.delayed(const Duration(milliseconds: 500));
      return !_isRefreshing; // Return true if refresh completed
    }
    
    if (onTokenExpired == null) {
      return false;
    }
    
    _isRefreshing = true;
    try {
      final success = await onTokenExpired!();
      return success;
    } finally {
      _isRefreshing = false;
    }
  }
}

// Custom exception for token expiration
class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
  
  @override
  String toString() => message;
}

