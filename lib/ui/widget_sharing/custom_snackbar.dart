import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class CustomFeedback {
  /// Show success SnackBar with medium haptic feedback
  static void showSuccess(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    _showSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFF2D8A4E), // cozy green
      icon: Icons.check_circle_rounded,
    );
  }

  /// Show error SnackBar with heavy haptic feedback
  static void showError(BuildContext context, String message) {
    HapticFeedback.heavyImpact();
    _showSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFFE04040), // cozy red
      icon: Icons.error_rounded,
    );
  }

  /// Show warning SnackBar with light haptic feedback
  static void showWarning(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    _showSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFFFF9E22), // cozy amber
      icon: Icons.warning_rounded,
    );
  }

  /// Show info SnackBar with selection haptic feedback
  static void showInfo(BuildContext context, String message) {
    HapticFeedback.selectionClick();
    _showSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFF2A1A0A), // warm coffee brown
      icon: Icons.info_rounded,
      borderColor: Colors.white.withValues(alpha: 0.08),
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Color? borderColor,
  }) {
    // Clear current snackbars first to make it responsive
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: spacing3),
            Expanded(
              child: Text(
                message,
                style: sMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: borderColor != null
              ? BorderSide(color: borderColor, width: 1.0)
              : BorderSide.none,
        ),
        margin: const EdgeInsets.all(spacing6),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
