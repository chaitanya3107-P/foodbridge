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
import '../../../data/models/pickup_model.dart';

class DonorDashboardView extends ConsumerWidget {
  final UserModel user;

  const DonorDashboardView({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(roleDonationsProvider);
    final auditsAsync = ref.watch(wasteAuditsProvider);
    final pickupsAsync = ref.watch(rolePickupsProvider);

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
                          'Pune NGO Network & Live Map',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                        ),
                        Text(
                          'Explore verified intake centers, live status & get directions',
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
              final activePickupsCount = donations
                  .where((d) =>
                      d.status == DonationStatus.accepted ||
                      d.status == DonationStatus.pickupScheduled)
                  .length;
              final completedCount = donations
                  .where((d) =>
                      d.status == DonationStatus.collected ||
                      d.status == DonationStatus.distributionRecorded ||
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

          const SizedBox(height: 18),

          // LIVE LOGISTICS & DRIVER TRACKING SECTION
          pickupsAsync.when(
            data: (pickups) {
              if (pickups.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.radar_rounded, color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 6),
                      const Text(
                        'Live Driver Tracking & Food Bank Drop',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                        child: const Text('Real-Time', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...pickups.map((p) {
                    final isEnRoute = p.status == PickupStatus.enRoute;
                    final isCollected = p.status == PickupStatus.collected;
                    final isEnRouteFoodBank = p.status == PickupStatus.enRouteToFoodBank;
                    final isDelivered = p.status == PickupStatus.delivered;
                    final isCancelled = p.status == PickupStatus.cancelled;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDelivered
                              ? const Color(0xFF81C784)
                              : (isEnRoute || isEnRouteFoodBank ? Colors.orange.shade300 : Colors.blue.shade200),
                          width: 1.5,
                        ),
                      ),
                      color: isDelivered ? const Color(0xFFF9FFF9) : const Color(0xFFFAFDFF),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Trip header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isDelivered
                                          ? Icons.verified_rounded
                                          : (isEnRoute || isEnRouteFoodBank ? Icons.delivery_dining_rounded : Icons.local_shipping_rounded),
                                      color: isDelivered ? AppTheme.primaryGreen : Colors.blue.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Trip #${p.pickupId.toUpperCase()}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDelivered
                                        ? const Color(0xFFE8F5E9)
                                        : (isCancelled
                                            ? const Color(0xFFFFEBEE)
                                            : (isEnRoute || isEnRouteFoodBank
                                                ? Colors.orange.shade100
                                                : const Color(0xFFE1F5FE))),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    p.status.displayName,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDelivered
                                          ? const Color(0xFF2E7D32)
                                          : (isCancelled
                                              ? AppTheme.alertRed
                                              : (isEnRoute || isEnRouteFoodBank
                                                  ? Colors.orange.shade900
                                                  : const Color(0xFF0277BD))),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Driver and vehicle info
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: p.assignedVolunteerId != null ? AppTheme.primaryGreen : Colors.amber.shade700,
                                    child: Icon(
                                      p.assignedVolunteerId != null ? Icons.person_rounded : Icons.radar_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.assignedVolunteerName ?? 'Awaiting Driver Claim (Broadcast Pool)',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                                        ),
                                        Text(
                                          p.assignedVolunteerId != null
                                              ? 'Contact: +91 98220 12345 • GPS Active'
                                              : 'Alert broadcasted to 3 nearby Pune drivers',
                                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Visual Step Progress Indicator
                            _buildTripTimeline(p),

                            const SizedBox(height: 10),

                            // Drop Location summary
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primaryGreen),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Destination: Sevadeep Platform, Shop No. 14, 14th Floor Manikchand Ikon, Kalyani Nagar',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (p.actualCollectedQuantity != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Verified Actual Food Collected: ${p.actualCollectedQuantity} ${p.actualQuantityUnit}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E6F5C)),
                              ),
                            ],

                            const SizedBox(height: 10),

                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.map_rounded, size: 16),
                              label: const Text('View Live Driver Route on Map', style: TextStyle(fontSize: 12)),
                              onPressed: () => context.push(AppRoutes.mapView),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

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
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Color(0xFFD84315)),
                                  SizedBox(width: 6),
                                  Expanded(
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

  // Visual Step Timeline Widget
  Widget _buildTripTimeline(PickupModel pickup) {
    final status = pickup.status;
    final isDriverAssigned = pickup.assignedVolunteerId != null;
    final isEnRoute = status == PickupStatus.enRoute;
    final isCollected = status == PickupStatus.collected;
    final isEnRouteFoodBank = status == PickupStatus.enRouteToFoodBank;
    final isDelivered = status == PickupStatus.delivered;

    final step1Done = true; // Intake accepted
    final step2Done = isDriverAssigned;
    final step3Done = isEnRoute || isCollected || isEnRouteFoodBank || isDelivered;
    final step4Done = isCollected || isEnRouteFoodBank || isDelivered;
    final step5Done = isDelivered;

    return Row(
      children: [
        _buildTimelineNode('Approved', step1Done),
        _buildTimelineLine(step2Done),
        _buildTimelineNode('Assigned', step2Done),
        _buildTimelineLine(step3Done),
        _buildTimelineNode('En Route', step3Done),
        _buildTimelineLine(step4Done),
        _buildTimelineNode('Weighed', step4Done),
        _buildTimelineLine(step5Done),
        _buildTimelineNode('Delivered', step5Done),
      ],
    );
  }

  Widget _buildTimelineNode(String label, bool isDone) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: isDone ? AppTheme.primaryGreen : Colors.grey.shade300,
            child: Icon(
              isDone ? Icons.check : Icons.circle,
              size: 10,
              color: isDone ? Colors.white : Colors.transparent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
              color: isDone ? const Color(0xFF1B5E20) : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(bool isDone) {
    return Container(
      width: 14,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: isDone ? AppTheme.primaryGreen : Colors.grey.shade300,
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
