import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/core/state/donation_status_engine.dart';

void main() {
  group('DonationStatusEngine Transition Tests', () {
    test('Valid standard lifecycle transitions are accepted', () {
      expect(
        DonationStatusEngine.canTransition(
          DonationStatus.draft,
          DonationStatus.awaitingNgoReview,
        ),
        isTrue,
      );

      expect(
        DonationStatusEngine.canTransition(
          DonationStatus.awaitingNgoReview,
          DonationStatus.accepted,
        ),
        isTrue,
      );

      expect(
        DonationStatusEngine.canTransition(
          DonationStatus.accepted,
          DonationStatus.pickupScheduled,
        ),
        isTrue,
      );

      expect(
        DonationStatusEngine.canTransition(
          DonationStatus.pickupScheduled,
          DonationStatus.collected,
        ),
        isTrue,
      );

      expect(
        DonationStatusEngine.canTransition(
          DonationStatus.collected,
          DonationStatus.distributionRecorded,
        ),
        isTrue,
      );

      expect(
        DonationStatusEngine.canTransition(
          DonationStatus.distributionRecorded,
          DonationStatus.closed,
        ),
        isTrue,
      );
    });

    test('Illegal state jumps are blocked and throw StateTransitionException', () {
      // Cannot jump from Draft directly to Accepted
      expect(
        () => DonationStatusEngine.validateTransition(
          DonationStatus.draft,
          DonationStatus.accepted,
        ),
        throwsA(isA<StateTransitionException>()),
      );

      // Cannot jump from Rejected to Collected
      expect(
        () => DonationStatusEngine.validateTransition(
          DonationStatus.rejected,
          DonationStatus.collected,
        ),
        throwsA(isA<StateTransitionException>()),
      );

      // Cannot jump backwards from Closed to AwaitingReview
      expect(
        () => DonationStatusEngine.validateTransition(
          DonationStatus.closed,
          DonationStatus.awaitingNgoReview,
        ),
        throwsA(isA<StateTransitionException>()),
      );
    });

    test('Cancellation requires a non-empty cancellation reason', () {
      // Empty reason throws
      expect(
        () => DonationStatusEngine.validateTransition(
          DonationStatus.accepted,
          DonationStatus.cancelled,
          cancelReason: '',
        ),
        throwsA(isA<StateTransitionException>()),
      );

      // Null reason throws
      expect(
        () => DonationStatusEngine.validateTransition(
          DonationStatus.accepted,
          DonationStatus.cancelled,
          cancelReason: null,
        ),
        throwsA(isA<StateTransitionException>()),
      );

      // Non-empty reason succeeds
      expect(
        () => DonationStatusEngine.validateTransition(
          DonationStatus.accepted,
          DonationStatus.cancelled,
          cancelReason: 'Vehicle breakdown prevented pickup',
        ),
        returnsNormally,
      );
    });

    test('Deadline expiry flags active listings but ignores collected or terminal listings', () {
      final pastTime = DateTime.now().subtract(const Duration(hours: 1));
      final futureTime = DateTime.now().add(const Duration(hours: 1));

      // Active listing with past deadline is expired
      expect(
        DonationStatusEngine.checkDeadlineExpired(pastTime, DonationStatus.awaitingNgoReview),
        isTrue,
      );

      // Active listing with future deadline is NOT expired
      expect(
        DonationStatusEngine.checkDeadlineExpired(futureTime, DonationStatus.awaitingNgoReview),
        isFalse,
      );

      // Collected listing with past deadline is NOT expired
      expect(
        DonationStatusEngine.checkDeadlineExpired(pastTime, DonationStatus.collected),
        isFalse,
      );

      // Closed listing is NOT expired
      expect(
        DonationStatusEngine.checkDeadlineExpired(pastTime, DonationStatus.closed),
        isFalse,
      );
    });
  });
}
