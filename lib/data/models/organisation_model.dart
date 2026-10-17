enum OrgType {
  donor,
  ngo,
  foodbank;

  String get displayName {
    switch (this) {
      case OrgType.donor:
        return 'Food Donor Organisation';
      case OrgType.ngo:
        return 'Approved Partner NGO';
      case OrgType.foodbank:
        return 'Central Food Bank';
    }
  }

  static OrgType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'ngo':
        return OrgType.ngo;
      case 'foodbank':
      case 'food_bank':
        return OrgType.foodbank;
      default:
        return OrgType.donor;
    }
  }
}

class OrganisationModel {
  final String organisationId;
  final String name;
  final OrgType type;
  final String operatingArea;
  final bool isVerified;
  final String operatingHours;
  final String contactPerson;
  final String contactPhone;
  final String physicalAddress;
  final double latitude;
  final double longitude;
  final bool isAcceptingDonations;
  final String capacityStatus;
  final String city;

  const OrganisationModel({
    required this.organisationId,
    required this.name,
    required this.type,
    required this.operatingArea,
    required this.isVerified,
    required this.operatingHours,
    required this.contactPerson,
    required this.contactPhone,
    required this.physicalAddress,
    this.latitude = 18.5204,
    this.longitude = 73.8567,
    this.isAcceptingDonations = true,
    this.capacityStatus = 'Accepting Donations',
    this.city = 'Pune',
  });

  OrganisationModel copyWith({
    String? name,
    OrgType? type,
    String? operatingArea,
    bool? isVerified,
    String? operatingHours,
    String? contactPerson,
    String? contactPhone,
    String? physicalAddress,
    double? latitude,
    double? longitude,
    bool? isAcceptingDonations,
    String? capacityStatus,
    String? city,
  }) {
    return OrganisationModel(
      organisationId: organisationId,
      name: name ?? this.name,
      type: type ?? this.type,
      operatingArea: operatingArea ?? this.operatingArea,
      isVerified: isVerified ?? this.isVerified,
      operatingHours: operatingHours ?? this.operatingHours,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      physicalAddress: physicalAddress ?? this.physicalAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAcceptingDonations: isAcceptingDonations ?? this.isAcceptingDonations,
      capacityStatus: capacityStatus ?? this.capacityStatus,
      city: city ?? this.city,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organisationId': organisationId,
      'name': name,
      'type': type.name,
      'operatingArea': operatingArea,
      'isVerified': isVerified,
      'operatingHours': operatingHours,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'physicalAddress': physicalAddress,
      'latitude': latitude,
      'longitude': longitude,
      'isAcceptingDonations': isAcceptingDonations,
      'capacityStatus': capacityStatus,
      'city': city,
    };
  }

  factory OrganisationModel.fromMap(Map<String, dynamic> map, String id) {
    return OrganisationModel(
      organisationId: id,
      name: map['name'] ?? '',
      type: OrgType.fromString(map['type'] ?? 'donor'),
      operatingArea: map['operatingArea'] ?? '',
      isVerified: map['isVerified'] ?? false,
      operatingHours: map['operatingHours'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      physicalAddress: map['physicalAddress'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 18.5204,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 73.8567,
      isAcceptingDonations: map['isAcceptingDonations'] ?? true,
      capacityStatus: map['capacityStatus'] ?? 'Accepting Donations',
      city: map['city'] ?? 'Pune',
    );
  }
}
