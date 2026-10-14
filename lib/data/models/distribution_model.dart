class DistributionModel {
  final String distributionId;
  final String donationId;
  final String pickupId;
  final double quantityDistributed;
  final String unit;
  final DateTime distributionTime;
  final String destinationCategory;
  final String recipientLocation;
  final double remainderQuantity;
  final String remainderDisposition;
  final String dispositionReason;
  final String recordedByUserId;
  final String recordedByUserName;
  final DateTime createdAt;

  const DistributionModel({
    required this.distributionId,
    required this.donationId,
    required this.pickupId,
    required this.quantityDistributed,
    this.unit = 'kg',
    required this.distributionTime,
    required this.destinationCategory,
    required this.recipientLocation,
    required this.remainderQuantity,
    required this.remainderDisposition,
    required this.dispositionReason,
    required this.recordedByUserId,
    required this.recordedByUserName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'distributionId': distributionId,
      'donationId': donationId,
      'pickupId': pickupId,
      'quantityDistributed': quantityDistributed,
      'unit': unit,
      'distributionTime': distributionTime.toIso8601String(),
      'destinationCategory': destinationCategory,
      'recipientLocation': recipientLocation,
      'remainderQuantity': remainderQuantity,
      'remainderDisposition': remainderDisposition,
      'dispositionReason': dispositionReason,
      'recordedByUserId': recordedByUserId,
      'recordedByUserName': recordedByUserName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DistributionModel.fromMap(Map<String, dynamic> map, String id) {
    return DistributionModel(
      distributionId: id,
      donationId: map['donationId'] ?? '',
      pickupId: map['pickupId'] ?? '',
      quantityDistributed: (map['quantityDistributed'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'kg',
      distributionTime: map['distributionTime'] != null
          ? DateTime.parse(map['distributionTime'])
          : DateTime.now(),
      destinationCategory: map['destinationCategory'] ?? '',
      recipientLocation: map['recipientLocation'] ?? '',
      remainderQuantity: (map['remainderQuantity'] as num?)?.toDouble() ?? 0.0,
      remainderDisposition: map['remainderDisposition'] ?? 'Compost',
      dispositionReason: map['dispositionReason'] ?? '',
      recordedByUserId: map['recordedByUserId'] ?? '',
      recordedByUserName: map['recordedByUserName'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
