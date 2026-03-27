import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/service_area_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/proximity_provider.dart';
import '../../models/address_model.dart';
import '../../utils/theme.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  int? _selectedAddressId;
  bool _isFromCheckout = false; // Track if user came from checkout flow
  bool _isUpdating = false; // Track if updating default address
  bool _isCheckingService = false; // Track if checking service availability
  int? _lastCheckedAddressId; // Track which address was last checked to prevent showing wrong result
  GoRouter? _router; // Store router reference to avoid context issues

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final serviceAreaProvider = Provider.of<ServiceAreaProvider>(context, listen: false);
      
      // Reset service area provider state when screen loads
      // This ensures we don't have stale state from previous checks
      serviceAreaProvider.reset();
      
      // Check if user came from checkout (has items in cart)
      _isFromCheckout = cartProvider.items.isNotEmpty;
      
      if (authProvider.token != null) {
        orderProvider.fetchAddresses(authProvider.token!).then((_) {
          // Auto-select default address (or first address if no default)
          if (orderProvider.addresses.isNotEmpty) {
            final defaultAddress = orderProvider.addresses.firstWhere(
              (addr) => addr.isDefault,
              orElse: () => orderProvider.addresses.first,
            );
            setState(() {
              _selectedAddressId = defaultAddress.id;
            });
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store router reference to avoid context issues in async callbacks
    _router = GoRouter.of(context);
    
    // Reset service area provider and selection when coming back from service not available screen
    // This is called when the route changes (e.g., coming back from another screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final serviceAreaProvider = Provider.of<ServiceAreaProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      
      // CRITICAL: Completely reset service area provider state
      serviceAreaProvider.reset();
      
      // Clear last checked address ID to ensure fresh checks
      _lastCheckedAddressId = null;
      
      // Reset checking state
      _isCheckingService = false;
      
      // Reset selected address to default address when coming back
      // This ensures we don't have stale selection from previous non-serviceable address
      if (orderProvider.addresses.isNotEmpty) {
        final defaultAddress = orderProvider.addresses.firstWhere(
          (addr) => addr.isDefault,
          orElse: () => orderProvider.addresses.first,
        );
        setState(() {
          _selectedAddressId = defaultAddress.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 18),
          ),
        ),
        title: const Text('Choose Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black54),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: (orderProvider.isLoading || _isUpdating || _isCheckingService)
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen)))
          : orderProvider.addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.location_off_outlined, size: 48, color: AppTheme.primaryGreen),
                      ),
                      const SizedBox(height: 16),
                      const Text('No addresses found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('Add a delivery address to get started', style: TextStyle(fontSize: 13, color: AppTheme.grey)),
                      const SizedBox(height: 20),
                      AppTheme.gradientButton(
                        onPressed: () => context.push('/address/add'),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Text('Add Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Use Current Location bar
                    Consumer<LocationProvider>(
                      builder: (context, locationProvider, _) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F9F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.my_location_rounded, color: AppTheme.primaryGreen, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    locationProvider.isPermissionGranted
                                        ? 'Use Current Location'
                                        : 'Use Current Location',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    if (locationProvider.isPermissionGranted) {
                                      // GPS granted — detect and use current location
                                      await locationProvider.detectLocation();
                                      if (mounted && locationProvider.detectedAddress != null) {
                                        final partial = locationProvider.detectedAddress!;
                                        context.push('/address/add', extra: {
                                          'city': partial.city ?? '',
                                          'state': partial.state ?? '',
                                          'pincode': partial.pincode ?? '',
                                          'latitude': partial.latitude.toString(),
                                          'longitude': partial.longitude.toString(),
                                        });
                                      }
                                    } else if (locationProvider.isPermissionPermanentlyDenied) {
                                      await locationProvider.openAppSettings();
                                    } else {
                                      final granted = await locationProvider.requestPermission();
                                      if (granted) {
                                        await locationProvider.detectLocation();
                                        if (mounted && locationProvider.detectedAddress != null) {
                                          final partial = locationProvider.detectedAddress!;
                                          context.push('/address/add', extra: {
                                            'city': partial.city ?? '',
                                            'state': partial.state ?? '',
                                            'pincode': partial.pincode ?? '',
                                            'latitude': partial.latitude.toString(),
                                            'longitude': partial.longitude.toString(),
                                          });
                                        }
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: locationProvider.isPermissionGranted
                                          ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                                          : const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      locationProvider.isPermissionGranted ? 'Use >' : 'Enable >',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: locationProvider.isPermissionGranted
                                            ? AppTheme.primaryGreen
                                            : const Color(0xFF1565C0),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Address count header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          Text('Your Addresses', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.grey)),
                          const Spacer(),
                          Text('${orderProvider.addresses.length} saved', style: TextStyle(fontSize: 11, color: AppTheme.grey)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: orderProvider.addresses.length,
                        itemBuilder: (context, index) {
                          final address = orderProvider.addresses[index];
                          final isSelected = _selectedAddressId == address.id;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF0C831F) : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                if (kDebugMode) {
                                  print('👆 [TAP] User tapped on address ID: ${address.id}, Pincode: ${address.pincode}');
                                  print('📍 Current selected address ID: $_selectedAddressId');
                                  print('📍 Is default: ${address.isDefault}, Is from checkout: $_isFromCheckout');
                                }
                                
                                // If clicking on default address (whether selected or not), check service and navigate
                                if (address.isDefault && !_isFromCheckout) {
                                  if (kDebugMode) {
                                    print('🏠 [TAP] Clicked on default address, checking service availability');
                                  }
                                  
                                  // Check service availability for the default address
                                  final isServiceable = await _checkServiceAvailability(address);
                                  
                                  // CRITICAL: Check if widget is still mounted before using context
                                  if (!mounted) {
                                    if (kDebugMode) {
                                      print('⚠️ [TAP] Widget no longer mounted, skipping navigation');
                                    }
                                    return;
                                  }
                                  
                                  if (isServiceable) {
                                    // Default address is serviceable, navigate to home
                                    if (kDebugMode) {
                                      print('✅ [TAP] Default address is serviceable, navigating to home');
                                    }
                                    
                                    // Update selection to default address
                                    if (mounted) {
                                      setState(() => _selectedAddressId = address.id);
                                    }
                                    
                                    // Navigate to home using router reference to avoid context issues
                                    if (mounted && _router != null) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted && _router != null) {
                                          _router!.go('/home');
                                        }
                                      });
                                    }
                                    return;
                                  } else {
                                    // Default address is not serviceable, service not available screen is already shown
                                    if (kDebugMode) {
                                      print('🚫 [TAP] Default address is not serviceable');
                                    }
                                    return;
                                  }
                                }
                                
                                // IMPORTANT: Check service availability for the CLICKED address, not the selected one
                                // Pass the address object directly to ensure we check the correct one
                                final isServiceable = await _checkServiceAvailability(address);
                                
                                if (!isServiceable) {
                                  // Service not available - screen is already shown
                                  // Don't update selection, keep current selection
                                  if (kDebugMode) {
                                    print('🚫 [TAP] Service not available for clicked address ID: ${address.id}');
                                  }
                                  return;
                                }
                                
                                // Update selection only if serviceable
                                if (kDebugMode) {
                                  print('✅ [TAP] Service available, updating selection to address ID: ${address.id}');
                                }
                                setState(() => _selectedAddressId = address.id);

                                // Sync with AddressProvider — so home screen reflects change
                                Provider.of<AddressProvider>(context, listen: false).selectAddress(address);

                                // If not from checkout, update default and go back
                                if (!_isFromCheckout) {
                                  _updateDefaultAddress(address.id);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Radio / selected indicator
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                        color: isSelected ? const Color(0xFF0C831F) : AppTheme.grey,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Address content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Tag + Default badge row
                                          Row(
                                            children: [
                                              if (address.tag != null) ...[
                                                Icon(
                                                  address.tag == 'home' ? Icons.home_rounded
                                                      : address.tag == 'office' ? Icons.work_rounded
                                                      : Icons.location_on_rounded,
                                                  size: 16,
                                                  color: const Color(0xFF0C831F),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  address.tag!.toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                              if (address.tag == null)
                                                const Text(
                                                  'ADDRESS',
                                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black),
                                                ),
                                              if (address.isDefault) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE8F5E9),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'DEFAULT',
                                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF0C831F)),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          // Full address
                                          Text(
                                            address.fullAddress,
                                            style: TextStyle(fontSize: 13, color: AppTheme.darkGrey, height: 1.4),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Distance badge + Edit button column
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        // Distance badge — shows "2.3 km" from GPS
                                        Consumer<LocationProvider>(
                                          builder: (context, locationProvider, _) {
                                            if (!locationProvider.isPermissionGranted ||
                                                locationProvider.currentPosition == null ||
                                                address.latitude == null ||
                                                address.longitude == null) {
                                              return const SizedBox.shrink();
                                            }
                                            final proximityProvider = Provider.of<ProximityProvider>(context, listen: false);
                                            final dist = proximityProvider.getDistanceKm(
                                              locationProvider.currentPosition!,
                                              address,
                                            );
                                            if (dist == null) return const SizedBox.shrink();
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: dist < 5
                                                    ? const Color(0xFFE8F5E9)
                                                    : dist < 20
                                                        ? const Color(0xFFFFF8E1)
                                                        : const Color(0xFFFFEBEE),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                dist < 1
                                                    ? '${(dist * 1000).toStringAsFixed(0)}m'
                                                    : '${dist.toStringAsFixed(1)} km',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: dist < 5
                                                      ? AppTheme.primaryGreen
                                                      : dist < 20
                                                          ? const Color(0xFFF57C00)
                                                          : const Color(0xFFE53935),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        if (!_isFromCheckout) ...[
                                          const SizedBox(height: 8),
                                          // Edit button
                                          GestureDetector(
                                            onTap: () => context.push('/address/edit', extra: address),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF5F5F5),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.grey),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Bottom buttons
                    SafeArea(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Add New Address button
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/address/add'),
                                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                                label: const Text('Add New Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0C831F),
                                  side: const BorderSide(color: Color(0xFF0C831F), width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            // Continue to Payment (only from checkout)
                            if (_isFromCheckout && _selectedAddressId != null) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: AppTheme.gradientButton(
                                  onPressed: _isCheckingService ? null : () async {
                                    if (_selectedAddressId != null) {
                                      final selectedAddress = orderProvider.addresses.firstWhere(
                                        (addr) => addr.id == _selectedAddressId,
                                      );
                                      final isServiceable = await _checkServiceAvailability(selectedAddress);
                                      if (isServiceable && mounted) {
                                        context.push('/payment', extra: _selectedAddressId);
                                      }
                                    }
                                  },
                                  height: 48,
                                  child: _isCheckingService
                                      ? const SizedBox(
                                          height: 20, width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                        )
                                      : const Text('Continue to Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  /// Check service availability for an address
  Future<bool> _checkServiceAvailability(AddressModel address) async {
    // CRITICAL: Get fresh provider instance to avoid any cached state
    final serviceAreaProvider = Provider.of<ServiceAreaProvider>(context, listen: false);
    
    // CRITICAL: Reset provider state before checking to ensure fresh check
    // This is critical to avoid showing cached results from previous checks
    serviceAreaProvider.reset();
    
    // Wait a moment to ensure reset completes and any pending operations finish
    await Future.delayed(const Duration(milliseconds: 150));
    
    setState(() => _isCheckingService = true);
    
    // Store the address ID and pincode we're checking to verify we got the right result
    final checkingAddressId = address.id;
    final checkingPincode = address.pincode.trim().replaceAll(' ', '');
    
    if (kDebugMode) {
      print('🔍 [CHECK START] Starting fresh check for Address ID: $checkingAddressId, Pincode: $checkingPincode');
    }
    
    try {
      if (kDebugMode) {
        print('🔍 [CHECK START] Address ID: $checkingAddressId, Pincode: $checkingPincode');
        print('📍 Address: ${address.addressLine1}, ${address.city}, ${address.state}');
      }
      
      // Make the API call with the exact pincode from the address
      final isAvailable = await serviceAreaProvider.checkServiceAvailability(
        pincode: checkingPincode,
        country: 'India',
      );
      
      setState(() => _isCheckingService = false);
      
      if (kDebugMode) {
        print('🔍 [CHECK RESULT] Address ID: $checkingAddressId, Pincode: $checkingPincode, Available: $isAvailable');
      }
      
      // Verify we got the result for the correct address
      // Double-check the provider state matches what we checked
      if (kDebugMode) {
        final serviceAreaInfo = serviceAreaProvider.serviceAreaInfo;
        if (serviceAreaInfo != null) {
          final checkedPincode = serviceAreaInfo['pincode'] as String?;
          if (checkedPincode != null && checkedPincode != checkingPincode) {
            print('⚠️ [WARNING] Pincode mismatch! Checked: $checkingPincode, Result: $checkedPincode');
          }
        }
      }
      
      if (!isAvailable && mounted) {
        // Store the address ID we just checked (before navigation)
        _lastCheckedAddressId = checkingAddressId;
        
        // Show service not available screen with the CORRECT address details
        if (kDebugMode) {
          print('🚫 [NAVIGATING] Service not available for Address ID: $checkingAddressId');
          print('📍 Showing service not available for: ${address.city}, ${address.state}, $checkingPincode');
        }
        
        // Navigate immediately - don't wait for post-frame callback
        try {
          context.push(
            '/service-not-available',
            extra: {
              'pincode': checkingPincode,
              'city': address.city,
              'state': address.state,
              'country': 'India',
              'returnTo': _isFromCheckout ? '/addresses' : '/home',
            },
          );
          if (kDebugMode) {
            print('✅ [NAVIGATED] Service not available screen for Address ID: $checkingAddressId, Pincode: $checkingPincode');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ [NAV ERROR] Navigation error: $e');
          }
          // Fallback: show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Service not available in this area. Please select a different address.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
        return false;
      }
      
      if (kDebugMode && isAvailable) {
        print('✅ [SUCCESS] Service is available for Address ID: $checkingAddressId, Pincode: $checkingPincode');
      }
      
      return isAvailable;
    } catch (e) {
      setState(() => _isCheckingService = false);
      if (kDebugMode) {
        print('❌ [ERROR] Error checking service availability for Address ID: $checkingAddressId, Pincode: $checkingPincode');
        print('❌ [ERROR] Exception: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking service availability: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _updateDefaultAddress(int addressId) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.token == null) return;
    
    final address = orderProvider.addresses.firstWhere(
      (addr) => addr.id == addressId,
    );
    
    // If address is already default, verify it's serviceable and navigate to home
    if (address.isDefault) {
      // Double-check service availability for the default address
      // This ensures we check the correct address even after returning from service not available
      final isServiceable = await _checkServiceAvailability(address);
      
      // CRITICAL: Check if widget is still mounted before using context
      if (!mounted) {
        if (kDebugMode) {
          print('⚠️ [UPDATE] Widget no longer mounted, skipping navigation');
        }
        return;
      }
      
      if (isServiceable) {
        // Default address is serviceable, navigate to home
        if (kDebugMode) {
          print('✅ [UPDATE] Default address is serviceable, navigating to home');
        }
        
        // Navigate to home using router reference to avoid context issues
        if (mounted && _router != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _router != null) {
              _router!.go('/home');
            }
          });
        }
      } else {
        // Default address is not serviceable, service not available screen is already shown
        if (kDebugMode) {
          print('🚫 [UPDATE] Default address is not serviceable');
        }
      }
      return;
    }
    
    // Note: Service availability was already checked before calling this method
    // So we don't need to check again here to avoid double checking
    // The check happens in onTap/onChanged before calling this method
    
    // Only update if not already default
    if (!address.isDefault) {
      setState(() => _isUpdating = true);
      final success = await orderProvider.updateAddress(
        token: authProvider.token!,
        addressId: addressId,
        isDefault: true,
      );
      setState(() => _isUpdating = false);
      
      if (success && mounted) {
        // Reset proximity so home screen re-checks with new address
        Provider.of<ProximityProvider>(context, listen: false).reset();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default address updated'),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.pop();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.error ?? 'Failed to update address'),
          ),
        );
      }
    } else {
      // Already default, just go back after a brief moment
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        context.pop();
      }
    }
  }
}
