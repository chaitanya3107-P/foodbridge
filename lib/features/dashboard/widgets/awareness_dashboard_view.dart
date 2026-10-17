import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/awareness_model.dart';

class AwarenessDashboardView extends ConsumerWidget {
  final UserModel user;

  const AwarenessDashboardView({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(awarenessContentProvider);
    final impactAsync = ref.watch(impactTotalsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Awareness Centre',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
          ),
          const SizedBox(height: 2),
          Text(
            'Participant: ${user.name} • Education & Waste Prevention Hub',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D54)),
          ),

          const SizedBox(height: 16),

          // Community Verified Impact Callout
          impactAsync.when(
            data: (totals) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E6F5C), Color(0xFF289672)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.public_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Community Diverted Food Waste',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${totals.verifiedDistributedKg.toStringAsFixed(0)} kg',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verified surplus safely distributed to community kitchens and student pantries • ${totals.collectionRatePercent}% collection efficiency.',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 12),

          // Pune NGO Map Quick Access Banner
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
                  Icon(Icons.map_rounded, color: Colors.blue.shade700, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find Food Banks & Relief NGOs in Pune',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                        ),
                        Text(
                          'View verified shelters, community kitchens & directions',
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

          // Interactive Quiz Card
          Card(
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
                  const Row(
                    children: [
                      Icon(Icons.quiz_rounded, color: AppTheme.primaryGreen, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Food-Waste Prevention Quiz',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E3228)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Test your knowledge on kitchen FIFO principles, temperature danger zones, and donation standards.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF4A5D54)),
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'Start 6-Question Quiz',
                    icon: Icons.play_arrow_rounded,
                    variant: AppButtonVariant.primary,
                    height: 44,
                    onPressed: () => context.push(AppRoutes.awarenessQuiz),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Educational Tips & Content Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prevention Tips & Guides',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E3228)),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.awarenessHub),
                child: const Text('View All'),
              ),
            ],
          ),

          const SizedBox(height: 6),

          contentAsync.when(
            data: (items) {
              return Column(
                children: items.map((item) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.type.displayName.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                item.category,
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.body,
                            style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.35),
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

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
