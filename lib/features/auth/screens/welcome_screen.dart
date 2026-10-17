import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/food_safety_disclaimer.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/user_model.dart';
import '../../../data/seed/seed_data.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userNotifier = ref.read(currentUserProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // App Brand Logo & Name
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A5D54),
                ),
              ),

              const SizedBox(height: 20),

              // Mandatory NGO Food Safety Notice
              const FoodSafetyDisclaimerBanner(),

              const SizedBox(height: 16),

              // Three Pillar Cards
              _buildFeaturePillar(
                icon: Icons.restaurant_rounded,
                title: 'Surplus Food Coordination',
                description:
                    'Canteens, restaurants & caterers safely coordinate surplus batches with verified partner food banks.',
              ),
              const SizedBox(height: 12),
              _buildFeaturePillar(
                icon: Icons.verified_user_rounded,
                title: 'NGO Review & Verification',
                description:
                    'Partner NGOs hold sole authority. Every donation is reviewed with customizable safety checklists before dispatch.',
              ),
              const SizedBox(height: 12),
              _buildFeaturePillar(
                icon: Icons.analytics_rounded,
                title: 'Audit & Impact Accounting',
                description:
                    'Daily waste audits, verified diverted kilograms, transparent distribution ledgers, and printable reports.',
              ),

              const SizedBox(height: 28),

              // Primary Actions
              AppButton(
                label: 'Create Account / Register',
                icon: Icons.person_add_alt_1_rounded,
                variant: AppButtonVariant.primary,
                onPressed: () => context.push(AppRoutes.register),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Sign In to Existing Account',
                icon: Icons.login_rounded,
                variant: AppButtonVariant.outline,
                onPressed: () => context.push(AppRoutes.login),
              ),

              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 12),

              // Fast Demo Switcher for Evaluation
              const Text(
                'QUICK DEMO ACCESS (1-TAP LOGIN)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _buildDemoChip(
                    label: 'Step 1: Donor (Chef Anand)',
                    icon: Icons.storefront_rounded,
                    onTap: () async {
                      await userNotifier.switchDemoRole(UserRole.donor);
                      if (context.mounted) context.go(AppRoutes.home);
                    },
                  ),
                  _buildDemoChip(
                    label: 'Step 2: NGO Staff (Sarah / Sevadeep)',
                    icon: Icons.verified_user_rounded,
                    onTap: () async {
                      await userNotifier.switchDemoRole(UserRole.ngoStaff);
                      if (context.mounted) context.go(AppRoutes.home);
                    },
                  ),
                  _buildDemoChip(
                    label: 'Step 3: Driver 1 (Alex)',
                    icon: Icons.local_shipping_rounded,
                    onTap: () async {
                      ref.read(currentUserProvider.notifier).state = SeedData.users[2];
                      if (context.mounted) context.go(AppRoutes.home);
                    },
                  ),
                  _buildDemoChip(
                    label: 'Driver 2 (Rahul Patil)',
                    icon: Icons.electric_moped_rounded,
                    onTap: () async {
                      ref.read(currentUserProvider.notifier).state = SeedData.users[3];
                      if (context.mounted) context.go(AppRoutes.home);
                    },
                  ),
                  _buildDemoChip(
                    label: 'Driver 3 (Sneha Deshmukh)',
                    icon: Icons.directions_car_rounded,
                    onTap: () async {
                      ref.read(currentUserProvider.notifier).state = SeedData.users[4];
                      if (context.mounted) context.go(AppRoutes.home);
                    },
                  ),
                  _buildDemoChip(
                    label: 'Awareness User',
                    icon: Icons.menu_book_rounded,
                    onTap: () async {
                      await userNotifier.switchDemoRole(UserRole.awareness);
                      if (context.mounted) context.go(AppRoutes.home);
                    },
                  ),
                  _buildDemoChip(
                    label: 'Administrator',
                    icon: Icons.admin_panel_settings_rounded,
                    onTap: () async {
                      await userNotifier.switchDemoRole(UserRole.admin);
                      if (context.mounted) context.go(AppRoutes.home);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePillar({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EBE5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1E3228),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF4A5D54),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppTheme.primaryGreen),
      label: Text(label),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryGreen,
      ),
      backgroundColor: AppTheme.primaryContainer.withOpacity(0.5),
      side: const BorderSide(color: Color(0xFFB8D9CC)),
      onPressed: onTap,
    );
  }
}
