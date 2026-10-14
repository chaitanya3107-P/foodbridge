import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/food_safety_disclaimer.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/calculators/impact_calculators.dart';
import '../services/export_service.dart';

enum DateRangeOption {
  past7Days,
  past30Days,
  past90Days,
  allTime;

  String get displayName {
    switch (this) {
      case DateRangeOption.past7Days:
        return 'Past 7 Days';
      case DateRangeOption.past30Days:
        return 'Past 30 Days';
      case DateRangeOption.past90Days:
        return 'Past 90 Days';
      case DateRangeOption.allTime:
        return 'All Time';
    }
  }

  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case DateRangeOption.past7Days:
        return now.subtract(const Duration(days: 7));
      case DateRangeOption.past30Days:
        return now.subtract(const Duration(days: 30));
      case DateRangeOption.past90Days:
        return now.subtract(const Duration(days: 90));
      case DateRangeOption.allTime:
        return null;
    }
  }
}

class ImpactReportScreen extends ConsumerStatefulWidget {
  const ImpactReportScreen({super.key});

  @override
  ConsumerState<ImpactReportScreen> createState() => _ImpactReportScreenState();
}

class _ImpactReportScreenState extends ConsumerState<ImpactReportScreen> {
  DateRangeOption _selectedRange = DateRangeOption.past30Days;
  bool _isExporting = false;

  void _showCsvExportModal(String csvData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.table_chart_outlined, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('CSV Report Generated'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your CSV export data is ready. You can copy it directly to your clipboard:'),
              const SizedBox(height: 12),
              Container(
                height: 160,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEFF1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csvData,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvData));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.primaryGreen,
                  content: Text('CSV data copied to clipboard!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalsAsync = ref.watch(impactTotalsProvider);
    final donationsAsync = ref.watch(roleDonationsProvider);
    final auditsAsync = ref.watch(wasteAuditsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impact & Audit Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(impactTotalsProvider);
              ref.invalidate(roleDonationsProvider);
              ref.invalidate(wasteAuditsProvider);
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
              // Mandatory Universal Disclaimer
              const FoodSafetyDisclaimerBanner(compact: true),

              const SizedBox(height: 10),

              // Date Range Filter Selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 20, color: AppTheme.primaryGreen),
                      const SizedBox(width: 10),
                      const Text(
                        'Audit Period:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const Spacer(),
                      DropdownButton<DateRangeOption>(
                        value: _selectedRange,
                        underline: const SizedBox(),
                        items: DateRangeOption.values.map((opt) {
                          return DropdownMenuItem(
                            value: opt,
                            child: Text(
                              opt.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primaryGreen),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRange = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Verified Limitations Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD4ECE3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_outlined, color: AppTheme.primaryGreen, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Limitations Note: The impact dashboard counts only collected and distributed records that are verified. Self-reported donor estimates are separated strictly to prevent inflated claims.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF2C3E35), height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Verified Diversion Statistics
              const Text(
                'Verified Food Diversion Totals',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
              ),
              const SizedBox(height: 8),

              totalsAsync.when(
                data: (totals) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Offered by Donors',
                              value: '${totals.estimatedSurplusOffered} kg',
                              subtitle: 'Self-reported estimate',
                              icon: Icons.storefront_outlined,
                              color: const Color(0xFF546E7A),
                              bgColor: const Color(0xFFECEFF1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Approved by NGO',
                              value: '${totals.acceptedQuantity} kg',
                              subtitle: 'Intake safety verified',
                              icon: Icons.verified_user_outlined,
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
                            child: _buildMetricTile(
                              title: 'Verified Collected',
                              value: '${totals.verifiedCollectedKg} kg',
                              subtitle: 'Measured on driver scale',
                              icon: Icons.scale_rounded,
                              color: const Color(0xFF2E7D32),
                              bgColor: const Color(0xFFE8F5E9),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Verified Distributed',
                              value: '${totals.verifiedDistributedKg} kg',
                              subtitle: 'Shelters & pantries',
                              icon: Icons.volunteer_activism_rounded,
                              color: AppTheme.primaryGreen,
                              bgColor: AppTheme.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Zero-Landfill Remainder',
                              value: '${totals.remainderKg} kg',
                              subtitle: 'Compost & animal feed',
                              icon: Icons.recycling_rounded,
                              color: const Color(0xFFE65100),
                              bgColor: const Color(0xFFFFF3E0),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Collection Efficiency',
                              value: '${totals.collectionRatePercent}%',
                              subtitle: '${totals.totalCompletedPickups}/${totals.totalAcceptedRequests} Pickups',
                              icon: Icons.task_alt_rounded,
                              color: const Color(0xFF1565C0),
                              bgColor: const Color(0xFFE3F2FD),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),

              const SizedBox(height: 18),

              // Canteen Waste Reduction Metric (Formula: Change in Discarded Waste %)
              auditsAsync.when(
                data: (audits) {
                  if (audits.length < 2) return const SizedBox.shrink();

                  // Sort chronologically
                  final sorted = List.from(audits)..sort((a, b) => a.date.compareTo(b.date));
                  final baselineAvg = (sorted.first.discardedKg + sorted[1].discardedKg) / 2.0;
                  final postAvg = (sorted.last.discardedKg + sorted[sorted.length - 2].discardedKg) / 2.0;

                  final changeResult = ImpactCalculators.calculateChangeInDiscardedWaste(
                    baselineAvgKg: baselineAvg,
                    postCampaignAvgKg: postAvg,
                    methodsChanged: false,
                  );

                  return Card(
                    color: const Color(0xFFF3FAF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFC7E7D9)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Change in Discarded Waste (%)',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF1E3228)),
                              ),
                              Text(
                                changeResult.displayText,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF2E7D32)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Baseline average (${baselineAvg.toStringAsFixed(1)} kg) vs Post-campaign average (${postAvg.toStringAsFixed(1)} kg). Reduction achieved through portion control and surplus donation.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF4A5D54)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Export Buttons
              const Text(
                'Generate Official Reports',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Export CSV',
                      icon: Icons.table_view_rounded,
                      variant: AppButtonVariant.outline,
                      height: 48,
                      onPressed: () {
                        totalsAsync.whenData((totals) {
                          donationsAsync.whenData((donations) {
                            auditsAsync.whenData((audits) {
                              final csv = ExportService.generateCsv(
                                totals: totals,
                                donations: donations,
                                audits: audits,
                                dateRangeLabel: _selectedRange.displayName,
                              );
                              _showCsvExportModal(csv);
                            });
                          });
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'Print / Save PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      variant: AppButtonVariant.primary,
                      height: 48,
                      isLoading: _isExporting,
                      onPressed: () async {
                        setState(() => _isExporting = true);
                        try {
                          final totals = await ref.read(impactTotalsProvider.future);
                          final donations = await ref.read(roleDonationsProvider.future);
                          final audits = await ref.read(wasteAuditsProvider.future);

                          await ExportService.printPdfReport(
                            totals: totals,
                            donations: donations,
                            audits: audits,
                            dateRangeLabel: _selectedRange.displayName,
                          );
                        } finally {
                          if (mounted) setState(() => _isExporting = false);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                value,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E3228)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
