import '../models/product_model.dart';
import '../models/product_variant_model.dart';

class CartItem {
  final ProductModel product;
  final ProductVariantModel? variant;
  int quantity;

  CartItem({
    required this.product,
    this.variant,
    this.quantity = 1,
  });

  double get total {
    final price = variant?.price ?? product.price;
    return price * quantity;
  }
  
  String get displayLabel {
    if (variant != null) {
      return '${quantity} × ${variant!.label}';
    }
    return '$quantity × ${product.name}';
  }
  
  // Unique key for cart items (product + variant combination)
  String get key {
    if (variant != null) {
      return '${product.id}_${variant!.id}';
    }
    return '${product.id}_null';
  }
}

class CartService {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  void addItem(ProductModel product, {ProductVariantModel? variant}) {
    final itemKey = variant != null 
        ? '${product.id}_${variant.id}'
        : '${product.id}_null';
    
    final existingIndex = _items.indexWhere((item) => item.key == itemKey);

    if (existingIndex >= 0) {
      final maxStock = variant?.stock ?? product.stock;
      if (_items[existingIndex].quantity < maxStock) {
        _items[existingIndex].quantity++;
      }
    } else {
      _items.add(CartItem(product: product, variant: variant, quantity: 1));
    }
  }

  void removeItem(int productId, {int? variantId}) {
    if (variantId != null) {
      _items.removeWhere((item) => 
          item.product.id == productId && item.variant?.id == variantId);
    } else {
      _items.removeWhere((item) => 
          item.product.id == productId && item.variant == null);
    }
  }

  void updateQuantity(int productId, int quantity, {int? variantId}) {
    final itemKey = variantId != null 
        ? '${productId}_$variantId'
        : '${productId}_null';
    
    final item = _items.firstWhere((item) => item.key == itemKey);
    if (quantity <= 0) {
      removeItem(productId, variantId: variantId);
    } else {
      final maxStock = item.variant?.stock ?? item.product.stock;
      if (quantity <= maxStock) {
        item.quantity = quantity;
      }
    }
  }

  void clear() {
    _items.clear();
  }

  bool contains(int productId, {int? variantId}) {
    if (variantId != null) {
      return _items.any((item) => 
          item.product.id == productId && item.variant?.id == variantId);
    }
    return _items.any((item) => 
        item.product.id == productId && item.variant == null);
  }

  int getQuantity(int productId, {int? variantId}) {
    try {
      if (variantId != null) {
        return _items.firstWhere((item) => 
            item.product.id == productId && item.variant?.id == variantId).quantity;
      }
      return _items.firstWhere((item) => 
          item.product.id == productId && item.variant == null).quantity;
    } catch (e) {
      return 0;
    }
  }
}

