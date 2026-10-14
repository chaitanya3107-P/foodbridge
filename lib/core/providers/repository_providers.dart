import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/foodbridge_repository.dart';
import '../../data/repositories/mock_foodbridge_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/models/donation_model.dart';
import '../../data/models/pickup_model.dart';
import '../../data/models/waste_audit_model.dart';
import '../../data/models/distribution_model.dart';
import '../../data/models/awareness_model.dart';
import '../../data/models/audit_log_model.dart';
import '../calculators/impact_calculators.dart';

/// Provider for the active repository implementation.
final repositoryProvider = Provider<FoodBridgeRepository>((ref) {
  return MockFoodBridgeRepository();
});

/// StateNotifier to manage the active authenticated user across demo and live modes.
class CurrentUserNotifier extends StateNotifier<UserModel?> {
  final FoodBridgeRepository _repo;

  CurrentUserNotifier(this._repo) : super(_repo.getCurrentUser());

  Future<void> switchDemoRole(UserRole role) async {
    final user = await _repo.switchDemoUser(role);
    state = user;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required UserRole role,
    required String contactNumber,
    String? organisationId,
  }) async {
    final user = await _repo.registerUser(
      name: name,
      email: email,
      role: role,
      contactNumber: contactNumber,
      organisationId: organisationId,
    );
    state = user;
    return user;
  }

  void signOut() {
    state = null;
  }
}

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, UserModel?>((ref) {
  final repo = ref.watch(repositoryProvider);
  return CurrentUserNotifier(repo);
});

/// Provider for donations accessible to the current user's role.
final roleDonationsProvider = FutureProvider<List<DonationModel>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  ref.watch(currentUserProvider); // re-fetch on user switch
  return repo.getDonationsForCurrentRole();
});

/// Provider for pickups accessible to the current user's role.
final rolePickupsProvider = FutureProvider<List<PickupModel>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  ref.watch(currentUserProvider);
  return repo.getPickupsForCurrentRole();
});

/// Provider for waste audits.
final wasteAuditsProvider = FutureProvider<List<WasteAuditModel>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  ref.watch(currentUserProvider);
  return repo.getWasteAudits();
});

/// Provider for food bank distributions.
final distributionsProvider = FutureProvider<List<DistributionModel>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getAllDistributions();
});

/// Provider for awareness tips and educational content.
final awarenessContentProvider = FutureProvider<List<AwarenessContent>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getAwarenessContent();
});

/// Provider for awareness quiz.
final quizProvider = FutureProvider<Quiz>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getQuiz();
});

/// Provider for verified impact statistics.
final impactTotalsProvider = FutureProvider<VerifiedImpactTotals>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getImpactTotals();
});

/// Provider for system audit log trail.
final auditLogsProvider = FutureProvider<List<AuditLogModel>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getAuditLogs();
});
