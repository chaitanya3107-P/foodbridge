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
import '../../../data/models/donation_model.dart';
import '../../../data/models/review_model.dart';
import '../../logistics/screens/pickup_tracking_screen.dart';

class NgoReviewScreen extends ConsumerStatefulWidget {
  final DonationModel donation;

  const NgoReviewScreen({super.key, required this.donation});

  @override
  ConsumerState<NgoReviewScreen> createState() => _NgoReviewScreenState();
}

class _NgoReviewScreenState extends ConsumerState<NgoReviewScreen> {
  late List<SafetyChecklistItem> _checklist;
  final _notesController = TextEditingController();
  final _newChecklistItemController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with standard configurable checklist items
    _checklist = AppConstants.defaultNgoChecklistItems.map((item) {
      return SafetyChecklistItem(item: item, isVerified: false);
    }).toList();
    _loadExistingReview();
  }

  Future<void> _loadExistingReview() async {
    final repo = ref.read(repositoryProvider);
    final existing = await repo.getReviewForDonation(widget.donation.donationId);
    if (existing != null && mounted) {
      setState(() {
        if (existing.checklist.isNotEmpty) {
          _checklist = List.from(existing.checklist);
        }
        _notesController.text = existing.ngoNotes;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _newChecklistItemController.dispose();
    super.dispose();
  }

  void _addNewChecklistItem() {
    final text = _newChecklistItemController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checklist.add(SafetyChecklistItem(item: text, isVerified: false));
      _newChecklistItemController.clear();
    });
  }

  void _removeChecklistItem(int index) {
    setState(() {
      _checklist.removeAt(index);
    });
  }

  Future<void> _handleReviewDecision(ReviewDecision decision) async {
    // Validation
    if (decision == ReviewDecision.rejected && _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.alertRed,
          content: Text('Please provide an explicit rejection reason in the notes field.'),
        ),
      );
      return;
    }

    if (decision == ReviewDecision.clarificationRequested &&
        _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.secondaryAmber,
          content: Text('Specify what details or clarifications the donor must provide.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(repositoryProvider);
      final review = await repo.submitReview(
        donationId: widget.donation.donationId,
        decision: decision,
        checklist: _checklist,
        ngoNotes: _notesController.text.trim(),
      );

      // Invalidate relevant providers
      ref.invalidate(roleDonationsProvider);
      ref.invalidate(rolePickupsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: decision == ReviewDecision.accepted
                ? AppTheme.primaryGreen
                : (decision == ReviewDecision.rejected ? AppTheme.alertRed : Colors.deepOrange),
            content: Text(
              'Review recorded by ${review.reviewerName}: ${decision.displayName.toUpperCase()}',
            ),
          ),
        );

        if (decision == ReviewDecision.accepted) {
          // Offer immediate prompt to schedule pickup logistics
          _showSchedulePrompt();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.alertRed, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSchedulePrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.local_shipping_rounded, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Schedule Pickup Now?'),
          ],
        ),
        content: const Text(
          'Donation intake has been accepted. Would you like to assign a volunteer driver and dispatch pickup window now?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const PickupTrackingScreen(),
                ),
              );
            },
            child: const Text('Schedule Pickup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.donation;
    final isAwaiting = d.status == DonationStatus.awaitingNgoReview ||
        d.status == DonationStatus.clarificationRequested;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Safety Review'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mandatory Disclaimer
              const FoodSafetyDisclaimerBanner(compact: true),

              const SizedBox(height: 10),

              // Donation Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              d.foodDescription,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                            ),
                          ),
                          StatusBadge(status: d.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Offered Quantity: ${d.listedQuantity} ${d.unit} • ${d.foodCategory}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E6F5C), fontSize: 14),
                      ),
                      const Divider(height: 18),
                      _buildInfoRow('Donor Organisation', d.donorOrgName),
                      _buildInfoRow('Preparation Timestamp', _formatDate(d.preparationDateTime)),
                      _buildInfoRow('Declared Temperature', d.storageCondition),
                      _buildInfoRow('Packaging Container', d.packagingType),
                      _buildInfoRow('Pickup Deadline', _formatDate(d.pickupDeadline)),
                      _buildInfoRow('Pickup Location', '${d.locationName}\n${d.locationAddress}'),
                      _buildInfoRow('Contact Person', '${d.contactPerson} (${d.contactPhone})'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          const Text('Allergens: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ...d.knownAllergens.map((a) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(a, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // NGO-Configurable Safety Checklist Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NGO Intake Safety Checklist',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
                  ),
                  Text(
                    '${_checklist.where((c) => c.isVerified).length}/${_checklist.length} Verified',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _checklist.every((c) => c.isVerified) ? AppTheme.primaryGreen : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Editable criteria set by the partner NGO. Toggle verification or add custom checks:',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),

              const SizedBox(height: 10),

              // Checklist Items
              ..._checklist.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  color: item.isVerified ? const Color(0xFFF3FAF6) : Colors.white,
                  child: CheckboxListTile(
                    value: item.isVerified,
                    activeColor: AppTheme.primaryGreen,
                    title: Text(
                      item.item,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: item.isVerified ? FontWeight.w700 : FontWeight.w500,
                        color: item.isVerified ? AppTheme.onPrimaryContainer : Colors.black87,
                      ),
                    ),
                    secondary: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.grey),
                      tooltip: 'Remove criteria',
                      onPressed: () => _removeChecklistItem(idx),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _checklist[idx] = item.copyWith(isVerified: val ?? false);
                      });
                    },
                  ),
                );
              }),

              const SizedBox(height: 8),

              // Add Custom Checklist Item Field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newChecklistItemController,
                      decoration: const InputDecoration(
                        hintText: 'Add custom inspection check...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: '+ Add',
                    isFullWidth: false,
                    height: 46,
                    variant: AppButtonVariant.outline,
                    onPressed: _addNewChecklistItem,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Reviewer Notes / Clarification Instructions
              const Text(
                'Reviewer Notes / Instructions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add intake remarks, transport instructions, or clarification details...',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              // Decision Action Buttons
              if (isAwaiting) ...[
                AppButton(
                  label: 'Accept Donation & Proceed to Logistics',
                  icon: Icons.check_circle_rounded,
                  isLoading: _isSubmitting,
                  variant: AppButtonVariant.primary,
                  onPressed: () => _handleReviewDecision(ReviewDecision.accepted),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Request Clarification',
                        icon: Icons.contact_support_outlined,
                        isLoading: _isSubmitting,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _handleReviewDecision(ReviewDecision.clarificationRequested),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Reject Listing',
                        icon: Icons.cancel_outlined,
                        isLoading: _isSubmitting,
                        variant: AppButtonVariant.danger,
                        onPressed: () => _handleReviewDecision(ReviewDecision.rejected),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Donation status is "${d.status.displayName}". Review decision already finalized.',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E3228)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} at $hour:$min $ampm';
  }
}
