import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/food_safety_disclaimer.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/awareness_model.dart';
import 'quiz_screen.dart';

class AwarenessHubScreen extends ConsumerStatefulWidget {
  const AwarenessHubScreen({super.key});

  @override
  ConsumerState<AwarenessHubScreen> createState() => _AwarenessHubScreenState();
}

class _AwarenessHubScreenState extends ConsumerState<AwarenessHubScreen> {
  AwarenessContentType? _selectedTypeFilter;

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(awarenessContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Awareness & Education Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(awarenessContentProvider),
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

              // Interactive Quiz Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Food-Waste & Safety Assessment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '6 Questions • Pre/Post Assessment with Explanations',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Test your commercial kitchen knowledge on FIFO principles, temperature danger zones, and surplus donation protocols.',
                      style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Take Assessment Quiz',
                      icon: Icons.play_arrow_rounded,
                      variant: AppButtonVariant.secondary,
                      height: 44,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QuizScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Filter Chips
              const Text(
                'Browse Prevention Resources',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
              ),
              const SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Resources'),
                      selected: _selectedTypeFilter == null,
                      onSelected: (_) => setState(() => _selectedTypeFilter = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Tips'),
                      selected: _selectedTypeFilter == AwarenessContentType.tip,
                      avatar: const Icon(Icons.lightbulb_outline_rounded, size: 14),
                      onSelected: (_) => setState(() => _selectedTypeFilter = AwarenessContentType.tip),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Posters'),
                      selected: _selectedTypeFilter == AwarenessContentType.poster,
                      avatar: const Icon(Icons.image_outlined, size: 14),
                      onSelected: (_) => setState(() => _selectedTypeFilter = AwarenessContentType.poster),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('FAQs'),
                      selected: _selectedTypeFilter == AwarenessContentType.faq,
                      avatar: const Icon(Icons.help_outline_rounded, size: 14),
                      onSelected: (_) => setState(() => _selectedTypeFilter = AwarenessContentType.faq),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Campaigns'),
                      selected: _selectedTypeFilter == AwarenessContentType.campaign,
                      avatar: const Icon(Icons.event_outlined, size: 14),
                      onSelected: (_) => setState(() => _selectedTypeFilter = AwarenessContentType.campaign),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Content Items
              contentAsync.when(
                data: (items) {
                  final filtered = items.where((i) {
                    if (_selectedTypeFilter != null && i.type != _selectedTypeFilter) {
                      return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('No resources found in this category.'),
                      ),
                    );
                  }

                  return Column(
                    children: filtered.map((item) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getBadgeColor(item.type),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.type.displayName.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: _getBadgeTextColor(item.type),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.category,
                                    style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                                  ),
                                  const Spacer(),
                                  if (item.campaignDate != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.deepOrange),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${item.campaignDate!.day}/${item.campaignDate!.month}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.deepOrange),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: Color(0xFF1E3228)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.body,
                                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.verified_outlined, size: 14, color: AppTheme.primaryGreen),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Reviewed by: ${item.sourceReviewer}',
                                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                                    ),
                                  ),
                                ],
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

  Color _getBadgeColor(AwarenessContentType type) {
    switch (type) {
      case AwarenessContentType.tip:
        return const Color(0xFFE8F5E9);
      case AwarenessContentType.poster:
        return const Color(0xFFE1F5FE);
      case AwarenessContentType.faq:
        return const Color(0xFFFFF8E1);
      case AwarenessContentType.campaign:
        return const Color(0xFFFBE9E7);
    }
  }

  Color _getBadgeTextColor(AwarenessContentType type) {
    switch (type) {
      case AwarenessContentType.tip:
        return const Color(0xFF2E7D32);
      case AwarenessContentType.poster:
        return const Color(0xFF0277BD);
      case AwarenessContentType.faq:
        return const Color(0xFFF57F17);
      case AwarenessContentType.campaign:
        return const Color(0xFFD84315);
    }
  }
}
