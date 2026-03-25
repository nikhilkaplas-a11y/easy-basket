/// Lightweight order model — sirf home screen ke active order bar ke liye
/// Kyun: Full OrderModel mein user, address, items sab hota hai — heavy data
/// Home screen pe sirf id, status, totalAmount chahiye — isliye alag model
class ActiveOrderModel {
  final int id;
  final String status;
  final double totalAmount;
  final DateTime createdAt;

  ActiveOrderModel({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
  });

  /// JSON → Dart object convert karta hai
  /// Backend se aata hai: {id: 64, status: "pending", totalAmount: "100.00", createdAt: "2026-..."}
  factory ActiveOrderModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.parse(value);
      return 0.0;
    }

    DateTime parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return ActiveOrderModel(
      id: json['id'] as int,
      status: json['status'] as String,
      totalAmount: parseDouble(json['totalAmount']),
      createdAt: parseDateTime(json['createdAt']),
    );
  }

  /// Status ka readable text — UI mein dikhane ke liye
  String get statusText {
    switch (status) {
      case 'pending': return 'Pending';
      case 'accepted': return 'Confirmed';
      case 'preparing': return 'Preparing';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }
}
