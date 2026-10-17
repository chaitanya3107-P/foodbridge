import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/food_safety_disclaimer.dart';
import '../../../data/models/user_model.dart';
import '../../../data/seed/seed_data.dart';
import '../widgets/donor_dashboard_view.dart';
import '../widgets/ngo_dashboard_view.dart';
import '../widgets/volunteer_dashboard_view.dart';
import '../widgets/awareness_dashboard_view.dart';
import '../widgets/admin_dashboard_view.dart';
import '../../notifications/widgets/notification_center_sheet.dart';

/// Main role-adaptive dashboard screen for FoodBridge.
/// Dynamically renders role-specific workflows based on the logged-in user.
class RoleDashboardScreen extends ConsumerWidget {
  const RoleDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.welcome),
                child: const Text('Go to Welcome Screen'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FoodBridge',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  _roleLabel(user.role),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Demo Mode Role Quick-Switcher
          PopupMenuButton<UserModel>(
            tooltip: 'Switch Demo Role',
            icon: const Icon(Icons.swap_horiz_rounded),
            onSelected: (selectedUser) {
              ref.read(currentUserProvider.notifier).state = selectedUser;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched to ${selectedUser.name} (${_roleLabel(selectedUser.role)})'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem<UserModel>(
                enabled: false,
                child: Text(
                  'QUICK SWITCH DEMO ROLE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              PopupMenuItem<UserModel>(
                value: SeedData.users[0],
                child: const Row(
                  children: [
                    Icon(Icons.storefront_outlined, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Step 1: Donor (Chef Anand)'),
                  ],
                ),
              ),
              PopupMenuItem<UserModel>(
                value: SeedData.users[1],
                child: const Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 18, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Step 2: NGO Staff (Sarah / Sevadeep)'),
                  ],
                ),
              ),
              PopupMenuItem<UserModel>(
                value: SeedData.users[2],
                child: const Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Driver 1 (Alex Driver)'),
                  ],
                ),
              ),
              PopupMenuItem<UserModel>(
                value: SeedData.users[3],
                child: const Row(
                  children: [
                    Icon(Icons.electric_moped_outlined, size: 18, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Driver 2 (Rahul Patil)'),
                  ],
                ),
              ),
              PopupMenuItem<UserModel>(
                value: SeedData.users[4],
                child: const Row(
                  children: [
                    Icon(Icons.directions_car_outlined, size: 18, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('Driver 3 (Sneha Deshmukh)'),
                  ],
                ),
              ),
              PopupMenuItem<UserModel>(
                value: SeedData.users[5],
                child: const Row(
                  children: [
                    Icon(Icons.school_outlined, size: 18, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('Awareness (Priya Sharma)'),
                  ],
                ),
              ),
              PopupMenuItem<UserModel>(
                value: SeedData.users[6],
                child: const Row(
                  children: [
                    Icon(Icons.admin_panel_settings_outlined, size: 18, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('Admin (System Admin)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Sign Out / Switch User',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(currentUserProvider.notifier).signOut();
              context.go(AppRoutes.welcome);
            },
          ),
          IconButton(
            tooltip: 'Pune NGO & Food Map',
            icon: const Icon(Icons.map_rounded),
            onPressed: () => context.push(AppRoutes.mapView),
          ),
          Consumer(
            builder: (context, ref, _) {
              final unreadCount = ref.watch(unreadNotificationsCountProvider);
              return IconButton(
                tooltip: 'Live Notifications ($unreadCount)',
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (unreadCount > 0)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => NotificationCenterSheet.show(context),
              );
            },
          ),
          IconButton(
            tooltip: 'Profile & Settings',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(AppRoutes.profileSettings),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Prominent Universal Food Safety Disclaimer banner
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FoodSafetyDisclaimerBanner(compact: true),
            ),
            Expanded(
              child: _buildRoleView(user),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              // Already on dashboard
              break;
            case 1:
              context.push(AppRoutes.impactReport);
              break;
            case 2:
              context.push(AppRoutes.awarenessHub);
              break;
            case 3:
              context.push(AppRoutes.wasteAudit);
              break;
            case 4:
              context.push(AppRoutes.profileSettings);
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Impact',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'Awareness',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Audit',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildRoleView(UserModel user) {
    switch (user.role) {
      case UserRole.donor:
        return DonorDashboardView(user: user);
      case UserRole.ngoStaff:
        return NgoDashboardView(user: user);
      case UserRole.volunteer:
        return VolunteerDashboardView(user: user);
      case UserRole.awareness:
        return AwarenessDashboardView(user: user);
      case UserRole.admin:
        return AdminDashboardView(user: user);
    }
  }

  static String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.donor:
        return 'Donor Portal';
      case UserRole.ngoStaff:
        return 'Partner NGO Console';
      case UserRole.volunteer:
        return 'Volunteer Logistics';
      case UserRole.awareness:
        return 'Awareness Participant';
      case UserRole.admin:
        return 'Platform Administration';
    }
  }
}
