/// Result structure for Change in Discarded Waste calculation.
class WasteChangeResult {
  final double? percentageChange;
  final bool isMeaningful;
  final String displayText;

  const WasteChangeResult({
    required this.percentageChange,
    required this.isMeaningful,
    required this.displayText,
  });

  factory WasteChangeResult.meaningful(double percentage) {
    final sign = percentage > 0 ? '-' : (percentage < 0 ? '+' : '');
    final absVal = percentage.abs().toStringAsFixed(1);
    return WasteChangeResult(
      percentageChange: percentage,
      isMeaningful: true,
      displayText: '$sign$absVal%',
    );
  }

  factory WasteChangeResult.notMeaningful(String reason) {
    return const WasteChangeResult(
      percentageChange: null,
      isMeaningful: false,
      displayText: 'Not meaningful',
    );
  }
}

/// Container for verified impact totals, keeping listed vs verified quantities strictly separate.
class VerifiedImpactTotals {
  final double estimatedSurplusOffered; // Listed quantity (donor estimate)
  final double acceptedQuantity;         // Quantity approved by NGO
  final double verifiedCollectedKg;      // Actual collected quantity (verified by driver/NGO)
  final double verifiedDistributedKg;    // Quantity safely distributed to communities
  final double remainderKg;              // Remainder processed (compost/animal feed/disposed)
  final int totalCompletedPickups;
  final int totalAcceptedRequests;
  final double collectionRatePercent;

  const VerifiedImpactTotals({
    required this.estimatedSurplusOffered,
    required this.acceptedQuantity,
    required this.verifiedCollectedKg,
    required this.verifiedDistributedKg,
    required this.remainderKg,
    required this.totalCompletedPickups,
    required this.totalAcceptedRequests,
    required this.collectionRatePercent,
  });

  factory VerifiedImpactTotals.zero() {
    return const VerifiedImpactTotals(
      estimatedSurplusOffered: 0.0,
      acceptedQuantity: 0.0,
      verifiedCollectedKg: 0.0,
      verifiedDistributedKg: 0.0,
      remainderKg: 0.0,
      totalCompletedPickups: 0,
      totalAcceptedRequests: 0,
      collectionRatePercent: 0.0,
    );
  }
}

/// Pure implementation of all required FoodBridge formulas.
class ImpactCalculators {
  /// Waste rate % = discarded ÷ total prepared × 100
  /// Guard: Returns 0.0 if total prepared <= 0.
  static double calculateWasteRate({
    required double discardedKg,
    required double totalPreparedKg,
  }) {
    if (totalPreparedKg <= 0.0) {
      return 0.0;
    }
    if (discardedKg < 0.0) {
      return 0.0;
    }
    final rate = (discardedKg / totalPreparedKg) * 100.0;
    return double.parse(rate.toStringAsFixed(2));
  }

  /// Change in discarded waste % = (baseline avg − post-campaign avg) ÷ baseline avg × 100
  /// Guard: If baseline avg <= 0 or methods changed between periods, returns "Not meaningful".
  static WasteChangeResult calculateChangeInDiscardedWaste({
    required double baselineAvgKg,
    required double postCampaignAvgKg,
    bool methodsChanged = false,
  }) {
    if (methodsChanged) {
      return WasteChangeResult.notMeaningful('Measurement methodology changed between periods');
    }

    if (baselineAvgKg <= 0.0) {
      return WasteChangeResult.notMeaningful('Baseline waste average is zero or negative');
    }

    final change = ((baselineAvgKg - postCampaignAvgKg) / baselineAvgKg) * 100.0;
    return WasteChangeResult.meaningful(double.parse(change.toStringAsFixed(2)));
  }

  /// Completed collection rate % = completed collections ÷ accepted requests × 100
  /// Guard: Returns 0.0 if accepted requests <= 0.
  static double calculateCompletedCollectionRate({
    required int completedCollections,
    required int acceptedRequests,
  }) {
    if (acceptedRequests <= 0) {
      return 0.0;
    }
    if (completedCollections < 0) {
      return 0.0;
    }
    final rate = (completedCollections / acceptedRequests) * 100.0;
    return double.parse(rate.clamp(0.0, 100.0).toStringAsFixed(1));
  }

  /// Data quality % = complete listings ÷ submitted listings × 100
  /// Guard: Returns 0.0 if submitted listings <= 0.
  static double calculateDataQualityScore({
    required int completeListings,
    required int submittedListings,
  }) {
    if (submittedListings <= 0) {
      return 0.0;
    }
    if (completeListings < 0) {
      return 0.0;
    }
    final score = (completeListings / submittedListings) * 100.0;
    return double.parse(score.clamp(0.0, 100.0).toStringAsFixed(1));
  }

  /// Evaluates whether a donation listing qualifies as "complete" for the data quality metric.
  /// Criteria: food description >= 5 chars, quantity > 0, unit specified, storage condition chosen,
  /// allergens explicitly checked, packaging filled, pickup deadline in future, contact details present.
  static bool isListingComplete({
    required String foodDescription,
    required double quantity,
    required String unit,
    required String storageCondition,
    required List<String> allergens,
    required String packaging,
    required DateTime pickupDeadline,
    required String contactPerson,
    required String contactPhone,
  }) {
    if (foodDescription.trim().length < 5) return false;
    if (quantity <= 0) return false;
    if (unit.trim().isEmpty) return false;
    if (storageCondition.trim().isEmpty) return false;
    if (allergens.isEmpty) return false; // Must have at least "None Declared" or specific allergens
    if (packaging.trim().isEmpty) return false;
    if (pickupDeadline.isBefore(DateTime.now())) return false;
    if (contactPerson.trim().isEmpty) return false;
    if (contactPhone.trim().length < 6) return false;
    return true;
  }
}
