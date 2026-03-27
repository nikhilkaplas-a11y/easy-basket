import 'dart:async';
import 'dart:math';
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
import '../../providers/location_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/proximity_provider.dart';
import '../../models/proximity_result.dart';
import '../../services/location_onboarding_service.dart';
import '../../utils/theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/product_card.dart';
import '../../widgets/floating_cart_bar.dart';
import '../../widgets/active_order_bar.dart';
import '../../widgets/smart_suggestion_banner.dart';
import '../../models/category_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _hasCheckedServiceAvailability = false; // Prevent multiple checks

  // Product cards auto-scroll
  final ScrollController _productScrollController = ScrollController();
  Timer? _autoScrollTimer;

  // Search hint flip animation
  late AnimationController _searchFlipController;
  late Animation<double> _searchFlipAnim;
  Timer? _searchHintTimer;
  int _currentHintIndex = 0;
  final List<String> _searchHints = [
    'Search "rice"',
    'Search "milk"',
    'Search "atta"',
    'Search "ghee"',
    'Search "sugar"',
    'Search "dal"',
    'Search "bread"',
    'Search "eggs"',
  ];

  @override
  void initState() {
    super.initState();

    // Search hint 3D flip animation
    _searchFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _searchFlipAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchFlipController, curve: Curves.easeInOut),
    );
    _startSearchHintRotation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      productProvider.fetchCategories();
      // limit: 15 → sirf 15 products fetch karo (snack it away section ke liye)
      // Kyun: 568 products fetch karna sirf 15 dikhane ke liye = 95% data waste
      productProvider.fetchProducts(limit: 15).then((_) {
        if (mounted) _startAutoScroll();
      });
      
      // Fetch orders and run smart address detection if authenticated
      if (authProvider.token != null) {
        // 1. Fetch active orders (lightweight — for active order bar)
        orderProvider.fetchActiveOrders(authProvider.token!, getUpdatedToken: () => authProvider.token);

        // 2. Smart address flow — GPS detect + saved addresses + proximity check
        _initSmartAddressFlow(authProvider.token!);
      }
    });
  }

  /// Smart Address Flow — The main address initialization method
  ///
  /// Flow:
  /// 1. Start GPS detection (LocationProvider) — runs in background
  /// 2. Fetch saved addresses (AddressProvider) — API call
  /// 3. When BOTH ready → run proximity check (ProximityProvider)
  /// 4. Based on decision:
  ///    - autoSelect → select nearest address, no interruption
  ///    - warn → select nearest + show warning banner
  ///    - forceNew → show partial address, ask at checkout
  ///    - noGps → use default saved address
  /// 5. Service area check for selected address
  Future<void> _initSmartAddressFlow(String token) async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    final proximityProvider = Provider.of<ProximityProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Step 1 & 2: Run GPS detection and address fetch in PARALLEL
    // Why parallel? GPS takes 2-3 sec, API takes 1 sec — don't wait sequentially
    // Always force fresh GPS detect — user might have moved
    // Fetch addresses ONCE via addressProvider, then sync to orderProvider
    await Future.wait([
      locationProvider.detectLocation(force: true),
      addressProvider.fetchAddresses(token),
    ]);
    // Sync addresses to OrderProvider (backward compatibility — no extra API call)
    if (mounted) {
      orderProvider.syncAddresses(addressProvider.addresses);
    }

    if (!mounted) return;

    // Step 3: New user check — no saved addresses
    if (!addressProvider.hasAddresses) {
      // New user — DON'T redirect to full form
      // Just show partial address from GPS on home screen
      // Full address will be asked at checkout via bottom sheet
      final partial = locationProvider.detectedAddress;
      if (partial != null) {
        // Set partial address in proximity provider for home header
        proximityProvider.checkProximity(
          locationProvider: locationProvider,
          addressProvider: addressProvider,
        );
        debugPrint('🏠 [Home] New user — showing partial: ${partial.displayName}');
      }
      return;
    }

    // Step 4: Run proximity check — GPS vs saved addresses (always force fresh)
    proximityProvider.checkProximity(
      locationProvider: locationProvider,
      addressProvider: addressProvider,
      force: true,
    );

    // Step 5: Act on decision
    final result = proximityProvider.result;
    if (result != null) {
      switch (result.decision) {
        case ProximityDecision.autoSelect:
          // User is near a saved address — auto-select it
          if (result.nearestAddress != null) {
            addressProvider.selectAddress(result.nearestAddress!);
          }
          debugPrint('🏠 [Home] Auto-selected: ${result.nearestAddress?.tag}');
          break;

        case ProximityDecision.warn:
          // User is somewhat far — select nearest but show warning
          if (result.nearestAddress != null) {
            addressProvider.selectAddress(result.nearestAddress!);
          }
          debugPrint('🏠 [Home] Warning: ${result.warningText}');
          // Warning banner will show automatically via Consumer in build()
          break;

        case ProximityDecision.forceNew:
          // User is in different city — show mismatch screen
          debugPrint('🏠 [Home] Force new: user in different city');
          if (mounted) {
            // Delay to let home screen render first
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) context.push('/location-mismatch');
            });
          }
          break;

        case ProximityDecision.noGps:
          // No GPS — use default saved address (current behavior)
          final defaultAddr = addressProvider.defaultAddress;
          if (defaultAddr != null) {
            addressProvider.selectAddress(defaultAddr);
          }
          debugPrint('🏠 [Home] No GPS — using default address');
          break;
      }
    }

    // Step 6: Service area check for selected/default address
    _checkSelectedAddressServiceAvailability(addressProvider);
  }

  /// Check if selected address is serviceable
  /// If NOT → check current GPS location pincode
  /// If GPS pincode serviceable → switch to partial address
  /// If neither → show "we don't deliver here"
  Future<void> _checkSelectedAddressServiceAvailability(AddressProvider addressProvider) async {
    if (_hasCheckedServiceAvailability) return;

    final address = addressProvider.selectedAddress ?? addressProvider.defaultAddress;
    if (address == null) return;

    _hasCheckedServiceAvailability = true;
    final serviceAreaProvider = Provider.of<ServiceAreaProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final proximityProvider = Provider.of<ProximityProvider>(context, listen: false);

    try {
      // Step 1: Check saved/selected address
      final isAvailable = await serviceAreaProvider.checkServiceAvailability(
        pincode: address.pincode,
        country: 'India',
      );

      debugPrint('🏠 [Home] Service check for saved ${address.pincode}: $isAvailable');

      if (isAvailable) return; // Saved address is serviceable — all good

      // Step 2: Saved address NOT serviceable — check current GPS location
      final partial = locationProvider.detectedAddress;
      debugPrint('🏠 [Home] GPS partial address: ${partial?.fullDisplay ?? "NULL — geocode may have failed"}');
      debugPrint('🏠 [Home] GPS position: ${locationProvider.currentPosition?.latitude}, ${locationProvider.currentPosition?.longitude}');
      if (partial?.pincode != null && partial!.pincode!.isNotEmpty) {
        final gpsServiceable = await serviceAreaProvider.checkServiceAvailability(
          pincode: partial.pincode!,
          country: 'India',
        );

        debugPrint('🏠 [Home] Service check for GPS ${partial.pincode}: $gpsServiceable');

        if (gpsServiceable && mounted) {
          // Current GPS location IS serviceable — switch to partial address
          // Deselect saved address, show partial in header
          addressProvider.selectAddress(address); // keep reference but proximity shows warning
          proximityProvider.checkProximity(
            locationProvider: locationProvider,
            addressProvider: addressProvider,
            force: true,
          );
          // Show snackbar informing user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Your saved address (${address.city}) is not serviceable. Using current location.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      // Step 3: Neither serviceable — show "not available" screen
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/service-not-available', extra: {
            'pincode': address.pincode,
            'city': address.city,
            'state': address.state,
            'country': 'India',
            'returnTo': '/home',
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [Home] Service check error: $e');
    }
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

  void _startSearchHintRotation() {
    _searchHintTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;

      // Text halfway (0.5) pe change karo — jab text sideways hai aur dikhta nahi
      // Kyun: Agar forward complete hone ke baad change karo toh briefly purana text flash hota hai
      bool hasChanged = false;
      void listener(AnimationStatus status) {
        // Jab forward animation chal rahi hai aur halfway cross ho jaye → text change karo
      }

      _searchFlipController.forward().then((_) {
        if (!mounted) return;
        // Forward complete — ab text change karo (agar halfway pe nahi hua)
        if (!hasChanged) {
          setState(() {
            _currentHintIndex = (_currentHintIndex + 1) % _searchHints.length;
          });
        }
        // Reverse — naya text flip hoke aata hai
        _searchFlipController.reverse();
      });

      // Halfway pe text change karo
      late VoidCallback halfwayListener;
      halfwayListener = () {
        if (_searchFlipAnim.value >= 0.5 && !hasChanged) {
          hasChanged = true;
          if (mounted) {
            setState(() {
              _currentHintIndex = (_currentHintIndex + 1) % _searchHints.length;
            });
          }
          _searchFlipAnim.removeListener(halfwayListener);
        }
      };
      _searchFlipAnim.addListener(halfwayListener);
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_productScrollController.hasClients) return;
      final maxScroll = _productScrollController.position.maxScrollExtent;
      final currentScroll = _productScrollController.offset;
      final nextScroll = currentScroll + 180; // scroll by ~1 card width

      if (nextScroll >= maxScroll) {
        // Scroll back to start
        _productScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        _productScrollController.animateTo(
          nextScroll,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchHintTimer?.cancel();
    _autoScrollTimer?.cancel();
    _searchFlipController.dispose();
    _productScrollController.dispose();
    super.dispose();
  }

  /// Generates white bokeh dots — small, clustered in the green (top-left) area
  List<Widget> _buildSparkles() {
    final rng = Random(42); // fixed seed for consistent layout
    return List.generate(45, (i) {
      final size = 3.0 + rng.nextDouble() * 8; // 3–11px (smaller)
      // Concentrate in top-left: bias toward lower values
      final top = rng.nextDouble() * rng.nextDouble() * 200; // clustered toward top
      final left = rng.nextDouble() * rng.nextDouble() * 300; // clustered toward left
      final opacity = 0.3 + rng.nextDouble() * 0.5; // 0.3–0.8 (more visible)
      return Positioned(
        top: top,
        left: left,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: opacity * 0.5),
                blurRadius: size,
                spreadRadius: size * 0.2,
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Stack(
        children: [
          // Green gradient behind status bar + header area
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 123, 226, 127).withValues(alpha: 0.15),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.6],
              ),
            ),
          ),
          SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
            onRefresh: () async {
              final productProvider = Provider.of<ProductProvider>(context, listen: false);
              final orderProvider = Provider.of<OrderProvider>(context, listen: false);
              await productProvider.fetchCategories();
              await productProvider.fetchProducts();
              if (authProvider.token != null) {
                // Reset and re-run smart address flow on pull-to-refresh
                final proximityProvider = Provider.of<ProximityProvider>(context, listen: false);
                final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                locationProvider.reset();
                proximityProvider.reset();
                _hasCheckedServiceAvailability = false;
                await _initSmartAddressFlow(authProvider.token!);
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
              // Header Section — white card on top of green gradient bg
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 6,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                  children: [
                    // Top Row: Brand, Address, Profile
                    Consumer2<AddressProvider, ProximityProvider>(
                      builder: (context, addressProvider, proximityProvider, _) {
                        // Decide what address text to show
                        final selectedAddr = addressProvider.selectedAddress;
                        final partial = proximityProvider.partialAddress;

                        // Two-line address display (matches UI design)
                        // Line 1: Label (CURRENT LOCATION / HOME ✓)
                        // Line 2: Address text (Sector 70, Mohali / 856, Doctor Goyal St)
                        String label;
                        String addressLine;
                        bool hasCheckmark = false;

                        if (selectedAddr != null) {
                          label = selectedAddr.tag?.toUpperCase() ?? 'ADDRESS';
                          hasCheckmark = true;
                          addressLine = '${selectedAddr.addressLine1}'
                              '${selectedAddr.addressLine2 != null ? ', ${selectedAddr.addressLine2}' : ''}'
                              ', ${selectedAddr.city}';
                        } else if (partial != null) {
                          label = 'CURRENT LOCATION';
                          addressLine = partial.displayName;
                        } else {
                          label = '';
                          addressLine = 'Add delivery address';
                        }

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
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGreen,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
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
                                    const SizedBox(height: 12),
                                    // Address Card — Two line layout (matches Blinkit UI)
                                    // Line 1: 📍 CURRENT LOCATION / HOME ✓
                                    // Line 2: Sector 70, Mohali / 856, Doctor Goyal St
                                    GestureDetector(
                                      onTap: () => context.push(
                                        addressProvider.hasAddresses ? '/addresses' : '/address/add',
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppTheme.lightGrey.withValues(alpha: 0.5),
                                              Colors.white.withValues(alpha: 0.8),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_rounded,
                                              color: AppTheme.primaryGreen,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Label row: CURRENT LOCATION / HOME ✓
                                                  if (label.isNotEmpty)
                                                    Row(
                                                      children: [
                                                        Text(
                                                          label,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w700,
                                                            color: AppTheme.primaryGreen,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                        if (hasCheckmark) ...[
                                                          const SizedBox(width: 4),
                                                          Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 14),
                                                        ],
                                                      ],
                                                    ),
                                                  // Address text
                                                  Text(
                                                    addressLine,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppTheme.black,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.chevron_right_rounded, color: AppTheme.black.withValues(alpha: 0.4), size: 22),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/profile'),
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 14,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 5),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.person_outline_rounded, color: AppTheme.black, size: 26),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Warning Banner — shows when user is 5-20km from saved address
                    // UI: Warning icon + text on top row
                    //     [Use Current Location]  [Continue Anyway] on bottom row
                    Consumer<ProximityProvider>(
                      builder: (context, proximityProvider, _) {
                        if (!proximityProvider.showWarning) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFF8E1), Color(0xFFFFFDE7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFFE082), width: 1),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFFFFE082).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row — warning icon + text
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFF57C00), size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        proximityProvider.warningText,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF57C00)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Bottom row — two action buttons
                                Row(
                                  children: [
                                    // Use Current Location button
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          // Navigate to add address with GPS pre-fill
                                          final partial = proximityProvider.partialAddress;
                                          final extra = <String, dynamic>{};
                                          if (partial != null) {
                                            extra['city'] = partial.city ?? '';
                                            extra['state'] = partial.state ?? '';
                                            extra['pincode'] = partial.pincode ?? '';
                                            extra['latitude'] = partial.latitude.toString();
                                            extra['longitude'] = partial.longitude.toString();
                                          }
                                          context.push('/address/add', extra: extra);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFE0E0E0)),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'Use Current Location',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Continue Anyway button
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => proximityProvider.dismissWarning(),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFE0E0E0)),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'Continue Anyway',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Enable Location Banner — shows when GPS permission denied
                    Consumer<ProximityProvider>(
                      builder: (context, proximityProvider, _) {
                        if (!proximityProvider.showEnableLocationBanner) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: GestureDetector(
                            onTap: () async {
                              final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                              if (locationProvider.isPermissionPermanentlyDenied) {
                                await locationProvider.openAppSettings();
                              } else {
                                final granted = await locationProvider.requestPermission();
                                if (granted && mounted) {
                                  // Permission granted — re-run smart flow
                                  locationProvider.reset();
                                  proximityProvider.reset();
                                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                  if (authProvider.token != null) {
                                    _hasCheckedServiceAvailability = false;
                                    _initSmartAddressFlow(authProvider.token!);
                                  }
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE3F2FD), Color(0xFFEBF5FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF90CAF9), width: 1),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF90CAF9).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.my_location_rounded, color: Color(0xFF1565C0), size: 20),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Enable location for faster delivery',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1565C0)),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1565C0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('Enable', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Smart Suggestion Banner (Phase 3)
                    // Shows time-based suggestions: "Heading to office?" / "Back home?"
                    const SmartSuggestionBanner(),

                    // Search Bar
                    GestureDetector(
                      onTap: () => context.push('/products'),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 14,
                              spreadRadius: 1,
                              offset: const Offset(0, 5),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppTheme.black, size: 24),
                            const SizedBox(width: 12),
                            AnimatedBuilder(
                              animation: _searchFlipAnim,
                              builder: (context, child) {
                                // 3D flip: rotate around X axis
                                final angle = _searchFlipAnim.value * pi;
                                return Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.002) // perspective
                                    ..rotateX(angle),
                                  child: _searchFlipAnim.value <= 0.5
                                      ? Text(
                                          _searchHints[_currentHintIndex],
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        )
                                      : Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()..rotateX(pi),
                                          child: Text(
                                            _searchHints[_currentHintIndex],
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                );
                              },
                            ),
                            const Spacer(),
                            Container(width: 1, height: 20, color: Colors.grey.shade300),
                            const SizedBox(width: 12),
                            const Icon(Icons.mic_none_rounded, color: AppTheme.black, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFB9E5B8).withValues(alpha: 0.6),
                          const Color(0xFFD4EDC9).withValues(alpha: 0.4),
                          const Color(0xFFECF6E5).withValues(alpha: 0.15),
                          Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.2, 0.5, 0.8],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Sparkle dots
                        ..._buildSparkles(),
                        // Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'View All',
                                          style: TextStyle(
                                            color: AppTheme.primaryGreen,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(Icons.arrow_forward_ios, size: 13, color: AppTheme.primaryGreen),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // 2 rows × 4 columns grid
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: provider.categories.length > 8 ? 8 : provider.categories.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.75,
                                ),
                                itemBuilder: (context, index) {
                                  final category = provider.categories[index];
                                  return _CategoryGridCard(category: category);
                                },
                              ),
                            ],
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
                  // Check saved addresses + partial GPS address + AddressProvider
                  // If ANY address exists (saved or partial), don't show "add address" box
                  final proximityProv = Provider.of<ProximityProvider>(context);
                  final addrProv = Provider.of<AddressProvider>(context);
                  final hasNoAddress = orderProvider.addresses.isEmpty
                      && !addrProv.hasAddresses
                      && proximityProv.partialAddress == null;
                  
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
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.grey.withValues(alpha: 0.03),
                          Colors.grey.withValues(alpha: 0.03),
                          Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info message for users without address
                        if (hasNoAddress)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16, top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
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
                        const SizedBox(height: 4),

                        // Snack it away Section (Horizontal Carousel - Blinkit Style)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0, right: 4.0),
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
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'see all',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0C831F),
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(Icons.arrow_forward_ios, size: 13, color: Color(0xFF0C831F)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Builder(
                              builder: (context) {
                                final inStockProducts = productProvider.products.where((p) =>
                                  p.isAvailable &&
                                  ((p.hasVariants && p.variants != null && p.variants!.any((v) => v.isAvailable && v.stock > 0)) ||
                                   (!p.hasVariants && p.stock > 0))
                                ).toList();
                                return SizedBox(
                                  height: 240,
                                  child: ListView.separated(
                                    controller: _productScrollController,
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    itemCount: inStockProducts.length,
                                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      return SizedBox(
                                        width: 175,
                                        child: ProductCard(product: inStockProducts[index]),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
          // Bottom bars — Cart bar + Active order bar dono dikhenge
          // Cart bar upar, Active order bar neeche
          // Kyun: User ko dono info chahiye — cart mein kya hai + order ka status
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                FloatingCartBar(),     // Cart bar — upar
                ActiveOrderBar(),      // Active orders — neeche
              ],
            ),
          ),
        ],
      ),
    ),
    ],
    ),
  );
}

}

// Category Grid Card — 2 rows × 4 columns, dark highlighted background
class _CategoryGridCard extends StatelessWidget {
  final CategoryModel category;

  const _CategoryGridCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/categories/${category.id}/products', extra: {
          'parentCategoryName': category.name,
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: category.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: category.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                          child: const Icon(Icons.category, size: 28, color: AppTheme.primaryGreen),
                        ),
                      )
                    : Container(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                        child: const Icon(Icons.category, size: 28, color: AppTheme.primaryGreen),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.black,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
      color: AppTheme.lightGrey.withValues(alpha: 0.15),
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
          const SizedBox(height: 6),
          Divider(color: AppTheme.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 6),
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
          const SizedBox(height: 2),
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
          const SizedBox(height: 2),
          Text(
            'Easy Basket © ${DateTime.now().year}',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.grey.withValues(alpha: 0.7),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
        ),
        const SizedBox(height: 4),
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
