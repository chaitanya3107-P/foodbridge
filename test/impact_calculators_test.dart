import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/core/calculators/impact_calculators.dart';

void main() {
  group('ImpactCalculators Tests', () {
    test('calculateWasteRate calculates correct percentage and handles zero division', () {
      expect(
        ImpactCalculators.calculateWasteRate(discardedKg: 15.0, totalPreparedKg: 200.0),
        equals(7.5),
      );
      // Zero division guard
      expect(
        ImpactCalculators.calculateWasteRate(discardedKg: 15.0, totalPreparedKg: 0.0),
        equals(0.0),
      );
      // Negative input guard
      expect(
        ImpactCalculators.calculateWasteRate(discardedKg: -5.0, totalPreparedKg: 100.0),
        equals(0.0),
      );
    });

    test('calculateChangeInDiscardedWaste returns meaningful reduction percentage', () {
      final result = ImpactCalculators.calculateChangeInDiscardedWaste(
        baselineAvgKg: 20.0,
        postCampaignAvgKg: 10.0,
      );
      expect(result.isMeaningful, isTrue);
      expect(result.percentageChange, equals(50.0));
      expect(result.displayText, equals('-50.0%'));
    });

    test('calculateChangeInDiscardedWaste returns "Not meaningful" if baseline is zero or negative', () {
      final resultZero = ImpactCalculators.calculateChangeInDiscardedWaste(
        baselineAvgKg: 0.0,
        postCampaignAvgKg: 10.0,
      );
      expect(resultZero.isMeaningful, isFalse);
      expect(resultZero.displayText, equals('Not meaningful'));

      final resultNegative = ImpactCalculators.calculateChangeInDiscardedWaste(
        baselineAvgKg: -2.0,
        postCampaignAvgKg: 5.0,
      );
      expect(resultNegative.isMeaningful, isFalse);
      expect(resultNegative.displayText, equals('Not meaningful'));
    });

    test('calculateChangeInDiscardedWaste returns "Not meaningful" if measurement methods changed', () {
      final result = ImpactCalculators.calculateChangeInDiscardedWaste(
        baselineAvgKg: 25.0,
        postCampaignAvgKg: 15.0,
        methodsChanged: true,
      );
      expect(result.isMeaningful, isFalse);
      expect(result.displayText, equals('Not meaningful'));
    });

    test('calculateCompletedCollectionRate returns correct percentage and guards zero', () {
      expect(
        ImpactCalculators.calculateCompletedCollectionRate(
          completedCollections: 8,
          acceptedRequests: 10,
        ),
        equals(80.0),
      );
      expect(
        ImpactCalculators.calculateCompletedCollectionRate(
          completedCollections: 0,
          acceptedRequests: 0,
        ),
        equals(0.0),
      );
    });

    test('calculateDataQualityScore calculates percentage of complete listings', () {
      expect(
        ImpactCalculators.calculateDataQualityScore(
          completeListings: 18,
          submittedListings: 20,
        ),
        equals(90.0),
      );
    });
  });
}
