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
  });

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
    );
  }
}
