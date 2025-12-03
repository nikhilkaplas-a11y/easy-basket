import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import 'map_address_picker_screen.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  
  bool _isDefault = false;
  String? _selectedTag;
  String? _latitude;
  String? _longitude;
  bool _isLoadingLocation = false;

  final List<Map<String, dynamic>> _tags = [
    {'value': 'home', 'label': 'Home', 'icon': Icons.home},
    {'value': 'office', 'label': 'Office', 'icon': Icons.work},
    {'value': 'other', 'label': 'Other', 'icon': Icons.location_on},
  ];

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _pickLocationFromMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapAddressPickerScreen(
          onLocationSelected: (lat, lng, address) {
            Navigator.pop(context, {
              'latitude': lat,
              'longitude': lng,
              'address': address,
            });
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'].toString();
        _longitude = result['longitude'].toString();
        _addressLine1Controller.text = result['address'] ?? '';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Navigate to map picker
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => MapAddressPickerScreen(
            onLocationSelected: (lat, lng, address) {
              Navigator.pop(context, {
                'latitude': lat,
                'longitude': lng,
                'address': address,
              });
            },
          ),
        ),
      );

      if (result != null && mounted) {
        setState(() {
          _latitude = result['latitude'].toString();
          _longitude = result['longitude'].toString();
          _addressLine1Controller.text = result['address'] ?? '';
          _isLoadingLocation = false;
        });
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

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    final success = await orderProvider.createAddress(
      token: authProvider.token!,
      addressLine1: _addressLine1Controller.text,
      addressLine2: _addressLine2Controller.text.isEmpty
          ? null
          : _addressLine2Controller.text,
      city: _cityController.text,
      state: _stateController.text,
      pincode: _pincodeController.text,
      landmark: _landmarkController.text.isEmpty ? null : _landmarkController.text,
      isDefault: _isDefault,
      latitude: _latitude,
      longitude: _longitude,
      tag: _selectedTag,
    );

    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved successfully!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderProvider.error ?? 'Failed to save address')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Address'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Location Picker Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                            icon: _isLoadingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.location_on),
                            label: const Text('Use Current Location'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickLocationFromMap,
                            icon: const Icon(Icons.map),
                            label: const Text('Pick on Map'),
                          ),
                        ),
                      ],
                    ),
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Location: $_latitude, $_longitude',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Address Tag Selection
            const Text(
              'Address Tag',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final isSelected = _selectedTag == tag['value'];
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tag['icon'] as IconData,
                        size: 18,
                        color: isSelected ? AppTheme.white : AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(tag['label'] as String),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedTag = selected ? tag['value'] as String : null;
                    });
                  },
                  selectedColor: AppTheme.primaryGreen,
                  checkmarkColor: AppTheme.white,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.white : AppTheme.black,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Address Form Fields
            TextFormField(
              controller: _addressLine1Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 1 *',
                hintText: 'House/Flat No., Building Name',
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Address is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressLine2Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 2',
                hintText: 'Street, Area',
                prefixIcon: Icon(Icons.streetview),
              ),
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
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'City is required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      hintText: 'State',
                      prefixIcon: Icon(Icons.map),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'State is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pincodeController,
              decoration: const InputDecoration(
                labelText: 'Pincode *',
                hintText: '123456',
                prefixIcon: Icon(Icons.pin),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Pincode is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _landmarkController,
              decoration: const InputDecoration(
                labelText: 'Landmark (Optional)',
                hintText: 'Near...',
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Set as default address'),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value ?? false),
              activeColor: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveAddress,
              child: const Text('Save Address'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
