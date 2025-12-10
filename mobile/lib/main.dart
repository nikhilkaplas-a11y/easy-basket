import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/delivery_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/service_area_provider.dart';
import 'routes/app_router.dart';
import 'utils/theme.dart';
import 'services/razorpay_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (optional - skip for web due to compatibility issues)
  if (!kIsWeb) {
    try {
      // ignore: avoid_print
      // Firebase is optional and has web compatibility issues
      // await Firebase.initializeApp();
    } catch (e) {
      // ignore: avoid_print
      print('Firebase initialization error: $e');
    }
  }
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize Razorpay (only for mobile platforms, not web)
  if (!kIsWeb) {
    RazorpayService.initialize();
  }
  
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    // Create a shared function to set up API service with token refresh
    ApiService createApiService(AuthProvider authProvider) {
      final apiService = ApiService();
      // Set up automatic token refresh callback
      apiService.onTokenExpired = () async {
        return await authProvider.refreshAccessToken();
      };
      return apiService;
    }
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final apiService = ApiService();
            final authService = AuthService(apiService: apiService);
            final authProvider = AuthProvider(
              authService: authService,
              prefs: prefs,
            );
            // Set up automatic token refresh callback after provider is created
            // We'll set it up in update callbacks for other providers
            return authProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider()..initialize(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(
          create: (_) => ProductProvider(apiService: ApiService()),
          update: (_, authProvider, previous) {
            if (previous != null) {
              // Update existing provider's API service callback
              previous.apiService.onTokenExpired = () async {
                return await authProvider.refreshAccessToken();
              };
              return previous;
            }
            return ProductProvider(apiService: createApiService(authProvider));
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(apiService: ApiService()),
          update: (_, authProvider, previous) {
            if (previous != null) {
              // Update existing provider's API service callback
              previous.apiService.onTokenExpired = () async {
                return await authProvider.refreshAccessToken();
              };
              return previous;
            }
            return OrderProvider(apiService: createApiService(authProvider));
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, DeliveryProvider>(
          create: (_) => DeliveryProvider(apiService: ApiService()),
          update: (_, authProvider, previous) {
            if (previous != null) {
              // Update existing provider's API service callback
              previous.apiService.onTokenExpired = () async {
                return await authProvider.refreshAccessToken();
              };
              return previous;
            }
            return DeliveryProvider(apiService: createApiService(authProvider));
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create: (_) => AdminProvider(apiService: ApiService()),
          update: (_, authProvider, previous) {
            if (previous != null) {
              // Update existing provider's API service callback
              previous.apiService.onTokenExpired = () async {
                return await authProvider.refreshAccessToken();
              };
              return previous;
            }
            return AdminProvider(apiService: createApiService(authProvider));
          },
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceAreaProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Easy Basket',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}

