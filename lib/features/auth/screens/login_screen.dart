import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/user_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'donor@foodbridge.ngo');
  final _passwordController = TextEditingController(text: 'demo123456');
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final repo = ref.read(repositoryProvider);
      final users = await repo.getAllUsers();

      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email,
        orElse: () => throw ArgumentError('No account found with email "$email".'),
      );

      // In demo mode, switch to this user
      await ref.read(currentUserProvider.notifier).switchDemoRole(user.role);

      if (mounted) {
        if (user.isPending && user.role != UserRole.awareness && user.role != UserRole.admin) {
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

  void _fillSampleUser(String email, String label) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = 'demo123456';
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
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
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3228),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to access your role-specific dashboard and actions.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF4A5D54)),
                ),

                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.alertContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.alertRed.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.alertRed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.alertRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryGreen),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your email.';
                    }
                    if (!val.contains('@')) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                AppButton(
                  label: 'Sign In',
                  isLoading: _isLoading,
                  icon: Icons.login_rounded,
                  onPressed: _handleLogin,
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.register),
                    child: const Text("Don't have an account? Register here"),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                // Quick Pre-fill Samples
                const Text(
                  'SELECT TEST ACCOUNT TO AUTO-FILL:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAccountChip('Donor (Canteen)', 'donor@foodbridge.ngo'),
                    _buildAccountChip('NGO Staff', 'ngo@foodbridge.ngo'),
                    _buildAccountChip('Volunteer Driver', 'volunteer@foodbridge.ngo'),
                    _buildAccountChip('Awareness User', 'awareness@foodbridge.ngo'),
                    _buildAccountChip('System Admin', 'admin@foodbridge.ngo'),
                    _buildAccountChip('Pending Account', 'sunil@grandhotel.com', isPending: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountChip(String label, String email, {bool isPending = false}) {
    final isSelected = _emailController.text == email;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      avatar: isPending
          ? const Icon(Icons.pending_actions_rounded, size: 16, color: Colors.amber)
          : null,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : (isPending ? Colors.deepOrange : AppTheme.primaryGreen),
      ),
      selectedColor: isPending ? Colors.deepOrange : AppTheme.primaryGreen,
      backgroundColor: isPending ? const Color(0xFFFFF3E0) : AppTheme.primaryContainer.withOpacity(0.5),
      onSelected: (_) => _fillSampleUser(email, label),
    );
  }
}
