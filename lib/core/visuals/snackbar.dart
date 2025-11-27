// lib/utils/snackbar_utils.dart
import 'package:flutter/material.dart';

enum SnackBarType {
  success,
  error,
  info,
  warning,
  auth,
  admin,
  restore,
  filter,
  navigation,
}

class SnackBarUtils {
  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration? duration,
  }) {
    if (!context.mounted) return;

    final config = _getSnackBarConfig(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(config.icon, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: config.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration ?? config.defaultDuration,
        dismissDirection: DismissDirection.horizontal,
        animation: CurvedAnimation(
          parent: kAlwaysCompleteAnimation,
          curve: Curves.easeOutBack,
        ),
      ),
    );
  }

  // Métodos convenientes para casos de uso comuns
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(context, message, type: SnackBarType.success, duration: duration);
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(context, message, type: SnackBarType.error, duration: duration);
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(context, message, type: SnackBarType.info, duration: duration);
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(context, message, type: SnackBarType.warning, duration: duration);
  }

  static void showAuth(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(context, message, type: SnackBarType.auth, duration: duration);
  }

  static void showAdmin(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(context, message, type: SnackBarType.admin, duration: duration);
  }

  static void showRestore(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(context, message, type: SnackBarType.restore, duration: duration);
  }

  static void showFilter(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(context, message, type: SnackBarType.filter, duration: duration);
  }

  static void showNavigation(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(context, message, type: SnackBarType.navigation, duration: duration);
  }

  static _SnackBarConfig _getSnackBarConfig(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return _SnackBarConfig(
          icon: Icons.check_circle_outline,
          color: const Color(
            0xFF4CAF50,
          ).withValues(alpha: 0.9), // Verde mais suave
          defaultDuration: const Duration(seconds: 3),
        );
      case SnackBarType.error:
        return _SnackBarConfig(
          icon: Icons.error_outline,
          color: const Color(
            0xFFE57373,
          ).withValues(alpha: 0.9), // Vermelho mais suave
          defaultDuration: const Duration(seconds: 4),
        );
      case SnackBarType.info:
        return _SnackBarConfig(
          icon: Icons.info_outline,
          color: const Color(
            0xFF64B5F6,
          ).withValues(alpha: 0.9), // Azul mais suave
          defaultDuration: const Duration(seconds: 3),
        );
      case SnackBarType.warning:
        return _SnackBarConfig(
          icon: Icons.warning_outlined,
          color: const Color(
            0xFFFFB74D,
          ).withValues(alpha: 0.9), // Laranja mais suave
          defaultDuration: const Duration(seconds: 3),
        );
      case SnackBarType.auth:
        return _SnackBarConfig(
          icon: Icons.lock_outline,
          color: const Color(
            0xFFFF8A65,
          ).withValues(alpha: 0.9), // Vermelho-alaranjado mais suave
          defaultDuration: const Duration(seconds: 3),
        );
      case SnackBarType.admin:
        return _SnackBarConfig(
          icon: Icons.admin_panel_settings,
          color: const Color(
            0xFFAD7BE9,
          ).withValues(alpha: 0.9), // Roxo mais suave
          defaultDuration: const Duration(seconds: 3),
        );
      case SnackBarType.restore:
        return _SnackBarConfig(
          icon: Icons.restore,
          color: const Color(
            0xFF81C784,
          ).withValues(alpha: 0.9), // Verde mais suave
          defaultDuration: const Duration(seconds: 3),
        );
      case SnackBarType.filter:
        return _SnackBarConfig(
          icon: Icons.filter_list_off,
          color: const Color(
            0xFF90CAF9,
          ).withValues(alpha: 0.9), // Azul mais suave
          defaultDuration: const Duration(seconds: 2),
        );
      case SnackBarType.navigation:
        return _SnackBarConfig(
          icon: Icons.navigation,
          color: const Color(
            0xFF5C7FBD,
          ).withValues(alpha: 0.9), // Azul marinho mais suave
          defaultDuration: const Duration(seconds: 2),
        );
    }
  }
}

class _SnackBarConfig {
  final IconData icon;
  final Color color;
  final Duration defaultDuration;

  const _SnackBarConfig({
    required this.icon,
    required this.color,
    required this.defaultDuration,
  });
}
