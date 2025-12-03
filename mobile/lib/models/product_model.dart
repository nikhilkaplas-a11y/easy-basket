import 'category_model.dart';

class ProductModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final CategoryModel? category;
  final int stock;
  final bool isAvailable;
  final String? unit;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.category,
    required this.stock,
    required this.isAvailable,
    this.unit,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Handle price as string (from database decimal) or number
    double priceValue;
    final priceData = json['price'];
    if (priceData is String) {
      priceValue = double.parse(priceData);
    } else if (priceData is num) {
      priceValue = priceData.toDouble();
    } else {
      // Fallback if price is null or unexpected type
      priceValue = 0.0;
    }
    
    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: priceValue,
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      stock: json['stock'] is int ? json['stock'] as int : (json['stock'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      unit: json['unit'] as String? ?? 'piece',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category?.toJson(),
      'stock': stock,
      'isAvailable': isAvailable,
      'unit': unit,
    };
  }
}

