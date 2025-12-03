import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/address/address_list_screen.dart';
import '../screens/address/add_address_screen.dart';
import '../screens/address/map_address_picker_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/orders/order_tracking_screen.dart';
import '../screens/orders/order_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/delivery/delivery_dashboard_screen.dart';
import '../screens/delivery/delivery_orders_screen.dart';
import '../screens/delivery/delivery_order_detail_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_orders_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_products_screen.dart';
import '../screens/admin/admin_categories_screen.dart';
import '../screens/admin/add_edit_category_screen.dart';
import '../screens/admin/add_edit_product_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      final currentLocation = state.matchedLocation;

      // If not authenticated, redirect to login (except splash and login routes)
      if (!isAuthenticated && !isLoginRoute && currentLocation != '/splash') {
        return '/login';
      }

      // If authenticated, check role and redirect accordingly
      if (isAuthenticated) {
        final userRole = authProvider.user?.role;
        
        // Admin users
        if (userRole == 'admin') {
          if (currentLocation != '/admin/dashboard' && 
              !currentLocation.startsWith('/admin/') &&
              currentLocation != '/splash' &&
              currentLocation != '/login') {
            return '/admin/dashboard';
          }
          if (isLoginRoute || currentLocation == '/splash') {
            return '/admin/dashboard';
          }
        }
        // Delivery users
        else if (userRole == 'delivery') {
          if (currentLocation != '/delivery/dashboard' && 
              !currentLocation.startsWith('/delivery/') &&
              currentLocation != '/splash' &&
              currentLocation != '/login') {
            return '/delivery/dashboard';
          }
          if (isLoginRoute || currentLocation == '/splash') {
            return '/delivery/dashboard';
          }
        }
        // Customer users
        else {
          // If customer user tries to access admin/delivery routes, redirect to home
          if (currentLocation.startsWith('/admin/') || currentLocation.startsWith('/delivery/')) {
            return '/home';
          }
          if (isLoginRoute || currentLocation == '/splash') {
            return '/home';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['categoryId'];
          return ProductListScreen(
            categoryId: categoryId != null ? int.parse(categoryId) : null,
          );
        },
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressListScreen(),
      ),
      GoRoute(
        path: '/address/add',
        builder: (context, state) => const AddAddressScreen(),
      ),
      GoRoute(
        path: '/address/map-picker',
        builder: (context, state) {
          return MapAddressPickerScreen(
            onLocationSelected: (lat, lng, address) {
              context.pop({
                'latitude': lat,
                'longitude': lng,
                'address': address,
              });
            },
          );
        },
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final addressId = state.extra as int?;
          return PaymentScreen(addressId: addressId);
        },
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrderListScreen(),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return OrderTrackingScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // Delivery Routes
      GoRoute(
        path: '/delivery/dashboard',
        builder: (context, state) => const DeliveryDashboardScreen(),
      ),
      GoRoute(
        path: '/delivery/orders',
        builder: (context, state) {
          final status = state.uri.queryParameters['status'];
          return DeliveryOrdersScreen(status: status);
        },
      ),
      GoRoute(
        path: '/delivery/order/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return DeliveryOrderDetailScreen(orderId: id);
        },
      ),
      // Admin Routes
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) {
          final status = state.uri.queryParameters['status'];
          return AdminOrdersScreen(status: status);
        },
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'];
          return AdminUsersScreen(role: role);
        },
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: '/admin/categories',
        builder: (context, state) => const AdminCategoriesScreen(),
      ),
      GoRoute(
        path: '/admin/categories/add',
        builder: (context, state) => const AddEditCategoryScreen(),
      ),
      GoRoute(
        path: '/admin/categories/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          // We'll fetch category by ID in the screen if needed
          return AddEditCategoryScreen(categoryId: id);
        },
      ),
      GoRoute(
        path: '/admin/products/add',
        builder: (context, state) => const AddEditProductScreen(),
      ),
      GoRoute(
        path: '/admin/products/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          // We'll fetch product by ID in the screen if needed
          return AddEditProductScreen(productId: id);
        },
      ),
    ],
  );
}

