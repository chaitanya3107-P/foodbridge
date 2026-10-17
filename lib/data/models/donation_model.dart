import '../../core/state/donation_status_engine.dart';

class DonationModel {
  final String donationId;
  final String donorId;
  final String donorOrgId;
  final String donorOrgName;
  final String foodDescription;
  final String foodCategory;
  final double listedQuantity;
  final String unit;
  final DateTime preparationDateTime;
  final String storageCondition;
  final List<String> knownAllergens;
  final String packagingType;
  final DateTime pickupDeadline;
  final String locationName;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final String contactPerson;
  final String contactPhone;
  final DonationStatus status;
  final String? cancelReason;
  final bool isExpired;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DonationModel({
    required this.donationId,
    required this.donorId,
    required this.donorOrgId,
    required this.donorOrgName,
    required this.foodDescription,
    required this.foodCategory,
    required this.listedQuantity,
    required this.unit,
    required this.preparationDateTime,
    required this.storageCondition,
    required this.knownAllergens,
    required this.packagingType,
    required this.pickupDeadline,
    required this.locationName,
    required this.locationAddress,
    this.latitude = 18.5204,
    this.longitude = 73.8567,
    required this.contactPerson,
    required this.contactPhone,
    required this.status,
    this.cancelReason,
    this.isExpired = false,
    required this.createdAt,
    required this.updatedAt,
  });

  DonationModel copyWith({
    String? foodDescription,
    String? foodCategory,
    double? listedQuantity,
    String? unit,
    DateTime? preparationDateTime,
    String? storageCondition,
    List<String>? knownAllergens,
    String? packagingType,
    DateTime? pickupDeadline,
    String? locationName,
    String? locationAddress,
    double? latitude,
    double? longitude,
    String? contactPerson,
    String? contactPhone,
    DonationStatus? status,
    String? cancelReason,
    bool? isExpired,
    DateTime? updatedAt,
  }) {
    return DonationModel(
      donationId: donationId,
      donorId: donorId,
      donorOrgId: donorOrgId,
      donorOrgName: donorOrgName,
      foodDescription: foodDescription ?? this.foodDescription,
      foodCategory: foodCategory ?? this.foodCategory,
      listedQuantity: listedQuantity ?? this.listedQuantity,
      unit: unit ?? this.unit,
      preparationDateTime: preparationDateTime ?? this.preparationDateTime,
      storageCondition: storageCondition ?? this.storageCondition,
      knownAllergens: knownAllergens ?? this.knownAllergens,
      packagingType: packagingType ?? this.packagingType,
      pickupDeadline: pickupDeadline ?? this.pickupDeadline,
      locationName: locationName ?? this.locationName,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      isExpired: isExpired ?? this.isExpired,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'donationId': donationId,
      'donorId': donorId,
      'donorOrgId': donorOrgId,
      'donorOrgName': donorOrgName,
      'foodDescription': foodDescription,
      'foodCategory': foodCategory,
      'listedQuantity': listedQuantity,
      'unit': unit,
      'preparationDateTime': preparationDateTime.toIso8601String(),
      'storageCondition': storageCondition,
      'knownAllergens': knownAllergens,
      'packagingType': packagingType,
      'pickupDeadline': pickupDeadline.toIso8601String(),
      'locationName': locationName,
      'locationAddress': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'status': status.name,
      'cancelReason': cancelReason,
      'isExpired': isExpired,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DonationModel.fromMap(Map<String, dynamic> map, String id) {
    return DonationModel(
      donationId: id,
      donorId: map['donorId'] ?? '',
      donorOrgId: map['donorOrgId'] ?? '',
      donorOrgName: map['donorOrgName'] ?? '',
      foodDescription: map['foodDescription'] ?? '',
      foodCategory: map['foodCategory'] ?? '',
      listedQuantity: (map['listedQuantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'kg',
      preparationDateTime: map['preparationDateTime'] != null
          ? DateTime.parse(map['preparationDateTime'])
          : DateTime.now(),
      storageCondition: map['storageCondition'] ?? '',
      knownAllergens: List<String>.from(map['knownAllergens'] ?? []),
      packagingType: map['packagingType'] ?? '',
      pickupDeadline: map['pickupDeadline'] != null
          ? DateTime.parse(map['pickupDeadline'])
          : DateTime.now().add(const Duration(hours: 4)),
      locationName: map['locationName'] ?? '',
      locationAddress: map['locationAddress'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 18.5204,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 73.8567,
      contactPerson: map['contactPerson'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      status: DonationStatus.fromString(map['status'] ?? 'awaitingNgoReview'),
      cancelReason: map['cancelReason'],
      isExpired: map['isExpired'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}
