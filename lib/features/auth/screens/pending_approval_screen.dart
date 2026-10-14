import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/user_model.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      final repo = ref.read(repositoryProvider);
      final users = await repo.getAllUsers();
      final fresh = users.firstWhere((u) => u.userId == currentUser.userId);

      if (fresh.isApproved) {
        ref.read(currentUserProvider.notifier).state = fresh;
        if (mounted) context.go(AppRoutes.home);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account is still awaiting administrator review.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }

    if (mounted) setState(() => _isChecking = false);
  }

  Future<void> _demoApproveInstantly() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final repo = ref.read(repositoryProvider);
    await repo.updateApprovalStatus(currentUser.userId, ApprovalStatus.approved);

    // Update active user state
    ref.read(currentUserProvider.notifier).state =
        currentUser.copyWith(approvalStatus: ApprovalStatus.approved);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primaryGreen,
          content: Text('Account for "${currentUser.name}" approved! Access granted.'),
        ),
      );
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Verification'),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(currentUserProvider.notifier).signOut();
              context.go(AppRoutes.welcome);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Animated/Clear Pending Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 46,
                  color: Color(0xFFF57F17),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Registration Awaiting Review',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3228),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'To maintain rigorous food safety, NGO hygiene intake protocols, and donor verification, all operational accounts are reviewed by an administrator before access is activated.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF4A5D54),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // Applicant Summary Card
              if (user != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2EBE5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Application Details',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const Divider(height: 18),
                      _buildDetailRow('Applicant Name', user.name),
                      const SizedBox(height: 8),
                      _buildDetailRow('Registered Email', user.email),
                      const SizedBox(height: 8),
                      _buildDetailRow('Applied Role', user.role.displayName),
                      const SizedBox(height: 8),
                      _buildDetailRow('Contact Phone', user.contactNumber),
                      const SizedBox(height: 8),
                      _buildDetailRow('Current Status', 'PENDING APPROVAL', isHighlight: true),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              AppButton(
                label: 'Refresh Verification Status',
                icon: Icons.refresh_rounded,
                isLoading: _isChecking,
                variant: AppButtonVariant.primary,
                onPressed: _checkStatus,
              ),

              const SizedBox(height: 14),

              // Demo Shortcut Button for Immediate Evaluation
              AppButton(
                label: '⚡ Instant Approve (Evaluation Demo)',
                variant: AppButtonVariant.secondary,
                onPressed: _demoApproveInstantly,
              ),

              const SizedBox(height: 24),

              // Visible Fallback Emergency Contact Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4ECE3)),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.headset_mic_outlined, size: 18, color: AppTheme.primaryGreen),
                        SizedBox(width: 8),
                        Text(
                          'Need expedited verification or urgent assistance?',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      AppConstants.fallbackSupportContact,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              TextButton.icon(
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Return to Welcome Screen'),
                onPressed: () {
                  ref.read(currentUserProvider.notifier).signOut();
                  context.go(AppRoutes.welcome);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isHighlight ? Colors.deepOrange : const Color(0xFF1E3228),
          ),
        ),
      ],
    );
  }
}
