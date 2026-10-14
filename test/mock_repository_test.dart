import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/data/repositories/mock_foodbridge_repository.dart';
import 'package:foodbridge/data/models/user_model.dart';
import 'package:foodbridge/data/models/review_model.dart';
import 'package:foodbridge/core/state/donation_status_engine.dart';

void main() {
  late MockFoodBridgeRepository repo;

  setUp(() {
    repo = MockFoodBridgeRepository();
    repo.resetToSeedData();
  });

  group('MockFoodBridgeRepository Lifecycle Tests', () {
    test('Donor creates listing and it immediately saves as Awaiting NGO Review', () async {
      await repo.switchDemoUser(UserRole.donor);

      final donation = await repo.createDonation(
        foodDescription: 'Hot Vegetable Pulao with Curry',
        foodCategory: 'Cooked Meals',
        listedQuantity: 25.0,
        unit: 'kg',
        preparationDateTime: DateTime.now().subtract(const Duration(hours: 1)),
        storageCondition: 'Hot Held (> 63°C)',
        knownAllergens: ['None Declared'],
        packagingType: 'Stainless food-grade canisters',
        pickupDeadline: DateTime.now().add(const Duration(hours: 3)),
        locationName: 'North Canteen Loading Gate',
        locationAddress: 'Sector 4, University North Campus',
        contactPerson: 'Chef Anand Sharma',
        contactPhone: '+91 98234 56789',
      );

      expect(donation.status, equals(DonationStatus.awaitingNgoReview));
      expect(donation.listedQuantity, equals(25.0));

      // Verify donor can see it in their listings
      final donorListings = await repo.getDonationsForCurrentRole();
      expect(donorListings.any((d) => d.donationId == donation.donationId), isTrue);
    });

    test('Missing required fields when creating a donation are blocked', () async {
      await repo.switchDemoUser(UserRole.donor);

      expect(
        () => repo.createDonation(
          foodDescription: '', // empty description blocked
          foodCategory: 'Cooked Meals',
          listedQuantity: 10.0,
          unit: 'kg',
          preparationDateTime: DateTime.now(),
          storageCondition: 'Ambient',
          knownAllergens: [],
          packagingType: 'Box',
          pickupDeadline: DateTime.now().add(const Duration(hours: 2)),
          locationName: 'Canteen',
          locationAddress: 'Address',
          contactPerson: 'Contact',
          contactPhone: '123456',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('NGO accept/reject records reviewer name, timestamp, and updates status', () async {
      await repo.switchDemoUser(UserRole.ngoStaff);

      final review = await repo.submitReview(
        donationId: 'don_101',
        decision: ReviewDecision.accepted,
        checklist: [
          const SafetyChecklistItem(item: 'Packaging intact', isVerified: true),
          const SafetyChecklistItem(item: 'Temperature verified', isVerified: true),
        ],
        ngoNotes: 'Meets intake hygiene guidelines.',
      );

      expect(review.decision, equals(ReviewDecision.accepted));
      expect(review.reviewerName, equals('Sarah Jenkins'));

      final updatedDonation = await repo.getDonationById('don_101');
      expect(updatedDonation?.status, equals(DonationStatus.accepted));
    });

    test('Actual collected quantity is stored separately from listed quantity', () async {
      await repo.switchDemoUser(UserRole.ngoStaff);

      // Schedule pickup for accepted donation don_101
      final pickup = await repo.schedulePickup(
        donationId: 'don_101',
        assignedVolunteerId: 'user_volunteer_1',
        assignedVolunteerName: 'Alex Driver',
        scheduledWindowStart: DateTime.now(),
        scheduledWindowEnd: DateTime.now().add(const Duration(hours: 2)),
      );

      // Switch to volunteer to confirm collection
      await repo.switchDemoUser(UserRole.volunteer);

      // don_101 listed quantity was 30 kg, driver collects 28.5 kg
      await repo.confirmCollection(
        pickupId: pickup.pickupId,
        actualCollectedQuantity: 28.5,
        actualQuantityUnit: 'kg',
        driverNotes: 'Tare weight deducted. 28.5 kg actual food weight.',
      );

      final storedPickup = await repo.getPickupForDonation('don_101');
      expect(storedPickup?.actualCollectedQuantity, equals(28.5));

      final storedDonation = await repo.getDonationById('don_101');
      // Listed quantity remains unaltered
      expect(storedDonation?.listedQuantity, equals(30.0));
      expect(storedDonation?.status, equals(DonationStatus.collected));
    });

    test('Distribution and remainder are recorded with disposition reason', () async {
      await repo.switchDemoUser(UserRole.ngoStaff);

      final dist = await repo.recordDistribution(
        donationId: 'don_104',
        pickupId: 'pick_104',
        quantityDistributed: 40.0,
        unit: 'kg',
        destinationCategory: 'Homeless Shelter',
        recipientLocation: 'East Wing Shelter, Sector 2',
        remainderQuantity: 2.0,
        remainderDisposition: 'Compost',
        dispositionReason: 'Trimming and packaging residue',
      );

      expect(dist.quantityDistributed, equals(40.0));
      expect(dist.remainderQuantity, equals(2.0));
      expect(dist.remainderDisposition, equals('Compost'));

      final donation = await repo.getDonationById('don_104');
      expect(donation?.status, equals(DonationStatus.closed));
    });

    test('Awareness participant has no access to private donation records', () async {
      await repo.switchDemoUser(UserRole.awareness);

      final donations = await repo.getDonationsForCurrentRole();
      expect(donations, isEmpty);

      final pickups = await repo.getPickupsForCurrentRole();
      expect(pickups, isEmpty);

      // But CAN view awareness content and quiz
      final content = await repo.getAwarenessContent();
      expect(content, isNotEmpty);
      final quiz = await repo.getQuiz();
      expect(quiz.questions, isNotEmpty);
    });

    test('Volunteers see only their assigned pickups', () async {
      await repo.switchDemoUser(UserRole.volunteer);

      final myPickups = await repo.getPickupsForCurrentRole();
      expect(myPickups, isNotEmpty);
      for (final p in myPickups) {
        expect(p.assignedVolunteerId, equals('user_volunteer_1'));
      }
    });
  });
}
