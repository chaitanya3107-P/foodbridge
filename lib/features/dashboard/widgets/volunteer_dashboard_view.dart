import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/pickup_model.dart';
import '../../../data/models/donation_model.dart';
import '../../../data/seed/seed_data.dart';

class VolunteerDashboardView extends ConsumerStatefulWidget {
  final UserModel user;

  const VolunteerDashboardView({super.key, required this.user});

  @override
  ConsumerState<VolunteerDashboardView> createState() => _VolunteerDashboardViewState();
}

class _VolunteerDashboardViewState extends ConsumerState<VolunteerDashboardView> {
  // Show Confirm Collection Dialog right on the dashboard
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
            Text('Weigh & Confirm Pickup'),
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
                  'IMPORTANT: Deduct tare container weight and record verified food weight.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: actualQtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Actual Measured Quantity ($unit) *',
                  prefixIcon: const Icon(Icons.scale_outlined, color: AppTheme.primaryGreen),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Driver Inspection Notes',
                  hintText: 'e.g. Temperature checked, insulated containers intact',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
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
                    content: Text('Collection confirmed: $actual $unit verified and recorded!'),
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

  // Open Google Maps GPS navigation
  Future<void> _openGoogleMaps(double lat, double lng, String label) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coordinates: $lat, $lng ($label)')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final pickupsAsync = ref.watch(rolePickupsProvider);
    final donationsAsync = ref.watch(roleDonationsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver Header Console
          Text(
            'Driver Logistics Console',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
          ),
          const SizedBox(height: 2),
          Text(
            'Logged in as: ${user.name} • Pune Region',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D54)),
          ),

          const SizedBox(height: 12),

          // FAST DRIVER PROFILE SWITCHER FOR TESTING MULTIPLE DRIVERS
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEMO DRIVER SELECTOR (Test Multiple Drivers Accepting Requests):',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildDriverSelectChip('Alex Driver (Van)', 'user_volunteer_1', 2),
                    _buildDriverSelectChip('Rahul Patil (3W)', 'user_volunteer_2', 3),
                    _buildDriverSelectChip('Sneha Deshmukh (Bike)', 'user_volunteer_3', 4),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Volunteer KPI summary
          pickupsAsync.when(
            data: (pickups) {
              final activePickups = pickups
                  .where((p) =>
                      p.assignedVolunteerId == user.userId &&
                      (p.status == PickupStatus.scheduled ||
                          p.status == PickupStatus.enRoute ||
                          p.status == PickupStatus.enRouteToFoodBank))
                  .toList();
              final collectedPickups = pickups
                  .where((p) =>
                      p.assignedVolunteerId == user.userId &&
                      (p.status == PickupStatus.collected || p.status == PickupStatus.delivered))
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
                          title: 'Active Trips',
                          value: '${activePickups.length}',
                          icon: Icons.local_shipping_rounded,
                          color: const Color(0xFF0277BD),
                          bgColor: const Color(0xFFE1F5FE),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Deliveries Made',
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
                    title: 'Total Verified Surplus Food Weighed',
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

          const SizedBox(height: 12),

          // Pune Navigation & Map Banner
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
                  Icon(Icons.directions_rounded, color: Colors.blue.shade700, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open Pune Navigation & Pickup Map',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                        ),
                        Text(
                          'Sevadeep Platform, Kalyani Nagar & Pune Donor Kitchens',
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

          // PICKUPS: OPEN BROADCAST REQUESTS + ASSIGNED TRIPS
          pickupsAsync.when(
            data: (pickups) {
              final openBroadcasts = pickups
                  .where((p) => p.assignedVolunteerId == null && p.status == PickupStatus.scheduled)
                  .toList();
              final myPickups = pickups
                  .where((p) => p.assignedVolunteerId == user.userId)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. OPEN BROADCAST REQUESTS (PROMINENT ALERT WITH 1-TAP ACCEPT)
                  if (openBroadcasts.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, color: Color(0xFFD97706), size: 22),
                        const SizedBox(width: 6),
                        const Text(
                          '⚡ Incoming Pickup Request (Broadcast Pool)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(10)),
                          child: Text('${openBroadcasts.length} Available', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ...openBroadcasts.map((p) {
                      return Card(
                        elevation: 3,
                        color: const Color(0xFFFFFBEB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.amber.shade400, width: 2.0),
                        ),
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Request #${p.pickupId.toUpperCase()}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: Colors.amber.shade200, borderRadius: BorderRadius.circular(8)),
                                    child: const Text('Open to All Drivers', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF78350F))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Icon(Icons.trip_origin_rounded, size: 15, color: Colors.green),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Pickup: GreenLeaf Campus Canteen (COEP Tech, Shivajinagar)',
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 15, color: AppTheme.alertRed),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Drop-off: Sevadeep Platform Food Bank (Shop No. 14, 14th Floor, Manikchand Ikon, Kalyani Nagar)',
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Time Window: ${_formatHour(p.scheduledWindowStart)} - ${_formatHour(p.scheduledWindowEnd)}',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              const SizedBox(height: 14),

                              // BIG ACCEPT & CLAIM BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                                  label: Text(
                                    'Accept & Claim Route as ${user.name}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  onPressed: () async {
                                    final repo = ref.read(repositoryProvider);
                                    await repo.acceptPickupRequest(pickupId: p.pickupId);
                                    ref.invalidate(rolePickupsProvider);
                                    ref.invalidate(roleDonationsProvider);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppTheme.primaryGreen,
                                          content: Text('Route claimed by ${user.name}! Proceed to donor pickup.'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                  ],

                  // 2. MY ASSIGNED TRIPS & STEPWISE PROGRESSION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Active Trips & Collections',
                        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.pickupTracking),
                        child: const Text('Logistics Console'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (myPickups.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.airport_shuttle_outlined, size: 36, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text(
                                'No trips currently claimed by you.',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                openBroadcasts.isNotEmpty
                                    ? 'Tap "Accept & Claim Route" above to claim today\'s open broadcast pickup.'
                                    : 'When an NGO coordinator broadcasts or assigns a pickup, it will appear here.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...myPickups.map((p) {
                      final isScheduled = p.status == PickupStatus.scheduled;
                      final isEnRoute = p.status == PickupStatus.enRoute;
                      final isCollected = p.status == PickupStatus.collected;
                      final isEnRouteFoodBank = p.status == PickupStatus.enRouteToFoodBank;
                      final isDelivered = p.status == PickupStatus.delivered;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Trip #${p.pickupId.toUpperCase()}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDelivered ? const Color(0xFFE8F5E9) : const Color(0xFFE1F5FE),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      p.status.displayName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDelivered ? const Color(0xFF2E7D32) : const Color(0xFF0277BD),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              const Text(
                                'Drop Destination: Sevadeep Platform Food Bank, Shop No. 14, 14th Floor, Manikchand Ikon, Kalyani Nagar',
                                style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Window: ${_formatHour(p.scheduledWindowStart)} - ${_formatHour(p.scheduledWindowEnd)}',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),

                              if (p.actualCollectedQuantity != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFFF4F8F5), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_rounded, size: 16, color: AppTheme.primaryGreen),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Verified Collected Weight: ${p.actualCollectedQuantity} ${p.actualQuantityUnit}',
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E6F5C)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),

                              // STEPWISE ACTION BUTTONS FOR DRIVER
                              if (isScheduled) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppButton(
                                        label: 'Start Trip (En Route)',
                                        icon: Icons.directions_car_rounded,
                                        variant: AppButtonVariant.primary,
                                        height: 44,
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
                                      tooltip: 'GPS Directions to Donor',
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.blue.shade50,
                                        foregroundColor: Colors.blue.shade700,
                                      ),
                                      icon: const Icon(Icons.navigation_rounded),
                                      onPressed: () => _openGoogleMaps(18.5293, 73.8565, 'Donor Canteen, Shivajinagar'),
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
                                        height: 44,
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
                                      onPressed: () => _openGoogleMaps(18.5293, 73.8565, 'Donor Location'),
                                    ),
                                  ],
                                ),
                              ] else if (isCollected) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppButton(
                                        label: 'En Route to Sevadeep Food Bank',
                                        icon: Icons.arrow_forward_rounded,
                                        variant: AppButtonVariant.primary,
                                        height: 44,
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
                                      tooltip: 'Directions to Sevadeep Platform',
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
                                  label: 'Delivered: Complete Food Bank Drop',
                                  icon: Icons.check_circle_outline_rounded,
                                  variant: AppButtonVariant.primary,
                                  height: 44,
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
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '✅ Successfully Delivered to Sevadeep Platform Food Bank',
                                      style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2E7D32), fontSize: 13),
                                    ),
                                  ),
                                ),
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

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDriverSelectChip(String label, String driverId, int seedIndex) {
    final isCurrent = widget.user.userId == driverId;
    return ChoiceChip(
      selected: isCurrent,
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: Colors.white,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          color: isCurrent ? Colors.white : Colors.black87,
        ),
      ),
      onSelected: (_) {
        ref.read(currentUserProvider.notifier).state = SeedData.users[seedIndex];
      },
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
