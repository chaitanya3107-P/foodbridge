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

  group('Phase 3: End-to-End Surplus Donation Pipeline Tests', () {
    test('1. Donor creates listing: Enforces required fields and saves strictly as Awaiting NGO Review', () async {
      await repo.switchDemoUser(UserRole.donor);

      // Attempt invalid listing (quantity <= 0)
      expect(
        () => repo.createDonation(
          foodDescription: 'Cold Pasta Salad',
          foodCategory: 'Cooked Meals',
          listedQuantity: 0.0,
          unit: 'kg',
          preparationDateTime: DateTime.now(),
          storageCondition: 'Chilled',
          knownAllergens: [],
          packagingType: 'Plastic Container',
          pickupDeadline: DateTime.now().add(const Duration(hours: 3)),
          locationName: 'Campus Kitchen',
          locationAddress: 'Sector 4',
          contactPerson: 'Chef',
          contactPhone: '987654321',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Valid listing creation
      final donation = await repo.createDonation(
        foodDescription: 'Prepared Surplus Vegetable Pulao with Dal',
        foodCategory: 'Cooked Meals',
        listedQuantity: 30.0,
        unit: 'kg',
        preparationDateTime: DateTime.now().subtract(const Duration(hours: 1)),
        storageCondition: 'Hot Held (> 63°C)',
        knownAllergens: ['None Declared'],
        packagingType: 'Stainless food-grade containers',
        pickupDeadline: DateTime.now().add(const Duration(hours: 4)),
        locationName: 'North Canteen Loading Gate',
        locationAddress: 'Sector 4, University North Campus',
        contactPerson: 'Chef Anand Sharma',
        contactPhone: '+91 98234 56789',
      );

      // Verifications
      expect(donation.status, equals(DonationStatus.awaitingNgoReview));
      expect(donation.listedQuantity, equals(30.0));
      expect(donation.unit, equals('kg'));
    });

    test('2. NGO Review: Verifies configurable safety checklist and saves decision with reviewer info', () async {
      await repo.switchDemoUser(UserRole.ngoStaff);

      final checklist = [
        const SafetyChecklistItem(item: 'Packaging is intact and sealed', isVerified: true),
        const SafetyChecklistItem(item: 'Temperature verified above 63C', isVerified: true),
        const SafetyChecklistItem(item: 'Custom inspection check', isVerified: true, notes: 'Steam visible, aroma fresh'),
      ];

      final review = await repo.submitReview(
        donationId: 'don_101',
        decision: ReviewDecision.accepted,
        checklist: checklist,
        ngoNotes: 'Meets intake hygiene criteria. Approved for pickup dispatch.',
      );

      expect(review.decision, equals(ReviewDecision.accepted));
      expect(review.reviewerName, equals('Sarah Jenkins'));
      expect(review.checklist.length, equals(3));
      expect(review.checklist.every((c) => c.isVerified), isTrue);

      // Verify donation transitioned to Accepted
      final donation = await repo.getDonationById('don_101');
      expect(donation?.status, equals(DonationStatus.accepted));
    });

    test('3. Scheduling & Collection: Keeps listed vs actual collected quantity strictly separated', () async {
      await repo.switchDemoUser(UserRole.ngoStaff);

      // Schedule pickup
      final pickup = await repo.schedulePickup(
        donationId: 'don_101',
        assignedVolunteerId: 'user_volunteer_1',
        assignedVolunteerName: 'Alex Driver',
        scheduledWindowStart: DateTime.now(),
        scheduledWindowEnd: DateTime.now().add(const Duration(hours: 2)),
      );

      expect(pickup.status.name, equals('scheduled'));

      // Switch to driver to confirm collection
      await repo.switchDemoUser(UserRole.volunteer);

      // Listed quantity was 30.0 kg; driver measures 27.5 kg
      await repo.confirmCollection(
        pickupId: pickup.pickupId,
        actualCollectedQuantity: 27.5,
        actualQuantityUnit: 'kg',
        driverNotes: 'Tare weight deducted. 27.5 kg actual net food.',
      );

      // Verify separate storage
      final updatedPickup = await repo.getPickupForDonation('don_101');
      expect(updatedPickup?.actualCollectedQuantity, equals(27.5));
      expect(updatedPickup?.status.name, equals('collected'));

      final updatedDonation = await repo.getDonationById('don_101');
      expect(updatedDonation?.listedQuantity, equals(30.0)); // original listed quantity preserved
      expect(updatedDonation?.status, equals(DonationStatus.collected));
    });

    test('4. Food-Bank Records: Records distribution and accounts for remainder with disposition reason', () async {
      await repo.switchDemoUser(UserRole.ngoStaff);

      final dist = await repo.recordDistribution(
        donationId: 'don_104',
        pickupId: 'pick_104',
        quantityDistributed: 40.0,
        unit: 'kg',
        destinationCategory: 'Student Food Pantry',
        recipientLocation: 'Block C Community Pantry',
        remainderQuantity: 2.0,
        remainderDisposition: 'Compost',
        dispositionReason: 'Trimming crusts and container edge residue',
      );

      expect(dist.quantityDistributed, equals(40.0));
      expect(dist.remainderQuantity, equals(2.0));
      expect(dist.remainderDisposition, equals('Compost'));
      expect(dist.dispositionReason, isNotEmpty);

      // Verify donation is closed
      final closedDonation = await repo.getDonationById('don_104');
      expect(closedDonation?.status, equals(DonationStatus.closed));
    });

    test('5. State Machine Security: Reject illegal direct jump from Awaiting Review to Collected', () {
      expect(
        () => DonationStatusEngine.validateTransition(
          DonationStatus.awaitingNgoReview,
          DonationStatus.collected,
        ),
        throwsA(isA<StateTransitionException>()),
      );
    });
  });
}
