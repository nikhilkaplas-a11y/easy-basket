import 'package:flutter/foundation.dart' show ChangeNotifier, kDebugMode;
import '../services/api_service.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/product_variant_model.dart';

class AdminProvider with ChangeNotifier {
  final ApiService apiService;

  Map<String, dynamic>? _stats;
  List<OrderModel> _orders = [];
  List<UserModel> _users = [];
  List<UserModel> _deliveryAgents = [];
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
  List<UserModel> get deliveryAgents => _deliveryAgents;
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

      // Update the order in the list if it exists
      final orderIndex = _orders.indexWhere((o) => o.id == orderId);
      if (orderIndex >= 0) {
        // Fetch updated order to refresh the list
        await fetchOrders(token: token);
      } else {
        // If order not in list, just refresh stats
        await fetchStats(token: token);
      }
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
    int? parentCategoryId,
    int? displayOrder,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{'name': name};
      if (description != null) data['description'] = description;
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (parentCategoryId != null) data['parentCategoryId'] = parentCategoryId;
      if (displayOrder != null) data['displayOrder'] = displayOrder;

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
    int? parentCategoryId,
    int? displayOrder,
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
      if (parentCategoryId != null) data['parentCategoryId'] = parentCategoryId;
      if (parentCategoryId == null && data.containsKey('parentCategoryId')) {
        // Explicitly set to null to remove parent
        data['parentCategoryId'] = null;
      }
      if (displayOrder != null) data['displayOrder'] = displayOrder;

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

  Future<void> fetchDeliveryAgents({String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/admin/delivery-agents', token: token);
      final List<dynamic> data = response is List ? response : [];
      _deliveryAgents = data.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
      
      if (kDebugMode) {
        print('✅ Fetched ${_deliveryAgents.length} delivery agents');
        if (_deliveryAgents.isEmpty) {
          print('⚠️ No delivery agents found. Make sure users have role="delivery" and isActive=true');
        }
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      if (kDebugMode) {
        print('❌ Error fetching delivery agents: $_error');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Variant Management Methods
  Future<List<ProductVariantModel>> fetchProductVariants({
    required String token,
    required int productId,
  }) async {
    _error = null;
    try {
      // Use admin endpoint for authenticated requests
      final response = await apiService.get('/admin/products/$productId/variants', token: token);
      if (response is Map<String, dynamic> && response.containsKey('variants')) {
        final List<dynamic> data = response['variants'] as List? ?? [];
        return data.map((json) => ProductVariantModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      print('❌ Error fetching variants: $_error');
      return [];
    }
  }

  Future<bool> createVariant({
    required String token,
    required int productId,
    required double quantity,
    required String unit,
    required String label,
    required double price,
    int? stock,
    bool? isAvailable,
    double? minQuantity,
    double? maxQuantity,
    int? displayOrder,
    bool? isDefault,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'quantity': quantity,
        'unit': unit,
        'label': label,
        'price': price,
      };
      if (stock != null) data['stock'] = stock;
      if (isAvailable != null) data['isAvailable'] = isAvailable;
      if (minQuantity != null) data['minQuantity'] = minQuantity;
      if (maxQuantity != null) data['maxQuantity'] = maxQuantity;
      if (displayOrder != null) data['displayOrder'] = displayOrder;
      if (isDefault != null) data['isDefault'] = isDefault;

      final response = await apiService.post('/admin/products/$productId/variants', data, token: token);
      
      // Check if response indicates success
      if (response != null) {
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      print('❌ Error creating variant: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateVariant({
    required String token,
    required int variantId,
    double? quantity,
    String? unit,
    String? label,
    double? price,
    int? stock,
    bool? isAvailable,
    double? minQuantity,
    double? maxQuantity,
    int? displayOrder,
    bool? isDefault,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (quantity != null) data['quantity'] = quantity;
      if (unit != null) data['unit'] = unit;
      if (label != null) data['label'] = label;
      if (price != null) data['price'] = price;
      if (stock != null) data['stock'] = stock;
      if (isAvailable != null) data['isAvailable'] = isAvailable;
      if (minQuantity != null) data['minQuantity'] = minQuantity;
      if (maxQuantity != null) data['maxQuantity'] = maxQuantity;
      if (displayOrder != null) data['displayOrder'] = displayOrder;
      if (isDefault != null) data['isDefault'] = isDefault;

      await apiService.put('/admin/variants/$variantId', data, token: token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteVariant({
    required String token,
    required int variantId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.delete('/admin/variants/$variantId', token: token);
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

