enum ReviewDecision {
  accepted,
  rejected,
  clarificationRequested;

  String get displayName {
    switch (this) {
      case ReviewDecision.accepted:
        return 'Accepted';
      case ReviewDecision.rejected:
        return 'Rejected';
      case ReviewDecision.clarificationRequested:
        return 'Clarification Requested';
    }
  }

  static ReviewDecision fromString(String val) {
    switch (val.toLowerCase()) {
      case 'accepted':
        return ReviewDecision.accepted;
      case 'rejected':
        return ReviewDecision.rejected;
      default:
        return ReviewDecision.clarificationRequested;
    }
  }
}

class SafetyChecklistItem {
  final String item;
  final bool isVerified;
  final String notes;

  const SafetyChecklistItem({
    required this.item,
    required this.isVerified,
    this.notes = '',
  });

  SafetyChecklistItem copyWith({
    String? item,
    bool? isVerified,
    String? notes,
  }) {
    return SafetyChecklistItem(
      item: item ?? this.item,
      isVerified: isVerified ?? this.isVerified,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item': item,
      'isVerified': isVerified,
      'notes': notes,
    };
  }

  factory SafetyChecklistItem.fromMap(Map<String, dynamic> map) {
    return SafetyChecklistItem(
      item: map['item'] ?? '',
      isVerified: map['isVerified'] ?? false,
      notes: map['notes'] ?? '',
    );
  }
}

class ReviewModel {
  final String reviewId;
  final String donationId;
  final String reviewerId;
  final String reviewerName;
  final ReviewDecision decision;
  final List<SafetyChecklistItem> checklist;
  final String ngoNotes;
  final DateTime reviewedAt;

  const ReviewModel({
    required this.reviewId,
    required this.donationId,
    required this.reviewerId,
    required this.reviewerName,
    required this.decision,
    required this.checklist,
    required this.ngoNotes,
    required this.reviewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'donationId': donationId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'decision': decision.name,
      'checklist': checklist.map((e) => e.toMap()).toList(),
      'ngoNotes': ngoNotes,
      'reviewedAt': reviewedAt.toIso8601String(),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      reviewId: id,
      donationId: map['donationId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? '',
      decision: ReviewDecision.fromString(map['decision'] ?? 'clarificationRequested'),
      checklist: (map['checklist'] as List<dynamic>?)
              ?.map((e) => SafetyChecklistItem.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      ngoNotes: map['ngoNotes'] ?? '',
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.parse(map['reviewedAt'])
          : DateTime.now(),
    );
  }
}
