enum UserRole {
  donor,
  ngoStaff,
  volunteer,
  awareness,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.donor:
        return 'Food Donor';
      case UserRole.ngoStaff:
        return 'NGO / Food Bank Staff';
      case UserRole.volunteer:
        return 'Volunteer / Driver';
      case UserRole.awareness:
        return 'Awareness Participant';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  static UserRole fromString(String val) {
    switch (val.toLowerCase()) {
      case 'donor':
        return UserRole.donor;
      case 'ngo_staff':
      case 'ngostaff':
      case 'ngo':
        return UserRole.ngoStaff;
      case 'volunteer':
      case 'driver':
        return UserRole.volunteer;
      case 'awareness':
        return UserRole.awareness;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.awareness;
    }
  }

  String get firestoreKey {
    switch (this) {
      case UserRole.donor:
        return 'donor';
      case UserRole.ngoStaff:
        return 'ngo_staff';
      case UserRole.volunteer:
        return 'volunteer';
      case UserRole.awareness:
        return 'awareness';
      case UserRole.admin:
        return 'admin';
    }
  }
}

enum ApprovalStatus {
  pending,
  approved,
  rejected;

  static ApprovalStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.pending;
    }
  }
}

class UserModel {
  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final String? organisationId;
  final String contactNumber;
  final ApprovalStatus approvalStatus;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.organisationId,
    required this.contactNumber,
    required this.approvalStatus,
    required this.createdAt,
    this.lastLoginAt,
  });

  bool get isApproved => approvalStatus == ApprovalStatus.approved;
  bool get isPending => approvalStatus == ApprovalStatus.pending;

  UserModel copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? organisationId,
    String? contactNumber,
    ApprovalStatus? approvalStatus,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      organisationId: organisationId ?? this.organisationId,
      contactNumber: contactNumber ?? this.contactNumber,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role.firestoreKey,
      'organisationId': organisationId,
      'contactNumber': contactNumber,
      'approvalStatus': approvalStatus.name,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      userId: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.fromString(map['role'] ?? 'awareness'),
      organisationId: map['organisationId'],
      contactNumber: map['contactNumber'] ?? '',
      approvalStatus: ApprovalStatus.fromString(map['approvalStatus'] ?? 'pending'),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null ? DateTime.parse(map['lastLoginAt']) : null,
    );
  }
}
