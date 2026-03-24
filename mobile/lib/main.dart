import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/notification_service.dart';
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

  // Initialize Firebase (required for FCM notifications — mobile only)
  if (!kIsWeb) {
    await Firebase.initializeApp();
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
        builder: (context, child) {
          // Initialize notification service when app is ready (mobile only)
          if (!kIsWeb) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                
                // Initialize for all authenticated users (not just admin)
                // Admin will receive order notifications, customers will receive order updates
                if (authProvider.user != null) {
                  debugPrint('📱 [NOTIFICATION] Initializing for user: ${authProvider.user!.role}');
                  NotificationService().initialize(
                    context: context,
                    adminProvider: adminProvider,
                    authProvider: authProvider,
                  );
                } else {
                  debugPrint('⚠️ [NOTIFICATION] User not logged in, skipping initialization');
                }
              } catch (e) {
                debugPrint('❌ [NOTIFICATION] Error initializing: $e');
              }
            });
          }
          return child!;
        },
      ),
    );
  }
}

