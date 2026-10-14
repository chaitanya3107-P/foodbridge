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

/// Abstract contract for FoodBridge data operations.
/// Supports both MockFoodBridgeRepository (demo mode) and FirestoreFoodBridgeRepository.
abstract class FoodBridgeRepository {
  // Auth & User Management
  UserModel? getCurrentUser();
  Future<UserModel> switchDemoUser(UserRole role);
  Future<UserModel> registerUser({
    required String name,
    required String email,
    required UserRole role,
    required String contactNumber,
    String? organisationId,
  });
  Future<void> updateApprovalStatus(String userId, ApprovalStatus status);
  Future<List<UserModel>> getAllUsers();

  // Organisations
  Future<List<OrganisationModel>> getOrganisations();
  Future<OrganisationModel?> getOrganisationById(String orgId);

  // Donations Lifecycle
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
  });

  Future<List<DonationModel>> getDonationsForCurrentRole();
  Future<DonationModel?> getDonationById(String donationId);
  Future<void> updateDonationStatus(
    String donationId,
    DonationStatus newStatus, {
    String? cancelReason,
    Map<String, dynamic>? metadata,
  });

  // NGO Review
  Future<ReviewModel> submitReview({
    required String donationId,
    required ReviewDecision decision,
    required List<SafetyChecklistItem> checklist,
    required String ngoNotes,
  });
  Future<ReviewModel?> getReviewForDonation(String donationId);

  // Logistics & Pickups
  Future<PickupModel> schedulePickup({
    required String donationId,
    required String? assignedVolunteerId,
    required String? assignedVolunteerName,
    required DateTime scheduledWindowStart,
    required DateTime scheduledWindowEnd,
  });
  Future<void> confirmCollection({
    required String pickupId,
    required double actualCollectedQuantity,
    required String actualQuantityUnit,
    required String driverNotes,
  });
  Future<void> cancelPickup({
    required String pickupId,
    required String cancelReason,
  });
  Future<List<PickupModel>> getPickupsForCurrentRole();
  Future<PickupModel?> getPickupForDonation(String donationId);

  // Food-Bank Records & Distribution
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
  });
  Future<List<DistributionModel>> getAllDistributions();

  // Waste Audits
  Future<WasteAuditModel> submitWasteAudit({
    required DateTime date,
    required double preparedKg,
    required double servedKg,
    required double edibleSurplusKg,
    required double discardedKg,
    required String measurementMethod,
    required String notes,
  });
  Future<List<WasteAuditModel>> getWasteAudits();

  // Awareness & Quizzes
  Future<List<AwarenessContent>> getAwarenessContent();
  Future<Quiz> getQuiz();

  // Impact Calculations & Verified Ledger
  Future<VerifiedImpactTotals> getImpactTotals({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Audit Log Trail
  Future<void> logAuditEntry({
    required String action,
    required String targetCollection,
    required String targetId,
    Map<String, dynamic> metadata = const {},
  });
  Future<List<AuditLogModel>> getAuditLogs();
}
