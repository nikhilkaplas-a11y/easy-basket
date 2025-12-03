import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

class MapAddressPickerScreen extends StatefulWidget {
  final Function(double lat, double lng, String address) onLocationSelected;

  const MapAddressPickerScreen({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<MapAddressPickerScreen> createState() => _MapAddressPickerScreenState();
}

class _MapAddressPickerScreenState extends State<MapAddressPickerScreen> {
  // Only use Google Maps on mobile platforms
  dynamic _mapController;
  double _currentLat = 28.7041; // Default: Delhi
  double _currentLng = 77.1025;
  double _selectedLat = 28.7041;
  double _selectedLng = 77.1025;
  String _selectedAddress = 'Loading...';
  bool _isLoading = true;
  bool _isGettingAddress = false;
  dynamic _marker;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    // Request location permission
    final status = await Permission.location.request();
    if (!status.isGranted) {
      setState(() {
        _isLoading = false;
        _selectedAddress = 'Location permission denied';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')),
        );
      }
      return;
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _selectedAddress = 'Location services are disabled';
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
        _isLoading = false;
      });

      await _getAddressFromCoordinates(_selectedLat, _selectedLng);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _selectedAddress = 'Error getting location: $e';
      });
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    setState(() => _isGettingAddress = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        lat,
        lng,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final address = _formatAddress(place);
        setState(() {
          _selectedAddress = address;
          _isGettingAddress = false;
        });
      } else {
        setState(() {
          _selectedAddress = 'Address not found';
          _isGettingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Error getting address: $e';
        _isGettingAddress = false;
      });
    }
  }

  String _formatAddress(Placemark place) {
    final parts = <String>[];
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      parts.add(place.postalCode!);
    }
    return parts.join(', ');
  }

  void _onLocationSelected(double lat, double lng) {
    setState(() {
      _selectedLat = lat;
      _selectedLng = lng;
    });
    _getAddressFromCoordinates(lat, lng);
  }

  Future<void> _moveToCurrentLocation() async {
    setState(() {
      _selectedLat = _currentLat;
      _selectedLng = _currentLng;
    });
    await _getAddressFromCoordinates(_currentLat, _currentLng);
  }

  void _confirmSelection() {
    widget.onLocationSelected(
      _selectedLat,
      _selectedLng,
      _selectedAddress,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveToCurrentLocation,
            tooltip: 'Current Location',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildLocationPicker(),
          ),
          // Address Card at Bottom
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
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _isGettingAddress
                          ? const LinearProgressIndicator()
                          : Text(
                              _selectedAddress,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmSelection,
                    child: const Text('Confirm Location'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPicker() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              size: 100,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Location',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (kIsWeb)
              const Text(
                'Map view available on mobile.\nUse current location below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.grey,
                ),
              )
            else
              const Text(
                'Get your current location or\nenter address manually.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.grey,
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Use Current Location'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedAddress != 'Loading...' && _selectedAddress != 'Location permission denied')
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Location:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_selectedAddress),
                      const SizedBox(height: 8),
                      Text(
                        'Coordinates: ${_selectedLat.toStringAsFixed(6)}, ${_selectedLng.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // _mapController?.dispose(); // Only if using GoogleMapController
    super.dispose();
  }
}

