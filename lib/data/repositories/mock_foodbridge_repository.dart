import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/organisation_model.dart';
import '../models/donation_model.dart';
import '../models/review_model.dart';
import '../models/pickup_model.dart';
import '../models/distribution_model.dart';
import '../models/waste_audit_model.dart';
import '../models/awareness_model.dart';
import '../models/audit_log_model.dart';
import '../../core/state/donation_status_engine.dart';
import '../../core/calculators/impact_calculators.dart';
import '../../core/services/realtime_service.dart';
import '../seed/seed_data.dart';
import 'foodbridge_repository.dart';

/// Fully reactive, in-memory repository implementing all FoodBridge requirements.
/// Preloaded with SeedData to enable zero-config demo mode and rigorous unit/widget testing.
class MockFoodBridgeRepository implements FoodBridgeRepository {
  static final MockFoodBridgeRepository _instance = MockFoodBridgeRepository._internal();
  factory MockFoodBridgeRepository() => _instance;

  final _uuid = const Uuid();

  // Internal state lists initialized from SeedData
  late List<UserModel> _users;
  late List<OrganisationModel> _organisations;
  late List<DonationModel> _donations;
  late List<ReviewModel> _reviews;
  late List<PickupModel> _pickups;
  late List<DistributionModel> _distributions;
  late List<WasteAuditModel> _wasteAudits;
  late List<AwarenessContent> _awarenessContent;
  late Quiz _quiz;
  late List<AuditLogModel> _auditLogs;

  UserModel? _currentUser;

  MockFoodBridgeRepository._internal() {
    resetToSeedData();
  }

  /// Resets internal state back to original seed data.
  void resetToSeedData() {
    _users = List.from(SeedData.users);
    _organisations = List.from(SeedData.organisations);
    _donations = List.from(SeedData.donations);
    _reviews = List.from(SeedData.reviews);
    _pickups = List.from(SeedData.pickups);
    _distributions = List.from(SeedData.distributions);
    _wasteAudits = List.from(SeedData.wasteAudits);
    _awarenessContent = List.from(SeedData.awarenessContent);
    _quiz = SeedData.sampleQuiz;
    _auditLogs = List.from(SeedData.initialAuditLogs);
    // Initial user is null so user starts on the Welcome / Role Login screen
    _currentUser = null;
  }

  // ---------------------------------------------------------------------------
  // User & Auth Management
  // ---------------------------------------------------------------------------
  @override
  UserModel? getCurrentUser() => _currentUser;

  @override
  Future<UserModel> switchDemoUser(UserRole role) async {
    final user = _users.firstWhere(
      (u) => u.role == role && u.approvalStatus == ApprovalStatus.approved,
      orElse: () => _users.firstWhere((u) => u.role == role),
    );
    _currentUser = user;
    await logAuditEntry(
      action: 'DEMO_SWITCH_USER',
      targetCollection: 'users',
      targetId: user.userId,
      metadata: {'role': role.name},
    );
    return user;
  }

  @override
  Future<UserModel> registerUser({
    required String name,
    required String email,
    required UserRole role,
    required String contactNumber,
    String? organisationId,
  }) async {
    // Admin role cannot be self-selected at registration
    if (role == UserRole.admin) {
      throw ArgumentError('Administrator accounts cannot be self-selected at registration.');
    }

    final newUser = UserModel(
      userId: 'user_${_uuid.v4().substring(0, 8)}',
      name: name,
      email: email,
      role: role,
      organisationId: organisationId,
      contactNumber: contactNumber,
      // Awareness participants are approved by default; operational roles start as pending
      approvalStatus: role == UserRole.awareness
          ? ApprovalStatus.approved
          : ApprovalStatus.pending,
      createdAt: DateTime.now(),
    );

    _users.add(newUser);
    _currentUser = newUser;

    await logAuditEntry(
      action: 'USER_REGISTERED',
      targetCollection: 'users',
      targetId: newUser.userId,
      metadata: {'role': role.name, 'approvalStatus': newUser.approvalStatus.name},
    );

    return newUser;
  }

