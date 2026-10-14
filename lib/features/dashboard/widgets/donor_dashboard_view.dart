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
import '../../../data/models/donation_model.dart';

class DonorDashboardView extends ConsumerWidget {
  final UserModel user;

  const DonorDashboardView({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(roleDonationsProvider);
    final auditsAsync = ref.watch(wasteAuditsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donor Header Greeting
          Text(
            'Welcome, ${user.name}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
          ),
          const SizedBox(height: 2),
          Text(
            user.organisationId != null
                ? 'Organisation: GreenLeaf Campus Canteen'
                : 'Independent Food Donor',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D54)),
          ),

          const SizedBox(height: 16),

          // Primary Donor Action Buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: '+ Create Donation',
                  icon: Icons.add_circle_outline_rounded,
                  variant: AppButtonVariant.primary,
                  height: 48,
                  onPressed: () => context.push(AppRoutes.createDonation),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Log Waste Audit',
                  icon: Icons.scale_rounded,
                  variant: AppButtonVariant.secondary,
                  height: 48,
                  onPressed: () => context.push(AppRoutes.wasteAudit),
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
              final activePickupsCount = donations
                  .where((d) =>
                      d.status == DonationStatus.accepted ||
                      d.status == DonationStatus.pickupScheduled)
                  .length;
              final completedCount = donations
                  .where((d) =>
                      d.status == DonationStatus.collected ||
                      d.status == DonationStatus.closed)
                  .length;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Awaiting NGO Review',
                          value: '$awaitingReviewCount',
                          icon: Icons.hourglass_top_rounded,
                          color: const Color(0xFFF57F17),
                          bgColor: const Color(0xFFFFF8E1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Pickups Scheduled',
                          value: '$activePickupsCount',
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
                          title: 'Completed Donations',
                          value: '$completedCount',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppTheme.primaryGreen,
                          bgColor: AppTheme.primaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: auditsAsync.when(
                          data: (audits) {
                            final latestWasteRate =
                                audits.isNotEmpty ? '${audits.first.wasteRatePercent}%' : 'N/A';
                            return _buildKpiCard(
                              title: 'Latest Waste Rate',
                              value: latestWasteRate,
                              icon: Icons.trending_down_rounded,
                              color: const Color(0xFF2E7D32),
                              bgColor: const Color(0xFFE8F5E9),
                            );
                          },
                          loading: () => _buildKpiCard(title: 'Latest Waste Rate', value: '...', icon: Icons.trending_down_rounded, color: Colors.grey, bgColor: Colors.grey.shade100),
                          error: (_, __) => _buildKpiCard(title: 'Latest Waste Rate', value: '0.0%', icon: Icons.trending_down_rounded, color: Colors.grey, bgColor: Colors.grey.shade100),
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

          // Recent Listings Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Food Listings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E3228)),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.impactReport),
                child: const Text('View All & Export'),
              ),
            ],
          ),

          const SizedBox(height: 6),

          donationsAsync.when(
            data: (donations) {
              if (donations.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text(
                            'No active donations listed.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Click "+ Create Donation" above to list today\'s surplus.',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: donations.take(4).map((d) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  d.foodDescription,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                ),
                              ),
                              StatusBadge(status: d.status, isSmall: true),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '${d.listedQuantity} ${d.unit} • ${d.foodCategory}',
                                style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                              ),
                              const Spacer(),
                              Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Deadline: ${_formatHour(d.pickupDeadline)}',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                          if (d.status == DonationStatus.clarificationRequested) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBE9E7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 16, color: Color(0xFFD84315)),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'NGO requested details. Tap to review and update.',
                                      style: TextStyle(fontSize: 11.5, color: Color(0xFFBF360C), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
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

  String _formatHour(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }
}
