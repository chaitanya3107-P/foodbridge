import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/food_safety_disclaimer.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/state/donation_status_engine.dart';
import '../../../data/models/donation_model.dart';
import '../../../data/models/pickup_model.dart';
import '../../../data/models/distribution_model.dart';

class FoodBankRecordsScreen extends ConsumerStatefulWidget {
  const FoodBankRecordsScreen({super.key});

  @override
  ConsumerState<FoodBankRecordsScreen> createState() => _FoodBankRecordsScreenState();
}

class _FoodBankRecordsScreenState extends ConsumerState<FoodBankRecordsScreen> {
  void _showRecordDistributionDialog({
    required DonationModel donation,
    required PickupModel pickup,
  }) {
    final collectedKg = pickup.actualCollectedQuantity ?? donation.listedQuantity;
    final distributedController = TextEditingController(text: collectedKg.toString());
    final remainderController = TextEditingController(text: '0.0');
    final recipientLocationController = TextEditingController(text: 'Campus Food Pantry Block C');
    final dispositionReasonController = TextEditingController();

    String selectedCategory = AppConstants.destinationCategories.first;
    String selectedDisposition = AppConstants.remainderDispositions.first;

    void updateRemainder() {
      final dist = double.tryParse(distributedController.text) ?? 0.0;
      final rem = (collectedKg - dist).clamp(0.0, collectedKg);
      remainderController.text = rem.toStringAsFixed(1);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final rem = double.tryParse(remainderController.text) ?? 0.0;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.inventory_2_rounded, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text('Record Distribution'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Donation: ${donation.foodDescription}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Actual Collected Weight: $collectedKg kg',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E6F5C)),
                  ),
                  const Divider(height: 18),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Destination Category *'),
                    items: AppConstants.destinationCategories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: recipientLocationController,
                    decoration: const InputDecoration(labelText: 'Recipient Facility / Location *'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: distributedController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Quantity Distributed (kg) *',
                      prefixIcon: Icon(Icons.outbox_rounded, color: AppTheme.primaryGreen),
                    ),
                    onChanged: (_) {
                      setDialogState(() {
                        updateRemainder();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: remainderController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Remainder Quantity (kg)',
                      prefixIcon: Icon(Icons.incomplete_circle_rounded, color: Colors.orange),
                    ),
                  ),
                  if (rem > 0) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedDisposition,
                      decoration: const InputDecoration(labelText: 'Remainder Disposition *'),
                      items: AppConstants.remainderDispositions.map((d) {
                        return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedDisposition = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dispositionReasonController,
                      decoration: const InputDecoration(
                        labelText: 'Disposition Reason *',
                        hintText: 'e.g. Crust trimming, perishable carryover',
                      ),
                    ),
                  ],
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
                  final distQty = double.tryParse(distributedController.text.trim()) ?? 0.0;
                  final remQty = double.tryParse(remainderController.text.trim()) ?? 0.0;

                  if (distQty <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppTheme.alertRed,
                        content: Text('Distributed quantity must be greater than zero.'),
                      ),
                    );
                    return;
                  }

                  if (remQty > 0 && dispositionReasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppTheme.alertRed,
                        content: Text('Please state the disposition reason for the remainder.'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  final repo = ref.read(repositoryProvider);
                  await repo.recordDistribution(
                    donationId: donation.donationId,
                    pickupId: pickup.pickupId,
                    quantityDistributed: distQty,
                    unit: 'kg',
                    destinationCategory: selectedCategory,
                    recipientLocation: recipientLocationController.text.trim(),
                    remainderQuantity: remQty,
                    remainderDisposition: selectedDisposition,
                    dispositionReason: dispositionReasonController.text.trim(),
                  );

                  ref.invalidate(distributionsProvider);
                  ref.invalidate(roleDonationsProvider);
                  ref.invalidate(impactTotalsProvider);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppTheme.primaryGreen,
                        content: Text('Distribution ledger saved and donation closed successfully!'),
                      ),
                    );
                  }
                },
                child: const Text('Save Distribution Record'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distsAsync = ref.watch(distributionsProvider);
    final donationsAsync = ref.watch(roleDonationsProvider);
    final pickupsAsync = ref.watch(rolePickupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Bank Records & Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(distributionsProvider);
              ref.invalidate(roleDonationsProvider);
              ref.invalidate(rolePickupsProvider);
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

              // Pending Distribution Section (Collected donations waiting for distribution ledger)
              donationsAsync.when(
                data: (donations) {
                  final collectedDonations = donations
                      .where((d) => d.status == DonationStatus.collected)
                      .toList();

                  if (collectedDonations.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Collected Surplus Awaiting Distribution Record',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
                      ),
                      const SizedBox(height: 6),
                      ...collectedDonations.map((d) {
                        return Card(
                          color: const Color(0xFFFFF8E1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFFFE082)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFFF57F17),
                                  child: Icon(Icons.move_to_inbox_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d.foodDescription, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                      Text('${d.listedQuantity} ${d.unit} • ${d.donorOrgName}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGreen,
                                    minimumSize: const Size(48, 36),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  onPressed: () {
                                    pickupsAsync.whenData((pickups) {
                                      final p = pickups.where((item) => item.donationId == d.donationId).firstOrNull;
                                      if (p != null) {
                                        _showRecordDistributionDialog(donation: d, pickup: p);
                                      }
                                    });
                                  },
                                  child: const Text('Record', style: TextStyle(fontSize: 12)),
                                ),
                              ],
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

              // Completed Distribution Ledger Table
              const Text(
                'Distribution & Remainder Ledger',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
              ),
              const SizedBox(height: 8),

              distsAsync.when(
                data: (dists) {
                  if (dists.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text('No distribution records logged yet.', style: TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: dists.map((dist) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dist.destinationCategory,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF1E6F5C)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${dist.quantityDistributed} ${dist.unit} Distributed',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Recipient Site: ${dist.recipientLocation}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(
                                'Logged By: ${dist.recordedByUserName} • ${_formatDate(dist.distributionTime)}',
                                style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                              ),
                              if (dist.remainderQuantity > 0) ...[
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.recycling_rounded, size: 16, color: Colors.deepOrange),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Remainder: ${dist.remainderQuantity} ${dist.unit} (${dist.remainderDisposition})',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.deepOrange),
                                    ),
                                  ],
                                ),
                                if (dist.dispositionReason.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Reason: ${dist.dispositionReason}',
                                    style: const TextStyle(fontSize: 11.5, color: Colors.black87),
                                  ),
                                ],
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

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
