import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Mandatory Universal Food Safety Disclaimer Banner.
///
/// CRITICAL PRINCIPLE: The app SUPPORTS the NGO's procedures; it does not replace them.
/// A listing is never "approved" or "safe" just because it is in the app.
class FoodSafetyDisclaimerBanner extends StatelessWidget {
  final bool compact;

  const FoodSafetyDisclaimerBanner({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        vertical: compact ? 6.0 : 10.0,
        horizontal: 0.0,
      ),
      padding: EdgeInsets.all(compact ? 10.0 : 14.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2214) : AppTheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.secondaryAmber.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: AppTheme.secondaryAmber,
            size: compact ? 20 : 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact) ...[
                  Text(
                    'NGO Food-Safety Authority Notice',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.amber.shade200 : AppTheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  AppConstants.universalFoodSafetyDisclaimer,
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: isDark ? Colors.amber.shade100 : AppTheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
