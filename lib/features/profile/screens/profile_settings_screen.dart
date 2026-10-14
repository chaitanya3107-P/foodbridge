import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/user_model.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  bool _notifyNewListings = true;
  bool _notifyStatusUpdates = true;
  bool _notifyPickupReminders = true;
  bool _notifyCancellations = true;
  bool _notifyExpiryReminders = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Identity Profile Card
              if (user != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          child: Text(
                            user.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  user.role.displayName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 18),

              // Organisation Details Section
              const Text(
                'Organisation Profile',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    children: [
                      _buildProfileRow('Entity Name', user?.organisationId != null ? 'GreenLeaf Campus Canteen' : 'Community Individual'),
                      _buildProfileRow('Verification Status', 'Verified Partner NGO/Donor', isVerified: true),
                      _buildProfileRow('Operating Area', 'University North Campus, Sector 4'),
                      _buildProfileRow('Operating Hours', '07:30 - 21:00 Daily'),
                      _buildProfileRow('Primary Contact Phone', user?.contactNumber ?? '+91 98234 56789'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Notification Settings (FCM simulation)
              const Text(
                'Push Notifications (FCM)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
              ),
              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('New Listing Dispatches (NGO)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Instant alert when donors submit surplus for intake', style: TextStyle(fontSize: 11.5)),
                      value: _notifyNewListings,
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (val) => setState(() => _notifyNewListings = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Intake Review Decisions (Donor)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Updates on Accepted, Clarification, or Rejected status', style: TextStyle(fontSize: 11.5)),
                      value: _notifyStatusUpdates,
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (val) => setState(() => _notifyStatusUpdates = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Pickup Time Window Reminders', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Notifies driver and donor 30 mins before pickup', style: TextStyle(fontSize: 11.5)),
                      value: _notifyPickupReminders,
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (val) => setState(() => _notifyPickupReminders = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Cancellation Alerts', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Alerts all parties if vehicle breakdown or cancellation occurs', style: TextStyle(fontSize: 11.5)),
                      value: _notifyCancellations,
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (val) => setState(() => _notifyCancellations = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Pickup Deadline Expiry Warnings', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Warns when food is within 1 hour of pickup deadline', style: TextStyle(fontSize: 11.5)),
                      value: _notifyExpiryReminders,
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (val) => setState(() => _notifyExpiryReminders = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Privacy & Data Minimization Policy
              const Text(
                'Safety, Privacy & Compliance',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2EBE5)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.privacy_tip_outlined, size: 18, color: AppTheme.primaryGreen),
                        SizedBox(width: 8),
                        Text('Privacy Standards', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• Minimal Personal Data: Contact phone and location are visible strictly to verified actors for assigned collections.\n'
                      '• Recipient Dignity: No beneficiary names or photos are collected or shared.\n'
                      '• NGO Primacy: App supports partner NGO safety procedures and does not replace them.',
                      style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Emergency Fallback Contact Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCCD9D1)),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.support_agent_rounded, size: 20, color: AppTheme.primaryGreen),
                        SizedBox(width: 8),
                        Text('Emergency Fallback Contact', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppConstants.fallbackSupportContact,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sign Out Button
              AppButton(
                label: 'Sign Out',
                icon: Icons.logout_rounded,
                variant: AppButtonVariant.outline,
                onPressed: () {
                  ref.read(currentUserProvider.notifier).signOut();
                  context.go(AppRoutes.welcome);
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, {bool isVerified = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Row(
            children: [
              if (isVerified) ...[
                const Icon(Icons.verified_rounded, size: 14, color: AppTheme.primaryGreen),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isVerified ? AppTheme.primaryGreen : const Color(0xFF1E3228),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
