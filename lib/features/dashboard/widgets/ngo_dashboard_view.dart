import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/state/donation_status_engine.dart';
import '../../../data/models/user_model.dart';

class NgoDashboardView extends ConsumerWidget {
  final UserModel user;

  const NgoDashboardView({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(roleDonationsProvider);
    final pickupsAsync = ref.watch(rolePickupsProvider);
    final distributionsAsync = ref.watch(distributionsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NGO Header
          Text(
            'NGO Logistics & Safety Hub',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
          ),
          const SizedBox(height: 2),
          Text(
            'Reviewer: ${user.name} • City Harvest Food Bank',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D54)),
          ),

          const SizedBox(height: 16),

          // Primary NGO Action Buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Review Listings',
                  icon: Icons.rate_review_outlined,
                  variant: AppButtonVariant.primary,
                  height: 48,
                  onPressed: () => context.push(AppRoutes.availableDonations),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Food Bank Ledger',
                  icon: Icons.menu_book_rounded,
                  variant: AppButtonVariant.outline,
                  height: 48,
                  onPressed: () => context.push(AppRoutes.foodBankRecords),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // KPI Summary Cards
          donationsAsync.when(
            data: (donations) {
              final awaitingReviewCount = donations
                  .where((d) => d.status == DonationStatus.awaitingNgoReview)
                  .length;
              final scheduledCount = donations
                  .where((d) => d.status == DonationStatus.pickupScheduled)
                  .length;
              final collectedCount = donations
                  .where((d) => d.status == DonationStatus.collected)
                  .length;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Awaiting NGO Review',
                          value: '$awaitingReviewCount',
                          icon: Icons.notification_important_rounded,
                          color: const Color(0xFFE65100),
                          bgColor: const Color(0xFFFFF3E0),
                          isUrgent: awaitingReviewCount > 0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Pickups Scheduled',
                          value: '$scheduledCount',
                          icon: Icons.local_shipping_outlined,
                          color: const Color(0xFF0277BD),
                          bgColor: const Color(0xFFE1F5FE),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Ready for Distribution',
                          value: '$collectedCount',
                          icon: Icons.inventory_rounded,
                          color: AppTheme.primaryGreen,
                          bgColor: AppTheme.primaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: distributionsAsync.when(
                          data: (dists) {
                            final totalKg = dists.fold<double>(
                              0.0,
                              (sum, d) => sum + d.quantityDistributed,
                            );
                            return _buildKpiCard(
                              title: 'Verified Distributed',
                              value: '${totalKg.toStringAsFixed(0)} kg',
                              icon: Icons.volunteer_activism_rounded,
                              color: const Color(0xFF2E7D32),
                              bgColor: const Color(0xFFE8F5E9),
                            );
                          },
                          loading: () => _buildKpiCard(title: 'Verified Distributed', value: '...', icon: Icons.volunteer_activism_rounded, color: Colors.grey, bgColor: Colors.grey.shade100),
                          error: (_, __) => _buildKpiCard(title: 'Verified Distributed', value: '0 kg', icon: Icons.volunteer_activism_rounded, color: Colors.grey, bgColor: Colors.grey.shade100),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading stats: $e'),
          ),

          const SizedBox(height: 20),

          // Immediate Review Queue Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 18, color: AppTheme.primaryGreen),
                  SizedBox(width: 6),
                  Text(
                    'Incoming Intake Queue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E3228)),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.availableDonations),
                child: const Text('View All'),
              ),
            ],
          ),

          const SizedBox(height: 6),

          donationsAsync.when(
            data: (donations) {
              final pendingDonations = donations
                  .where((d) => d.status == DonationStatus.awaitingNgoReview)
                  .toList();

              if (pendingDonations.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 36, color: AppTheme.primaryGreen),
                          const SizedBox(height: 8),
                          const Text(
                            'Review queue is clear!',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No donations currently awaiting safety review.',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: pendingDonations.map((d) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  d.foodDescription,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ),
                              StatusBadge(status: d.status, isSmall: true),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Offered: ${d.listedQuantity} ${d.unit} • Storage: ${d.storageCondition}',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Donor Org: ${d.donorOrgName} • Location: ${d.locationName}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            label: 'Conduct Intake Safety Review',
                            icon: Icons.fact_check_outlined,
                            variant: AppButtonVariant.primary,
                            height: 44,
                            onPressed: () => context.push(AppRoutes.availableDonations),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    bool isUrgent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent ? Colors.deepOrange : color.withOpacity(0.3),
          width: isUrgent ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E35),
            ),
          ),
        ],
      ),
    );
  }
}
