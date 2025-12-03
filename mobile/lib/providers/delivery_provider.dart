import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';

class DeliveryProvider with ChangeNotifier {
  final ApiService apiService;

  List<OrderModel> _orders = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DeliveryProvider({required this.apiService});

  Future<void> fetchOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String endpoint = '/delivery/orders';
      if (status != null && status.isNotEmpty) {
        endpoint += '?status=$status';
      }

      final response = await apiService.get(endpoint);
      final List<dynamic> data = response is List ? response : [];
      _orders = data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/delivery/stats');
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
      await fetchOrders();
      await fetchStats();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> getOrderDetails(int orderId) async {
    try {
      final response = await apiService.get('/delivery/orders/$orderId');
      return OrderModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return null;
    }
  }
}

