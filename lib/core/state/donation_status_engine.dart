/// Enumeration of all valid donation lifecycle statuses.
enum DonationStatus {
  draft,
  submitted,
  awaitingNgoReview,
  accepted,
  rejected,
  clarificationRequested,
  pickupScheduled,
  collected,
  distributionRecorded,
  closed,
  cancelled,
  expired;

  String get displayName {
    switch (this) {
      case DonationStatus.draft:
        return 'Draft';
      case DonationStatus.submitted:
        return 'Submitted';
      case DonationStatus.awaitingNgoReview:
        return 'Awaiting NGO Review';
      case DonationStatus.accepted:
        return 'Accepted by NGO';
      case DonationStatus.rejected:
        return 'Rejected';
      case DonationStatus.clarificationRequested:
        return 'Clarification Requested';
      case DonationStatus.pickupScheduled:
        return 'Pickup Scheduled';
      case DonationStatus.collected:
        return 'Collected';
      case DonationStatus.distributionRecorded:
        return 'Distribution Recorded';
      case DonationStatus.closed:
        return 'Closed';
      case DonationStatus.cancelled:
        return 'Cancelled';
      case DonationStatus.expired:
        return 'Expired';
    }
  }

  static DonationStatus fromString(String val) {
    return DonationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => DonationStatus.draft,
    );
  }
}

/// Custom exception thrown when an illegal state transition is attempted.
class StateTransitionException implements Exception {
  final DonationStatus currentStatus;
  final DonationStatus targetStatus;
  final String message;

  StateTransitionException({
    required this.currentStatus,
    required this.targetStatus,
    required this.message,
  });

  @override
  String toString() =>
      'StateTransitionException: Cannot transition from "${currentStatus.displayName}" to "${targetStatus.displayName}". Reason: $message';
}

/// The Donation Status Engine enforces valid state transitions and lifecycle guards.
class DonationStatusEngine {
  /// Defines all permissible transitions for each status.
  static final Map<DonationStatus, Set<DonationStatus>> _legalTransitions = {
    DonationStatus.draft: {
      DonationStatus.submitted,
      DonationStatus.awaitingNgoReview,
      DonationStatus.cancelled,
      DonationStatus.expired,
    },
    DonationStatus.submitted: {
      DonationStatus.awaitingNgoReview,
      DonationStatus.cancelled,
      DonationStatus.expired,
    },
    DonationStatus.awaitingNgoReview: {
      DonationStatus.accepted,
      DonationStatus.rejected,
      DonationStatus.clarificationRequested,
      DonationStatus.cancelled,
      DonationStatus.expired,
    },
    DonationStatus.clarificationRequested: {
      DonationStatus.submitted,
      DonationStatus.awaitingNgoReview,
      DonationStatus.cancelled,
      DonationStatus.expired,
    },
    DonationStatus.accepted: {
      DonationStatus.pickupScheduled,
      DonationStatus.cancelled,
      DonationStatus.expired,
    },
    DonationStatus.pickupScheduled: {
      DonationStatus.collected,
      DonationStatus.cancelled,
    },
    DonationStatus.collected: {
      DonationStatus.distributionRecorded,
    },
    DonationStatus.distributionRecorded: {
      DonationStatus.closed,
    },
    // Terminal statuses have no outgoing transitions
    DonationStatus.closed: {},
    DonationStatus.rejected: {},
    DonationStatus.cancelled: {},
    DonationStatus.expired: {},
  };

  /// Returns true if transitioning from [from] to [to] is legally permissible.
  static bool canTransition(DonationStatus from, DonationStatus to) {
    if (from == to) return true;
    final allowed = _legalTransitions[from];
    return allowed != null && allowed.contains(to);
  }

  /// Validates a transition and throws [StateTransitionException] if illegal.
  static void validateTransition(
    DonationStatus from,
    DonationStatus to, {
    String? cancelReason,
  }) {
    if (from == to) return;

    if (to == DonationStatus.cancelled) {
      if (cancelReason == null || cancelReason.trim().isEmpty) {
        throw StateTransitionException(
          currentStatus: from,
          targetStatus: to,
          message: 'A non-empty cancellation reason is strictly required.',
        );
      }
    }

    if (!canTransition(from, to)) {
      throw StateTransitionException(
        currentStatus: from,
        targetStatus: to,
        message: 'Illegal state jump. Adhere strictly to the NGO donation lifecycle.',
      );
    }
  }

  /// Checks if an active donation has passed its pickup deadline.
  static bool checkDeadlineExpired(DateTime deadline, DonationStatus currentStatus) {
    if (isTerminal(currentStatus) || currentStatus == DonationStatus.collected) {
      return false;
    }
    return DateTime.now().isAfter(deadline);
  }

  /// Returns true if the status is in a terminal end-state.
  static bool isTerminal(DonationStatus status) {
    return status == DonationStatus.closed ||
        status == DonationStatus.rejected ||
        status == DonationStatus.cancelled ||
        status == DonationStatus.expired;
  }

  /// Returns true if the donation is still awaiting or undergoing review.
  static bool isUnderReview(DonationStatus status) {
    return status == DonationStatus.submitted ||
        status == DonationStatus.awaitingNgoReview ||
        status == DonationStatus.clarificationRequested;
  }

  /// Returns true if active in logistics/distribution pipeline.
  static bool isInLogistics(DonationStatus status) {
    return status == DonationStatus.accepted ||
        status == DonationStatus.pickupScheduled ||
        status == DonationStatus.collected;
  }
}
