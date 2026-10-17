import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/organisation_model.dart';
import '../../../data/models/donation_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/services/realtime_service.dart';

enum MapFilter { all, accepting, foodBanks, donations }

/// Interactive OpenStreetMap screen displaying verified Pune NGOs, food banks,
/// active surplus food pickups, and 1-tap Google Maps turn-by-turn directions.
class NgoMapScreen extends ConsumerStatefulWidget {
  const NgoMapScreen({super.key});

  @override
  ConsumerState<NgoMapScreen> createState() => _NgoMapScreenState();
}

class _NgoMapScreenState extends ConsumerState<NgoMapScreen> {
  static const LatLng _puneCenter = LatLng(18.5204, 73.8567);
  final MapController _mapController = MapController();

  MapFilter _activeFilter = MapFilter.all;
  OrganisationModel? _selectedOrg;
  DonationModel? _selectedDonation;

  Future<void> _launchDirections(double lat, double lng, String label) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=${Uri.encodeComponent(label)}',
    );
    final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Coordinates: $lat, $lng ($label)'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open map: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _callPhone(String phone) async {
    final cleanPhone = phone.replaceAll(' ', '');
    final telUri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contact: $phone')),
        );
      }
    }
  }

  void _showNgoDetailSheet(OrganisationModel org) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNgoSheetContent(org),
    );
  }

  void _showDonationDetailSheet(DonationModel donation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDonationSheetContent(donation),
    );
  }

  void _showStatusUpdateDialog(OrganisationModel org) {
    bool isAccepting = org.isAcceptingDonations;
    String selectedStatus = org.capacityStatus;
    final statuses = [
      'Accepting Donations',
      'High Demand (Need Cooked Meals)',
      'Accepting Dry & Cooked',
      'At Capacity (Temporarily Paused)',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.sync_rounded, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Update Real-Time Status',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                org.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Accepting Donations Now'),
                subtitle: Text(
                  isAccepting ? 'Listed as active intake center' : 'Marked as paused',
                  style: const TextStyle(fontSize: 12),
                ),
                value: isAccepting,
                activeColor: AppTheme.primaryGreen,
                onChanged: (val) {
                  setDialogState(() => isAccepting = val);
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Capacity Status Badge',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: statuses.contains(selectedStatus) ? selectedStatus : statuses[0],
                isExpanded: true,
                items: statuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedStatus = val);
                },
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(),
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
                final repo = ref.read(repositoryProvider);
                await repo.updateOrganisationStatus(
                  organisationId: org.organisationId,
                  isAcceptingDonations: isAccepting,
                  capacityStatus: selectedStatus,
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Updated real-time status for ${org.name}'),
                      backgroundColor: AppTheme.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save & Broadcast Live'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNgoSheetContent(OrganisationModel org) {
    final currentUser = ref.watch(currentUserProvider);
    final isStaff = currentUser?.role == UserRole.ngoStaff || currentUser?.role == UserRole.admin;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: org.type == OrgType.foodbank
                      ? Colors.indigo.shade50
                      : AppTheme.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  org.type == OrgType.foodbank
                      ? Icons.warehouse_rounded
                      : Icons.volunteer_activism_rounded,
                  color: org.type == OrgType.foodbank ? Colors.indigo : AppTheme.primaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            org.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (org.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified_rounded, color: Colors.blue, size: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      org.type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Live status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: org.isAcceptingDonations
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: org.isAcceptingDonations
                    ? Colors.green.shade300
                    : Colors.orange.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  org.isAcceptingDonations ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                  size: 16,
                  color: org.isAcceptingDonations ? Colors.green.shade700 : Colors.orange.shade800,
                ),
                const SizedBox(width: 6),
                Text(
                  org.capacityStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: org.isAcceptingDonations ? Colors.green.shade800 : Colors.orange.shade900,
                  ),
                ),
                const Spacer(),
                const Text(
                  'REAL-TIME',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Address & Operating hours
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  org.physicalAddress,
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                org.operatingHours,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '${org.contactPerson} (${org.contactPhone})',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Actions: Get Directions & Call
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _launchDirections(org.latitude, org.longitude, org.name);
                  },
                  icon: const Icon(Icons.directions_rounded, size: 20),
                  label: const Text('Get Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _callPhone(org.contactPhone),
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text('Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (isStaff) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Update NGO Status Live',
                  icon: const Icon(Icons.edit_note_rounded),
                  onPressed: () {
                    Navigator.pop(context);
                    _showStatusUpdateDialog(org);
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDonationSheetContent(DonationModel donation) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fastfood_rounded, color: Colors.orange, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.foodDescription,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${donation.foodCategory} • ${donation.listedQuantity} ${donation.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${donation.locationName}, ${donation.locationAddress}',
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Text(
                'Pickup by: ${donation.pickupDeadline.hour.toString().padLeft(2, '0')}:${donation.pickupDeadline.minute.toString().padLeft(2, '0')} today',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '${donation.contactPerson} (${donation.contactPhone})',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _launchDirections(
                      donation.latitude,
                      donation.longitude,
                      donation.locationName,
                    );
                  },
                  icon: const Icon(Icons.directions_car_rounded, size: 20),
                  label: const Text('Navigate to Pickup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _callPhone(donation.contactPhone),
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text('Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(organisationsProvider);
    final donationsAsync = ref.watch(roleDonationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pune NGO & Food Map',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              'OpenStreetMap • Real-Time Pune Network',
              style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Center Pune City',
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () {
              _mapController.move(_puneCenter, 12.5);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. OpenStreetMap Layer
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _puneCenter,
              initialZoom: 12.2,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.foodbridge.app',
              ),
              // Marker Layer for NGOs and Donations
              orgsAsync.when(
                data: (orgs) {
                  return donationsAsync.when(
                    data: (donations) {
                      final markers = <Marker>[];

                      // 1. NGO Markers
                      if (_activeFilter != MapFilter.donations) {
                        for (final org in orgs) {
                          if (org.type == OrgType.donor) continue;
                          if (_activeFilter == MapFilter.accepting && !org.isAcceptingDonations) {
                            continue;
                          }
                          if (_activeFilter == MapFilter.foodBanks && org.type != OrgType.foodbank) {
                            continue;
                          }

                          final isFoodBank = org.type == OrgType.foodbank;
                          final isAccepting = org.isAcceptingDonations;
                          final isSevadeep = org.organisationId == 'org_ngo_sevadeep';

                          markers.add(
                            Marker(
                              point: LatLng(org.latitude, org.longitude),
                              width: isSevadeep ? 140 : 100,
                              height: 70,
                              child: GestureDetector(
                                onTap: () => _showNgoDetailSheet(org),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: isSevadeep
                                            ? const Color(0xFFD97706)
                                            : (isFoodBank
                                                ? Colors.indigo.shade600
                                                : isAccepting
                                                    ? AppTheme.primaryGreen
                                                    : Colors.deepOrange),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: isSevadeep ? 2.5 : 2),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black38,
                                            blurRadius: 5,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isSevadeep
                                            ? Icons.stars_rounded
                                            : (isFoodBank
                                                ? Icons.warehouse_rounded
                                                : Icons.volunteer_activism_rounded),
                                        color: Colors.white,
                                        size: isSevadeep ? 22 : 18,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSevadeep ? const Color(0xFF1B5E20) : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSevadeep ? Colors.amber : Colors.grey.shade400,
                                          width: isSevadeep ? 1.5 : 0.8,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(color: Colors.black26, blurRadius: 3),
                                        ],
                                      ),
                                      child: Text(
                                        isSevadeep ? '⭐ Sevadeep Platform' : org.name.split(' ').take(2).join(' '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: isSevadeep ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      }

                      // 2. Surplus Donation Markers
                      if (_activeFilter == MapFilter.all || _activeFilter == MapFilter.donations) {
                        final activeDonations = donations.where((d) => !d.isExpired).toList();
                        for (final d in activeDonations) {
                          markers.add(
                            Marker(
                              point: LatLng(d.latitude, d.longitude),
                              width: 46,
                              height: 46,
                              child: GestureDetector(
                                onTap: () => _showDonationDetailSheet(d),
                                child: Tooltip(
                                  message: 'Surplus: ${d.foodDescription}',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade700,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.fastfood_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      }

                      return MarkerLayer(markers: markers);
                    },
                    loading: () => const MarkerLayer(markers: []),
                    error: (_, __) => const MarkerLayer(markers: []),
                  );
                },
                loading: () => const MarkerLayer(markers: []),
                error: (_, __) => const MarkerLayer(markers: []),
              ),
            ],
          ),

          // 2. Floating Filter Chips at top
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Pune NGOs', MapFilter.all, Icons.map_outlined),
                  const SizedBox(width: 8),
                  _buildFilterChip('Accepting Now', MapFilter.accepting, Icons.check_circle_outline),
                  const SizedBox(width: 8),
                  _buildFilterChip('Food Banks', MapFilter.foodBanks, Icons.warehouse_outlined),
                  const SizedBox(width: 8),
                  _buildFilterChip('Surplus Pickups', MapFilter.donations, Icons.fastfood_outlined),
                ],
              ),
            ),
          ),

          // 2.5 Quick Hub Focus Bar (Sevadeep Platform & Neighborhood Hubs)
          Positioned(
            top: 56,
            left: 12,
            right: 12,
            child: orgsAsync.when(
              data: (orgs) {
                final sevadeep = orgs.firstWhere(
                  (o) => o.organisationId == 'org_ngo_sevadeep',
                  orElse: () => orgs.first,
                );

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        icon: const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                        label: const Text(
                          '⭐ Jump to Sevadeep Platform (Kalyani Nagar)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        onPressed: () {
                          _mapController.move(LatLng(sevadeep.latitude, sevadeep.longitude), 15.0);
                          _showNgoDetailSheet(sevadeep);
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        backgroundColor: Colors.white,
                        avatar: const Icon(Icons.location_on_rounded, size: 16, color: Colors.indigo),
                        label: const Text('Sadhu Vaswani (KP)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        onPressed: () => _mapController.move(const LatLng(18.5310, 73.8820), 14.5),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        backgroundColor: Colors.white,
                        avatar: const Icon(Icons.location_on_rounded, size: 16, color: Colors.teal),
                        label: const Text('Kalyani Nagar Drive', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        onPressed: () => _mapController.move(const LatLng(18.5472, 73.9038), 14.5),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        backgroundColor: Colors.white,
                        avatar: const Icon(Icons.location_on_rounded, size: 16, color: Colors.green),
                        label: const Text('Prerna Koregaon Park', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        onPressed: () => _mapController.move(const LatLng(18.5375, 73.8925), 14.5),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        backgroundColor: Colors.white,
                        avatar: const Icon(Icons.location_on_rounded, size: 16, color: Colors.deepOrange),
                        label: const Text('Shivajinagar Food Bank', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        onPressed: () => _mapController.move(const LatLng(18.5348, 73.8505), 14.5),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // 3. Bottom Sliding NGO Quick Cards Carousel
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: orgsAsync.when(
              data: (List<OrganisationModel> orgs) {
                final ngoList = orgs.where((o) => o.type != OrgType.donor).toList();
                return SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: ngoList.length,
                    itemBuilder: (context, index) {
                      final org = ngoList[index];
                      return GestureDetector(
                        onTap: () {
                          _mapController.move(LatLng(org.latitude, org.longitude), 14.5);
                          _showNgoDetailSheet(org);
                        },
                        child: Container(
                          width: 260,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: org.isAcceptingDonations
                                  ? AppTheme.primaryGreen.withOpacity(0.3)
                                  : Colors.orange.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    org.type == OrgType.foodbank
                                        ? Icons.warehouse_rounded
                                        : Icons.volunteer_activism_rounded,
                                    size: 16,
                                    color: org.type == OrgType.foodbank
                                        ? Colors.indigo
                                        : AppTheme.primaryGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      org.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                org.operatingArea,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: org.isAcceptingDonations
                                          ? Colors.green.shade50
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      org.isAcceptingDonations ? 'Accepting' : 'Paused',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: org.isAcceptingDonations
                                            ? Colors.green.shade800
                                            : Colors.orange.shade900,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => _launchDirections(
                                      org.latitude,
                                      org.longitude,
                                      org.name,
                                    ),
                                    icon: const Icon(Icons.directions, size: 14),
                                    label: const Text('Directions', style: TextStyle(fontSize: 11)),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, MapFilter filter, IconData icon) {
    final isSelected = _activeFilter == filter;
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: isSelected ? AppTheme.primaryGreen : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() => _activeFilter = filter);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
