import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/food_safety_disclaimer.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/state/donation_status_engine.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/pickup_model.dart';
import '../../../data/models/donation_model.dart';

class PickupTrackingScreen extends ConsumerStatefulWidget {
  const PickupTrackingScreen({super.key});

  @override
  ConsumerState<PickupTrackingScreen> createState() => _PickupTrackingScreenState();
}

class _PickupTrackingScreenState extends ConsumerState<PickupTrackingScreen> {
  // Show Confirm Collection Dialog
  void _showConfirmCollectionDialog(PickupModel pickup, DonationModel? donation) {
    final actualQtyController = TextEditingController(
      text: donation != null ? donation.listedQuantity.toString() : '20.0',
    );
    final notesController = TextEditingController();
    String unit = donation?.unit ?? 'kg';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.scale_rounded, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Confirm Collection'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Listed Donor Quantity: ${donation?.listedQuantity ?? 0} $unit',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'IMPORTANT: Record the ACTUAL measured food weight on pickup, deducting container tare weight.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: actualQtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Actual Collected Quantity ($unit) *',
                  prefixIcon: const Icon(Icons.scale_outlined, color: AppTheme.primaryGreen),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Driver Inspection Notes',
                  hintText: 'e.g. Insulated containers intact, weighed on scale',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final actual = double.tryParse(actualQtyController.text.trim());
              if (actual == null || actual <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.alertRed,
                    content: Text('Please enter a valid collected quantity (> 0).'),
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              final repo = ref.read(repositoryProvider);
              await repo.confirmCollection(
                pickupId: pickup.pickupId,
                actualCollectedQuantity: actual,
                actualQuantityUnit: unit,
                driverNotes: notesController.text.trim(),
              );

              ref.invalidate(rolePickupsProvider);
              ref.invalidate(roleDonationsProvider);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.primaryGreen,
                    content: Text('Collection confirmed: $actual $unit safely collected!'),
                  ),
                );
              }
            },
            child: const Text('Save & Confirm'),
          ),
        ],
      ),
    );
  }

  // Show Cancel Pickup Dialog
  void _showCancelDialog(PickupModel pickup) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.alertRed),
            SizedBox(width: 8),
            Text('Cancel Pickup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A mandatory cancellation reason is required for system audit tracking:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason *',
                hintText: 'e.g. Donor cancelled, transport breakdown',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alertRed),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.alertRed,
                    content: Text('Reason cannot be empty.'),
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              final repo = ref.read(repositoryProvider);
              await repo.cancelPickup(
                pickupId: pickup.pickupId,
                cancelReason: reason,
              );

              ref.invalidate(rolePickupsProvider);
              ref.invalidate(roleDonationsProvider);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.alertRed,
                    content: Text('Pickup cancelled and reason logged.'),
                  ),
                );
              }
            },
            child: const Text('Cancel Pickup'),
          ),
        ],
      ),
    );
  }

  // Show Schedule Pickup Dialog for Accepted Donation
  void _showScheduleDialog(DonationModel donation) {
    final start = DateTime.now().add(const Duration(minutes: 30));
    final end = DateTime.now().add(const Duration(hours: 2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Schedule Volunteer Pickup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Donation: ${donation.foodDescription}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('Offered: ${donation.listedQuantity} ${donation.unit} • ${donation.locationName}'),
            const SizedBox(height: 14),
            const Text('Assign Volunteer:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.directions_car_rounded, size: 18, color: AppTheme.primaryGreen),
                  SizedBox(width: 8),
                  Text('Alex Driver (Approved Volunteer)', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(repositoryProvider);
              await repo.schedulePickup(
                donationId: donation.donationId,
                assignedVolunteerId: 'user_volunteer_1',
                assignedVolunteerName: 'Alex Driver',
                scheduledWindowStart: start,
                scheduledWindowEnd: end,
              );

              ref.invalidate(rolePickupsProvider);
              ref.invalidate(roleDonationsProvider);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.primaryGreen,
                    content: Text('Pickup successfully scheduled and assigned to Alex Driver!'),
                  ),
                );
              }
            },
            child: const Text('Confirm Schedule'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final pickupsAsync = ref.watch(rolePickupsProvider);
    final donationsAsync = ref.watch(roleDonationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Logistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(rolePickupsProvider);
              ref.invalidate(roleDonationsProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FoodSafetyDisclaimerBanner(compact: true),

              const SizedBox(height: 8),

              // If NGO, show donations ready to schedule
              if (user?.role == UserRole.ngoStaff || user?.role == UserRole.admin) ...[
                donationsAsync.when(
                  data: (donations) {
                    final readyToSchedule = donations
                        .where((d) => d.status == DonationStatus.accepted)
                        .toList();

                    if (readyToSchedule.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Intake Accepted: Awaiting Pickup Scheduling',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
                        ),
                        const SizedBox(height: 6),
                        ...readyToSchedule.map((d) {
                          return Card(
                            color: const Color(0xFFE8F5E9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFC8E6C9)),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppTheme.primaryGreen,
                                child: Icon(Icons.schedule_send_rounded, color: Colors.white, size: 20),
                              ),
                              title: Text(d.foodDescription, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              subtitle: Text('${d.listedQuantity} ${d.unit} • ${d.locationName}'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  minimumSize: const Size(48, 38),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onPressed: () => _showScheduleDialog(d),
                                child: const Text('Schedule', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],

              // Pickups List
              Text(
                user?.role == UserRole.volunteer
                    ? 'My Assigned Collections'
                    : 'Scheduled Pickup Operations',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
              ),
              const SizedBox(height: 8),

              pickupsAsync.when(
                data: (pickups) {
                  if (pickups.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.local_shipping_outlined, size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text('No pickup records found.', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                user?.role == UserRole.volunteer
                                    ? 'You have no assigned pickups at this moment.'
                                    : 'Accepted donations will appear above for scheduling.',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                      final isCollected = p.status == PickupStatus.collected;
                      final isCancelled = p.status == PickupStatus.cancelled;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isCollected
                                          ? const Color(0xFFE8F5E9)
                                          : (isCancelled ? const Color(0xFFFFEBEE) : const Color(0xFFE1F5FE)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      p.status.displayName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isCollected
                                            ? const Color(0xFF2E7D32)
                                            : (isCancelled ? AppTheme.alertRed : const Color(0xFF0277BD)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Assigned Volunteer: ${p.assignedVolunteerName ?? "Unassigned"}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Time Window: ${_formatHour(p.scheduledWindowStart)} - ${_formatHour(p.scheduledWindowEnd)}',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              if (p.actualCollectedQuantity != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F8F5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_rounded, size: 16, color: AppTheme.primaryGreen),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Verified Actual Weight: ${p.actualCollectedQuantity} ${p.actualQuantityUnit}',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E6F5C)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (p.cancelReason != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Cancellation Reason: ${p.cancelReason}',
                                  style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                                ),
                              ],
                              if (isScheduled) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppButton(
                                        label: 'Confirm Collection',
                                        icon: Icons.check_circle_outline,
                                        variant: AppButtonVariant.primary,
                                        height: 42,
                                        onPressed: () {
                                          donationsAsync.whenData((list) {
                                            final d = list.where((item) => item.donationId == p.donationId).firstOrNull;
                                            _showConfirmCollectionDialog(p, d);
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: AppButton(
                                        label: 'Cancel',
                                        icon: Icons.close_rounded,
                                        variant: AppButtonVariant.outline,
                                        height: 42,
                                        onPressed: () => _showCancelDialog(p),
                                      ),
                                    ),
                                  ],
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

              const SizedBox(height: 24),
            ],
          ),
        ),
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
