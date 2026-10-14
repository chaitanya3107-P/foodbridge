import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/food_safety_disclaimer.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/router/app_router.dart';

class CreateDonationScreen extends ConsumerStatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  ConsumerState<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends ConsumerState<CreateDonationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _foodDescriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '20');
  final _packagingController = TextEditingController(text: 'Insulated food-grade stainless containers');
  final _locationNameController = TextEditingController(text: 'Campus Canteen Loading Bay');
  final _locationAddressController = TextEditingController(text: 'Sector 4, University North Campus Gate 2');
  final _contactPersonController = TextEditingController(text: 'Chef Anand Sharma');
  final _contactPhoneController = TextEditingController(text: '+91 98234 56789');

  String _selectedCategory = AppConstants.foodCategories.first;
  String _selectedUnit = AppConstants.supportedUnits.first;
  String _selectedStorage = AppConstants.storageConditions.first;
  final Set<String> _selectedAllergens = {'None Declared'};

  DateTime _prepDateTime = DateTime.now().subtract(const Duration(hours: 1));
  DateTime _pickupDeadline = DateTime.now().add(const Duration(hours: 4));

  bool _isLoading = false;

  @override
  void dispose() {
    _foodDescriptionController.dispose();
    _quantityController.dispose();
    _packagingController.dispose();
    _locationNameController.dispose();
    _locationAddressController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({
    required bool isPrep,
  }) async {
    final initial = isPrep ? _prepDateTime : _pickupDeadline;
    final firstDate = isPrep ? DateTime.now().subtract(const Duration(days: 2)) : DateTime.now();
    final lastDate = DateTime.now().add(const Duration(days: 7));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );

      if (pickedTime != null && mounted) {
        final combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isPrep) {
            _prepDateTime = combined;
          } else {
            _pickupDeadline = combined;
          }
        });
      }
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickupDeadline.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.alertRed,
          content: Text('Pickup deadline must be set to a future time.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(repositoryProvider);
      final qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;

      final donation = await repo.createDonation(
        foodDescription: _foodDescriptionController.text.trim(),
        foodCategory: _selectedCategory,
        listedQuantity: qty,
        unit: _selectedUnit,
        preparationDateTime: _prepDateTime,
        storageCondition: _selectedStorage,
        knownAllergens: _selectedAllergens.toList(),
        packagingType: _packagingController.text.trim(),
        pickupDeadline: _pickupDeadline,
        locationName: _locationNameController.text.trim(),
        locationAddress: _locationAddressController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
      );

      // Invalidate relevant providers
      ref.invalidate(roleDonationsProvider);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 28),
                SizedBox(width: 10),
                Text('Listing Submitted', style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your donation listing #${donation.donationId} has been successfully saved.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'STATUS: Awaiting NGO Review\n\nPer FoodBridge safety standards, the listing is not approved until the partner NGO conducts intake safety verification.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                  ),
                ),
              ],
            ),
            actions: [
              AppButton(
                label: 'Return to Dashboard',
                isFullWidth: false,
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(AppRoutes.home);
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.alertRed,
            content: Text('Error: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Food Donation'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mandatory Universal Disclaimer Banner
                const FoodSafetyDisclaimerBanner(),

                const SizedBox(height: 12),

                // 1. Food Details
                const Text(
                  '1. Food Surplus Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _foodDescriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Food Description *',
                    hintText: 'e.g. Steamed Rice, Dal Makhani, Mixed Vegetable Curry',
                    alignLabelWithHint: true,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 5) {
                      return 'Please provide a clear description (at least 5 characters).';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Food Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Food Category *'),
                  items: AppConstants.foodCategories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),

                const SizedBox(height: 12),

                // Quantity and Unit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Surplus Quantity *',
                          prefixIcon: Icon(Icons.scale_outlined, color: AppTheme.primaryGreen),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter quantity.';
                          final n = double.tryParse(val);
                          if (n == null || n <= 0) return 'Must be > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unit *'),
                        items: AppConstants.supportedUnits.map((u) {
                          return DropdownMenuItem(value: u, child: Text(u));
                        }).toList>,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 2. Preparation & Storage Conditions
                const Text(
                  '2. Preparation & Temperature Storage',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
                ),
                const SizedBox(height: 10),

                // Storage Condition
                DropdownButtonFormField<String>(
                  value: _selectedStorage,
                  decoration: const InputDecoration(labelText: 'Current Storage Condition *'),
                  items: AppConstants.storageConditions.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStorage = val);
                  },
                ),

                const SizedBox(height: 12),

                // Prep Date & Time Picker Tile
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFCCD9D1)),
                  ),
                  leading: const Icon(Icons.timer_outlined, color: AppTheme.primaryGreen),
                  title: const Text('Preparation Timestamp *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(_formatDateTime(_prepDateTime), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E6F5C))),
                  trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                  onTap: () => _pickDateTime(isPrep: true),
                ),

                const SizedBox(height: 12),

                // Packaging Type
                TextFormField(
                  controller: _packagingController,
                  decoration: const InputDecoration(
                    labelText: 'Packaging Container Type *',
                    hintText: 'e.g. Sealed food containers, tray with cover',
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Packaging type is required.' : null,
                ),

                const SizedBox(height: 16),

                // Allergens Checklist
                const Text(
                  'Declared Allergens (Select all that apply) *',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AppConstants.commonAllergens.map((allergen) {
                    final isSelected = _selectedAllergens.contains(allergen);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(allergen),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF1E3228),
                      ),
                      selectedColor: AppTheme.primaryGreen,
                      backgroundColor: Colors.white,
                      onSelected: (selected) {
                        setState(() {
                          if (allergen == 'None Declared') {
                            _selectedAllergens.clear();
                            if (selected) _selectedAllergens.add('None Declared');
                          } else {
                            _selectedAllergens.remove('None Declared');
                            if (selected) {
                              _selectedAllergens.add(allergen);
                            } else {
                              _selectedAllergens.remove(allergen);
                            }
                            if (_selectedAllergens.isEmpty) {
                              _selectedAllergens.add('None Declared');
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 3. Logistics & Location
                const Text(
                  '3. Pickup Logistics & Contact',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
                ),
                const SizedBox(height: 10),

                // Pickup Deadline Picker Tile
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFCCD9D1)),
                  ),
                  leading: const Icon(Icons.event_busy_rounded, color: AppTheme.secondaryAmber),
                  title: const Text('Pickup Deadline (Auto-expires after) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(_formatDateTime(_pickupDeadline), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFD84315))),
                  trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                  onTap: () => _pickDateTime(isPrep: false),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _locationNameController,
                  decoration: const InputDecoration(
                    labelText: 'Pickup Location Name *',
                    hintText: 'e.g. North Canteen Receiving Bay',
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Location name is required.' : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _locationAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Physical Pickup Address *',
                    hintText: 'Full street address for volunteer driver',
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Address is required.' : null,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _contactPersonController,
                        decoration: const InputDecoration(labelText: 'Contact Person *'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required.' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _contactPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Contact Phone *'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required.' : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                AppButton(
                  label: 'Submit Listing (Awaiting NGO Review)',
                  icon: Icons.send_rounded,
                  isLoading: _isLoading,
                  variant: AppButtonVariant.primary,
                  onPressed: _submitDonation,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final date = '${dt.day}/${dt.month}/${dt.year}';
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$date at $hour:$min $ampm';
  }
}
