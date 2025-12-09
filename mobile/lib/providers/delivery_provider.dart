import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';

class DeliveryProvider with ChangeNotifier {
  final ApiService apiService;

  List<OrderModel> _orders = [];
  List<OrderModel> _availableOrders = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  List<OrderModel> get availableOrders => _availableOrders;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DeliveryProvider({required this.apiService});

  Future<void> fetchOrders({String? status, String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String endpoint = '/delivery/orders';
      if (status != null && status.isNotEmpty) {
        endpoint += '?status=$status';
      }

      final response = await apiService.get(endpoint, token: token);
      final List<dynamic> data = response is List ? response : [];
      _orders = data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStats({String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/delivery/stats', token: token);
      _stats = response as Map<String, dynamic>;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus({
    required String token,
    required int orderId,
    required String status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.put(
        '/delivery/orders/$orderId/status',
        {'status': status},
        token: token,
      );

      // Refresh orders after status update
      await fetchOrders(token: token);
      await fetchStats(token: token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> getOrderDetails(int orderId, {String? token}) async {
    try {
      final response = await apiService.get('/delivery/orders/$orderId', token: token);
      return OrderModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return null;
    }
  }

  Future<void> fetchAvailableOrders({String? status, String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String endpoint = '/delivery/orders/available';
      if (status != null && status.isNotEmpty) {
        endpoint += '?status=$status';
      }

      final response = await apiService.get(endpoint, token: token);
      final List<dynamic> data = response is List ? response : [];
      _availableOrders = data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptOrder({
    required String token,
    required int orderId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.post(
        '/delivery/orders/$orderId/accept',
        {},
        token: token,
      );

      // Refresh available orders and assigned orders
      await fetchAvailableOrders(token: token);
      await fetchOrders(token: token);
      await fetchStats(token: token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

