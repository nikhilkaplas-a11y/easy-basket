import 'user_model.dart';
import 'address_model.dart';
import 'product_model.dart';
import 'product_variant_model.dart';

class OrderItemModel {
  final int id;
  final ProductModel product;
  final ProductVariantModel? variant; // Variant if product has variants
  final int quantity;
  final double price;
  final double total;
  final String? unit; // Unit of measurement
  final String? displayLabel; // Display label (e.g., "2 × 1 kg")

  OrderItemModel({
    required this.id,
    required this.product,
    this.variant,
    required this.quantity,
    required this.price,
    required this.total,
    this.unit,
    this.displayLabel,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // Helper to parse numeric values (handles both string and num from MySQL DECIMAL)
    double parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.parse(value);
      } else {
        return 0.0;
      }
    }

    // Helper to parse quantity (can be int or decimal, but we store as int)
    int parseQuantity(dynamic value) {
      if (value is int) {
        return value;
      } else if (value is num) {
        return value.toInt();
      } else if (value is String) {
        // Handle string like "1.000" or "1"
        final parsed = double.tryParse(value);
        return parsed?.toInt() ?? 0;
      } else {
        return 0;
      }
    }

    return OrderItemModel(
      id: json['id'] as int,
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      variant: json['variant'] != null
          ? ProductVariantModel.fromJson(json['variant'] as Map<String, dynamic>)
          : null,
      quantity: parseQuantity(json['quantity']),
      price: parseDouble(json['price']),
      total: parseDouble(json['total']),
      unit: json['unit'] as String?,
      displayLabel: json['displayLabel'] as String?,
    );
  }
}

class OrderModel {
  final int id;
  final UserModel user;
  final AddressModel deliveryAddress;
  final List<OrderItemModel> items;
  final double totalAmount;
  final String status;
  final String? paymentMethod;
  final String? paymentId;
  final bool isPaid;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? deliveryBoy;

  OrderModel({
    required this.id,
    required this.user,
    required this.deliveryAddress,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.paymentMethod,
    this.paymentId,
    required this.isPaid,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deliveryBoy,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Helper to parse numeric values (handles both string and num from MySQL DECIMAL)
    double parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.parse(value);
      } else {
        return 0.0;
      }
    }

    // Helper to parse DateTime (handles both string and DateTime)
    DateTime parseDateTime(dynamic value) {
      if (value is DateTime) {
        return value;
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        return DateTime.now();
      }
    }

    return OrderModel(
      id: json['id'] as int,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      deliveryAddress: AddressModel.fromJson(json['deliveryAddress'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: parseDouble(json['totalAmount']),
      status: json['status'] as String,
      paymentMethod: json['paymentMethod'] as String?,
      paymentId: json['paymentId'] as String?,
      isPaid: json['isPaid'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      deliveryBoy: json['deliveryBoy'] != null
          ? UserModel.fromJson(json['deliveryBoy'] as Map<String, dynamic>)
          : null,
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

