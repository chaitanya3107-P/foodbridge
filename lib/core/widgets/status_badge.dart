import 'package:flutter/material.dart';
import '../state/donation_status_engine.dart';
import '../theme/app_theme.dart';

/// Accessible, color-coded status badge for donation and pickup states.
class StatusBadge extends StatelessWidget {
  final DonationStatus status;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case DonationStatus.draft:
        bg = const Color(0xFFECEFF1);
        fg = const Color(0xFF455A64);
        icon = Icons.edit_note;
        break;
      case DonationStatus.submitted:
      case DonationStatus.awaitingNgoReview:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57F17);
        icon = Icons.hourglass_top_rounded;
        break;
      case DonationStatus.clarificationRequested:
        bg = const Color(0xFFFBE9E7);
        fg = const Color(0xFFD84315);
        icon = Icons.contact_support_outlined;
        break;
      case DonationStatus.accepted:
        bg = AppTheme.primaryContainer;
        fg = AppTheme.onPrimaryContainer;
        icon = Icons.verified_rounded;
        break;
      case DonationStatus.pickupScheduled:
        bg = const Color(0xFFE1F5FE);
        fg = const Color(0xFF0277BD);
        icon = Icons.schedule_rounded;
        break;
      case DonationStatus.collected:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = Icons.local_shipping_rounded;
        break;
      case DonationStatus.distributionRecorded:
      case DonationStatus.closed:
        bg = const Color(0xFFE0F2F1);
        fg = const Color(0xFF00695C);
        icon = Icons.task_alt_rounded;
        break;
      case DonationStatus.rejected:
        bg = AppTheme.alertContainer;
        fg = AppTheme.alertRed;
        icon = Icons.cancel_outlined;
        break;
      case DonationStatus.cancelled:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        icon = Icons.do_not_disturb_on_outlined;
        break;
      case DonationStatus.expired:
        bg = const Color(0xFFEEEEEE);
        fg = const Color(0xFF616161);
        icon = Icons.timer_off_outlined;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 14 : 16, color: fg),
          const SizedBox(width: 5),
          Text(
            status.displayName,
            style: TextStyle(
              color: fg,
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
