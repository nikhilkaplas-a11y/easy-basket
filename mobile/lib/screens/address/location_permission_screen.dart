import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/location_provider.dart';
import '../../utils/theme.dart';

/// Location Permission Screen — Premium onboarding with skeleton loading
///
/// Flow:
/// 1. Show permission screen (illustration + CTA)
/// 2. User taps "Use Current Location"
/// 3. CrossFade to skeleton loading (simulates home screen)
/// 4. GPS detects → navigate to real home screen
/// 5. Error → show error + allow retry
class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoadingLocation = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isLoadingLocation ? const Color(0xFFF4F8F3) : const Color(0xFFEEF7F0),
      body: AnimatedCrossFade(
        duration: const Duration(milliseconds: 400),
        crossFadeState: _isLoadingLocation ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: _buildPermissionScreen(),
        secondChild: _buildSkeletonScreen(),
        layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
          return Stack(
            children: [
              Positioned.fill(key: bottomChildKey, child: bottomChild),
              Positioned.fill(key: topChildKey, child: topChild),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════
  // SCREEN 1: Permission UI
  // ═══════════════════════════════════════

  Widget _buildPermissionScreen() {
    final size = MediaQuery.of(context).size;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // Bottom wave decoration
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: ClipPath(
            clipper: _BottomWaveClipper(),
            child: Container(
              height: size.height * 0.18,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD6EFDB), Color(0xFFEEF7F0)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
        ),

        // Content — vertically centered, image + text grouped together
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ─── Branding ───
                  _buildBranding(),
                  const SizedBox(height: 8),

                  // ─── HERO Image — edge to edge, maximum size ───
                  Image.asset(
                    'assets/images/delivery.png',
                    fit: BoxFit.contain,
                    width: size.width + 40, // overflow padding to fill edge-to-edge
                    height: size.height * 0.42,
                  ),
                  const SizedBox(height: 12),

                  // ─── Heading — bold, full width ───
                  Text(
                    'Groceries, delivered fast',
                    style: TextStyle(
                      fontSize: size.width * 0.076, // ~28px on 360w, scales up on bigger screens
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: -0.8,
                      height: 1.15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // ─── Subtext ───
                  Text(
                    'Allow location to find your address faster\nand show nearby delivery options.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey[500], height: 1.5),
                    textAlign: TextAlign.center,
                  ),

                  // ─── Error message ───
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                          const SizedBox(width: 6),
                          Flexible(child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ─── CTA Button ───
                  _buildPrimaryCTA(),
                  const SizedBox(height: 14),

                  // ─── Manual entry ───
                  GestureDetector(
                    onTap: () => context.push('/address/add'),
                    child: const Text(
                      'Enter address manually',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF444444), decoration: TextDecoration.underline, decorationColor: Color(0xFF888888), decorationThickness: 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        // Icon + Name in single row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/icons/app_icon.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Easy Basket', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), letterSpacing: -0.3)),
          ],
        ),
        const SizedBox(height: 4),
        Text('Fresh groceries in minutes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildPrimaryCTA() {
    return Container(
      width: double.infinity, height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2E8B3C), Color(0xFF38A34A)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2E8B3C).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: const Color(0xFF38A34A).withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _isLoadingLocation ? null : _handleAllowLocation,
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.my_location_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text('Use Current Location', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // SCREEN 2: Skeleton Loading (simulates home screen)
  // ═══════════════════════════════════════

  Widget _buildSkeletonScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header skeleton (staggered — appears first) ───
            _shimmerWrap(
              period: 800,
              child: _skeletonHeader(),
            ),
            const SizedBox(height: 16),

            // ─── Search bar skeleton ───
            _shimmerWrap(
              period: 900,
              child: _skeletonBox(height: 48, radius: 14),
            ),
            const SizedBox(height: 20),

            // ─── "Detecting location" — REAL indicator (no shimmer) ───
            const _DetectingLocationIndicator(),
            const SizedBox(height: 20),

            // ─── Category chips skeleton (staggered — appears after header) ───
            _shimmerWrap(
              period: 1000,
              child: _skeletonCategoryChips(),
            ),
            const SizedBox(height: 22),

            // ─── Section title ───
            _shimmerWrap(
              period: 1100,
              child: _skeletonBox(width: 140, height: 18, radius: 6),
            ),
            const SizedBox(height: 14),

            // ─── Product grid (staggered — appears last) ───
            _shimmerWrap(
              period: 1200,
              child: _skeletonProductGrid(),
            ),
            const SizedBox(height: 22),

            _shimmerWrap(
              period: 1100,
              child: _skeletonBox(width: 120, height: 18, radius: 6),
            ),
            const SizedBox(height: 14),

            _shimmerWrap(
              period: 1300,
              child: _skeletonProductGrid(),
            ),
          ],
        ),
      ),
    );
  }

  /// Wrap a widget in its own Shimmer with custom period (staggered effect)
  Widget _shimmerWrap({required int period, required Widget child}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF8F8F8),
      period: Duration(milliseconds: period),
      child: child,
    );
  }

  /// Header — brand row + address bar
  Widget _skeletonHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          Row(
            children: [
              _skeletonBox(width: 40, height: 40, radius: 12),
              const SizedBox(width: 10),
              _skeletonBox(width: 120, height: 20, radius: 6),
              const Spacer(),
              _skeletonCircle(36),
            ],
          ),
          const SizedBox(height: 14),
          _skeletonBox(height: 42, radius: 12),
        ],
      ),
    );
  }

  /// Category chips — horizontal row
  Widget _skeletonCategoryChips() {
    return SizedBox(
      height: 100,
      child: Row(
        children: List.generate(4, (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 3 ? 10 : 0),
            child: Column(
              children: [
                _skeletonBox(width: 60, height: 60, radius: 16),
                const SizedBox(height: 8),
                _skeletonBox(width: 50, height: 10, radius: 4),
              ],
            ),
          ),
        )),
      ),
    );
  }

  /// Product grid — 2 cards side by side
  Widget _skeletonProductGrid() {
    return Row(
      children: [
        Expanded(child: _skeletonProductCard()),
        const SizedBox(width: 12),
        Expanded(child: _skeletonProductCard()),
      ],
    );
  }

  /// Single product card skeleton
  Widget _skeletonProductCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonBox(height: 100, radius: 14),
          const SizedBox(height: 10),
          _skeletonBox(width: double.infinity, height: 12, radius: 4),
          const SizedBox(height: 6),
          _skeletonBox(width: 80, height: 10, radius: 4),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _skeletonBox(width: 50, height: 16, radius: 4),
              _skeletonBox(width: 56, height: 28, radius: 8),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Skeleton primitives ───

  Widget _skeletonBox({double? width, double height = 20, double radius = 8}) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
    );
  }

  Widget _skeletonCircle(double size) {
    return Container(width: size, height: size, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle));
  }

  // ═══════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════

  Future<void> _handleAllowLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Request permission first (before showing skeleton)
    final granted = await locationProvider.requestPermission();
    if (!mounted) return;

    if (!granted) {
      if (locationProvider.isPermissionPermanentlyDenied) {
        setState(() => _errorMessage = 'Location permanently denied. Tap to open Settings.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enable location in phone Settings'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(label: 'Open Settings', textColor: Colors.white, onPressed: () => locationProvider.openAppSettings()),
            ),
          );
        }
      } else {
        setState(() => _errorMessage = 'Location permission is needed for delivery');
      }
      return;
    }

    // Permission granted — show skeleton and detect
    setState(() => _isLoadingLocation = true);

    await locationProvider.detectLocation(force: true);

    if (!mounted) return;

    if (locationProvider.detectedAddress != null || locationProvider.currentPosition != null) {
      // Success — navigate to home
      context.go('/home');
    } else {
      // Detection failed — show error, allow retry
      setState(() {
        _isLoadingLocation = false;
        _errorMessage = 'Could not detect location. Please try again.';
      });
    }
  }
}

/// Custom wave clipper for bottom decoration
/// Animated "Detecting your location..." indicator with pulsing dots
class _DetectingLocationIndicator extends StatefulWidget {
  const _DetectingLocationIndicator();

  @override
  State<_DetectingLocationIndicator> createState() => _DetectingLocationIndicatorState();
}

class _DetectingLocationIndicatorState extends State<_DetectingLocationIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _dotCount = (_dotCount % 3) + 1);
          _controller.forward(from: 0);
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Detecting your location$dots',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.45);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.15, size.width * 0.5, size.height * 0.35);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.55, size.width, size.height * 0.25);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
