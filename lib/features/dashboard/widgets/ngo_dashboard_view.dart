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
import '../../donations/screens/ngo_review_screen.dart';
import '../../logistics/widgets/dispatch_and_porter_sheet.dart';

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
            'Reviewer: ${user.name} • Sevadeep / City Harvest Food Bank',
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
                  label: 'Logistics Console',
                  icon: Icons.local_shipping_outlined,
                  variant: AppButtonVariant.secondary,
                  height: 48,
                  onPressed: () => context.push(AppRoutes.pickupTracking),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Pune NGO Map Quick Access Banner
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push(AppRoutes.mapView),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.map_rounded, color: Colors.blue.shade700, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pune Food Rescue Map & Live Status',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                        ),
                        Text(
                          'Sevadeep Platform, Kalyani Nagar & Pune Intake Network',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.blue.shade700),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // KPI Summary Cards
          donationsAsync.when(
            data: (donations) {
              final awaitingReviewCount = donations
                  .where((d) => d.status == DonationStatus.awaitingNgoReview)
                  .length;
              final readyToDispatchCount = donations
                  .where((d) => d.status == DonationStatus.accepted)
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
                          title: 'Awaiting Review',
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
                          title: 'Ready to Dispatch',
                          value: '$readyToDispatchCount',
                          icon: Icons.schedule_send_rounded,
                          color: const Color(0xFF00695C),
                          bgColor: const Color(0xFFE0F2F1),
                          isUrgent: readyToDispatchCount > 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Pickups Scheduled',
                          value: '$scheduledCount',
                          icon: Icons.local_shipping_outlined,
                          color: const Color(0xFF0277BD),
                          bgColor: const Color(0xFFE1F5FE),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Ready for Distribution',
                          value: '$collectedCount',
                          icon: Icons.inventory_rounded,
                          color: AppTheme.primaryGreen,
                          bgColor: AppTheme.primaryContainer,
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

          const SizedBox(height: 18),

          // 1. INTAKE ACCEPTED: READY FOR DRIVER DISPATCH & PORTER BOOKING
          donationsAsync.when(
            data: (donations) {
              final acceptedDonations = donations
                  .where((d) => d.status == DonationStatus.accepted)
                  .toList();

              if (acceptedDonations.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_rounded, color: Color(0xFF00695C), size: 20),
                      const SizedBox(width: 6),
                      const Text(
                        'Step 2: Intake Accepted (Dispatch Driver / Porter)',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF004D40)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(10)),
                        child: Text('${acceptedDonations.length} Action Needed', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...acceptedDonations.map((d) {
                    return Card(
                      color: const Color(0xFFF0FDF4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFA7F3D0), width: 1.5),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    d.foodDescription,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Intake Approved', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Offered: ${d.listedQuantity} ${d.unit} • Storage: ${d.storageCondition}',
                              style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pickup Point: ${d.locationName} (${d.locationAddress})',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.flash_on_rounded, size: 16),
                                    label: const Text('Broadcast to Drivers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                    onPressed: () => DispatchAndPorterSheet.show(context, d),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue.shade800,
                                      side: BorderSide(color: Colors.blue.shade700),
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.local_shipping_rounded, size: 16),
                                    label: const Text('Book Porter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                    onPressed: () => DispatchAndPorterSheet.show(context, d),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 2. INCOMING INTAKE QUEUE (AWAITING NGO REVIEW)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 18, color: AppTheme.primaryGreen),
                  SizedBox(width: 6),
                  Text(
                    'Step 1: Incoming Intake Queue',
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NgoReviewScreen(donation: d),
                                ),
                              );
                            },
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
          color: isUrgent ? color : color.withOpacity(0.3),
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
