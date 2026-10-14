import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/core/calculators/impact_calculators.dart';
import 'package:foodbridge/data/repositories/mock_foodbridge_repository.dart';
import 'package:foodbridge/features/impact_report/services/export_service.dart';

void main() {
  late MockFoodBridgeRepository repo;

  setUp(() {
    repo = MockFoodBridgeRepository();
    repo.resetToSeedData();
  });

  group('Phase 4: Impact, Waste Audit, and Export Tests', () {
    test('Verified Impact Totals separates listed vs actual collected vs distributed', () async {
      final totals = await repo.getImpactTotals();

      expect(totals.estimatedSurplusOffered, greaterThan(0.0));
      expect(totals.verifiedCollectedKg, greaterThan(0.0));
      expect(totals.verifiedDistributedKg, greaterThan(0.0));
      expect(totals.collectionRatePercent, greaterThanOrEqualTo(0.0));

      // Verifies numbers are tracked separately
      expect(totals.estimatedSurplusOffered != totals.verifiedCollectedKg, isTrue);
    });

    test('CSV Generation contains mandatory disclaimer and verified totals', () async {
      final totals = await repo.getImpactTotals();
      final donations = await repo.getDonationsForCurrentRole();
      final audits = await repo.getWasteAudits();

      final csvString = ExportService.generateCsv(
        totals: totals,
        donations: donations,
        audits: audits,
        dateRangeLabel: 'Past 30 Days',
      );

      expect(csvString, contains('FoodBridge Surplus & Waste Impact Report'));
      expect(csvString, contains('Food-safety rules are set by the partner NGO'));
      expect(csvString, contains('VERIFIED IMPACT TOTALS'));
      expect(csvString, contains('CANTEEN DAILY WASTE AUDITS'));
    });

    test('Quiz questions have valid structure and correct answers', () async {
      final quiz = await repo.getQuiz();

      expect(quiz.questions.length, greaterThanOrEqualTo(5));
      for (final q in quiz.questions) {
        expect(q.options.length, greaterThanOrEqualTo(3));
        expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
        expect(q.explanation, isNotEmpty);
      }
    });

    test('Waste audit submission correctly computes waste rate and updates repository', () async {
      final newAudit = await repo.submitWasteAudit(
        date: DateTime.now(),
        preparedKg: 200.0,
        servedKg: 190.0,
        edibleSurplusKg: 5.0,
        discardedKg: 5.0,
        measurementMethod: 'Direct Weighing (Scale)',
        notes: 'Strict portioning implemented',
      );

      expect(newAudit.wasteRatePercent, equals(2.5));

      final audits = await repo.getWasteAudits();
      expect(audits.any((a) => a.auditId == newAudit.auditId), isTrue);
    });
  });
}
