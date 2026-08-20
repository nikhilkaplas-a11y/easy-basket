import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  /// Language sent as `Accept-Language` on every request, which is how the
  /// backend decides whether to resolve product and category names into
  /// Hindi or Punjabi (see backend ResponseTranslator).
  ///
  /// Static because `ApiService()` is constructed independently in several
  /// providers — an instance field would leave some of them still asking for
  /// English. Owned by LocaleProvider; nothing else should assign to it.
  static String language = 'en';

  // Callback to refresh the token when the server reports it expired (401).
  Future<bool> Function()? onTokenExpired;

  // Returns the CURRENT valid token after a refresh, so retries pick up the new
  // one without every caller having to pass `getUpdatedToken`. Wired in main.dart.
  String? Function()? getCurrentToken;

  // Prevent multiple simultaneous refresh attempts.
  bool _isRefreshing = false;

  ApiService({this.onTokenExpired, this.getCurrentToken});

  static const _timeout = Duration(seconds: 30);

  // ---------------------------------------------------------------------------
  // Public verbs — thin wrappers over the shared _send (which now does the
  // refresh-and-retry-on-401 for EVERY verb, not just GET).
  // ---------------------------------------------------------------------------

  Future<dynamic> get(
    String endpoint, {
    String? token,
    bool retryOnExpired = true,
    String? Function()? getUpdatedToken,
  }) {
    return _send(
      method: 'GET',
      endpoint: endpoint,
      token: token,
      retryOnExpired: retryOnExpired,
      getUpdatedToken: getUpdatedToken,
    );
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
    Map<String, String>? extraHeaders,
    bool retryOnExpired = true,
  }) {
    return _send(
      method: 'POST',
      endpoint: endpoint,
      token: token,
      body: data,
      extraHeaders: extraHeaders,
      retryOnExpired: retryOnExpired,
    );
  }

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
    bool retryOnExpired = true,
  }) {
    return _send(
      method: 'PUT',
      endpoint: endpoint,
      token: token,
      body: data,
      retryOnExpired: retryOnExpired,
    );
  }

  Future<dynamic> delete(
    String endpoint, {
    String? token,
    bool retryOnExpired = true,
  }) {
    return _send(
      method: 'DELETE',
      endpoint: endpoint,
      token: token,
      retryOnExpired: retryOnExpired,
    );
  }

  // ---------------------------------------------------------------------------
  // Shared request path with refresh-and-retry.
  // ---------------------------------------------------------------------------

  Future<dynamic> _send({
    required String method,
    required String endpoint,
    String? token,
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
    bool retryOnExpired = true,
    String? Function()? getUpdatedToken,
  }) async {
    Future<http.Response> dispatch(String? authToken) {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept-Language': language,
      };
      if (authToken != null) headers['Authorization'] = 'Bearer $authToken';
      if (extraHeaders != null) headers.addAll(extraHeaders);

      // ignore: avoid_print
      print('[API][$method] $baseUrl$endpoint');
      final uri = Uri.parse('$baseUrl$endpoint');
      final encoded = body != null ? jsonEncode(body) : null;

      switch (method) {
        case 'GET':
          return http.get(uri, headers: headers).timeout(_timeout, onTimeout: _onTimeout);
        case 'POST':
          return http.post(uri, headers: headers, body: encoded).timeout(_timeout, onTimeout: _onTimeout);
        case 'PUT':
          return http.put(uri, headers: headers, body: encoded).timeout(_timeout, onTimeout: _onTimeout);
        case 'DELETE':
          return http.delete(uri, headers: headers).timeout(_timeout, onTimeout: _onTimeout);
        default:
          throw Exception('Unsupported method: $method');
      }
    }

    final initialToken = token ?? getUpdatedToken?.call() ?? getCurrentToken?.call();

    try {
      return _handleResponse(await dispatch(initialToken));
    } on TokenExpiredException {
      // Standard behaviour for EVERY verb: refresh once, then retry with the new
      // token. Previously only GET retried, and only when the caller passed
      // getUpdatedToken — so writes (place order, profile, address) failed after
      // the 15-min access-token expiry.
      if (retryOnExpired && await _handleTokenExpiration()) {
        final newToken =
            getUpdatedToken?.call() ?? getCurrentToken?.call() ?? initialToken;
        return _handleResponse(await dispatch(newToken));
      }
      rethrow;
    } catch (e) {
      if (e is TokenExpiredException) rethrow;
      throw _mapNetworkError(e);
    }
  }

  static Never _onTimeout() {
    throw Exception(
      'Request timeout: Server took too long to respond. Please check if backend is running and database is connected.',
    );
  }

  Exception _mapNetworkError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('failed host lookup') || s.contains('connection refused')) {
      return Exception('Cannot connect to server. Check if backend is running at $baseUrl');
    }
    if (s.contains('failed to fetch') || s.contains('networkerror')) {
      return Exception(
        'Network error: Cannot reach server at $baseUrl. Check:\n1. Backend is running\n2. CORS is enabled\n3. No firewall blocking connection',
      );
    }
    if (s.contains('timeout')) {
      return Exception('Request timeout: Server took too long to respond');
    }
    if (s.contains('certificate') || s.contains('ssl') || s.contains('tls')) {
      return Exception('SSL certificate error. Please check if HTTPS is properly configured on the server.');
    }
    return Exception('Network error: $e');
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return [];
      }
      try {
        return jsonDecode(response.body);
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

  /// Handle token expiration with automatic refresh (single-flight).
  Future<bool> _handleTokenExpiration() async {
    // A refresh is already running — wait briefly for it to finish, then assume
    // success if it cleared. (Best-effort coordination.)
    if (_isRefreshing) {
      for (var i = 0; i < 20 && _isRefreshing; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return !_isRefreshing;
    }

    if (onTokenExpired == null) {
      return false;
    }

    _isRefreshing = true;
    try {
      return await onTokenExpired!();
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
