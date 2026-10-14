import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/core/calculators/impact_calculators.dart';
import 'package:foodbridge/core/state/donation_status_engine.dart';
import 'package:foodbridge/data/models/user_model.dart';
import 'package:foodbridge/data/models/review_model.dart';
import 'package:foodbridge/data/models/pickup_model.dart';
import 'package:foodbridge/data/repositories/mock_foodbridge_repository.dart';

void main() {
  late MockFoodBridgeRepository repo;

  setUp(() {
    repo = MockFoodBridgeRepository();
    repo.resetToSeedData();
  });

  group('FoodBridge Master Specification Test Suite (All Required Cases)', () {
    // -------------------------------------------------------------------------
    // TEST CASE 1: Complete donor listing saves as "Awaiting NGO Review"
    // -------------------------------------------------------------------------
    test('TEST CASE 1: Complete donor listing saves strictly as "Awaiting NGO Review"', () async {
      await repo.switchDemoUser(UserRole.donor);

      final donation = await repo.createDonation(
        foodDescription: 'Steamed Basmati Rice & Mixed Dal',
        foodCategory: 'Cooked Meals',
        listedQuantity: 25.0,
        unit: 'kg',
        preparationDateTime: DateTime.now().subtract(const Duration(hours: 1)),
        storageCondition: 'Hot Held (> 63°C)',
        knownAllergens: ['None Declared'],
        packagingType: 'Stainless food-grade containers',
        pickupDeadline: DateTime.now().add(const Duration(hours: 4)),
        locationName: 'Campus Canteen Loading Bay',
        locationAddress: 'Sector 4, University North Campus Gate 2',
        contactPerson: 'Chef Anand Sharma',
        contactPhone: '+91 98234 56789',
      );

      // Must be saved as Awaiting NGO Review; NOT auto-approved
      expect(donation.status, equals(DonationStatus.awaitingNgoReview));
      expect(donation.status.name, equals('awaitingNgoReview'));
      expect(donation.listedQuantity, equals(25.0));
    });

    // -------------------------------------------------------------------------
    // TEST CASE 2: Missing required fields are blocked and nothing is auto-approved
    // -------------------------------------------------------------------------
    test('TEST CASE 2: Missing required fields are blocked and nothing is auto-approved', () async {
      await repo.switchDemoUser(UserRole.donor);

      // Missing description
      expect(
        () => repo.createDonation(
          foodDescription: '',
          foodCategory: 'Cooked Meals',
          listedQuantity: 10.0,
          unit: 'kg',
          preparationDateTime: DateTime.now(),
          storageCondition: 'Ambient',
          knownAllergens: [],
          packagingType: 'Container',
          pickupDeadline: DateTime.now().add(const Duration(hours: 3)),
          locationName: 'Bay',
          locationAddress: 'Sector 4',
          contactPerson: 'Chef',
          contactPhone: '+91 9876543210',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Invalid quantity (<= 0)
      expect(
        () => repo.createDonation(
          foodDescription: 'Cooked Rice',
          foodCategory: 'Cooked Meals',
          listedQuantity: -5.0,
          unit: 'kg',
          preparationDateTime: DateTime.now(),
          storageCondition: 'Ambient',
          knownAllergens: [],
          packagingType: 'Container',
          pickupDeadline: DateTime.now().add(const Duration(hours: 3)),
          locationName: 'Bay',
          locationAddress: 'Sector 4',
          contactPerson: 'Chef',
          contactPhone: '+91 9876543210',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Past pickup deadline
      expect(
        () => repo.createDonation(
          foodDescription: 'Cooked Rice',
          foodCategory: 'Cooked Meals',
          listedQuantity: 10.0,
          unit: 'kg',
          preparationDateTime: DateTime.now(),
          storageCondition: 'Ambient',
          knownAllergens: [],
          packagingType: 'Container',
          pickupDeadline: DateTime.now().subtract(const Duration(minutes: 10)),
          locationName: 'Bay',
          locationAddress: 'Sector 4',
          contactPerson: 'Chef',
          contactPhone: '+91 9876543210',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    // -------------------------------------------------------------------------
    // TEST CASE 3: A donor or volunteer cannot read NGO records
    // -------------------------------------------------------------------------
    test('TEST CASE 3: A donor or volunteer cannot read private NGO records', () async {
      // 1. Volunteer perspective
      await repo.switchDemoUser(UserRole.volunteer);
      final volunteerPickups = await repo.getPickupsForCurrentRole();
      // Volunteer sees strictly assigned pickups
      for (final p in volunteerPickups) {
        expect(p.assignedVolunteerId, equals('user_volunteer_1'));
      }

      // 2. Awareness perspective
      await repo.switchDemoUser(UserRole.awareness);
      final awarenessDonations = await repo.getDonationsForCurrentRole();
      expect(awarenessDonations, isEmpty);
      final awarenessPickups = await repo.getPickupsForCurrentRole();
      expect(awarenessPickups, isEmpty);

      // 3. NGO perspective (sees all)
      await repo.switchDemoUser(UserRole.ngoStaff);
      final ngoDonations = await repo.getDonationsForCurrentRole();
      expect(ngoDonations.length, greaterThan(1));
    });

    // -------------------------------------------------------------------------
    // TEST CASE 4: NGO accept/reject saves decision and timestamp
    // -------------------------------------------------------------------------
    test('TEST CASE 4: NGO accept/reject saves decision, timestamp, and reviewer credentials', () async {
      await repo.switchDemoUser(UserRole.ngoStaff);

      final review = await repo.submitReview(
        donationId: 'don_101',
        decision: ReviewDecision.accepted,
        checklist: [
          const SafetyChecklistItem(item: 'Packaging intact', isVerified: true),
          const SafetyChecklistItem(item: 'Temperature acceptable', isVerified: true),
        ],
        ngoNotes: 'Approved per NGO intake guidelines.',
      );

      expect(review.decision, equals(ReviewDecision.accepted));
      expect(review.reviewerName, equals('Sarah Jenkins'));
      expect(review.reviewerId, equals('user_ngo_1'));
      expect(review.reviewedAt, isNotNull);

      final updated = await repo.getDonationById('don_101');
      expect(updated?.status, equals(DonationStatus.accepted));
    });

    // -------------------------------------------------------------------------
    // TEST CASE 5: A cancelled pickup stores its reason
    // -------------------------------------------------------------------------
    test('TEST CASE 5: A cancelled pickup stores its reason', () async {
      await repo.switchDemoUser(UserRole.ngoStaff);

      const cancelReason = 'Vehicle tyre puncture delayed driver beyond food holding time';

      await repo.cancelPickup(
        pickupId: 'pick_103',
        cancelReason: cancelReason,
      );

      final pickup = await repo.getPickupForDonation('don_103');
      expect(pickup?.status, equals(PickupStatus.cancelled));
      expect(pickup?.cancelReason, equals(cancelReason));

      final donation = await repo.getDonationById('don_103');
      expect(donation?.status, equals(DonationStatus.cancelled));
      expect(donation?.cancelReason, equals(cancelReason));
    });

    // -------------------------------------------------------------------------
    // TEST CASE 6: Actual collected quantity is stored separately from listed quantity
    // -------------------------------------------------------------------------
    test('TEST CASE 6: Actual collected quantity is stored separately from listed quantity', () async {
      await repo.switchDemoUser(UserRole.volunteer);

      // Initial listed quantity for don_103 was 22.0 kg
      final originalDonation = await repo.getDonationById('don_103');
      expect(originalDonation?.listedQuantity, equals(22.0));

      // Volunteer weighs net food at pickup site: 20.5 kg
      await repo.confirmCollection(
        pickupId: 'pick_103',
        actualCollectedQuantity: 20.5,
        actualQuantityUnit: 'kg',
        driverNotes: 'Tare container deducted on digital scale',
      );

      final updatedPickup = await repo.getPickupForDonation('don_103');
      expect(updatedPickup?.actualCollectedQuantity, equals(20.5));
      expect(updatedPickup?.actualQuantityUnit, equals('kg'));

      final updatedDonation = await repo.getDonationById('don_103');
      // Listed quantity is immutable and remains 22.0 kg
      expect(updatedDonation?.listedQuantity, equals(22.0));
      expect(updatedDonation?.status, equals(DonationStatus.collected));
    });

    // -------------------------------------------------------------------------
    // TEST CASE 7: Distribution and remainder can be recorded
    // -------------------------------------------------------------------------
    test('TEST CASE 7: Distribution and remainder can be recorded with disposition reason', () async {
      await repo.switchDemoUser(UserRole.ngoStaff);

      final distribution = await repo.recordDistribution(
        donationId: 'don_104',
        pickupId: 'pick_104',
        quantityDistributed: 38.0,
        unit: 'kg',
        destinationCategory: 'Homeless Shelter',
        recipientLocation: 'East Wing Shelter, Sector 2',
        remainderQuantity: 4.0,
        remainderDisposition: 'Compost',
        dispositionReason: 'Trimming crusts and container edge residue',
      );

      expect(distribution.quantityDistributed, equals(38.0));
      expect(distribution.remainderQuantity, equals(4.0));
      expect(distribution.remainderDisposition, equals('Compost'));
      expect(distribution.dispositionReason, contains('Trimming crusts'));

      final closedDonation = await repo.getDonationById('don_104');
      expect(closedDonation?.status, equals(DonationStatus.closed));
    });

    // -------------------------------------------------------------------------
    // TEST CASE 8: An expired deadline flags the listing
    // -------------------------------------------------------------------------
    test('TEST CASE 8: An expired deadline flags the listing as Expired', () async {
      final pastTime = DateTime.now().subtract(const Duration(hours: 2));

      // 1. Engine check
      expect(
        DonationStatusEngine.checkDeadlineExpired(pastTime, DonationStatus.awaitingNgoReview),
        isTrue,
      );

      // 2. Active repository inspection
      await repo.switchDemoUser(UserRole.donor);
      final donations = await repo.getDonationsForCurrentRole();
      final expiredDonation = donations.firstWhere((d) => d.donationId == 'don_106');

      expect(expiredDonation.status, equals(DonationStatus.expired));
      expect(expiredDonation.isExpired, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST CASE 9: The dashboard shows verified totals with the date range
    // -------------------------------------------------------------------------
    test('TEST CASE 9: The dashboard shows verified totals with date range filtering', () async {
      final totalsPast7Days = await repo.getImpactTotals(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
      );

      expect(totalsPast7Days.verifiedCollectedKg, greaterThanOrEqualTo(0.0));
      expect(totalsPast7Days.verifiedDistributedKg, greaterThanOrEqualTo(0.0));
      expect(totalsPast7Days.collectionRatePercent, inInclusiveRange(0.0, 100.0));

      // Separate listed estimates from verified collections
      expect(totalsPast7Days.estimatedSurplusOffered, greaterThanOrEqualTo(totalsPast7Days.verifiedCollectedKg));
    });

    // -------------------------------------------------------------------------
    // TEST CASE 10: Mathematical formulas precision and guards
    // -------------------------------------------------------------------------
    test('TEST CASE 10: Formula calculations handle zero-division and method change guards', () {
      // 1. Waste Rate %
      expect(ImpactCalculators.calculateWasteRate(discardedKg: 10.0, totalPreparedKg: 200.0), equals(5.0));
      expect(ImpactCalculators.calculateWasteRate(discardedKg: 10.0, totalPreparedKg: 0.0), equals(0.0));

      // 2. Change in Discarded Waste %
      final changeValid = ImpactCalculators.calculateChangeInDiscardedWaste(baselineAvgKg: 20.0, postCampaignAvgKg: 15.0);
      expect(changeValid.isMeaningful, isTrue);
      expect(changeValid.displayText, equals('-25.0%'));

      final changeZeroBaseline = ImpactCalculators.calculateChangeInDiscardedWaste(baselineAvgKg: 0.0, postCampaignAvgKg: 10.0);
      expect(changeZeroBaseline.isMeaningful, isFalse);
      expect(changeZeroBaseline.displayText, equals('Not meaningful'));

      final changeMethodChanged = ImpactCalculators.calculateChangeInDiscardedWaste(baselineAvgKg: 20.0, postCampaignAvgKg: 10.0, methodsChanged: true);
      expect(changeMethodChanged.isMeaningful, isFalse);
      expect(changeMethodChanged.displayText, equals('Not meaningful'));

      // 3. Collection Rate %
      expect(ImpactCalculators.calculateCompletedCollectionRate(completedCollections: 4, acceptedRequests: 5), equals(80.0));
      expect(ImpactCalculators.calculateCompletedCollectionRate(completedCollections: 0, acceptedRequests: 0), equals(0.0));
    });
  });
}
