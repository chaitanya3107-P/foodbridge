class WasteAuditModel {
  final String auditId;
  final String siteId;
  final String siteName;
  final String recordedByUserId;
  final DateTime date;
  final double preparedKg;
  final double servedKg;
  final double edibleSurplusKg;
  final double discardedKg;
  final String measurementMethod;
  final String notes;
  final DateTime createdAt;

  const WasteAuditModel({
    required this.auditId,
    required this.siteId,
    required this.siteName,
    required this.recordedByUserId,
    required this.date,
    required this.preparedKg,
    required this.servedKg,
    required this.edibleSurplusKg,
    required this.discardedKg,
    required this.measurementMethod,
    this.notes = '',
    required this.createdAt,
  });

  /// Calculates the waste rate % directly for this specific audit
  double get wasteRatePercent {
    if (preparedKg <= 0) return 0.0;
    return double.parse(((discardedKg / preparedKg) * 100).toStringAsFixed(2));
  }

  Map<String, dynamic> toMap() {
    return {
      'auditId': auditId,
      'siteId': siteId,
      'siteName': siteName,
      'recordedByUserId': recordedByUserId,
      'date': date.toIso8601String(),
      'preparedKg': preparedKg,
      'servedKg': servedKg,
      'edibleSurplusKg': edibleSurplusKg,
      'discardedKg': discardedKg,
      'measurementMethod': measurementMethod,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WasteAuditModel.fromMap(Map<String, dynamic> map, String id) {
    return WasteAuditModel(
      auditId: id,
      siteId: map['siteId'] ?? '',
      siteName: map['siteName'] ?? '',
      recordedByUserId: map['recordedByUserId'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      preparedKg: (map['preparedKg'] as num?)?.toDouble() ?? 0.0,
      servedKg: (map['servedKg'] as num?)?.toDouble() ?? 0.0,
      edibleSurplusKg: (map['edibleSurplusKg'] as num?)?.toDouble() ?? 0.0,
      discardedKg: (map['discardedKg'] as num?)?.toDouble() ?? 0.0,
      measurementMethod: map['measurementMethod'] ?? 'Direct Weighing (Scale)',
      notes: map['notes'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
