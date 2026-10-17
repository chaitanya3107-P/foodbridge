import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/donation_model.dart';
import '../../../data/models/user_model.dart';

/// Comprehensive modal sheet allowing NGO coordinators to dispatch a pickup via:
/// 1. Broadcast to all volunteer drivers (open pool)
/// 2. Direct volunteer assignment
/// 3. Porter on-demand delivery booking interface
class DispatchAndPorterSheet extends ConsumerStatefulWidget {
  final DonationModel donation;

  const DispatchAndPorterSheet({super.key, required this.donation});

  static Future<void> show(BuildContext context, DonationModel donation) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DispatchAndPorterSheet(donation: donation),
    );
  }

  @override
  ConsumerState<DispatchAndPorterSheet> createState() => _DispatchAndPorterSheetState();
}

class _DispatchAndPorterSheetState extends ConsumerState<DispatchAndPorterSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Volunteer assignment state
  String _selectedVolunteerId = 'user_volunteer_1';
  String _selectedVolunteerName = 'Alex Driver (Van - 250kg)';

  // Porter booking state
  String _porterVehicleType = '3W'; // 2W, 3W, TATA_ACE
  bool _isPorterSubmitting = false;

  final _volunteerDrivers = [
    {'id': 'user_volunteer_1', 'name': 'Alex Driver (Van - 250kg capacity)'},
    {'id': 'user_volunteer_2', 'name': 'Rahul Patil (Electric 3W - 400kg capacity)'},
    {'id': 'user_volunteer_3', 'name': 'Sneha Deshmukh (Motorbike - 30kg capacity)'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleBroadcast() async {
    final repo = ref.read(repositoryProvider);
    final start = DateTime.now().add(const Duration(minutes: 20));
    final end = DateTime.now().add(const Duration(hours: 2));

    await repo.schedulePickup(
      donationId: widget.donation.donationId,
      assignedVolunteerId: null,
      assignedVolunteerName: null,
      scheduledWindowStart: start,
      scheduledWindowEnd: end,
    );

    ref.invalidate(rolePickupsProvider);
    ref.invalidate(roleDonationsProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.primaryGreen,
          content: Text(
            '📢 Broadcast dispatched to all nearby volunteer drivers in Pune (Alex, Rahul, Sneha)!',
          ),
        ),
      );
    }
  }

  Future<void> _handleDirectAssign() async {
    final repo = ref.read(repositoryProvider);
    final start = DateTime.now().add(const Duration(minutes: 20));
    final end = DateTime.now().add(const Duration(hours: 2));

    await repo.schedulePickup(
      donationId: widget.donation.donationId,
      assignedVolunteerId: _selectedVolunteerId,
      assignedVolunteerName: _selectedVolunteerName,
      scheduledWindowStart: start,
      scheduledWindowEnd: end,
    );

    ref.invalidate(rolePickupsProvider);
    ref.invalidate(roleDonationsProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primaryGreen,
          content: Text('✅ Pickup scheduled and directly assigned to $_selectedVolunteerName!'),
        ),
      );
    }
  }

  Future<void> _handlePorterBooking() async {
    setState(() => _isPorterSubmitting = true);
    final repo = ref.read(repositoryProvider);
    final start = DateTime.now().add(const Duration(minutes: 15));
    final end = DateTime.now().add(const Duration(hours: 1));

    String vehicleDesc;
    if (_porterVehicleType == '2W') {
      vehicleDesc = 'Porter 2-Wheeler (MH12-CX-1024)';
    } else if (_porterVehicleType == '3W') {
      vehicleDesc = 'Porter Electric 3W Auto (MH12-EE-8821)';
    } else {
      vehicleDesc = 'Porter Tata Ace Mini-Truck (MH12-TB-5544)';
    }

    await repo.schedulePickup(
      donationId: widget.donation.donationId,
      assignedVolunteerId: 'porter_fleet_dispatch',
      assignedVolunteerName: vehicleDesc,
      scheduledWindowStart: start,
      scheduledWindowEnd: end,
    );

    ref.invalidate(rolePickupsProvider);
    ref.invalidate(roleDonationsProvider);

    if (mounted) {
      setState(() => _isPorterSubmitting = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blue.shade800,
          content: Text(
            '🚚 Porter delivery booked! $vehicleDesc assigned. Pickup ETA: 12 mins.',
          ),
        ),
      );
    }
  }

  Future<void> _openPorterExternalApp() async {
    final uri = Uri.parse('https://porter.in/city/pune');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open https://porter.in')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_shipping_rounded, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dispatch Logistics & Transport',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
                      ),
                      Text(
                        '${widget.donation.foodDescription} • ${widget.donation.listedQuantity} ${widget.donation.unit}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tab Bar with 3 Options
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: '⚡ Broadcast'),
                Tab(text: '👤 Assign Driver'),
                Tab(text: '🚚 Porter Booking'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBroadcastTab(),
                _buildDirectAssignTab(),
                _buildPorterTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: BROADCAST TO ALL VOLUNTEER DRIVERS
  Widget _buildBroadcastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade400, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Broadcast to Pune Volunteer Fleet (Open Pool)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF7F4F00)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'An instant alert will be broadcasted to all registered volunteer drivers in Pune (Alex Driver, Rahul Patil, Sneha Deshmukh). The first driver to accept will claim the pickup.',
                        style: TextStyle(fontSize: 12, color: Colors.brown.shade800, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Text('Route & Drop-off Coordinates:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),

          _buildRouteInfoCard(),

          const SizedBox(height: 20),

          AppButton(
            label: 'Broadcast Request to All Drivers Now',
            icon: Icons.send_rounded,
            variant: AppButtonVariant.primary,
            height: 48,
            onPressed: _handleBroadcast,
          ),
        ],
      ),
    );
  }

  // TAB 2: DIRECT VOLUNTEER DRIVER ASSIGNMENT
  Widget _buildDirectAssignTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Approved Volunteer Driver:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),

          ..._volunteerDrivers.map((driver) {
            final isSelected = _selectedVolunteerId == driver['id'];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected ? AppTheme.primaryGreen : Colors.grey.shade200,
                  child: Icon(
                    driver['id'] == 'user_volunteer_3'
                        ? Icons.two_wheeler_rounded
                        : Icons.directions_car_rounded,
                    color: isSelected ? Colors.white : Colors.black54,
                    size: 20,
                  ),
                ),
                title: Text(
                  driver['name']!,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  driver['id'] == 'user_volunteer_1'
                      ? 'Coverage: Kalyani Nagar & Pune Station • Verified Van'
                      : (driver['id'] == 'user_volunteer_2'
                          ? 'Coverage: Kalyani Nagar, Viman Nagar • Electric 3W'
                          : 'Coverage: Koregaon Park, Camp • Motorbike'),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                trailing: Radio<String>(
                  value: driver['id']!,
                  groupValue: _selectedVolunteerId,
                  activeColor: AppTheme.primaryGreen,
                  onChanged: (val) {
                    setState(() {
                      _selectedVolunteerId = val!;
                      _selectedVolunteerName = driver['name']!;
                    });
                  },
                ),
              ),
            );
          }),

          const SizedBox(height: 10),
          _buildRouteInfoCard(),
          const SizedBox(height: 18),

          AppButton(
            label: 'Confirm Driver Assignment',
            icon: Icons.check_circle_rounded,
            variant: AppButtonVariant.primary,
            height: 48,
            onPressed: _handleDirectAssign,
          ),
        ],
      ),
    );
  }

  // TAB 3: PORTER ON-DEMAND DELIVERY BOOKING INTERFACE
  Widget _buildPorterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Porter Branding Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_shipping_rounded, color: Colors.blue.shade800, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Porter On-Demand Logistics (Pune)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      Text(
                        'Book instant 2W, 3W, or Tata Ace for rapid surplus pickup',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Select Commercial Vehicle Type:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
          const SizedBox(height: 8),

          // Vehicle Type Selectors
          Row(
            children: [
              _buildPorterVehicleCard(
                type: '2W',
                title: '2-Wheeler',
                capacity: '≤ 20 kg',
                fare: '₹60 - ₹85',
                icon: Icons.two_wheeler_rounded,
              ),
              const SizedBox(width: 8),
              _buildPorterVehicleCard(
                type: '3W',
                title: '3W Auto',
                capacity: '≤ 300 kg',
                fare: '₹140 - ₹180',
                icon: Icons.electric_moped_rounded,
              ),
              const SizedBox(width: 8),
              _buildPorterVehicleCard(
                type: 'TATA_ACE',
                title: 'Tata Ace',
                capacity: '≤ 750 kg',
                fare: '₹260 - ₹340',
                icon: Icons.local_shipping_rounded,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Addresses & Contacts
          _buildRouteInfoCard(),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_outlined, size: 18, color: Colors.blue.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'NGO Subsidy Applied: Freight is sponsored via FoodBridge CSR Logistics Pool.',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isPorterSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Confirm Porter Dispatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: _isPorterSubmitting ? null : _handlePorterBooking,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade800,
                  side: BorderSide(color: Colors.blue.shade700),
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open App', style: TextStyle(fontSize: 12)),
                onPressed: _openPorterExternalApp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPorterVehicleCard({
    required String type,
    required String title,
    required String capacity,
    required String fare,
    required IconData icon,
  }) {
    final isSelected = _porterVehicleType == type;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _porterVehicleType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: isSelected ? Colors.blue.shade800 : Colors.black54),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? Colors.blue.shade900 : Colors.black87)),
              Text(capacity, style: const TextStyle(fontSize: 10, color: Colors.black54)),
              const SizedBox(height: 2),
              Text(fare, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trip_origin_rounded, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pickup: ${widget.donation.locationName} (${widget.donation.locationAddress})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Container(width: 2, height: 14, color: Colors.grey.shade400),
          ),
          const Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: AppTheme.alertRed),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Drop: Sevadeep Platform Food Bank (Shop No. 14, 14th Floor, Manikchand Ikon, Kalyani Nagar, Pune 411006)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
