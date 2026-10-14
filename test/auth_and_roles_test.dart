import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/data/repositories/mock_foodbridge_repository.dart';
import 'package:foodbridge/data/models/user_model.dart';

void main() {
  late MockFoodBridgeRepository repo;

  setUp(() {
    repo = MockFoodBridgeRepository();
    repo.resetToSeedData();
  });

  group('Phase 2: Auth, Roles, and Approval Flow Tests', () {
    test('Donor registration creates account in pending approval status', () async {
      final newUser = await repo.registerUser(
        name: 'Grand Horizon Canteen',
        email: 'canteen@grandhorizon.com',
        role: UserRole.donor,
        contactNumber: '+91 98765 00112',
        organisationId: 'org_grand_horizon',
      );

      expect(newUser.role, equals(UserRole.donor));
      expect(newUser.approvalStatus, equals(ApprovalStatus.pending));
      expect(newUser.isPending, isTrue);
      expect(newUser.isApproved, isFalse);
    });

    test('Volunteer registration creates account in pending approval status', () async {
      final newVolunteer = await repo.registerUser(
        name: 'Carlos Mendez',
        email: 'carlos@driver.org',
        role: UserRole.volunteer,
        contactNumber: '+91 98765 33445',
      );

      expect(newVolunteer.role, equals(UserRole.volunteer));
      expect(newVolunteer.approvalStatus, equals(ApprovalStatus.pending));
      expect(newVolunteer.isPending, isTrue);
    });

    test('Awareness participant registration is immediately approved', () async {
      final awarenessUser = await repo.registerUser(
        name: 'Sneha Patel',
        email: 'sneha@university.edu',
        role: UserRole.awareness,
        contactNumber: '+91 98765 88990',
      );

      expect(awarenessUser.role, equals(UserRole.awareness));
      expect(awarenessUser.approvalStatus, equals(ApprovalStatus.approved));
      expect(awarenessUser.isApproved, isTrue);
    });

    test('Admin role CANNOT be self-selected at registration', () async {
      expect(
        () => repo.registerUser(
          name: 'Fake Admin',
          email: 'fake@admin.com',
          role: UserRole.admin,
          contactNumber: '+91 98765 99999',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Administrator can approve pending registrations', () async {
      // Register pending user
      final user = await repo.registerUser(
        name: 'Metro Bakery',
        email: 'metro@bakery.com',
        role: UserRole.donor,
        contactNumber: '+91 98765 11223',
      );
      expect(user.isPending, isTrue);

      // Admin approves
      await repo.updateApprovalStatus(user.userId, ApprovalStatus.approved);

      final allUsers = await repo.getAllUsers();
      final updated = allUsers.firstWhere((u) => u.userId == user.userId);

      expect(updated.approvalStatus, equals(ApprovalStatus.approved));
      expect(updated.isApproved, isTrue);
    });

    test('Demo role switcher successfully changes active authenticated identity', () async {
      final donorUser = await repo.switchDemoUser(UserRole.donor);
      expect(repo.getCurrentUser()?.role, equals(UserRole.donor));
      expect(donorUser.email, equals('donor@foodbridge.ngo'));

      final ngoUser = await repo.switchDemoUser(UserRole.ngoStaff);
      expect(repo.getCurrentUser()?.role, equals(UserRole.ngoStaff));
      expect(ngoUser.email, equals('ngo@foodbridge.ngo'));

      final volunteerUser = await repo.switchDemoUser(UserRole.volunteer);
      expect(repo.getCurrentUser()?.role, equals(UserRole.volunteer));
      expect(volunteerUser.email, equals('volunteer@foodbridge.ngo'));

      final adminUser = await repo.switchDemoUser(UserRole.admin);
      expect(repo.getCurrentUser()?.role, equals(UserRole.admin));
      expect(adminUser.email, equals('admin@foodbridge.ngo'));
    });
  });
}
