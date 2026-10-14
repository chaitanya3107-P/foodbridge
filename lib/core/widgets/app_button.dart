import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant {
  primary,
  secondary,
  danger,
  outline,
}

/// Accessible button widget with guaranteed 48dp minimum touch target.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppTheme.primaryGreen;
        fg = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bg = AppTheme.secondaryAmber;
        fg = Colors.white;
        break;
      case AppButtonVariant.danger:
        bg = AppTheme.alertRed;
        fg = Colors.white;
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppTheme.primaryGreen;
        border = const BorderSide(color: AppTheme.primaryGreen, width: 1.6);
        break;
    }

    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height.clamp(AppTheme.minTouchTargetSize, 72.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: variant == AppButtonVariant.outline ? 0 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: border ?? BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}
