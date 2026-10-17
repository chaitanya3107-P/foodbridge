import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/core/services/realtime_service.dart';
import 'package:foodbridge/data/repositories/mock_foodbridge_repository.dart';
import 'package:foodbridge/data/models/user_model.dart';
import 'package:foodbridge/data/models/review_model.dart';

void main() {
  group('Real-Time Engine Tests across 6 Dimensions', () {
    late RealtimeService realtimeService;
    late MockFoodBridgeRepository repository;

    setUp(() {
      realtimeService = RealtimeService();
      realtimeService.clearAll();
      repository = MockFoodBridgeRepository();
      repository.resetToSeedData();
    });

    test('1. Food Availability: Creating a donation dispatches real-time alert and event', () async {
      await repository.switchDemoUser(UserRole.donor);

      final events = <RealtimeEvent>[];
      final sub = realtimeService.eventStream.listen(events.add);

      await repository.createDonation(
        foodDescription: 'Surplus Dal Makhani & Jeera Rice',
        foodCategory: 'Cooked Meals',
        listedQuantity: 25.0,
        unit: 'kg',
        preparationDateTime: DateTime.now().subtract(const Duration(hours: 1)),
        storageCondition: 'Hot Held (> 63°C)',
        knownAllergens: ['Dairy / Milk'],
        packagingType: 'Stainless containers',
        pickupDeadline: DateTime.now().add(const Duration(hours: 3)),
        locationName: 'COEP Main Canteen',
        locationAddress: 'Shivajinagar, Pune 411005',
        contactPerson: 'Chef Anand',
        contactPhone: '+91 98234 56789',
        latitude: 18.5293,
        longitude: 73.8565,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(events.any((e) => e.type == RealtimeEventType.foodAvailability), isTrue);
      expect(events.any((e) => e.type == RealtimeEventType.map), isTrue);
      expect(realtimeService.notifications.first.type, equals(RealtimeEventType.map));
    });

    test('2. NGO Status: Updating operational availability broadcasts live status change', () async {
      final events = <RealtimeEvent>[];
      final sub = realtimeService.eventStream.listen(events.add);

      await repository.updateOrganisationStatus(
        organisationId: 'org_ngo_1',
        isAcceptingDonations: false,
        capacityStatus: 'At Capacity (Temporarily Paused)',
      );

      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(events.any((e) => e.type == RealtimeEventType.ngoStatus), isTrue);
      expect(events.any((e) => e.type == RealtimeEventType.map), isTrue);

      final org = await repository.getOrganisationById('org_ngo_1');
      expect(org?.isAcceptingDonations, isFalse);
      expect(org?.capacityStatus, equals('At Capacity (Temporarily Paused)'));
    });

    test('3. Donation Tracking: NGO review and state progression emits real-time event', () async {
      await repository.switchDemoUser(UserRole.ngoStaff);

      final events = <RealtimeEvent>[];
      final sub = realtimeService.eventStream.listen(events.add);

      await repository.submitReview(
        donationId: 'don_101',
        decision: ReviewDecision.accepted,
        checklist: [],
        ngoNotes: 'Verified temperature and hygiene.',
      );

      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(events.any((e) => e.type == RealtimeEventType.donationTracking), isTrue);
    });

    test('4. Map: Pune NGOs have verified real-world coordinates and operating areas', () async {
      final orgs = await repository.getOrganisations();

      expect(orgs.length, greaterThanOrEqualTo(5));

      final rha = orgs.firstWhere((o) => o.organisationId == 'org_ngo_1');
      expect(rha.name, contains('Robin Hood Army'));
      expect(rha.city, equals('Pune'));
      expect(rha.latitude, closeTo(18.5679, 0.01));
      expect(rha.longitude, closeTo(73.9143, 0.01));

      final feedingIndia = orgs.firstWhere((o) => o.organisationId == 'org_ngo_feeding_india');
      expect(feedingIndia.name, contains('Feeding India'));
      expect(feedingIndia.latitude, closeTo(18.5314, 0.01));
      expect(feedingIndia.longitude, closeTo(73.8446, 0.01));
    });

    test('5. Notifications: Mark read and unread counter functions accurately', () {
      realtimeService.emit(
        type: RealtimeEventType.notifications,
        title: 'Priority Notice',
        message: 'High demand in Hadapsar region.',
      );

      expect(realtimeService.unreadCount, equals(1));
      final notifId = realtimeService.notifications.first.id;

      realtimeService.markAsRead(notifId);
      expect(realtimeService.unreadCount, equals(0));

      realtimeService.emit(
        type: RealtimeEventType.foodAvailability,
        title: 'Alert 1',
        message: 'Test 1',
      );
      realtimeService.emit(
        type: RealtimeEventType.ngoStatus,
        title: 'Alert 2',
        message: 'Test 2',
      );
      expect(realtimeService.unreadCount, equals(2));

      realtimeService.markAllAsRead();
      expect(realtimeService.unreadCount, equals(0));
    });

    test('6. Impact Dashboard: Collection records recalculate live metrics', () async {
      await repository.switchDemoUser(UserRole.volunteer);

      final events = <RealtimeEvent>[];
      final sub = realtimeService.eventStream.listen(events.add);

      // don_103 has pickup scheduled: pickup_103
      await repository.confirmCollection(
        pickupId: 'pick_103',
        actualCollectedQuantity: 21.5,
        actualQuantityUnit: 'kg',
        driverNotes: 'Picked up on time.',
      );

      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(events.any((e) => e.type == RealtimeEventType.impactDashboard), isTrue);
    });
  });
}
