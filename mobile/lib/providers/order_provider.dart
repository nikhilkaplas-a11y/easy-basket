import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';
import '../models/address_model.dart';

class OrderProvider with ChangeNotifier {
  final ApiService apiService;

  List<OrderModel> _orders = [];
  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  OrderProvider({required this.apiService});

  Future<void> fetchOrders(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/orders', token: token);
      // Backend returns array directly: res.json(orders)
      final List<dynamic> data = response is List ? response : [];
      _orders = data.map((json) {
        try {
          return OrderModel.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing order: $e');
            print('Order data: $json');
          }
          rethrow;
        }
      }).toList();
      if (kDebugMode) {
        print('✅ Fetched ${_orders.length} orders');
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      if (kDebugMode) {
        print('❌ Error fetching orders: $_error');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> fetchOrderById(int id, String token) async {
    try {
      final response = await apiService.get('/orders/$id', token: token);
      return OrderModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return null;
    }
  }

  Future<OrderModel?> createOrder({
    required String token,
    required List<Map<String, dynamic>> items,
    required int addressId,
    required String paymentMethod,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.post(
        '/orders',
        {
          'items': items,
          'addressId': addressId,
          'paymentMethod': paymentMethod,
          if (notes != null) 'notes': notes,
        },
        token: token,
      );
      // Backend returns { order: {...}, paymentOrder: {...} }
      // Extract the order from the response
      final responseMap = response as Map<String, dynamic>;
      OrderModel? createdOrder;
      if (responseMap.containsKey('order')) {
        createdOrder = OrderModel.fromJson(responseMap['order'] as Map<String, dynamic>);
      } else {
        // Fallback: if response is directly the order object
        createdOrder = OrderModel.fromJson(responseMap);
      }
      
      // Add the order to the list immediately (optimistic update)
      if (createdOrder != null) {
        _orders.insert(0, createdOrder); // Add at the beginning (newest first)
        if (kDebugMode) {
          print('✅ Added order ${createdOrder.id} to list. Total orders: ${_orders.length}');
        }
      }
      
      _isLoading = false;
      notifyListeners();
      
      return createdOrder;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchAddresses(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/addresses', token: token);
      // Backend returns array directly: res.json(addresses)
      final List<dynamic> data = response is List ? response : [];
      _addresses = data.map((json) => AddressModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAddress({
    required String token,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String pincode,
    String? landmark,
    bool isDefault = false,
    String? latitude,
    String? longitude,
    String? tag,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.post(
        '/addresses',
        {
          'addressLine1': addressLine1,
          if (addressLine2 != null) 'addressLine2': addressLine2,
          'city': city,
          'state': state,
          'pincode': pincode,
          if (landmark != null) 'landmark': landmark,
          'isDefault': isDefault,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (tag != null) 'tag': tag,
        },
        token: token,
      );
      await fetchAddresses(token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

