import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class ProductProvider with ChangeNotifier {
  final ApiService apiService;

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProductProvider({required this.apiService});

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/categories');
      // Handle both paginated and non-paginated responses
      if (response is Map<String, dynamic> && response.containsKey('categories')) {
        final List<dynamic> data = response['categories'] as List? ?? [];
        _categories = data.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        // Fallback for old API format (direct array)
        final List<dynamic> data = response is List ? response : [];
        _categories = data.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProducts({int? categoryId, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String endpoint = '/products';
      if (categoryId != null) {
        endpoint += '?categoryId=$categoryId';
      }
      if (search != null && search.isNotEmpty) {
        endpoint += categoryId != null ? '&search=$search' : '?search=$search';
      }

      final response = await apiService.get(endpoint);
      // Backend returns array directly: res.json(products)
      final List<dynamic> data = response is List ? response : [];
      
      // Clear products when filtering by category to show fresh results
      if (categoryId != null) {
        _products = [];
      }
      
      _products = data.map((json) {
        try {
          return ProductModel.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing product: $e');
          print('Product JSON: $json');
          rethrow;
        }
      }).toList();
      
      print('Fetched ${_products.length} products for categoryId: $categoryId');
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      print('Error fetching products: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProductModel?> fetchProductById(int id) async {
    try {
      final response = await apiService.get('/products/$id');
      return ProductModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return null;
    }
  }
}

