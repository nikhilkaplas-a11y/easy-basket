import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/location_provider.dart';
import '../../utils/theme.dart';

/// Location Permission Screen
///
/// Shows when: User opens app for first time OR GPS permission not granted
/// Purpose: Beautiful permission ask screen (not the default Android dialog)
///
/// UI: Delivery scooter illustration at top
///     "Deliver to your doorstep!" title
///     "Allow location access for accurate delivery" subtitle
///     [Allow Location] green button
///     "Enter address manually" text link
class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 123, 226, 127).withValues(alpha: 0.08),
                Colors.white,
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Illustration — delivery scooter
                // Using Icon as placeholder (replace with actual SVG/image asset later)
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background decoration circles
                      Positioned(
                        top: 20,
                        right: 30,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        left: 20,
                        child: Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Main icon
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delivery_dining_rounded,
                            size: 80,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            Icons.location_on_rounded,
                            size: 36,
                            color: AppTheme.primaryGreen.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Title
                const Text(
                  'Deliver to your doorstep!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Allow location access for accurate delivery.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 2),

                // Allow Location Button — green gradient
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _handleAllowLocation(context),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Allow Location',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Enter manually link
                GestureDetector(
                  onTap: () => _handleManualEntry(context),
                  child: Text(
                    'Enter address manually',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handle "Allow Location" button tap
  /// Requests GPS permission, if granted → detect location → go to home
  Future<void> _handleAllowLocation(BuildContext context) async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    final granted = await locationProvider.requestPermission();

    if (!context.mounted) return;

    if (granted) {
      // Permission granted — detect location and go to home
      await locationProvider.detectLocation();
      if (context.mounted) {
        context.go('/home');
      }
    } else if (locationProvider.isPermissionPermanentlyDenied) {
      // Permanently denied — open app settings
      await locationProvider.openAppSettings();
    }
    // If just denied, stay on this screen — user can tap "Enter manually"
  }

  /// Handle "Enter address manually" tap
  /// Skip GPS, go to add address screen
  void _handleManualEntry(BuildContext context) {
    context.push('/address/add');
  }
}
