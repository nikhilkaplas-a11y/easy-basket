import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_area_provider.dart';
import '../../utils/theme.dart';

/// Screen shown to new users to automatically detect their location
/// Similar to Blinkit/Zomato onboarding flow
class LocationDetectionScreen extends StatefulWidget {
  const LocationDetectionScreen({super.key});

  @override
  State<LocationDetectionScreen> createState() => _LocationDetectionScreenState();
}

class _LocationDetectionScreenState extends State<LocationDetectionScreen> {
  bool _isDetecting = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _detectedCity;
  String? _detectedState;
  String? _detectedPincode;
  double? _latitude;
  double? _longitude;
  String? _addressLine1;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isDetecting = true;
      _hasError = false;
      _errorMessage = null;
    });

    if (kIsWeb) {
      setState(() {
        _isDetecting = false;
        _hasError = true;
        _errorMessage = 'Location detection is not available on web. Please add address manually.';
      });
      return;
    }

    try {
      // Request location permission
      final status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() {
          _isDetecting = false;
          _hasError = true;
          _errorMessage = 'Location permission is required to detect your delivery area.';
        });
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isDetecting = false;
          _hasError = true;
          _errorMessage = 'Please enable location services in your device settings.';
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        setState(() {
          _isDetecting = false;
          _hasError = true;
          _errorMessage = 'Could not detect your location. Please add address manually.';
        });
        return;
      }

      final place = placemarks.first;

      // Extract address components (India-specific)
      String? city = place.locality?.trim() ?? 
                     place.subAdministrativeArea?.trim() ?? 
                     place.subLocality?.trim();
      
      String? state = place.administrativeArea?.trim();
      String? pincode = place.postalCode?.trim();
      
      // Clean pincode (remove non-digits)
      if (pincode != null && pincode.isNotEmpty) {
        pincode = pincode.replaceAll(RegExp(r'[^0-9]'), '');
      }

      // Build address line 1
      final addressParts = <String>[];
      if (place.street != null && place.street!.isNotEmpty) {
        addressParts.add(place.street!);
      }
      if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
        addressParts.add(place.subThoroughfare!);
      }
      if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
        addressParts.add(place.thoroughfare!);
      }
      final addressLine1 = addressParts.isNotEmpty 
          ? addressParts.join(', ')
          : (city ?? 'Your Location');

      setState(() {
        _detectedCity = city;
        _detectedState = state;
        _detectedPincode = pincode;
        _addressLine1 = addressLine1;
        _isDetecting = false;
      });

      // Check service availability for detected pincode
      if (pincode != null && pincode.isNotEmpty) {
        final serviceAreaProvider = Provider.of<ServiceAreaProvider>(context, listen: false);
        await serviceAreaProvider.checkServiceAvailability(
          pincode: pincode,
          country: 'India',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error detecting location: $e');
      }
      setState(() {
        _isDetecting = false;
        _hasError = true;
        _errorMessage = 'Error detecting location. Please try again or add address manually.';
      });
    }
  }

  Future<void> _confirmAndSave() async {
    if (_latitude == null || _longitude == null || _detectedPincode == null) {
      return;
    }

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serviceAreaProvider = Provider.of<ServiceAreaProvider>(context, listen: false);

    if (authProvider.token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
      }
      return;
    }

    // Check service availability one more time
    final isAvailable = serviceAreaProvider.isServiceAvailable ?? false;
    if (!isAvailable) {
      if (mounted) {
        context.push('/service-not-available', extra: {
          'pincode': _detectedPincode,
          'city': _detectedCity,
          'state': _detectedState,
          'country': 'India',
        });
      }
      return;
    }

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // Save the detected address as default
      final success = await orderProvider.createAddress(
        token: authProvider.token!,
        addressLine1: _addressLine1 ?? 'Your Location',
        city: _detectedCity ?? '',
        state: _detectedState ?? '',
        pincode: _detectedPincode!,
        isDefault: true,
        latitude: _latitude!.toString(),
        longitude: _longitude!.toString(),
        tag: 'home',
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          // Navigate to home
          context.go('/home');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Location saved! Start shopping now.'),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderProvider.error ?? 'Failed to save location'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isDetecting ? Icons.my_location : Icons.location_on,
                  size: 64,
                  color: AppTheme.primaryGreen,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                _isDetecting 
                    ? 'Detecting your location...'
                    : _hasError
                        ? 'Location Detection'
                        : 'We found your location!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.black,
                    ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Loading or Error or Success
              if (_isDetecting)
                Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please wait while we detect your delivery area',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.grey,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else if (_hasError)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage ?? 'Unknown error',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.black,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _detectLocation,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/address/add'),
                        icon: const Icon(Icons.add_location),
                        label: const Text('Add Address Manually'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(color: AppTheme.primaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Success - Show detected location
                Column(
                  children: [
                    // Location Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: AppTheme.primaryGreen,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _addressLine1 ?? 'Your Location',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (_detectedCity != null || _detectedState != null)
                                        Text(
                                          [
                                            _detectedCity,
                                            _detectedState,
                                            _detectedPincode,
                                          ].where((e) => e != null && e.isNotEmpty).join(', '),
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: AppTheme.grey,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _confirmAndSave,
                        icon: const Icon(Icons.check_circle),
                        label: const Text(
                          'Confirm & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/address/add'),
                        icon: const Icon(Icons.edit_location),
                        label: const Text('Refine Location'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