  @override
  Future<void> updateApprovalStatus(String userId, ApprovalStatus status) async {
    final index = _users.indexWhere((u) => u.userId == userId);
    if (index != -1) {
      final oldUser = _users[index];
      _users[index] = oldUser.copyWith(approvalStatus: status);
      await logAuditEntry(
        action: 'USER_APPROVAL_STATUS_CHANGED',
        targetCollection: 'users',
        targetId: userId,
        metadata: {'newStatus': status.name},
      );
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async => List.unmodifiable(_users);

  // ---------------------------------------------------------------------------
  // Organisations
  // ---------------------------------------------------------------------------
  @override
  Future<List<OrganisationModel>> getOrganisations() async =>
      List.unmodifiable(_organisations);

  @override
  Future<OrganisationModel?> getOrganisationById(String orgId) async {
    try {
      return _organisations.firstWhere((o) => o.organisationId == orgId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateOrganisationStatus({
    required String organisationId,
    required bool isAcceptingDonations,
    required String capacityStatus,
    String? operatingHours,
  }) async {
    final index = _organisations.indexWhere((o) => o.organisationId == organisationId);
    if (index != -1) {
      final current = _organisations[index];
      final updated = current.copyWith(
        isAcceptingDonations: isAcceptingDonations,
        capacityStatus: capacityStatus,
        operatingHours: operatingHours ?? current.operatingHours,
      );
      _organisations[index] = updated;

      RealtimeService().emit(
        type: RealtimeEventType.ngoStatus,
        title: 'NGO Status Updated',
        message: '${updated.name} updated intake status to "$capacityStatus" (${isAcceptingDonations ? "Accepting Donations" : "Temporarily Paused"}).',
        metadata: {'orgId': organisationId, 'isAccepting': isAcceptingDonations},
      );

      RealtimeService().emit(
        type: RealtimeEventType.map,
        title: 'Map Availability Updated',
        message: 'Map markers refreshed with new operational status for ${updated.name}.',
        metadata: {'orgId': organisationId},
      );

      await logAuditEntry(
        action: 'ORGANISATION_STATUS_CHANGED',
        targetCollection: 'organisations',
        targetId: organisationId,
        metadata: {
          'isAcceptingDonations': isAcceptingDonations,
          'capacityStatus': capacityStatus,
        },
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Donations Lifecycle & State Engine
  // ---------------------------------------------------------------------------
  @override
  Future<DonationModel> createDonation({
    required String foodDescription,
    required String foodCategory,
    required double listedQuantity,
    required String unit,
    required DateTime preparationDateTime,
    required String storageCondition,
    required List<String> knownAllergens,
    required String packagingType,
    required DateTime pickupDeadline,
    required String locationName,
    required String locationAddress,
    required String contactPerson,
    required String contactPhone,
    double? latitude,
    double? longitude,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw StateError('Authentication required to create a donation.');
    }

    // Required fields validation
    if (foodDescription.trim().isEmpty ||
        listedQuantity <= 0 ||
        packagingType.trim().isEmpty ||
        locationAddress.trim().isEmpty) {
      throw ArgumentError('All required donation fields must be completed.');
    }

    if (pickupDeadline.isBefore(DateTime.now())) {
      throw ArgumentError('Pickup deadline must be set to a future date/time.');
    }

    final newDonation = DonationModel(
      donationId: 'don_${_uuid.v4().substring(0, 8)}',
      donorId: user.userId,
      donorOrgId: user.organisationId ?? 'org_independent',
      donorOrgName: user.name,
      foodDescription: foodDescription,
      foodCategory: foodCategory,
      listedQuantity: listedQuantity,
      unit: unit,
      preparationDateTime: preparationDateTime,
      storageCondition: storageCondition,
      knownAllergens: knownAllergens.isEmpty ? ['None Declared'] : knownAllergens,
      packagingType: packagingType,
      pickupDeadline: pickupDeadline,
      locationName: locationName,
      locationAddress: locationAddress,
      latitude: latitude ?? 18.5293,
      longitude: longitude ?? 73.8565,
      contactPerson: contactPerson,
      contactPhone: contactPhone,
      // CRITICAL PRINCIPLE: Listings always start as Awaiting NGO Review
      status: DonationStatus.awaitingNgoReview,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _donations.insert(0, newDonation);

    // 1. Feature: Food availability becomes real-time
    RealtimeService().emit(
      type: RealtimeEventType.foodAvailability,
      title: 'New Food Donation Available',
      message: '$foodDescription ($listedQuantity $unit) posted at $locationName.',
      metadata: {'donationId': newDonation.donationId},
    );

    // 4. Feature: Map updates when donation coordinates change / new donation posted
    RealtimeService().emit(
      type: RealtimeEventType.map,
      title: 'Food Donation Pin Added to Map',
      message: 'New surplus pickup marker active at $locationAddress (Pune).',
      metadata: {'donationId': newDonation.donationId},
    );

    await logAuditEntry(
      action: 'DONATION_CREATED',
      targetCollection: 'donations',
      targetId: newDonation.donationId,
      metadata: {
        'status': DonationStatus.awaitingNgoReview.name,
        'listedQuantity': listedQuantity,
        'unit': unit,
      },
    );

    return newDonation;
  }

  @override
  Future<List<DonationModel>> getDonationsForCurrentRole() async {
    final user = _currentUser;
    if (user == null) return [];

    // Trigger auto-expiry check for active donations
    _checkAndFlagExpirations();

    switch (user.role) {
      case UserRole.donor:
        // Donor sees only own listings
        return _donations.where((d) => d.donorId == user.userId).toList();
      case UserRole.ngoStaff:
      case UserRole.admin:
        // NGO Staff and Admin see all donations
        return List.unmodifiable(_donations);
      case UserRole.volunteer:
        // Volunteers see donations linked to pickups assigned to them
        final assignedPickupDonationIds = _pickups
            .where((p) => p.assignedVolunteerId == user.userId)
            .map((p) => p.donationId)
            .toSet();
        return _donations
            .where((d) => assignedPickupDonationIds.contains(d.donationId))
            .toList();
      case UserRole.awareness:
        // Public awareness participants have no access to operational donation records
        return [];
    }
  }

  @override
  Future<DonationModel?> getDonationById(String donationId) async {
    try {
      return _donations.firstWhere((d) => d.donationId == donationId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateDonationStatus(
    String donationId,
    DonationStatus newStatus, {
    String? cancelReason,
    Map<String, dynamic>? metadata,
  }) async {
    final index = _donations.indexWhere((d) => d.donationId == donationId);
    if (index == -1) {
      throw ArgumentError('Donation with id $donationId not found.');
    }

    final current = _donations[index];

    // Enforce strict state transition rules; throws StateTransitionException on illegal jump
    DonationStatusEngine.validateTransition(
      current.status,
      newStatus,
      cancelReason: cancelReason,
    );

    _donations[index] = current.copyWith(
      status: newStatus,
      cancelReason: cancelReason,
      isExpired: newStatus == DonationStatus.expired,
      updatedAt: DateTime.now(),
    );

    await logAuditEntry(
      action: 'DONATION_STATUS_CHANGED',
      targetCollection: 'donations',
      targetId: donationId,
      metadata: {
        'from': current.status.name,
        'to': newStatus.name,
        if (cancelReason != null) 'cancelReason': cancelReason,
        ...?metadata,
      },
    );

    // 3. Feature: Donation tracking becomes real-time
    RealtimeService().emit(
      type: RealtimeEventType.donationTracking,
      title: 'Donation Tracking: ${newStatus.displayName}',
      message: 'Donation status updated from ${current.status.displayName} to ${newStatus.displayName}.',
      metadata: {'donationId': donationId, 'status': newStatus.name},
    );
  }

  void _checkAndFlagExpirations() {
    final now = DateTime.now();
    for (var i = 0; i < _donations.length; i++) {
      final d = _donations[i];
      if (DonationStatusEngine.checkDeadlineExpired(d.pickupDeadline, d.status)) {
        _donations[i] = d.copyWith(
          status: DonationStatus.expired,
          isExpired: true,
          updatedAt: now,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // NGO Review
  // ---------------------------------------------------------------------------
  @override
  Future<ReviewModel> submitReview({
    required String donationId,
    required ReviewDecision decision,
    required List<SafetyChecklistItem> checklist,
    required String ngoNotes,
  }) async {
    final user = _currentUser;
    if (user == null || (user.role != UserRole.ngoStaff && user.role != UserRole.admin)) {
      throw StateError('Only NGO Staff or Admin can submit safety reviews.');
    }

    final newReview = ReviewModel(
      reviewId: 'rev_${_uuid.v4().substring(0, 8)}',
      donationId: donationId,
      reviewerId: user.userId,
      reviewerName: user.name,
      decision: decision,
      checklist: checklist,
      ngoNotes: ngoNotes,
      reviewedAt: DateTime.now(),
    );

    _reviews.add(newReview);

    // Map decision to donation status
    DonationStatus targetStatus;
    switch (decision) {
      case ReviewDecision.accepted:
        targetStatus = DonationStatus.accepted;
        break;
      case ReviewDecision.rejected:
        targetStatus = DonationStatus.rejected;
        break;
      case ReviewDecision.clarificationRequested:
        targetStatus = DonationStatus.clarificationRequested;
        break;
    }

    await updateDonationStatus(
      donationId,
      targetStatus,
      metadata: {
        'reviewerId': user.userId,
        'reviewerName': user.name,
        'reviewId': newReview.reviewId,
      },
    );

    return newReview;
  }

  @override
  Future<ReviewModel?> getReviewForDonation(String donationId) async {
    try {
      return _reviews.lastWhere((r) => r.donationId == donationId);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Logistics & Pickups
  // ---------------------------------------------------------------------------
  @override
  Future<PickupModel> schedulePickup({
    required String donationId,
    required String? assignedVolunteerId,
    required String? assignedVolunteerName,
    required DateTime scheduledWindowStart,
    required DateTime scheduledWindowEnd,
  }) async {
    final newPickup = PickupModel(
      pickupId: 'pick_${_uuid.v4().substring(0, 8)}',
      donationId: donationId,
      assignedVolunteerId: assignedVolunteerId,
      assignedVolunteerName: assignedVolunteerName,
      scheduledWindowStart: scheduledWindowStart,
      scheduledWindowEnd: scheduledWindowEnd,
      status: PickupStatus.scheduled,
      createdAt: DateTime.now(),
    );

    _pickups.add(newPickup);

    await updateDonationStatus(
      donationId,
      DonationStatus.pickupScheduled,
      metadata: {'pickupId': newPickup.pickupId, 'assignedVolunteer': assignedVolunteerName},
    );

    return newPickup;
  }

  @override
  Future<void> confirmCollection({
    required String pickupId,
    required double actualCollectedQuantity,
    required String actualQuantityUnit,
    required String driverNotes,
  }) async {
    if (actualCollectedQuantity <= 0) {
      throw ArgumentError('Actual collected quantity must be greater than zero.');
    }

    final pIndex = _pickups.indexWhere((p) => p.pickupId == pickupId);
    if (pIndex == -1) {
      throw ArgumentError('Pickup with id $pickupId not found.');
    }

    final pickup = _pickups[pIndex];
    _pickups[pIndex] = pickup.copyWith(
      status: PickupStatus.collected,
      actualCollectedQuantity: actualCollectedQuantity,
      actualQuantityUnit: actualQuantityUnit,
      actualPickupTime: DateTime.now(),
      driverNotes: driverNotes,
    );

    // Update donation status to Collected
    await updateDonationStatus(
      pickup.donationId,
      DonationStatus.collected,
      metadata: {
        'actualCollectedQuantity': actualCollectedQuantity,
        'unit': actualQuantityUnit,
      },
    );

    // 6. Feature: Impact dashboard becomes real-time
    RealtimeService().emit(
      type: RealtimeEventType.impactDashboard,
      title: 'Impact Dashboard Recalculated',
      message: 'Added $actualCollectedQuantity $actualQuantityUnit of verified collected surplus food.',
      metadata: {'collectedKg': actualCollectedQuantity},
    );
  }

  @override
  Future<void> acceptPickupRequest({required String pickupId}) async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.volunteer) {
      throw StateError('Only volunteer drivers can accept pickup requests.');
    }

    final pIndex = _pickups.indexWhere((p) => p.pickupId == pickupId);
    if (pIndex == -1) {
      throw ArgumentError('Pickup with id $pickupId not found.');
    }

    final pickup = _pickups[pIndex];
    _pickups[pIndex] = pickup.copyWith(
      assignedVolunteerId: user.userId,
      assignedVolunteerName: user.name,
      status: PickupStatus.scheduled,
    );

    RealtimeService().emit(
      type: RealtimeEventType.donationTracking,
      title: 'Pickup Claimed by Driver',
      message: '${user.name} accepted the pickup request and is now assigned.',
      metadata: {'pickupId': pickupId, 'driverId': user.userId, 'driverName': user.name},
    );
  }

  @override
  Future<void> updatePickupTripStatus({
    required String pickupId,
    required PickupStatus status,
    String? driverNotes,
  }) async {
    final pIndex = _pickups.indexWhere((p) => p.pickupId == pickupId);
    if (pIndex == -1) return;

    final pickup = _pickups[pIndex];
    _pickups[pIndex] = pickup.copyWith(
      status: status,
      driverNotes: driverNotes ?? pickup.driverNotes,
    );

    if (status == PickupStatus.delivered) {
      final dIndex = _donations.indexWhere((d) => d.donationId == pickup.donationId);
      if (dIndex != -1 && _donations[dIndex].status == DonationStatus.collected) {
        await updateDonationStatus(
          pickup.donationId,
          DonationStatus.distributionRecorded,
          metadata: {
            'foodBankDeliveredAt': DateTime.now().toIso8601String(),
            'destination': 'Sevadeep Platform Food Bank, Kalyani Nagar',
          },
        );
      }
    }

    RealtimeService().emit(
      type: RealtimeEventType.donationTracking,
      title: 'Live Trip Progress: ${status.displayName}',
      message: '${pickup.assignedVolunteerName ?? "Driver"} updated trip: ${status.displayName}.',
      metadata: {'pickupId': pickupId, 'status': status.name},
    );
  }

  @override
  Future<void> cancelPickup({
    required String pickupId,
    required String cancelReason,
  }) async {
    if (cancelReason.trim().isEmpty) {
      throw ArgumentError('A cancellation reason is required.');
    }

    final pIndex = _pickups.indexWhere((p) => p.pickupId == pickupId);
    if (pIndex == -1) return;

    final pickup = _pickups[pIndex];
    _pickups[pIndex] = pickup.copyWith(
      status: PickupStatus.cancelled,
      cancelReason: cancelReason,
    );

    await updateDonationStatus(
      pickup.donationId,
      DonationStatus.cancelled,
      cancelReason: cancelReason,
    );
  }

  @override
  Future<List<PickupModel>> getPickupsForCurrentRole() async {
    final user = _currentUser;
    if (user == null) return [];

    if (user.role == UserRole.volunteer) {
      // Volunteers see pickups assigned to them OR open broadcast pickups waiting for driver acceptance
      return _pickups
          .where((p) => p.assignedVolunteerId == user.userId || p.assignedVolunteerId == null)
          .toList();
    }

    if (user.role == UserRole.ngoStaff || user.role == UserRole.admin) {
      return List.unmodifiable(_pickups);
    }

    if (user.role == UserRole.donor) {
      // Donors see pickups for their donations
      final myDonationIds = _donations.where((d) => d.donorId == user.userId).map((d) => d.donationId).toSet();
      return _pickups.where((p) => myDonationIds.contains(p.donationId)).toList();
    }

    return [];
  }

  @override
  Future<PickupModel?> getPickupForDonation(String donationId) async {
    try {
      return _pickups.lastWhere((p) => p.donationId == donationId);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Food-Bank Records & Distribution
  // ---------------------------------------------------------------------------
  @override
  Future<DistributionModel> recordDistribution({
    required String donationId,
    required String pickupId,
    required double quantityDistributed,
    required String unit,
    required String destinationCategory,
    required String recipientLocation,
    required double remainderQuantity,
    required String remainderDisposition,
    required String dispositionReason,
  }) async {
    final user = _currentUser;
    if (user == null || (user.role != UserRole.ngoStaff && user.role != UserRole.admin)) {
      throw StateError('Only NGO Staff can record food-bank distribution.');
    }

    final newDistribution = DistributionModel(
      distributionId: 'dist_${_uuid.v4().substring(0, 8)}',
      donationId: donationId,
      pickupId: pickupId,
      quantityDistributed: quantityDistributed,
      unit: unit,
      distributionTime: DateTime.now(),
      destinationCategory: destinationCategory,
      recipientLocation: recipientLocation,
      remainderQuantity: remainderQuantity,
      remainderDisposition: remainderDisposition,
      dispositionReason: dispositionReason,
      recordedByUserId: user.userId,
      recordedByUserName: user.name,
      createdAt: DateTime.now(),
    );

    _distributions.add(newDistribution);

    // Progress donation to Distribution Recorded and Closed
    await updateDonationStatus(donationId, DonationStatus.distributionRecorded);
    await updateDonationStatus(donationId, DonationStatus.closed);

    // 6. Feature: Impact dashboard becomes real-time
    RealtimeService().emit(
      type: RealtimeEventType.impactDashboard,
      title: 'Food Bank Distribution Recorded',
      message: 'Recorded distribution of $quantityDistributed $unit to $recipientLocation ($destinationCategory).',
      metadata: {'distributedKg': quantityDistributed},
    );

    return newDistribution;
  }

  @override
  Future<List<DistributionModel>> getAllDistributions() async =>
      List.unmodifiable(_distributions);

  // ---------------------------------------------------------------------------
  // Waste Audits
  // ---------------------------------------------------------------------------
  @override
  Future<WasteAuditModel> submitWasteAudit({
    required DateTime date,
    required double preparedKg,
    required double servedKg,
    required double edibleSurplusKg,
    required double discardedKg,
    required String measurementMethod,
    required String notes,
  }) async {
    final user = _currentUser;
    final newAudit = WasteAuditModel(
      auditId: 'audit_${_uuid.v4().substring(0, 8)}',
      siteId: user?.organisationId ?? 'site_default',
      siteName: user?.name ?? 'Site Audit',
      recordedByUserId: user?.userId ?? 'unknown',
      date: date,
      preparedKg: preparedKg,
      servedKg: servedKg,
      edibleSurplusKg: edibleSurplusKg,
      discardedKg: discardedKg,
      measurementMethod: measurementMethod,
      notes: notes,
      createdAt: DateTime.now(),
    );

    _wasteAudits.insert(0, newAudit);

    await logAuditEntry(
      action: 'WASTE_AUDIT_SUBMITTED',
      targetCollection: 'waste_audits',
      targetId: newAudit.auditId,
      metadata: {
        'date': date.toIso8601String(),
        'discardedKg': discardedKg,
        'preparedKg': preparedKg,
      },
    );

    return newAudit;
  }

  @override
  Future<List<WasteAuditModel>> getWasteAudits() async {
    final user = _currentUser;
    if (user != null && user.role == UserRole.donor) {
      return _wasteAudits.where((a) => a.recordedByUserId == user.userId).toList();
    }
    return List.unmodifiable(_wasteAudits);
  }

  // ---------------------------------------------------------------------------
  // Awareness Content & Quizzes
  // ---------------------------------------------------------------------------
  @override
  Future<List<AwarenessContent>> getAwarenessContent() async =>
      List.unmodifiable(_awarenessContent);

  @override
  Future<Quiz> getQuiz() async => _quiz;

  // ---------------------------------------------------------------------------
  // Impact Calculations (Verified Accounting)
  // ---------------------------------------------------------------------------
  @override
  Future<VerifiedImpactTotals> getImpactTotals({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filteredDonations = _donations.where((d) {
      if (startDate != null && d.createdAt.isBefore(startDate)) return false;
      if (endDate != null && d.createdAt.isAfter(endDate)) return false;
      return true;
    }).toList();

    double estimatedSurplus = 0.0;
    double acceptedTotal = 0.0;
    int acceptedRequests = 0;

    for (final d in filteredDonations) {
      estimatedSurplus += d.listedQuantity;
      if (d.status != DonationStatus.draft &&
          d.status != DonationStatus.submitted &&
          d.status != DonationStatus.awaitingNgoReview &&
          d.status != DonationStatus.rejected) {
        acceptedTotal += d.listedQuantity;
        acceptedRequests++;
      }
    }

    double verifiedCollected = 0.0;
    int completedPickups = 0;

    for (final p in _pickups) {
      if (p.status == PickupStatus.collected && p.actualCollectedQuantity != null) {
        if (startDate != null && p.createdAt.isBefore(startDate)) continue;
        if (endDate != null && p.createdAt.isAfter(endDate)) continue;
        verifiedCollected += p.actualCollectedQuantity!;
        completedPickups++;
      }
    }

    double verifiedDistributed = 0.0;
    double remainderTotal = 0.0;

    for (final dist in _distributions) {
      if (startDate != null && dist.createdAt.isBefore(startDate)) continue;
      if (endDate != null && dist.createdAt.isAfter(endDate)) continue;
      verifiedDistributed += dist.quantityDistributed;
      remainderTotal += dist.remainderQuantity;
    }

    final collectionRate = ImpactCalculators.calculateCompletedCollectionRate(
      completedCollections: completedPickups,
      acceptedRequests: acceptedRequests,
    );

    return VerifiedImpactTotals(
      estimatedSurplusOffered: double.parse(estimatedSurplus.toStringAsFixed(1)),
      acceptedQuantity: double.parse(acceptedTotal.toStringAsFixed(1)),
      verifiedCollectedKg: double.parse(verifiedCollected.toStringAsFixed(1)),
      verifiedDistributedKg: double.parse(verifiedDistributed.toStringAsFixed(1)),
      remainderKg: double.parse(remainderTotal.toStringAsFixed(1)),
      totalCompletedPickups: completedPickups,
      totalAcceptedRequests: acceptedRequests,
      collectionRatePercent: collectionRate,
    );
  }

  // ---------------------------------------------------------------------------
  // Audit Trail
  // ---------------------------------------------------------------------------
  @override
  Future<void> logAuditEntry({
    required String action,
    required String targetCollection,
    required String targetId,
    Map<String, dynamic> metadata = const {},
  }) async {
    final user = _currentUser;
    final log = AuditLogModel(
      logId: 'log_${_uuid.v4().substring(0, 8)}',
      actorId: user?.userId ?? 'anonymous',
      actorName: user?.name ?? 'Anonymous User',
      actorRole: user?.role.name ?? 'unknown',
      action: action,
      targetCollection: targetCollection,
      targetId: targetId,
      metadata: metadata,
      timestamp: DateTime.now(),
    );
    _auditLogs.insert(0, log);
  }

  @override
  Future<List<AuditLogModel>> getAuditLogs() async => List.unmodifiable(_auditLogs);
}
