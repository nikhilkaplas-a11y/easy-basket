import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/service_area_provider.dart';
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
      appBar: AppBar(
        title: const Text('Select Address'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/address/add'),
          ),
        ],
      ),
      body: (orderProvider.isLoading || _isUpdating || _isCheckingService)
          ? const Center(child: CircularProgressIndicator())
          : orderProvider.addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 100, color: AppTheme.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No addresses found',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.grey,
                          fontFamily: 'RoundedSans',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/address/add'),
                        child: const Text('Add Address'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orderProvider.addresses.length,
                        itemBuilder: (context, index) {
                          final address = orderProvider.addresses[index];
                          final isSelected = _selectedAddressId == address.id;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSelected ? AppTheme.primaryGreen.withOpacity(0.1) : null,
                            child: InkWell(
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
                                
                                // If not from checkout, update default and go back
                                if (!_isFromCheckout) {
                                  _updateDefaultAddress(address.id);
                                }
                              },
                              child: ListTile(
                                leading: Radio<int>(
                                  value: address.id,
                                  groupValue: _selectedAddressId,
                                  onChanged: (value) async {
                                    if (value == null) return;
                                    
                                    if (kDebugMode) {
                                      print('🔘 [RADIO] User selected address ID: $value');
                                      print('📍 Current selected address ID: $_selectedAddressId');
                                    }
                                    
                                    // Find the CLICKED address
                                    final clickedAddress = orderProvider.addresses.firstWhere(
                                      (addr) => addr.id == value,
                                    );
                                    
                                    if (kDebugMode) {
                                      print('🔘 [RADIO] Checking service for clicked address ID: ${clickedAddress.id}, Pincode: ${clickedAddress.pincode}');
                                      print('🔘 [RADIO] Is default: ${clickedAddress.isDefault}, Is from checkout: $_isFromCheckout');
                                    }
                                    
                                    // If clicking on default address and not from checkout, check service and navigate to home
                                    if (clickedAddress.isDefault && !_isFromCheckout) {
                                      final isServiceable = await _checkServiceAvailability(clickedAddress);
                                      
                                      // CRITICAL: Check if widget is still mounted before using context
                                      if (!mounted) {
                                        if (kDebugMode) {
                                          print('⚠️ [RADIO] Widget no longer mounted, skipping navigation');
                                        }
                                        return;
                                      }
                                      
                                      if (isServiceable) {
                                        // Default address is serviceable, navigate to home
                                        if (kDebugMode) {
                                          print('✅ [RADIO] Default address is serviceable, navigating to home');
                                        }
                                        if (mounted) {
                                          setState(() => _selectedAddressId = value);
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
                                          print('🚫 [RADIO] Default address is not serviceable');
                                        }
                                        return;
                                      }
                                    }
                                    
                                    // Check service availability for the CLICKED address
                                    final isServiceable = await _checkServiceAvailability(clickedAddress);
                                    
                                    if (!isServiceable) {
                                      // Service not available - screen is already shown
                                      // Don't update selection, keep current selection
                                      if (kDebugMode) {
                                        print('🚫 [RADIO] Service not available for clicked address ID: ${clickedAddress.id}');
                                      }
                                      return;
                                    }
                                    
                                    // Update selection only if serviceable
                                    if (kDebugMode) {
                                      print('✅ [RADIO] Service available, updating selection to address ID: $value');
                                    }
                                    setState(() => _selectedAddressId = value);
                                    
                                    // If not from checkout, update default immediately
                                    if (!_isFromCheckout) {
                                      _updateDefaultAddress(value);
                                    }
                                  },
                                ),
                                title: Row(
                                  children: [
                                    if (address.tag != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          address.tag!.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryGreen,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      address.isDefault ? 'Default Address' : 'Address',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  address.fullAddress,
                                ),
                                trailing: _isFromCheckout
                                    ? null
                                    : const Icon(Icons.chevron_right, color: AppTheme.grey),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Only show "Continue to Payment" button if:
                    // 1. User came from checkout flow (has items in cart)
                    // 2. An address is selected
                    if (_isFromCheckout && _selectedAddressId != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isCheckingService ? null : () async {
                                // Check service availability before proceeding to payment
                                if (_selectedAddressId != null) {
                                  final selectedAddress = orderProvider.addresses.firstWhere(
                                    (addr) => addr.id == _selectedAddressId,
                                  );
                                  
                                  final isServiceable = await _checkServiceAvailability(selectedAddress);
                                  
                                  if (isServiceable) {
                                    if (mounted) {
                                      context.push('/payment', extra: _selectedAddressId);
                                    }
                                  }
                                }
                              },
                              child: _isCheckingService
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                      ),
                                    )
                                  : const Text('Continue to Payment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: AppTheme.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default address updated'),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        // Small delay to show the update, then go back
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

