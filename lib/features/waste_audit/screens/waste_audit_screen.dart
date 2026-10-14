import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/food_safety_disclaimer.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/calculators/impact_calculators.dart';
import '../../../data/models/waste_audit_model.dart';

class WasteAuditScreen extends ConsumerStatefulWidget {
  const WasteAuditScreen({super.key});

  @override
  ConsumerState<WasteAuditScreen> createState() => _WasteAuditScreenState();
}

class _WasteAuditScreenState extends ConsumerState<WasteAuditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _preparedController = TextEditingController(text: '190.0');
  final _servedController = TextEditingController(text: '182.0');
  final _surplusController = TextEditingController(text: '5.5');
  final _discardedController = TextEditingController(text: '2.5');
  final _notesController = TextEditingController(text: 'Buffet batching monitored. Minimal plate waste.');

  DateTime _auditDate = DateTime.now();
  String _selectedMethod = AppConstants.auditMeasurementMethods.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _preparedController.dispose();
    _servedController.dispose();
    _surplusController.dispose();
    _discardedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _getCalculatedWasteRate() {
    final prep = double.tryParse(_preparedController.text.trim()) ?? 0.0;
    final disc = double.tryParse(_discardedController.text.trim()) ?? 0.0;
    return ImpactCalculators.calculateWasteRate(discardedKg: disc, totalPreparedKg: prep);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _auditDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _auditDate = picked);
    }
  }

  Future<void> _submitAudit() async {
    if (!_formKey.currentState!.validate()) return;

    final prep = double.tryParse(_preparedController.text.trim()) ?? 0.0;
    final served = double.tryParse(_servedController.text.trim()) ?? 0.0;
    final surplus = double.tryParse(_surplusController.text.trim()) ?? 0.0;
    final disc = double.tryParse(_discardedController.text.trim()) ?? 0.0;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(repositoryProvider);
      await repo.submitWasteAudit(
        date: _auditDate,
        preparedKg: prep,
        servedKg: served,
        edibleSurplusKg: surplus,
        discardedKg: disc,
        measurementMethod: _selectedMethod,
        notes: _notesController.text.trim(),
      );

      ref.invalidate(wasteAuditsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primaryGreen,
            content: Text('Daily waste audit logged successfully!'),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final auditsAsync = ref.watch(wasteAuditsProvider);
    final liveWasteRate = _getCalculatedWasteRate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Audit & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(wasteAuditsProvider),
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

              // Waste Trend Chart Section (fl_chart)
              auditsAsync.when(
                data: (audits) {
                  if (audits.isEmpty) return const SizedBox.shrink();

                  // Sort chronologically for chart display
                  final sortedAudits = List<WasteAuditModel>.from(audits)
                    ..sort((a, b) => a.date.compareTo(b.date));

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Waste Rate (%) Trend',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E3228)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.trending_down_rounded, size: 14, color: Color(0xFF2E7D32)),
                                    SizedBox(width: 4),
                                    Text('Reduction Trend', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Formula: Discarded kg ÷ Total Prepared kg × 100',
                            style: TextStyle(fontSize: 11.5, color: Colors.black54),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 180,
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: true, drawVerticalLine: false),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (val, meta) {
                                        final int index = val.toInt();
                                        if (index >= 0 && index < sortedAudits.length) {
                                          final d = sortedAudits[index].date;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6.0),
                                            child: Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 36,
                                      getTitlesWidget: (val, meta) {
                                        return Text('${val.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: Colors.black54));
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: sortedAudits.asMap().entries.map((e) {
                                      return FlSpot(e.key.toDouble(), e.value.wasteRatePercent);
                                    }).toList(),
                                    isCurved: true,
                                    color: AppTheme.primaryGreen,
                                    barWidth: 3.5,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: AppTheme.primaryGreen.withOpacity(0.15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 18),

              // Daily Audit Input Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Record Daily Waste Audit',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E3228)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: liveWasteRate > 10 ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Rate: ${liveWasteRate.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: liveWasteRate > 10 ? AppTheme.alertRed : const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Date Picker Tile
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          tileColor: const Color(0xFFF4F8F5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          leading: const Icon(Icons.calendar_today_rounded, size: 20, color: AppTheme.primaryGreen),
                          title: const Text('Audit Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('${_auditDate.day}/${_auditDate.month}/${_auditDate.year}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                          trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                          onTap: _pickDate,
                        ),

                        const SizedBox(height: 12),

                        // Prepared vs Served
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _preparedController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Total Prepared (kg) *'),
                                onChanged: (_) => setState(() {}),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Required';
                                  final n = double.tryParse(val);
                                  if (n == null || n <= 0) return '> 0 required';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _servedController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Total Served (kg) *'),
                                onChanged: (_) => setState(() {}),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Required';
                                  final n = double.tryParse(val);
                                  if (n == null || n < 0) return '>= 0 required';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Edible Surplus vs Discarded
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _surplusController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Edible Surplus (kg) *'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _discardedController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Discarded Waste (kg) *'),
                                onChanged: (_) => setState(() {}),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Required';
                                  final n = double.tryParse(val);
                                  if (n == null || n < 0) return '>= 0 required';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Measurement Method Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedMethod,
                          decoration: const InputDecoration(labelText: 'Measurement Methodology *'),
                          items: AppConstants.auditMeasurementMethods.map((m) {
                            return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMethod = val);
                          },
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Operational Notes',
                            hintText: 'e.g. Menu items that generated waste, weather impacts',
                          ),
                        ),

                        const SizedBox(height: 18),

                        AppButton(
                          label: 'Submit Daily Waste Audit',
                          icon: Icons.check_circle_outline_rounded,
                          isLoading: _isSubmitting,
                          variant: AppButtonVariant.primary,
                          onPressed: _submitAudit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Historical Audits Table
              const Text(
                'Audit History Logs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
              ),
              const SizedBox(height: 8),

              auditsAsync.when(
                data: (audits) {
                  return Column(
                    children: audits.map((a) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${a.date.day}/${a.date.month}/${a.date.year}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Waste Rate: ${a.wasteRatePercent}%',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Prep: ${a.preparedKg} kg • Served: ${a.servedKg} kg • Surplus: ${a.edibleSurplusKg} kg • Discard: ${a.discardedKg} kg',
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Method: ${a.measurementMethod} • ${a.notes}',
                                style: const TextStyle(fontSize: 11.5, color: Colors.black54),
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

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
