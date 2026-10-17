import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/providers/repository_providers.dart';

/// Modal bottom sheet displaying the real-time notification ledger and
/// allowing users/evaluators to inspect live broadcast events across all 6 dimensions.
class NotificationCenterSheet extends ConsumerWidget {
  const NotificationCenterSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationCenterSheet(),
    );
  }

  Color _badgeColor(RealtimeEventType type) {
    switch (type) {
      case RealtimeEventType.foodAvailability:
        return Colors.amber.shade800;
      case RealtimeEventType.ngoStatus:
        return Colors.teal.shade700;
      case RealtimeEventType.donationTracking:
        return Colors.blue.shade700;
      case RealtimeEventType.map:
        return Colors.indigo.shade600;
      case RealtimeEventType.notifications:
        return Colors.deepPurple.shade600;
      case RealtimeEventType.impactDashboard:
        return AppTheme.primaryGreen;
    }
  }

  IconData _badgeIcon(RealtimeEventType type) {
    switch (type) {
      case RealtimeEventType.foodAvailability:
        return Icons.fastfood_rounded;
      case RealtimeEventType.ngoStatus:
        return Icons.business_rounded;
      case RealtimeEventType.donationTracking:
        return Icons.timeline_rounded;
      case RealtimeEventType.map:
        return Icons.map_rounded;
      case RealtimeEventType.notifications:
        return Icons.notifications_active_rounded;
      case RealtimeEventType.impactDashboard:
        return Icons.eco_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realtimeService = ref.watch(realtimeServiceProvider);
    final notificationsAsync = ref.watch(realtimeNotificationsStreamProvider);

    final notifications = notificationsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => realtimeService.notifications,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppTheme.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Notification Center',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Real-time updates across 6 reactive dimensions',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (notifications.any((n) => !n.isRead))
                TextButton(
                  onPressed: () {
                    realtimeService.markAllAsRead();
                  },
                  child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick Demo Trigger Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Simulate a live surplus food alert to test real-time pipeline:',
                    style: TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    realtimeService.emit(
                      type: RealtimeEventType.foodAvailability,
                      title: 'Live Surplus Alert: Baner Kitchen',
                      message: 'Hotel Green Park listed 25 kg Prepared Rice & Dal for pickup.',
                      metadata: {'simulated': true},
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Simulated real-time food availability event dispatched!'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Simulate Alert', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Notifications List
          Expanded(
            child: notifications.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      final color = _badgeColor(item.type);
                      final icon = _badgeIcon(item.type);
                      final timeStr = DateFormat('h:mm a').format(item.timestamp);

                      return InkWell(
                        onTap: () {
                          realtimeService.markAsRead(item.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          color: item.isRead ? Colors.transparent : Colors.green.shade50.withOpacity(0.4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.message,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade800,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.type.displayName,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                        if (!item.isRead) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: AppTheme.primaryGreen,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
