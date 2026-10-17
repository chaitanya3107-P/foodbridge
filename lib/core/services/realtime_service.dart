import 'dart:async';
import 'package:uuid/uuid.dart';

/// The 6 dimensions of real-time updates in FoodBridge:
/// 1. Food availability: When a donor posts or updates a donation
/// 2. NGO status: When authorized staff update operating or availability information
/// 3. Donation tracking: When an NGO accepts or collects food
/// 4. Map: When approved locations or donation coordinates change
/// 5. Notifications: When notification service sends an alert
/// 6. Impact dashboard: When completed donations are recorded
enum RealtimeEventType {
  foodAvailability,
  ngoStatus,
  donationTracking,
  map,
  notifications,
  impactDashboard;

  String get displayName {
    switch (this) {
      case RealtimeEventType.foodAvailability:
        return 'Food Availability';
      case RealtimeEventType.ngoStatus:
        return 'NGO Operational Status';
      case RealtimeEventType.donationTracking:
        return 'Donation Lifecycle Tracking';
      case RealtimeEventType.map:
        return 'Live Map & Geolocation';
      case RealtimeEventType.notifications:
        return 'Real-time Alert';
      case RealtimeEventType.impactDashboard:
        return 'Live Impact Calculation';
    }
  }
}

class RealtimeNotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final RealtimeEventType type;
  final bool isRead;
  final Map<String, dynamic> metadata;

  const RealtimeNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.metadata = const {},
  });

  RealtimeNotificationItem copyWith({
    bool? isRead,
  }) {
    return RealtimeNotificationItem(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      type: type,
      isRead: isRead ?? this.isRead,
      metadata: metadata,
    );
  }
}

class RealtimeEvent {
  final RealtimeEventType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  RealtimeEvent({
    required this.type,
    required this.title,
    required this.message,
    DateTime? timestamp,
    this.metadata = const {},
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Central singleton service broadcasting live updates across the 6 reactive dimensions.
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;

  final _uuid = const Uuid();

  final StreamController<RealtimeEvent> _eventController =
      StreamController<RealtimeEvent>.broadcast();
  final StreamController<List<RealtimeNotificationItem>> _notificationsController =
      StreamController<List<RealtimeNotificationItem>>.broadcast();

  final List<RealtimeNotificationItem> _notifications = [];

  Stream<RealtimeEvent> get eventStream => _eventController.stream;
  Stream<List<RealtimeNotificationItem>> get notificationStream =>
      _notificationsController.stream;

  List<RealtimeNotificationItem> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  RealtimeService._internal() {
    _initializeSeedNotifications();
  }

  void _initializeSeedNotifications() {
    final now = DateTime.now();
    _notifications.addAll([
      RealtimeNotificationItem(
        id: 'notif_001',
        title: 'New Food Donation Available',
        message: 'GreenLeaf Canteen listed 30 kg Cooked Meals in Shivajinagar.',
        timestamp: now.subtract(const Duration(minutes: 25)),
        type: RealtimeEventType.foodAvailability,
      ),
      RealtimeNotificationItem(
        id: 'notif_002',
        title: 'NGO Status Updated',
        message: 'Feeding India (Pune Central) is actively accepting prepared meals.',
        timestamp: now.subtract(const Duration(minutes: 50)),
        type: RealtimeEventType.ngoStatus,
      ),
      RealtimeNotificationItem(
        id: 'notif_003',
        title: 'Pickup Confirmed & Weighed',
        message: 'Driver Alex collected 22 kg fresh rolls from GreenLeaf Canteen.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 15)),
        type: RealtimeEventType.donationTracking,
      ),
      RealtimeNotificationItem(
        id: 'notif_004',
        title: 'Map Coordinates Refreshed',
        message: 'Pune NGO network updated: 6 verified intake centers online.',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: RealtimeEventType.map,
      ),
      RealtimeNotificationItem(
        id: 'notif_005',
        title: 'Impact Milestone Reached!',
        message: 'Pune district community ledger crossed 320 kg diverted surplus food.',
        timestamp: now.subtract(const Duration(hours: 3)),
        type: RealtimeEventType.impactDashboard,
      ),
    ]);
  }

  /// Dispatches an event across the real-time pipeline.
  void emit({
    required RealtimeEventType type,
    required String title,
    required String message,
    Map<String, dynamic> metadata = const {},
  }) {
    final event = RealtimeEvent(
      type: type,
      title: title,
      message: message,
      metadata: metadata,
    );
    _eventController.add(event);

    final notification = RealtimeNotificationItem(
      id: 'notif_${_uuid.v4().substring(0, 8)}',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
      metadata: metadata,
    );

    _notifications.insert(0, notification);
    _notificationsController.add(List.unmodifiable(_notifications));
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notificationsController.add(List.unmodifiable(_notifications));
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _notificationsController.add(List.unmodifiable(_notifications));
  }

  void clearAll() {
    _notifications.clear();
    _notificationsController.add(List.unmodifiable(_notifications));
  }
}
