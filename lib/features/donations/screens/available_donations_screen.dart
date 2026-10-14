import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/food_safety_disclaimer.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/state/donation_status_engine.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/donation_model.dart';
import 'ngo_review_screen.dart';

class AvailableDonationsScreen extends ConsumerStatefulWidget {
  const AvailableDonationsScreen({super.key});

  @override
  ConsumerState<AvailableDonationsScreen> createState() => _AvailableDonationsScreenState();
}

class _AvailableDonationsScreenState extends ConsumerState<AvailableDonationsScreen> {
  String _searchQuery = '';
  DonationStatus? _selectedStatusFilter;

  @override
  Widget build(BuildContext context) {
    final donationsAsync = ref.watch(roleDonationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Donations (NGO)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(roleDonationsProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Universal Food Safety Disclaimer
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: FoodSafetyDisclaimerBanner(compact: true),
            ),

            // Search and Status Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search food description, donor, or category...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Listings'),
                    selected: _selectedStatusFilter == null,
                    onSelected: (_) => setState(() => _selectedStatusFilter = null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Awaiting Review'),
                    selected: _selectedStatusFilter == DonationStatus.awaitingNgoReview,
                    avatar: const Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFF57F17)),
                    onSelected: (_) => setState(() => _selectedStatusFilter = DonationStatus.awaitingNgoReview),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Clarification Requested'),
                    selected: _selectedStatusFilter == DonationStatus.clarificationRequested,
                    onSelected: (_) => setState(() => _selectedStatusFilter = DonationStatus.clarificationRequested),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Accepted'),
                    selected: _selectedStatusFilter == DonationStatus.accepted,
                    onSelected: (_) => setState(() => _selectedStatusFilter = DonationStatus.accepted),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Pickup Scheduled'),
                    selected: _selectedStatusFilter == DonationStatus.pickupScheduled,
                    onSelected: (_) => setState(() => _selectedStatusFilter = DonationStatus.pickupScheduled),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Donations List
            Expanded(
              child: donationsAsync.when(
                data: (donations) {
                  final filtered = donations.where((d) {
                    if (_selectedStatusFilter != null && d.status != _selectedStatusFilter) {
                      return false;
                    }
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      final matchFood = d.foodDescription.toLowerCase().contains(q);
                      final matchDonor = d.donorOrgName.toLowerCase().contains(q);
                      final matchCat = d.foodCategory.toLowerCase().contains(q);
                      if (!matchFood && !matchDonor && !matchCat) return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text('No donations match your filter criteria.', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isUrgent = item.pickupDeadline.difference(DateTime.now()).inHours <= 3 &&
                          !DonationStatusEngine.isTerminal(item.status);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NgoReviewScreen(donation: item),
                              ),
                            );
                          },
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
                                        item.foodDescription,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                    ),
                                    StatusBadge(status: item.status, isSmall: true),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      '${item.listedQuantity} ${item.unit} • ${item.foodCategory}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E6F5C)),
                                    ),
                                    const Spacer(),
                                    if (isUrgent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFEBEE),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.timer_outlined, size: 12, color: Colors.red),
                                            SizedBox(width: 3),
                                            Text('Urgent', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Donor: ${item.donorOrgName} (${item.locationName})',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Storage: ${item.storageCondition}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                                    ),
                                    Text(
                                      'Deadline: ${_formatDeadline(item.pickupDeadline)}',
                                      style: const TextStyle(fontSize: 11.5, color: Colors.black54, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: const Size(48, 36),
                                      ),
                                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                      label: Text(
                                        item.status == DonationStatus.awaitingNgoReview
                                            ? 'Review & Verify'
                                            : 'Inspect Details',
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => NgoReviewScreen(donation: item),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDeadline(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inHours < 1) return '${diff.inMinutes} mins left';
    if (diff.inHours < 24) return '${diff.inHours} hrs left';
    return '${diff.inDays} days left';
  }
}
