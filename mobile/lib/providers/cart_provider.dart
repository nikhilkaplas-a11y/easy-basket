import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cart_service.dart';
import '../models/product_model.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  final Set<int> _addingItems = {}; // Track items being added
  SharedPreferences? _prefs;
  bool _isLoading = false;

  List<CartItem> get items => _cartService.items;
  int get itemCount => _cartService.itemCount;
  double get totalAmount => _cartService.totalAmount;
  bool isAddingItem(int productId) => _addingItems.contains(productId);
  bool get isLoading => _isLoading;

  CartProvider();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCart();
  }

  Future<void> _loadCart() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final cartJson = _prefs!.getString('cart_items');
      if (cartJson != null && cartJson.isNotEmpty) {
        final List<dynamic> cartData = jsonDecode(cartJson);
        
        for (var itemData in cartData) {
          try {
            final productJson = itemData['product'] as Map<String, dynamic>;
            final product = ProductModel.fromJson(productJson);
            final quantity = itemData['quantity'] as int;
            
            // Add item with quantity
            for (int i = 0; i < quantity; i++) {
              _cartService.addItem(product);
            }
            // Adjust quantity if needed (in case it was > 1)
            if (quantity > 1) {
              _cartService.updateQuantity(product.id, quantity);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error loading cart item: $e');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cart: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    try {
      final cartData = _cartService.items.map((item) => {
        'product': item.product.toJson(),
        'quantity': item.quantity,
      }).toList();

      final cartJson = jsonEncode(cartData);
      await _prefs!.setString('cart_items', cartJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving cart: $e');
      }
    }
  }

  Future<void> addItem(ProductModel product) async {
    _addingItems.add(product.id);
    notifyListeners();
    
    // Simulate a brief delay for better UX (even though it's instant)
    await Future.delayed(const Duration(milliseconds: 300));
    
    _cartService.addItem(product);
    _addingItems.remove(product.id);
    await _saveCart();
    notifyListeners();
  }

  Future<void> removeItem(int productId) async {
    _cartService.removeItem(productId);
    await _saveCart();
    notifyListeners();
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    _cartService.updateQuantity(productId, quantity);
    await _saveCart();
    notifyListeners();
  }

  Future<void> clear() async {
    _cartService.clear();
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    await _prefs!.remove('cart_items');
    notifyListeners();
  }

  bool contains(int productId) {
    return _cartService.contains(productId);
  }

  int getQuantity(int productId) {
    return _cartService.getQuantity(productId);
  }
}

