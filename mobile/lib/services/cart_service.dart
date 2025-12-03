import '../models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get total => product.price * quantity;
}

class CartService {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  void addItem(ProductModel product) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      if (_items[existingIndex].quantity < product.stock) {
        _items[existingIndex].quantity++;
      }
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
  }

  void updateQuantity(int productId, int quantity) {
    final item = _items.firstWhere((item) => item.product.id == productId);
    if (quantity <= 0) {
      removeItem(productId);
    } else if (quantity <= item.product.stock) {
      item.quantity = quantity;
    }
  }

  void clear() {
    _items.clear();
  }

  bool contains(int productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getQuantity(int productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId).quantity;
    } catch (e) {
      return 0;
    }
  }
}

