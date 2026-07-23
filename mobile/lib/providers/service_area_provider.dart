import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ServiceAreaProvider with ChangeNotifier {
  final ApiService apiService = ApiService();

  bool _isChecking = false;
  bool? _isServiceAvailable;
  String? _error;
  Map<String, dynamic>? _serviceAreaInfo;

  bool get isChecking => _isChecking;
  bool? get isServiceAvailable => _isServiceAvailable;
  String? get error => _error;
  Map<String, dynamic>? get serviceAreaInfo => _serviceAreaInfo;

  /// Check if service is available for a location.
  ///
  /// Prefers GPS coordinates (latitude/longitude) — the backend decides via a
  /// distance-from-store radius check. Falls back to `pincode` when coordinates
  /// aren't provided (e.g. GPS denied). Callers that already have address/GPS
  /// coordinates should pass them for an accurate, radius-based result.
  Future<bool> checkServiceAvailability({
    String? pincode,
    double? latitude,
    double? longitude,
    String country = 'India',
  }) async {
    // CRITICAL: Always reset state before checking to prevent stale results
    _isChecking = true;
    _error = null;
    _isServiceAvailable = null;
    _serviceAreaInfo = null;
    notifyListeners();

    try {
      final hasCoords = latitude != null && longitude != null;
      final String queryString;
      if (hasCoords) {
        queryString = '?lat=$latitude&lng=$longitude';
        if (kDebugMode) {
          print('🌐 [API CALL] Checking service for coords: $latitude,$longitude');
        }
      } else {
        final cleanPincode = (pincode ?? '').trim().replaceAll(' ', '');
        queryString = '?pincode=$cleanPincode&country=${Uri.encodeComponent(country)}';
        if (kDebugMode) {
          print('🌐 [API CALL] Checking service for pincode: $cleanPincode, country: $country');
        }
      }

      final response = await apiService.get(
        '/service-area/check$queryString',
      );

      _isServiceAvailable = response['available'] as bool? ?? false;
      if (_isServiceAvailable == true && response['serviceArea'] != null) {
        _serviceAreaInfo = response['serviceArea'] as Map<String, dynamic>;
      }

      _isChecking = false;
      notifyListeners();
      
      if (kDebugMode) {
        final where = (latitude != null && longitude != null)
            ? '$latitude,$longitude'
            : (pincode ?? '');
        print('🌐 [API RESULT] $where: ${(_isServiceAvailable == true) ? "AVAILABLE" : "NOT AVAILABLE"}');
      }
      
      return _isServiceAvailable ?? false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isServiceAvailable = false;
      _isChecking = false;
      notifyListeners();
      if (kDebugMode) {
        print('❌ [API ERROR] Error checking service availability for pincode $pincode: ${_error ?? "Unknown error"}');
      }
      return false;
    }
  }

  /// Reset state
  void reset() {
    _isChecking = false;
    _isServiceAvailable = null;
    _error = null;
    _serviceAreaInfo = null;
    notifyListeners();
  }
}

