import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/service_area_provider.dart';
import '../../services/location_onboarding_service.dart';
import '../../utils/theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/product_card.dart';
import '../../widgets/floating_cart_bar.dart';
import '../../models/category_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _hasCheckedServiceAvailability = false; // Prevent multiple checks

  late AnimationController _dateAnimController;
  late Animation<Offset> _dateSlideAnim;
  late Animation<double> _dateFadeAnim;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();

    _dateAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),   // slide-in duration
      reverseDuration: const Duration(milliseconds: 400), // slide-out duration
    );

    _dateSlideAnim = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _dateAnimController,
      curve: Curves.elasticOut,        // bouncy slide-in
      reverseCurve: Curves.easeInBack, // smooth slide-out to the right
    ));

    _dateFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dateAnimController, curve: Curves.easeIn),
    );

    // Trigger pop-in after first frame, hold 1s, then pop-out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playDateAnimation();
      _scheduleMidnightUpdate();
    });

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

  void _playDateAnimation() {
    _dateAnimController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) _dateAnimController.reverse();
      });
    });
  }

  void _scheduleMidnightUpdate() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);

    _midnightTimer = Timer(duration, () {
      if (mounted) {
        setState(() {}); // rebuilds date text with new DateTime.now()
        _playDateAnimation();
        _scheduleMidnightUpdate(); // schedule for the following midnight
      }
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _dateAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Stack(
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
              // Header Section (Blinkit Style: Delivery Info + Search)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    // Top Row: Delivery Time, Address, Profile
                    Consumer<OrderProvider>(
                      builder: (context, orderProvider, _) {
                        final defaultAddress = orderProvider.addresses.isNotEmpty
                            ? orderProvider.addresses.firstWhere(
                                (addr) => addr.isDefault,
                                orElse: () => orderProvider.addresses.first,
                              )
                            : null;
                        
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Brand Header
                                    Row(
                                      children: [
                                        // Logo Icon
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGreen,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.shopping_basket_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Brand Name
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Easy Basket',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                color: AppTheme.black,
                                                height: 1.0,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Address Row with Dropdown
                                    GestureDetector(
                                      onTap: () => context.push(orderProvider.addresses.isEmpty ? '/address/add' : '/addresses'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.lightGrey.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.location_on_rounded, color: AppTheme.primaryGreen, size: 16),
                                            const SizedBox(width: 6),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 160),
                                              child: Text(
                                                defaultAddress != null
                                                    ? defaultAddress.tag != null
                                                        ? '${defaultAddress.tag!.toUpperCase()} - ${defaultAddress.addressLine1}'
                                                        : defaultAddress.addressLine1
                                                    : 'Add delivery address',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.black.withOpacity(0.8),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.black.withOpacity(0.6), size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Profile Icon
                              GestureDetector(
                                onTap: () => context.push('/profile'),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: AppTheme.lightGrey, width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.person_outline_rounded, color: AppTheme.black, size: 26),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Search Bar
                    GestureDetector(
                      onTap: () => context.push('/products'),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: AppTheme.black, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Search "rice"',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const Spacer(),
                            Container(
                                width: 1, 
                                height: 20, 
                                color: Colors.grey.shade300
                            ), // Divider
                            const SizedBox(width: 12),
                             Icon(Icons.mic_none_rounded, color: AppTheme.black, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                              'Shop by category',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.black,
                                letterSpacing: -0.5,
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
                        
                        // Snack it away Section (Horizontal Carousel - Blinkit Style)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0), // Aligned with content
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Snack it away',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.black,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.push('/products'),
                                    child: const Text(
                                      'see all',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0C831F), // Blinkit green
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 290, // Increased height for taller cards (0.55 aspect ratio)
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: productProvider.products.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final product = productProvider.products[index];
                                  return SizedBox(
                                    width: 160, // Fixed width for horizontal cards
                                    child: ProductCard(product: product),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
              const _HomeFooter(),
            ],
                  ),
                );
              },
            ),
          ),
          // Floating Cart Button (Blinkit Style)
          // Date badge — floats at screen level so it slides freely from the right edge
          Positioned(
            right: 0,
            top: 68,
            child: AnimatedBuilder(
              animation: _dateAnimController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_dateSlideAnim.value.dx * 80, 0),
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('d MMM').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const FloatingCartBar(),
          ),
        ],
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
                      child: CachedNetworkImage(
                        imageUrl: category.imageUrl!,
                        width: iconSize,
                        height: iconSize,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
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


class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      color: AppTheme.lightGrey.withOpacity(0.5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTrustBadge(
                context,
                icon: Icons.verified_user_outlined,
                text: '100% Genuine',
              ),
              _buildTrustBadge(
                context,
                icon: Icons.local_shipping_outlined,
                text: 'Fast Delivery',
              ),
              _buildTrustBadge(
                context,
                icon: Icons.refresh_outlined,
                text: 'Easy Returns',
              ),
            ],
          ),
          const SizedBox(height: 32),
          Divider(color: AppTheme.grey.withOpacity(0.2)),
          const SizedBox(height: 24),
          const Text(
            'Live for food, delivered by Easy Basket',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.grey,
              letterSpacing: 0.5,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Made with ',
                style: TextStyle(fontSize: 12, color: AppTheme.grey),
              ),
              const Icon(Icons.favorite, color: Colors.red, size: 14),
              const Text(
                ' in India',
                style: TextStyle(fontSize: 12, color: AppTheme.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Easy Basket © ${DateTime.now().year}',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.grey.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(BuildContext context, {required IconData icon, required String text}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGrey,
          ),
        ),
      ],
    );
  }
}
