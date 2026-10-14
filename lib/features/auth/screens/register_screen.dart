import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/user_model.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _orgController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.donor;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _orgController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ref.read(currentUserProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            role: _selectedRole,
            contactNumber: _phoneController.text.trim(),
            organisationId: _orgController.text.trim().isNotEmpty
                ? _orgController.text.trim()
                : null,
          );

      if (mounted) {
        if (user.isPending) {
          context.go(AppRoutes.pendingApproval);
        } else {
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('ArgumentError: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join FoodBridge',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3228),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Register as a food donor, partner NGO staff, volunteer driver, or community participant.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF4A5D54)),
                ),

                const SizedBox(height: 16),

                // Approval Status Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFF57F17), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Verification Notice: Donor, NGO staff, and Volunteer accounts require administrator review and approval before full operational access is unlocked. Awareness participant accounts are active immediately.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.alertContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.alertRed.withOpacity(0.4)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppTheme.alertRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Step 1: Select Role
                const Text(
                  'Select Your Primary Role',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                _buildRoleOption(
                  role: UserRole.donor,
                  title: 'Food Donor',
                  subtitle: 'Canteen, restaurant, hostel mess, or event caterer offering surplus food.',
                  icon: Icons.storefront_rounded,
                ),
                const SizedBox(height: 8),
                _buildRoleOption(
                  role: UserRole.ngoStaff,
                  title: 'NGO / Food Bank Staff',
                  subtitle: 'Review incoming listings, enforce intake safety, and manage distributions.',
                  icon: Icons.food_bank_rounded,
                ),
                const SizedBox(height: 8),
                _buildRoleOption(
                  role: UserRole.volunteer,
                  title: 'Volunteer / Driver',
                  subtitle: 'Collect verified surplus from donors and record actual collected quantities.',
                  icon: Icons.local_shipping_rounded,
                ),
                const SizedBox(height: 8),
                _buildRoleOption(
                  role: UserRole.awareness,
                  title: 'Awareness Participant',
                  subtitle: 'Learn food-waste prevention, explore tips, take quizzes, and track public impact.',
                  icon: Icons.menu_book_rounded,
                ),

                const SizedBox(height: 24),

                // Personal & Org Details
                const Text(
                  'Account Details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name / Contact Person *',
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryGreen),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Please enter your full name.' : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryGreen),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your email.';
                    if (!val.contains('@')) return 'Enter a valid email address.';
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone Number *',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryGreen),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Contact phone is required.';
                    if (val.trim().length < 8) return 'Enter a valid phone number.';
                    return null;
                  },
                ),

                if (_selectedRole == UserRole.donor || _selectedRole == UserRole.ngoStaff) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _orgController,
                    decoration: InputDecoration(
                      labelText: _selectedRole == UserRole.donor
                          ? 'Canteen / Restaurant / Organisation Name *'
                          : 'NGO / Food Bank Entity Name *',
                      prefixIcon: const Icon(Icons.business_outlined, color: AppTheme.primaryGreen),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Organisation name is required for this role.';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password (min. 6 characters) *',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.length < 6 ? 'Password must be at least 6 characters.' : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password *',
                    prefixIcon: Icon(Icons.lock_reset_outlined, color: AppTheme.primaryGreen),
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                AppButton(
                  label: 'Submit Registration',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Already registered? Sign in instead'),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryContainer.withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : const Color(0xFFDCE6E0),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : const Color(0xFFE8F0EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1E3228),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF4A5D54)),
                  ),
                ],
              ),
            ),
            Radio<UserRole>(
              value: role,
              groupValue: _selectedRole,
              activeColor: AppTheme.primaryGreen,
              onChanged: (val) {
                if (val != null) setState(() => _selectedRole = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
