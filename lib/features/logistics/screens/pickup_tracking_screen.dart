import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
import '../widgets/dispatch_and_porter_sheet.dart';

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

  // Show Schedule Pickup Dialog with Dispatch Mode: Broadcast, Specific Volunteer, or Porter
  void _showScheduleDialog(DonationModel donation) {
    DispatchAndPorterSheet.show(context, donation);
  }

  // Open external Google Maps for driver navigation
  Future<void> _openGoogleMaps(double lat, double lng, String label) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps navigation.')),
        );
      }
    }
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
                          'Intake Accepted: Ready for Driver Dispatch',
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
                                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                              ),
                              title: Text(d.foodDescription, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              subtitle: Text('${d.listedQuantity} ${d.unit} • ${d.locationName}'),
                              trailing: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  minimumSize: const Size(90, 38),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                                icon: const Icon(Icons.local_shipping_rounded, size: 16),
                                label: const Text('Dispatch', style: TextStyle(fontSize: 12)),
                                onPressed: () => _showScheduleDialog(d),
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

              // Pickups Section for Volunteers and NGO Staff
              pickupsAsync.when(
                data: (pickups) {
                  final isVolunteer = user?.role == UserRole.volunteer;

                  // Separate open broadcast requests from assigned pickups
                  final openBroadcastPickups = pickups
                      .where((p) => p.assignedVolunteerId == null && p.status == PickupStatus.scheduled)
                      .toList();

                  final myOrAssignedPickups = pickups
                      .where((p) => p.assignedVolunteerId != null)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. OPEN BROADCAST REQUESTS (Volunteer view)
                      if (isVolunteer && openBroadcastPickups.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 6),
                            const Text(
                              'Open Broadcast Requests (Tap to Accept)',
                              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFFB78103)),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(10)),
                              child: Text('${openBroadcastPickups.length} Available', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...openBroadcastPickups.map((p) {
                          return Card(
                            elevation: 2,
                            color: const Color(0xFFFFFDF5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.amber.shade300, width: 1.5),
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
                                      Text(
                                        'Broadcast #${p.pickupId.toUpperCase()}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Unclaimed Pool',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Time Window: ${_formatHour(p.scheduledWindowStart)} - ${_formatHour(p.scheduledWindowEnd)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Status: Broadcasted to all nearby volunteer drivers in Pune. Ready for collection.',
                                    style: TextStyle(fontSize: 11.5, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 12),
                                  AppButton(
                                    label: 'Accept & Claim Pickup Now',
                                    icon: Icons.check_circle_rounded,
                                    variant: AppButtonVariant.primary,
                                    height: 44,
                                    onPressed: () async {
                                      final repo = ref.read(repositoryProvider);
                                      await repo.acceptPickupRequest(pickupId: p.pickupId);
                                      ref.invalidate(rolePickupsProvider);
                                      ref.invalidate(roleDonationsProvider);

                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppTheme.primaryGreen,
                                            content: Text('Accepted! Pickup #${p.pickupId.toUpperCase()} is assigned to you.'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],

                      // 2. ASSIGNED PICKUPS & PROGRESSION
                      Text(
                        isVolunteer ? 'My Active Trips & Collections' : 'All Scheduled Pickup Operations',
                        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
                      ),
                      const SizedBox(height: 8),

                      if (myOrAssignedPickups.isEmpty && openBroadcastPickups.isEmpty)
                        Card(
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
                                    isVolunteer
                                        ? 'You have no active trips. Look out for broadcast requests above.'
                                        : 'Accepted donations will appear above for dispatch.',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      ...myOrAssignedPickups.map((p) {
                        final isScheduled = p.status == PickupStatus.scheduled;
                        final isEnRoute = p.status == PickupStatus.enRoute;
                        final isCollected = p.status == PickupStatus.collected;
                        final isEnRouteFoodBank = p.status == PickupStatus.enRouteToFoodBank;
                        final isDelivered = p.status == PickupStatus.delivered;
                        final isCancelled = p.status == PickupStatus.cancelled;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Trip #${p.pickupId.toUpperCase()}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDelivered
                                            ? const Color(0xFFE8F5E9)
                                            : (isCancelled
                                                ? const Color(0xFFFFEBEE)
                                                : (isEnRoute || isEnRouteFoodBank
                                                    ? Colors.amber.shade100
                                                    : const Color(0xFFE1F5FE))),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        p.status.displayName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDelivered
                                              ? const Color(0xFF2E7D32)
                                              : (isCancelled
                                                  ? AppTheme.alertRed
                                                  : (isEnRoute || isEnRouteFoodBank
                                                      ? Colors.amber.shade900
                                                      : const Color(0xFF0277BD))),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Driver & Schedule Information
                                Row(
                                  children: [
                                    const Icon(Icons.person_pin_rounded, size: 16, color: AppTheme.primaryGreen),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Driver: ${p.assignedVolunteerName ?? "Unassigned"}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 16, color: Colors.black45),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Window: ${_formatHour(p.scheduledWindowStart)} - ${_formatHour(p.scheduledWindowEnd)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),

                                // Verified Weight info if collected
                                if (p.actualCollectedQuantity != null) ...[
                                  const SizedBox(height: 8),
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
                                          'Verified Weight: ${p.actualCollectedQuantity} ${p.actualQuantityUnit}',
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

                                const SizedBox(height: 12),

                                // Driver Stepwise Progression Action Buttons
                                if (isVolunteer) ...[
                                  if (isScheduled) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AppButton(
                                            label: 'Start Trip (En Route)',
                                            icon: Icons.directions_car_rounded,
                                            variant: AppButtonVariant.primary,
                                            height: 42,
                                            onPressed: () async {
                                              final repo = ref.read(repositoryProvider);
                                              await repo.updatePickupTripStatus(
                                                pickupId: p.pickupId,
                                                status: PickupStatus.enRoute,
                                              );
                                              ref.invalidate(rolePickupsProvider);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          tooltip: 'Get Directions to Donor',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.blue.shade50,
                                            foregroundColor: Colors.blue.shade700,
                                          ),
                                          icon: const Icon(Icons.navigation_rounded),
                                          onPressed: () => _openGoogleMaps(18.5204, 73.8567, 'Donor Location'),
                                        ),
                                      ],
                                    ),
                                  ] else if (isEnRoute) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AppButton(
                                            label: 'Arrived: Weigh & Confirm',
                                            icon: Icons.scale_rounded,
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
                                        IconButton(
                                          tooltip: 'Directions',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.blue.shade50,
                                            foregroundColor: Colors.blue.shade700,
                                          ),
                                          icon: const Icon(Icons.navigation_rounded),
                                          onPressed: () => _openGoogleMaps(18.5204, 73.8567, 'Donor Location'),
                                        ),
                                      ],
                                    ),
                                  ] else if (isCollected) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AppButton(
                                            label: 'En Route to Food Bank',
                                            icon: Icons.arrow_forward_rounded,
                                            variant: AppButtonVariant.primary,
                                            height: 42,
                                            onPressed: () async {
                                              final repo = ref.read(repositoryProvider);
                                              await repo.updatePickupTripStatus(
                                                pickupId: p.pickupId,
                                                status: PickupStatus.enRouteToFoodBank,
                                              );
                                              ref.invalidate(rolePickupsProvider);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          tooltip: 'Directions to Sevadeep Food Bank',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.blue.shade50,
                                            foregroundColor: Colors.blue.shade700,
                                          ),
                                          icon: const Icon(Icons.navigation_rounded),
                                          onPressed: () => _openGoogleMaps(18.5367, 73.8998, 'Sevadeep Platform, Kalyani Nagar'),
                                        ),
                                      ],
                                    ),
                                  ] else if (isEnRouteFoodBank) ...[
                                    AppButton(
                                      label: 'Drop-off Complete (Delivered)',
                                      icon: Icons.check_circle_outline_rounded,
                                      variant: AppButtonVariant.primary,
                                      height: 42,
                                      onPressed: () async {
                                        final repo = ref.read(repositoryProvider);
                                        await repo.updatePickupTripStatus(
                                          pickupId: p.pickupId,
                                          status: PickupStatus.delivered,
                                        );
                                        ref.invalidate(rolePickupsProvider);
                                        ref.invalidate(roleDonationsProvider);
                                      },
                                    ),
                                  ] else if (isDelivered) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '✅ Delivered to Sevadeep Platform Food Bank',
                                          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2E7D32), fontSize: 12.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ] else ...[
                                  // NGO staff actions: can cancel or view directions
                                  if (isScheduled || isEnRoute) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AppButton(
                                            label: 'Cancel Trip',
                                            icon: Icons.close_rounded,
                                            variant: AppButtonVariant.outline,
                                            height: 38,
                                            onPressed: () => _showCancelDialog(p),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: AppButton(
                                            label: 'Open Map',
                                            icon: Icons.map_rounded,
                                            variant: AppButtonVariant.secondary,
                                            height: 38,
                                            onPressed: () => context.push(AppRoutes.mapView),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
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
