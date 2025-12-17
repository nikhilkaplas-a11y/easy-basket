import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/service_area_provider.dart';
import '../../services/location_onboarding_service.dart';
import '../../utils/theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/product_card.dart';
import '../../models/category_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasCheckedServiceAvailability = false; // Prevent multiple checks

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      productProvider.fetchCategories();
      productProvider.fetchProducts();
      
      // Fetch addresses if user is authenticated
      if (authProvider.token != null) {
        orderProvider.fetchAddresses(authProvider.token!).then((_) async {
          // If no addresses, auto-detect location in background (seamless onboarding)
          if (orderProvider.addresses.isEmpty && mounted) {
            await _autoDetectLocationForNewUser(
              orderProvider: orderProvider,
              authProvider: authProvider,
            );
            return;
          }
          // Check service availability for default address after addresses are loaded
          _checkDefaultAddressServiceAvailability(orderProvider);
        });
      }
    });
  }

  /// Auto-detect location for new users (seamless onboarding)
  /// Only shows screen if service not available
  Future<void> _autoDetectLocationForNewUser({
    required OrderProvider orderProvider,
    required AuthProvider authProvider,
  }) async {
    final serviceAreaProvider = Provider.of<ServiceAreaProvider>(context, listen: false);
    
    // Auto-detect and save location in background
    final result = await LocationOnboardingService.autoDetectAndSaveLocation(
      orderProvider: orderProvider,
      authProvider: authProvider,
      serviceAreaProvider: serviceAreaProvider,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      // Location detected - show edit screen for user to review/refine (Blinkit-style)
      if (result['addressData'] != null && mounted) {
        // Navigate to add address screen with pre-filled data
        context.push(
          '/address/add',
          extra: result['addressData'] as Map<String, dynamic>,
        );
      } else {
        // Fallback: if no address data, refresh and show success
        await orderProvider.fetchAddresses(authProvider.token!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Location detected! Start shopping now.'),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else if (result['showScreen'] == true) {
      if (result['permissionDenied'] == true) {
        // Permission denied - show permission explanation screen
        context.go('/onboarding/location-permission');
      } else {
        // Service not available - show service not available screen
        // Mark as onboarding since user has no addresses yet
        context.go(
          '/service-not-available',
          extra: {
            'pincode': result['pincode'],
            'city': result['city'],
            'state': result['state'],
            'country': result['country'] ?? 'India',
            'returnTo': '/home',
            'isOnboarding': true, // Mark as onboarding flow
          },
        );
      }
    }
    // If error but don't show screen, user can add address manually via address bar
  }

  /// Check if the default address is serviceable
  Future<void> _checkDefaultAddressServiceAvailability(OrderProvider orderProvider) async {
    // Prevent multiple checks
    if (_hasCheckedServiceAvailability) return;
    
    // Only check if we have addresses
    if (orderProvider.addresses.isEmpty) return;
    
    // Find default address
    final defaultAddress = orderProvider.addresses.firstWhere(
      (addr) => addr.isDefault,
      orElse: () => orderProvider.addresses.first,
    );
    
    if (defaultAddress == null) return;
    
    _hasCheckedServiceAvailability = true;
    
    final serviceAreaProvider = Provider.of<ServiceAreaProvider>(context, listen: false);
    
    try {
      final isAvailable = await serviceAreaProvider.checkServiceAvailability(
        pincode: defaultAddress.pincode,
        country: 'India',
      );
      
      if (kDebugMode) {
        print('🏠 Home screen: Service availability check for default address (${defaultAddress.pincode}): $isAvailable');
      }
      
      if (!isAvailable && mounted) {
        // Show service not available screen
        if (kDebugMode) {
          print('🚫 Default address is not serviceable, showing service not available screen');
        }
        
        // Small delay to ensure home screen is fully rendered
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          // Use context.go to replace home page instead of stacking
          context.go(
            '/service-not-available',
            extra: {
              'pincode': defaultAddress.pincode,
              'city': defaultAddress.city,
              'state': defaultAddress.state,
              'country': 'India',
              'returnTo': '/home',
            },
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking service availability on home screen: $e');
      }
      // Don't block the user if there's an error checking service availability
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
        iconTheme: const IconThemeData(color: AppTheme.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen,
                AppTheme.primaryGreen.withOpacity(0.85),
              ],
            ),
          ),
        ),
        title: Row(
          children: [
            // Logo/Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.shopping_basket_rounded,
                color: AppTheme.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // App Name with better typography
            const Text(
              'Easy Basket',
              style: TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Cart Icon with badge
          Stack(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    color: AppTheme.white,
                    size: 22,
                  ),
                ),
                onPressed: () => context.push('/cart'),
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Profile Icon
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppTheme.white,
                size: 22,
              ),
            ),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              final productProvider = Provider.of<ProductProvider>(context, listen: false);
              final orderProvider = Provider.of<OrderProvider>(context, listen: false);
              await productProvider.fetchCategories();
              await productProvider.fetchProducts();
              if (authProvider.token != null) {
                await orderProvider.fetchAddresses(authProvider.token!);
                // Reset check flag and check again after refresh
                _hasCheckedServiceAvailability = false;
                _checkDefaultAddressServiceAvailability(orderProvider);
              }
            },
            child: Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: cartProvider.itemCount > 0 ? 120 : 24, // Extra padding when cart button is visible (button height ~90px + margin)
                  ),
                  child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address Bar (Blinkit Style)
              Consumer<OrderProvider>(
                builder: (context, orderProvider, _) {
                  final defaultAddress = orderProvider.addresses.isNotEmpty
                      ? orderProvider.addresses.firstWhere(
                          (addr) => addr.isDefault,
                          orElse: () => orderProvider.addresses.first,
                        )
                      : null;
                  final hasNoAddress = orderProvider.addresses.isEmpty;

                  // Address Bar - Clean & Elegant Design (Blinkit/Zomato Style)
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    decoration: BoxDecoration(
                      color: hasNoAddress
                          ? Colors.orange.shade50
                          : AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasNoAddress
                            ? Colors.orange.shade200
                            : AppTheme.primaryGreen.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: GestureDetector(
                      onTap: () {
                        if (hasNoAddress) {
                          context.push('/address/add');
                        } else {
                          context.push('/addresses');
                        }
                      },
                      child: Row(
                        children: [
                          // Location Icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: hasNoAddress
                                  ? Colors.orange.shade100
                                  : AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: hasNoAddress
                                  ? Colors.orange.shade700
                                  : AppTheme.primaryGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Address Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (defaultAddress != null && defaultAddress.tag != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      defaultAddress.tag!.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryGreen,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                Text(
                                  defaultAddress != null
                                      ? defaultAddress.addressLine1.length > 45
                                          ? '${defaultAddress.addressLine1.substring(0, 45)}...'
                                          : defaultAddress.addressLine1
                                      : 'Add delivery address',
                                  style: TextStyle(
                                    color: hasNoAddress
                                        ? Colors.orange.shade900
                                        : AppTheme.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (defaultAddress != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '${defaultAddress.city}, ${defaultAddress.state}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.grey,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                else if (hasNoAddress)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Required to place orders',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Arrow Icon
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: hasNoAddress
                                ? Colors.orange.shade700
                                : AppTheme.primaryGreen,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Search Bar - Premium Design
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                color: AppTheme.white,
                child: GestureDetector(
                  onTap: () => context.push('/products'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.lightGrey.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: AppTheme.grey.withOpacity(0.7),
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Search for products...',
                            style: TextStyle(
                              color: AppTheme.grey.withOpacity(0.8),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.mic_rounded,
                            color: AppTheme.primaryGreen,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Categories Section (Horizontal Scrollable Slider - Blinkit Style)
              Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.categories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                        ),
                      ),
                    );
                  }
                  if (provider.categories.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    color: AppTheme.white,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.black,
                                fontFamily: 'RoundedSans',
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/categories'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View All',
                                    style: TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      fontFamily: 'RoundedSans',
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.categories.length,
                            itemBuilder: (context, index) {
                              final category = provider.categories[index];
                              return _CategorySliderCard(category: category);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Products Section
              Consumer2<ProductProvider, OrderProvider>(
                builder: (context, productProvider, orderProvider, _) {
                  final hasNoAddress = orderProvider.addresses.isEmpty;
                  
                  if (productProvider.isLoading && productProvider.products.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (productProvider.products.isEmpty) {
                    return Container(
                      color: AppTheme.white,
                      padding: const EdgeInsets.all(48.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: AppTheme.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products available',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back soon!',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Container(
                    color: AppTheme.white,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Featured Products',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.black,
                                        fontFamily: 'RoundedSans',
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => context.push('/products'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'View All',
                                        style: TextStyle(
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        // Info message for users without address
                        if (hasNoAddress)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16, top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Add your delivery address to place orders',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: MediaQuery.of(context).size.width < 400 ? 0.68 : 0.70, // Increased to reduce white space below image
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: productProvider.products.length > 4 ? 4 : productProvider.products.length,
                          itemBuilder: (context, index) {
                            final product = productProvider.products[index];
                            return ProductCard(product: product);
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ],
                  ),
                );
              },
            ),
          ),
          // Floating Cart Button (Blinkit Style)
          if (cartProvider.itemCount > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildFloatingCartButton(context, cartProvider),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingCartButton(BuildContext context, CartProvider cartProvider) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/cart'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Cart Icon with Badge
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_cart_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryYellow,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              '${cartProvider.itemCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Cart Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${cartProvider.itemCount} ${cartProvider.itemCount == 1 ? 'item' : 'items'} in cart',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(cartProvider.totalAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // View Cart Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Cart',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppTheme.primaryGreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Category Slider Card (Horizontal Scrollable - Blinkit Style)
class _CategorySliderCard extends StatelessWidget {
  final CategoryModel category;

  const _CategorySliderCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // Reduced icon size to fit in 100px height container
    final iconSize = screenWidth < 360 ? 50.0 : 55.0;
    final fontSize = responsive.fontSize(11);
    
    return GestureDetector(
      onTap: () {
        // Always navigate to category screen - it will handle subcategories
        context.push('/categories/${category.id}/products', extra: {
          'parentCategoryName': category.name,
        });
      },
      child: Container(
        width: 90,
        height: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: category.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        category.imageUrl!,
                        width: iconSize,
                        height: iconSize,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.category,
                          size: responsive.iconSize(24),
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.category,
                      size: responsive.iconSize(24),
                      color: AppTheme.primaryGreen,
                    ),
            ),
            const SizedBox(height: 6),
            // Category Name - Fixed height to prevent overlap
            SizedBox(
              height: 32, // Fixed height to ensure name doesn't overlap
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.black,
                    fontFamily: 'RoundedSans',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

