import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class AdminProvider with ChangeNotifier {
  final ApiService apiService;

  Map<String, dynamic>? _stats;
  List<OrderModel> _orders = [];
  List<UserModel> _users = [];
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  Map<String, dynamic>? get stats => _stats;
  List<OrderModel> get orders => _orders;
  List<UserModel> get users => _users;
  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;

  AdminProvider({required this.apiService});

  Future<void> fetchStats({String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/admin/dashboard', token: token);
      _stats = response as Map<String, dynamic>;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      print('Error fetching admin stats: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrders({String? status, String? token, bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      _currentPage++;
    } else {
      _isLoading = true;
      _currentPage = 1;
      _orders = [];
      _hasMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      String endpoint = '/admin/orders?page=$_currentPage&limit=20';
      if (status != null && status.isNotEmpty) {
        endpoint += '&status=$status';
      }

      final response = await apiService.get(endpoint, token: token);
      if (response is Map<String, dynamic> && response.containsKey('orders')) {
        final List<dynamic> data = response['orders'] as List? ?? [];
        final pagination = response['pagination'] as Map<String, dynamic>?;
        _hasMore = pagination?['hasMore'] as bool? ?? false;
        
        final newOrders = data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
        if (loadMore) {
          _orders.addAll(newOrders);
        } else {
          _orders = newOrders;
        }
      } else {
        // Fallback for old API format
        final List<dynamic> data = response is List ? response : [];
        final newOrders = data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
        if (loadMore) {
          _orders.addAll(newOrders);
        } else {
          _orders = newOrders;
        }
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      print('Error fetching admin orders: $_error');
      if (loadMore) _currentPage--;
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchUsers({String? role, String? token, bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      _currentPage++;
    } else {
      _isLoading = true;
      _currentPage = 1;
      _users = [];
      _hasMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      String endpoint = '/admin/users?page=$_currentPage&limit=20';
      if (role != null && role.isNotEmpty) {
        endpoint += '&role=$role';
      }

      final response = await apiService.get(endpoint, token: token);
      if (response is Map<String, dynamic> && response.containsKey('users')) {
        final List<dynamic> data = response['users'] as List? ?? [];
        final pagination = response['pagination'] as Map<String, dynamic>?;
        _hasMore = pagination?['hasMore'] as bool? ?? false;
        
        final newUsers = data.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
        if (loadMore) {
          _users.addAll(newUsers);
        } else {
          _users = newUsers;
        }
      } else {
        // Fallback for old API format
        final List<dynamic> data = response is List ? response : [];
        final newUsers = data.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
        if (loadMore) {
          _users.addAll(newUsers);
        } else {
          _users = newUsers;
        }
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      print('Error fetching admin users: $_error');
      if (loadMore) _currentPage--;
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus({
    required String token,
    required int orderId,
    required String status,
    int? deliveryBoyId,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{'status': status};
      if (deliveryBoyId != null) data['deliveryBoyId'] = deliveryBoyId;
      if (notes != null) data['notes'] = notes;

      await apiService.put(
        '/admin/orders/$orderId/status',
        data,
        token: token,
      );

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

  Future<bool> updateUser({
    required String token,
    required int userId,
    String? name,
    String? email,
    String? role,
    bool? isActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (role != null) data['role'] = role;
      if (isActive != null) data['isActive'] = isActive;

      await apiService.put(
        '/admin/users/$userId',
        data,
        token: token,
      );

      await fetchUsers(token: token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProducts({String? token, bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      _currentPage++;
    } else {
      _isLoading = true;
      _currentPage = 1;
      _products = [];
      _hasMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/admin/products?page=$_currentPage&limit=20', token: token);
      if (response is Map<String, dynamic> && response.containsKey('products')) {
        final List<dynamic> data = response['products'] as List? ?? [];
        final pagination = response['pagination'] as Map<String, dynamic>?;
        _hasMore = pagination?['hasMore'] as bool? ?? false;
        
        final newProducts = data.map((json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
        if (loadMore) {
          _products.addAll(newProducts);
        } else {
          _products = newProducts;
        }
      } else {
        // Fallback for old API format
        final List<dynamic> data = response is List ? response : [];
        final newProducts = data.map((json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
        if (loadMore) {
          _products.addAll(newProducts);
        } else {
          _products = newProducts;
        }
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      print('Error fetching admin products: $_error');
      if (loadMore) _currentPage--;
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createProduct({
    required String token,
    required String name,
    required double price,
    required int categoryId,
    String? description,
    String? imageUrl,
    int? stock,
    String? unit,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'name': name,
        'price': price,
        'categoryId': categoryId,
      };
      if (description != null) data['description'] = description;
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (stock != null) data['stock'] = stock;
      if (unit != null) data['unit'] = unit;

      await apiService.post('/admin/products', data, token: token);
      await fetchProducts(token: token);
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

  Future<bool> updateProduct({
    required String token,
    required int productId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    int? categoryId,
    int? stock,
    String? unit,
    bool? isAvailable,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (categoryId != null) data['categoryId'] = categoryId;
      if (stock != null) data['stock'] = stock;
      if (unit != null) data['unit'] = unit;
      if (isAvailable != null) data['isAvailable'] = isAvailable;

      await apiService.put('/admin/products/$productId', data, token: token);
      await fetchProducts(token: token);
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

  Future<bool> deleteProduct({
    required String token,
    required int productId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.delete('/admin/products/$productId', token: token);
      await fetchProducts(token: token);
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

  Future<void> fetchCategories({String? token, bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      _currentPage++;
    } else {
      _isLoading = true;
      _currentPage = 1;
      _categories = [];
      _hasMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/categories?page=$_currentPage&limit=20', token: token);
      if (response is Map<String, dynamic> && response.containsKey('categories')) {
        final List<dynamic> data = response['categories'] as List? ?? [];
        final pagination = response['pagination'] as Map<String, dynamic>?;
        _hasMore = pagination?['hasMore'] as bool? ?? false;
        
        final newCategories = data.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
        if (loadMore) {
          _categories.addAll(newCategories);
        } else {
          _categories = newCategories;
        }
      } else {
        // Fallback for old API format
        final List<dynamic> data = response is List ? response : [];
        final newCategories = data.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
        if (loadMore) {
          _categories.addAll(newCategories);
        } else {
          _categories = newCategories;
        }
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      print('Error fetching admin categories: $_error');
      if (loadMore) _currentPage--;
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory({
    required String token,
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{'name': name};
      if (description != null) data['description'] = description;
      if (imageUrl != null) data['imageUrl'] = imageUrl;

      await apiService.post('/categories', data, token: token);
      await fetchCategories(token: token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCategory({
    required String token,
    required int categoryId,
    String? name,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (isActive != null) data['isActive'] = isActive;

      await apiService.put('/categories/$categoryId', data, token: token);
      await fetchCategories(token: token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory({
    required String token,
    required int categoryId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.delete('/categories/$categoryId', token: token);
      await fetchCategories(token: token);
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

