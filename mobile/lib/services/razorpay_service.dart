import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/app_config.dart';
import 'api_service.dart';

// Conditional import - only import Razorpay on mobile platforms
import 'package:razorpay_flutter/razorpay_flutter.dart' if (dart.library.html) 'razorpay_web_stub.dart';

class RazorpayService {
  static Razorpay? _razorpay;
  static bool _initialized = false;

  static void initialize() {
    if (_initialized || kIsWeb) return;
    try {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      _initialized = true;
    } catch (e) {
      print('Razorpay initialization error: $e');
    }
  }

  static Function(PaymentSuccessResponse)? onSuccess;
  static Function(PaymentFailureResponse)? onError;
  static Function(ExternalWalletResponse)? onExternalWallet;

  static void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (onSuccess != null) {
      onSuccess!(response);
    }
  }

  static void _handlePaymentError(PaymentFailureResponse response) {
    if (onError != null) {
      onError!(response);
    }
  }

  static void _handleExternalWallet(ExternalWalletResponse response) {
    if (onExternalWallet != null) {
      onExternalWallet!(response);
    }
  }

  static Future<Map<String, dynamic>?> createOrder({
    required double amount,
    required int orderId,
    required String token,
  }) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        '/payment/create-order',
        {
          'amount': amount,
          'orderId': orderId,
        },
        token: token,
      );

      return response as Map<String, dynamic>?;
    } catch (e) {
      print('Error creating Razorpay order: $e');
      return null;
    }
  }

  static Future<bool> verifyPayment({
    required int orderId,
    required String paymentId,
    required String signature,
    required String razorpayOrderId,
    required String token,
  }) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        '/payment/verify',
        {
          'orderId': orderId,
          'paymentId': paymentId,
          'signature': signature,
          'razorpayOrderId': razorpayOrderId,
        },
        token: token,
      );

      return response != null;
    } catch (e) {
      print('Error verifying payment: $e');
      return false;
    }
  }

  static void openCheckout({
    required String keyId,
    required double amount,
    required String orderId,
    required String name,
    required String description,
    String? prefillEmail,
    String? prefillContact,
    Map<String, dynamic>? notes,
  }) {
    if (kIsWeb) {
      // For web, open Razorpay checkout in new window
      _openRazorpayWebCheckout(
        keyId: keyId,
        amount: amount,
        orderId: orderId,
        name: name,
        description: description,
        prefillEmail: prefillEmail,
        prefillContact: prefillContact,
        notes: notes,
      );
      return;
    }

    if (_razorpay == null) {
      print('Razorpay not initialized');
      return;
    }

    final options = {
      'key': keyId,
      'amount': (amount * 100).toInt(), // Convert to paise
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': {
        if (prefillEmail != null) 'email': prefillEmail,
        if (prefillContact != null) 'contact': prefillContact,
      },
      'external': {
        'wallets': ['paytm']
      },
      if (notes != null) 'notes': notes,
      'theme': {
        'color': '#00A859' // AppTheme.primaryGreen
      }
    };

    _razorpay!.open(options);
  }

  static void _openRazorpayWebCheckout({
    required String keyId,
    required double amount,
    required String orderId,
    required String name,
    required String description,
    String? prefillEmail,
    String? prefillContact,
    Map<String, dynamic>? notes,
  }) {
    // For web, we'll use Razorpay Checkout.js
    // This requires adding Razorpay script to index.html
    // For now, show a message to use mobile app or implement web checkout
    print('Web Razorpay checkout - requires web implementation');
    // TODO: Implement Razorpay Checkout.js for web
  }

  static void clear() {
    if (!kIsWeb && _razorpay != null) {
      _razorpay!.clear();
    }
  }
}

