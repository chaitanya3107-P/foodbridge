import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/audit_log_model.dart';

class AdminDashboardView extends ConsumerStatefulWidget {
  final UserModel user;

  const AdminDashboardView({super.key, required this.user});

  @override
  ConsumerState<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends ConsumerState<AdminDashboardView> {
  List<UserModel> _allUsers = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    final repo = ref.read(repositoryProvider);
    final users = await repo.getAllUsers();
    if (mounted) {
      setState(() {
        _allUsers = users;
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _changeApproval(String userId, ApprovalStatus status) async {
    final repo = ref.read(repositoryProvider);
    await repo.updateApprovalStatus(userId, status);
    await _loadUsers();
    // Refresh audits
    ref.invalidate(auditLogsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account updated to ${status.name.toUpperCase()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auditLogsAsync = ref.watch(auditLogsProvider);
    final pendingUsers = _allUsers.where((u) => u.isPending).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Administration Console',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
          ),
          const SizedBox(height: 2),
          Text(
            'Administrator: ${widget.user.name} • Full System Oversight',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D54)),
          ),

          const SizedBox(height: 16),

          // Admin KPI Tiles
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Pending Approvals',
                  value: '${pendingUsers.length}',
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFE65100),
                  bgColor: const Color(0xFFFFF3E0),
                  isUrgent: pendingUsers.isNotEmpty,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  title: 'Registered Users',
                  value: '${_allUsers.length}',
                  icon: Icons.people_outline_rounded,
                  color: const Color(0xFF0277BD),
                  bgColor: const Color(0xFFE1F5FE),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Pending Approvals Queue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_ind_outlined, size: 18, color: AppTheme.primaryGreen),
                  const SizedBox(width: 6),
                  Text(
                    'User Registration Approvals (${pendingUsers.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E3228)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: _loadUsers,
              ),
            ],
          ),

          const SizedBox(height: 6),

          if (_isLoadingUsers)
            const Center(child: CircularProgressIndicator())
          else if (pendingUsers.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.verified_rounded, size: 32, color: AppTheme.primaryGreen),
                      const SizedBox(height: 6),
                      const Text(
                        'No pending registrations.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'All donor, NGO, and volunteer accounts have been verified.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Column(
              children: pendingUsers.map((u) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              u.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                u.role.displayName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${u.email} • Phone: ${u.contactNumber}',
                          style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Approve',
                                icon: Icons.check_circle_outline,
                                variant: AppButtonVariant.primary,
                                height: 40,
                                onPressed: () => _changeApproval(u.userId, ApprovalStatus.approved),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppButton(
                                label: 'Reject',
                                icon: Icons.cancel_outlined,
                                variant: AppButtonVariant.danger,
                                height: 40,
                                onPressed: () => _changeApproval(u.userId, ApprovalStatus.rejected),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),

          // System Audit Log Trail Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, size: 18, color: AppTheme.primaryGreen),
                  SizedBox(width: 6),
                  Text(
                    'Recent System Audit Trail',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E3228)),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => ref.invalidate(auditLogsProvider),
                child: const Text('Refresh Logs'),
              ),
            ],
          ),

          const SizedBox(height: 6),

          auditLogsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No audit events recorded.'),
                  ),
                );
              }

              return Column(
                children: logs.take(6).map((log) {
                  return Card(
                    child: ListTile(
                      dense: true,
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryContainer,
                        child: Icon(Icons.bolt_rounded, size: 18, color: AppTheme.primaryGreen),
                      ),
                      title: Text(
                        log.action,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      subtitle: Text(
                        'Actor: ${log.actorName} (${log.actorRole}) • Target: ${log.targetCollection}/${log.targetId}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        _formatTime(log.timestamp),
                        style: const TextStyle(fontSize: 10, color: Colors.black45),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading logs: $e'),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    bool isUrgent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent ? Colors.deepOrange : color.withOpacity(0.3),
          width: isUrgent ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF2C3E35)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }
}
