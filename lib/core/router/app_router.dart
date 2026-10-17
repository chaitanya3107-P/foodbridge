import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/repository_providers.dart';
import '../../data/models/user_model.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/pending_approval_screen.dart';
import '../../features/dashboard/screens/role_dashboard_screen.dart';
import '../../features/donations/screens/create_donation_screen.dart';
import '../../features/donations/screens/available_donations_screen.dart';
import '../../features/logistics/screens/pickup_tracking_screen.dart';
import '../../features/food_bank/screens/food_bank_records_screen.dart';
import '../../features/awareness/screens/awareness_hub_screen.dart';
import '../../features/awareness/screens/quiz_screen.dart';
import '../../features/waste_audit/screens/waste_audit_screen.dart';
import '../../features/impact_report/screens/impact_report_screen.dart';
import '../../features/profile/screens/profile_settings_screen.dart';
import '../../features/map/screens/ngo_map_screen.dart';

/// Navigation routes for FoodBridge
class AppRoutes {
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const pendingApproval = '/pending-approval';
  static const home = '/home';

  static const createDonation = '/donations/create';
  static const availableDonations = '/donations/available';
  static const pickupTracking = '/logistics/pickups';
  static const foodBankRecords = '/food-bank/records';
  static const awarenessHub = '/awareness';
  static const awarenessQuiz = '/awareness/quiz';
  static const wasteAudit = '/waste-audit';
  static const impactReport = '/impact-report';
  static const profileSettings = '/profile';
  static const mapView = '/map';
}

/// Provider for GoRouter configured with authentication and approval state redirects.
final routerProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthRoute = loc == AppRoutes.welcome ||
          loc == AppRoutes.login ||
          loc == AppRoutes.register;

      // 1. If unauthenticated, redirect to welcome
      if (currentUser == null) {
        return isAuthRoute ? null : AppRoutes.welcome;
      }

      // 2. If user is in Pending Approval state (and not Awareness Participant or Admin)
      if (currentUser.isPending &&
          currentUser.role != UserRole.awareness &&
          currentUser.role != UserRole.admin) {
        return AppRoutes.pendingApproval;
      }

      // 3. If authenticated & approved, keep away from welcome/login/pending
      if (isAuthRoute || loc == AppRoutes.pendingApproval) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const RoleDashboardScreen(),
      ),

      // Phase 3 routes
      GoRoute(
        path: AppRoutes.createDonation,
        builder: (context, state) => const CreateDonationScreen(),
      ),
      GoRoute(
        path: AppRoutes.availableDonations,
        builder: (context, state) => const AvailableDonationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.pickupTracking,
        builder: (context, state) => const PickupTrackingScreen(),
      ),
      GoRoute(
        path: AppRoutes.foodBankRecords,
        builder: (context, state) => const FoodBankRecordsScreen(),
      ),

      // Phase 4 routes
      GoRoute(
        path: AppRoutes.awarenessHub,
        builder: (context, state) => const AwarenessHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.awarenessQuiz,
        builder: (context, state) => const QuizScreen(),
      ),
      GoRoute(
        path: AppRoutes.wasteAudit,
        builder: (context, state) => const WasteAuditScreen(),
      ),
      GoRoute(
        path: AppRoutes.impactReport,
        builder: (context, state) => const ImpactReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSettings,
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.mapView,
        builder: (context, state) => const NgoMapScreen(),
      ),
    ],
  );
});
