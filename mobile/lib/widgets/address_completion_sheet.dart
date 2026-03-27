import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/partial_address_model.dart';
import '../providers/address_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

/// Address Completion Bottom Sheet
///
/// Shows at checkout when user has partial address (GPS detected)
/// but needs to fill remaining details (house no, street, landmark)
///
/// Pre-filled from GPS: city, state, pincode, lat/lng
/// User fills: house/flat no, floor, street/road, landmark
/// User selects: tag (Home/Office/Other)
///
/// After save: Full address created → continue to payment
class AddressCompletionSheet extends StatefulWidget {
  /// Partial address detected from GPS
  final PartialAddress partialAddress;

  /// Callback when address is saved successfully
  final VoidCallback onAddressSaved;

  const AddressCompletionSheet({
    super.key,
    required this.partialAddress,
    required this.onAddressSaved,
  });

  /// Show this bottom sheet from any screen
  static void show({
    required BuildContext context,
    required PartialAddress partialAddress,
    required VoidCallback onAddressSaved,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Full height control
      backgroundColor: Colors.transparent,
      builder: (_) => AddressCompletionSheet(
        partialAddress: partialAddress,
        onAddressSaved: onAddressSaved,
      ),
    );
  }

  @override
  State<AddressCompletionSheet> createState() => _AddressCompletionSheetState();
}

class _AddressCompletionSheetState extends State<AddressCompletionSheet> {
  // Form controllers
  final _houseController = TextEditingController();
  final _floorController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Selected tag: home, office, other
  String _selectedTag = 'home';

  // Loading state
  bool _isSaving = false;

  @override
  void dispose() {
    _houseController.dispose();
    _floorController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      // Take up ~80% of screen, adjust for keyboard
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Easy Basket',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.grey[500], size: 22),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Detected address card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Address: ${widget.partialAddress.fullDisplay}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Form fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // House / Flat No (required)
                    _buildField(
                      controller: _houseController,
                      label: 'House / Flat No *',
                      required: true,
                    ),

                    const SizedBox(height: 12),

                    // Floor (optional)
                    _buildField(
                      controller: _floorController,
                      label: 'Floor (optional)',
                    ),

                    const SizedBox(height: 12),

                    // Street / Road (required)
                    _buildField(
                      controller: _streetController,
                      label: 'Street / Road *',
                      required: true,
                    ),

                    const SizedBox(height: 12),

                    // Landmark (optional)
                    _buildField(
                      controller: _landmarkController,
                      label: 'Landmark (optional)',
                    ),

                    const SizedBox(height: 16),

                    // Tag selector — Home / Office / Other
                    Row(
                      children: [
                        _buildTagChip('home', Icons.home_rounded, 'Home'),
                        const SizedBox(width: 10),
                        _buildTagChip('office', Icons.business_rounded, 'Office'),
                        const SizedBox(width: 10),
                        _buildTagChip('other', Icons.location_on_rounded, 'Other'),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Save & Continue button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
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
                    onTap: _isSaving ? null : _saveAndContinue,
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save & Continue to Payment',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a form field with filled grey style
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[400],
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  /// Build tag selection chip (Home / Office / Other)
  Widget _buildTagChip(String tag, IconData icon, String label) {
    final isSelected = _selectedTag == tag;

    return GestureDetector(
      onTap: () => setState(() => _selectedTag = tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Save address and continue to payment
  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);

      if (authProvider.token == null) {
        setState(() => _isSaving = false);
        return;
      }

      // Build addressLine1 from house + street
      final house = _houseController.text.trim();
      final floor = _floorController.text.trim();
      final street = _streetController.text.trim();
      final landmark = _landmarkController.text.trim();

      // Combine house + floor into addressLine1
      String addressLine1 = house;
      if (floor.isNotEmpty) {
        addressLine1 = '$addressLine1, Floor $floor';
      }

      final success = await addressProvider.createAddress(
        token: authProvider.token!,
        addressLine1: addressLine1,
        addressLine2: street.isNotEmpty ? street : null,
        city: widget.partialAddress.city ?? '',
        state: widget.partialAddress.state ?? '',
        pincode: widget.partialAddress.pincode ?? '',
        landmark: landmark.isNotEmpty ? landmark : null,
        isDefault: true, // New address = make it default
        latitude: widget.partialAddress.latitude.toString(),
        longitude: widget.partialAddress.longitude.toString(),
        tag: _selectedTag,
      );

      setState(() => _isSaving = false);

      if (success && mounted) {
        // Select the newly created address
        final newDefault = addressProvider.defaultAddress;
        if (newDefault != null) {
          addressProvider.selectAddress(newDefault);
        }

        // Close bottom sheet
        Navigator.pop(context);

        // Callback — payment screen continues
        widget.onAddressSaved();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving address: $e')),
        );
      }
    }
  }
}
