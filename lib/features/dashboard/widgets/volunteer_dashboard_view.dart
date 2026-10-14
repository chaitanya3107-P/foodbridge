import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/pickup_model.dart';

class VolunteerDashboardView extends ConsumerWidget {
  final UserModel user;

  const VolunteerDashboardView({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickupsAsync = ref.watch(rolePickupsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Driver Logistics Console',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
          ),
          const SizedBox(height: 2),
          Text(
            'Volunteer: ${user.name} • Assigned Pickups Only',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D54)),
          ),

          const SizedBox(height: 16),

          // Volunteer KPI summary
          pickupsAsync.when(
            data: (pickups) {
              final activePickups = pickups
                  .where((p) => p.status == PickupStatus.scheduled || p.status == PickupStatus.enRoute)
                  .toList();
              final collectedPickups = pickups
                  .where((p) => p.status == PickupStatus.collected)
                  .toList();
              final totalKgCollected = collectedPickups.fold<double>(
                0.0,
                (sum, p) => sum + (p.actualCollectedQuantity ?? 0.0),
              );

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Active Pickups',
                          value: '${activePickups.length}',
                          icon: Icons.local_shipping_rounded,
                          color: const Color(0xFF0277BD),
                          bgColor: const Color(0xFFE1F5FE),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Completed Collections',
                          value: '${collectedPickups.length}',
                          icon: Icons.task_alt_rounded,
                          color: AppTheme.primaryGreen,
                          bgColor: AppTheme.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildKpiCard(
                    title: 'Total Actual Food Weighed & Collected',
                    value: '${totalKgCollected.toStringAsFixed(1)} kg',
                    icon: Icons.scale_rounded,
                    color: const Color(0xFF2E7D32),
                    bgColor: const Color(0xFFE8F5E9),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),

          const SizedBox(height: 20),

          // Today's Assigned Tasks
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Assigned Pickups',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E3228)),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.pickupTracking),
                child: const Text('View Logistics Page'),
              ),
            ],
          ),

          const SizedBox(height: 6),

          pickupsAsync.when(
            data: (pickups) {
              if (pickups.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.airport_shuttle_outlined, size: 36, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text(
                            'No pickups currently assigned to you.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'When the partner NGO schedules a pickup in your route, it will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: pickups.map((p) {
                  final isScheduled = p.status == PickupStatus.scheduled;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pickup #${p.pickupId.toUpperCase()}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isScheduled ? const Color(0xFFE1F5FE) : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  p.status.displayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isScheduled ? const Color(0xFF0277BD) : const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time_filled_rounded, size: 15, color: Colors.black54),
                              const SizedBox(width: 6),
                              Text(
                                'Window: ${_formatHour(p.scheduledWindowStart)} - ${_formatHour(p.scheduledWindowEnd)}',
                                style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          if (p.actualCollectedQuantity != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Actual Collected Weight: ${p.actualCollectedQuantity} ${p.actualQuantityUnit}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E6F5C)),
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (isScheduled)
                            AppButton(
                              label: 'Confirm Collection (Enter Actual kg)',
                              icon: Icons.check_circle_rounded,
                              variant: AppButtonVariant.primary,
                              height: 44,
                              onPressed: () => context.push(AppRoutes.pickupTracking),
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
  }) {
    return Container(
      width: double.infinity,
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
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF2C3E35)),
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
