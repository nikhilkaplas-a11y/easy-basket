import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_area_provider.dart';
import '../../models/address_model.dart';
import '../../utils/theme.dart';
import 'map_address_picker_screen.dart';

class EditAddressScreen extends StatefulWidget {
  final AddressModel address;

  const EditAddressScreen({super.key, required this.address});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _deliveryInstructionsController = TextEditingController();
  final _contactNameController = TextEditingController();
  
  bool _isDefault = false;
  String? _selectedTag;
  String? _latitude;
  String? _longitude;
  String? _selectedAddressText;
  bool _isLoadingLocation = false;
  bool _isSaving = false;
  bool _showAdditionalDetails = false;
  int _currentStep = 0; // 0: Location, 1: Details, 2: Review

  final List<Map<String, dynamic>> _tags = [
    {'value': 'home', 'label': 'Home', 'icon': Icons.home, 'color': Colors.blue},
    {'value': 'office', 'label': 'Office', 'icon': Icons.work, 'color': Colors.orange},
    {'value': 'other', 'label': 'Other', 'icon': Icons.location_on, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill form with existing address data
    _preFillAddressData();
  }

  void _preFillAddressData() {
    final address = widget.address;
    setState(() {
      _addressLine1Controller.text = address.addressLine1;
      _addressLine2Controller.text = address.addressLine2 ?? '';
      _cityController.text = address.city;
      _stateController.text = address.state;
      _pincodeController.text = address.pincode;
      _landmarkController.text = address.landmark ?? '';
      _latitude = address.latitude;
      _longitude = address.longitude;
      _selectedTag = address.tag;
      _isDefault = address.isDefault;
      
      // Build address text from existing data
      if (address.latitude != null && address.longitude != null) {
        _selectedAddressText = address.fullAddress;
      }
      
      // Skip to details step since we already have location
      _currentStep = 1;
    });
  }

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    _deliveryInstructionsController.dispose();
    _contactNameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => MapAddressPickerScreen(
            onLocationSelected: (lat, lng, address) {
              // Callback for immediate updates (optional)
            },
          ),
        ),
      );

      if (result != null && mounted) {
        final lat = result['latitude'];
        final lng = result['longitude'];
        final address = result['address'] as String?;
        
        final addressLine1 = result['addressLine1'] as String?;
        final addressLine2 = result['addressLine2'] as String?;
        final city = result['city'] as String?;
        final state = result['state'] as String?;
        final pincode = result['pincode'] as String?;
        
        setState(() {
          _latitude = lat is double ? lat.toString() : (lat?.toString() ?? '');
          _longitude = lng is double ? lng.toString() : (lng?.toString() ?? '');
          _selectedAddressText = address ?? '';
          
          if (addressLine1 != null && addressLine1.isNotEmpty) {
            _addressLine1Controller.text = addressLine1;
          } else if (address != null && address.isNotEmpty) {
            final parts = address.split(',');
            _addressLine1Controller.text = parts[0].trim();
          }
          
          if (addressLine2 != null && addressLine2.isNotEmpty) {
            _addressLine2Controller.text = addressLine2;
          }
          
          if (city != null && city.isNotEmpty) {
            _cityController.text = city;
          }
          
          if (state != null && state.isNotEmpty) {
            _stateController.text = state;
          }
          
          if (pincode != null && pincode.isNotEmpty) {
            _pincodeController.text = pincode;
          }
          
          _isLoadingLocation = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location updated successfully!'),
              backgroundColor: AppTheme.primaryGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a location first for accurate delivery'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      setState(() => _currentStep = 2);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _updateAddress() async {
    if (!_formKey.currentState!.validate()) return;

    // Location is mandatory for instant delivery
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location is required for instant delivery. Please select your location.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serviceAreaProvider = Provider.of<ServiceAreaProvider>(context, listen: false);

    // Check service availability first
    final pincode = _pincodeController.text.trim().replaceAll(' ', '');
    if (pincode.isNotEmpty) {
      final isAvailable = await serviceAreaProvider.checkServiceAvailability(
        pincode: pincode,
        country: 'India',
      );

      if (!isAvailable) {
        setState(() => _isSaving = false);
        if (mounted) {
          context.push('/service-not-available', extra: {
            'pincode': pincode,
            'city': _cityController.text.trim(),
            'state': _stateController.text.trim(),
          });
        }
        return;
      }
    }

    String? token = authProvider.accessToken ?? authProvider.token;
    
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      setState(() => _isSaving = false);
      return;
    }

    bool success = false;
    try {
      success = await orderProvider.updateAddress(
        token: token,
        addressId: widget.address.id,
        addressLine1: _addressLine1Controller.text,
        addressLine2: _addressLine2Controller.text.isEmpty ? null : _addressLine2Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        landmark: _landmarkController.text.isEmpty ? null : _landmarkController.text,
        isDefault: _isDefault,
        latitude: _latitude,
        longitude: _longitude,
        tag: _selectedTag,
      );
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('Invalid token') || 
          errorMessage.contains('Authentication required') ||
          errorMessage.contains('TokenExpiredException')) {
        if (authProvider.refreshToken != null) {
          try {
            final refreshed = await authProvider.refreshAccessToken();
            if (refreshed && mounted) {
              final newToken = authProvider.accessToken ?? authProvider.token;
              if (newToken != null) {
                success = await orderProvider.updateAddress(
                  token: newToken,
                  addressId: widget.address.id,
                  addressLine1: _addressLine1Controller.text,
                  addressLine2: _addressLine2Controller.text.isEmpty ? null : _addressLine2Controller.text,
                  city: _cityController.text,
                  state: _stateController.text,
                  pincode: _pincodeController.text,
                  landmark: _landmarkController.text.isEmpty ? null : _landmarkController.text,
                  isDefault: _isDefault,
                  latitude: _latitude,
                  longitude: _longitude,
                  tag: _selectedTag,
                );
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Session expired. Please login again.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                setState(() => _isSaving = false);
                return;
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session expired. Please login again.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              setState(() => _isSaving = false);
              return;
            }
          } catch (refreshError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session expired. Please login again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() => _isSaving = false);
            return;
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session expired. Please login again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isSaving = false);
          return;
        }
      } else {
        setState(() => _isSaving = false);
        rethrow;
      }
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      context.pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Address updated successfully!'),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Failed to update address'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Address'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: AppTheme.lightGrey,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Step Indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              color: AppTheme.lightGrey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStepIndicator(0, 'Location', Icons.location_on),
                  _buildStepIndicator(1, 'Details', Icons.edit),
                  _buildStepIndicator(2, 'Review', Icons.check_circle),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildStepContent(),
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppTheme.primaryGreen),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: _currentStep == 0 ? 1 : 2,
                      child: ElevatedButton(
                        onPressed: _currentStep == 2
                            ? (_isSaving ? null : _updateAddress)
                            : _nextStep,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(_currentStep == 2 ? 'Update Address' : 'Continue'),
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

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.primaryGreen
                  : isActive
                      ? AppTheme.primaryGreen
                      : AppTheme.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isActive || isCompleted ? AppTheme.white : AppTheme.grey,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppTheme.primaryGreen : AppTheme.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildLocationStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildReviewStep();
      default:
        return _buildLocationStep();
    }
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on,
                color: AppTheme.primaryGreen,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Required for instant delivery',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Card(
          elevation: 0,
          color: _latitude != null && _longitude != null
              ? AppTheme.primaryGreen.withOpacity(0.05)
              : Colors.orange.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _latitude != null && _longitude != null
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  color: _latitude != null && _longitude != null
                      ? AppTheme.primaryGreen
                      : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _latitude != null && _longitude != null
                            ? 'Location Selected'
                            : 'Location Not Selected',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_selectedAddressText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _selectedAddressText!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.my_location),
            label: Text(_isLoadingLocation ? 'Getting Location...' : 'Update Location'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.map),
            label: const Text('Pick on Map'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppTheme.primaryGreen),
            ),
          ),
        ),

        if (_latitude != null && _longitude != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Coordinates: ${_latitude!.substring(0, 8)}, ${_longitude!.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Update address details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'All fields marked with * are required',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.grey,
          ),
        ),
        const SizedBox(height: 20),

        _buildTagSelector(),
        const SizedBox(height: 20),

        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.lightGrey, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.home_outlined, size: 20, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Address',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _addressLine1Controller,
                  decoration: const InputDecoration(
                    labelText: 'House/Flat No., Building *',
                    hintText: 'e.g., 123, Green Apartments',
                    prefixIcon: Icon(Icons.home_outlined, size: 20),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  style: const TextStyle(fontSize: 15),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _addressLine2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Street, Area',
                    hintText: 'Optional',
                    prefixIcon: Icon(Icons.streetview_outlined, size: 20),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.lightGrey, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 20, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          hintText: 'City',
                          prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        style: const TextStyle(fontSize: 15),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(
                          labelText: 'State *',
                          hintText: 'State',
                          prefixIcon: Icon(Icons.map_outlined, size: 20),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        style: const TextStyle(fontSize: 15),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _pincodeController,
                  decoration: const InputDecoration(
                    labelText: 'Pincode *',
                    hintText: '6-digit pincode',
                    prefixIcon: Icon(Icons.pin_outlined, size: 20),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  style: const TextStyle(fontSize: 15),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    final cleanPincode = value!.replaceAll(RegExp(r'[^0-9]'), '');
                    if (cleanPincode.length != 6) return 'Must be 6 digits';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        _buildAdditionalDetailsSection(),
        const SizedBox(height: 12),

        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.lightGrey, width: 1),
          ),
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: const Text(
              'Set as default address',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            value: _isDefault,
            onChanged: (value) => setState(() => _isDefault = value),
            activeColor: AppTheme.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildTagSelector() {
    return Row(
      children: [
        Icon(Icons.label_outline, size: 18, color: AppTheme.grey),
        const SizedBox(width: 8),
        Text(
          'Save as',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.grey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: _tags.map((tag) {
              final isSelected = _selectedTag == tag['value'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTag = isSelected ? null : tag['value'] as String;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryGreen 
                            : AppTheme.lightGrey,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primaryGreen 
                              : AppTheme.lightGrey,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tag['icon'] as IconData,
                            size: 16,
                            color: isSelected ? AppTheme.white : tag['color'] as Color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tag['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? AppTheme.white : AppTheme.black,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalDetailsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.lightGrey, width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showAdditionalDetails = !_showAdditionalDetails;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppTheme.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Additional Details (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.grey,
                      ),
                    ),
                  ),
                  Icon(
                    _showAdditionalDetails 
                        ? Icons.keyboard_arrow_up 
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_showAdditionalDetails)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactNameController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Name',
                      hintText: 'Name for delivery',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _landmarkController,
                    decoration: const InputDecoration(
                      labelText: 'Landmark',
                      hintText: 'e.g., Near Metro Station',
                      prefixIcon: Icon(Icons.place_outlined, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deliveryInstructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Instructions',
                      hintText: 'e.g., Ring doorbell, Leave at gate',
                      prefixIcon: Icon(Icons.note_outlined, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    style: const TextStyle(fontSize: 15),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppTheme.primaryGreen,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review Changes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Verify before updating',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_selectedTag != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _tags.firstWhere((t) => t['value'] == _selectedTag)['icon'] as IconData,
                              size: 16,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _tags.firstWhere((t) => t['value'] == _selectedTag)['label'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              'Default',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildReviewItem(Icons.location_on, 'Address', [
                  _addressLine1Controller.text,
                  if (_addressLine2Controller.text.isNotEmpty) _addressLine2Controller.text,
                  '${_cityController.text}, ${_stateController.text} - ${_pincodeController.text}',
                  if (_landmarkController.text.isNotEmpty) 'Landmark: ${_landmarkController.text}',
                ]),

                if (_contactNameController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildReviewItem(Icons.person, 'Contact', [_contactNameController.text]),
                ],

                if (_deliveryInstructionsController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildReviewItem(Icons.note, 'Instructions', [_deliveryInstructionsController.text]),
                ],

                if (_latitude != null && _longitude != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gps_fixed, size: 16, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location: ${_latitude!.substring(0, 8)}, ${_longitude!.substring(0, 8)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.grey,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const Icon(Icons.check_circle, size: 16, color: AppTheme.primaryGreen),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your address will be updated and can be used for future orders.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(IconData icon, String label, List<String> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...values.map((value) => Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 4),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.grey,
                ),
              ),
            )),
      ],
    );
  }
}

