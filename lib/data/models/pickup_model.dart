enum PickupStatus {
  scheduled,
  enRoute,
  collected,
  enRouteToFoodBank,
  delivered,
  failed,
  cancelled;

  String get displayName {
    switch (this) {
      case PickupStatus.scheduled:
        return 'Pickup Scheduled';
      case PickupStatus.enRoute:
        return 'En Route to Donor';
      case PickupStatus.collected:
        return 'Weighed & Collected';
      case PickupStatus.enRouteToFoodBank:
        return 'En Route to Food Bank';
      case PickupStatus.delivered:
        return 'Delivered to Food Bank';
      case PickupStatus.failed:
        return 'Collection Failed';
      case PickupStatus.cancelled:
        return 'Pickup Cancelled';
    }
  }

  static PickupStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'enroute':
      case 'en_route':
        return PickupStatus.enRoute;
      case 'collected':
        return PickupStatus.collected;
      case 'en_route_to_food_bank':
      case 'enroutetofoodbank':
        return PickupStatus.enRouteToFoodBank;
      case 'delivered':
        return PickupStatus.delivered;
      case 'failed':
        return PickupStatus.failed;
      case 'cancelled':
        return PickupStatus.cancelled;
      default:
        return PickupStatus.scheduled;
    }
  }
}

class PickupModel {
  final String pickupId;
  final String donationId;
  final String? assignedVolunteerId;
  final String? assignedVolunteerName;
  final DateTime scheduledWindowStart;
  final DateTime scheduledWindowEnd;
  final DateTime? actualPickupTime;
  final double? actualCollectedQuantity;
  final String? actualQuantityUnit;
  final String driverNotes;
  final PickupStatus status;
  final String? cancelReason;
  final DateTime createdAt;

  const PickupModel({
    required this.pickupId,
    required this.donationId,
    this.assignedVolunteerId,
    this.assignedVolunteerName,
    required this.scheduledWindowStart,
    required this.scheduledWindowEnd,
    this.actualPickupTime,
    this.actualCollectedQuantity,
    this.actualQuantityUnit,
    this.driverNotes = '',
    required this.status,
    this.cancelReason,
    required this.createdAt,
  });

  PickupModel copyWith({
    String? assignedVolunteerId,
    String? assignedVolunteerName,
    DateTime? scheduledWindowStart,
    DateTime? scheduledWindowEnd,
    DateTime? actualPickupTime,
    double? actualCollectedQuantity,
    String? actualQuantityUnit,
    String? driverNotes,
    PickupStatus? status,
    String? cancelReason,
  }) {
    return PickupModel(
      pickupId: pickupId,
      donationId: donationId,
      assignedVolunteerId: assignedVolunteerId ?? this.assignedVolunteerId,
      assignedVolunteerName: assignedVolunteerName ?? this.assignedVolunteerName,
      scheduledWindowStart: scheduledWindowStart ?? this.scheduledWindowStart,
      scheduledWindowEnd: scheduledWindowEnd ?? this.scheduledWindowEnd,
      actualPickupTime: actualPickupTime ?? this.actualPickupTime,
      actualCollectedQuantity: actualCollectedQuantity ?? this.actualCollectedQuantity,
      actualQuantityUnit: actualQuantityUnit ?? this.actualQuantityUnit,
      driverNotes: driverNotes ?? this.driverNotes,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pickupId': pickupId,
      'donationId': donationId,
      'assignedVolunteerId': assignedVolunteerId,
      'assignedVolunteerName': assignedVolunteerName,
      'scheduledWindowStart': scheduledWindowStart.toIso8601String(),
      'scheduledWindowEnd': scheduledWindowEnd.toIso8601String(),
      'actualPickupTime': actualPickupTime?.toIso8601String(),
      'actualCollectedQuantity': actualCollectedQuantity,
      'actualQuantityUnit': actualQuantityUnit,
      'driverNotes': driverNotes,
      'status': status.name,
      'cancelReason': cancelReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PickupModel.fromMap(Map<String, dynamic> map, String id) {
    return PickupModel(
      pickupId: id,
      donationId: map['donationId'] ?? '',
      assignedVolunteerId: map['assignedVolunteerId'],
      assignedVolunteerName: map['assignedVolunteerName'],
      scheduledWindowStart: map['scheduledWindowStart'] != null
          ? DateTime.parse(map['scheduledWindowStart'])
          : DateTime.now(),
      scheduledWindowEnd: map['scheduledWindowEnd'] != null
          ? DateTime.parse(map['scheduledWindowEnd'])
          : DateTime.now().add(const Duration(hours: 2)),
      actualPickupTime: map['actualPickupTime'] != null
          ? DateTime.parse(map['actualPickupTime'])
          : null,
      actualCollectedQuantity: (map['actualCollectedQuantity'] as num?)?.toDouble(),
      actualQuantityUnit: map['actualQuantityUnit'] ?? 'kg',
      driverNotes: map['driverNotes'] ?? '',
      status: PickupStatus.fromString(map['status'] ?? 'scheduled'),
      cancelReason: map['cancelReason'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
