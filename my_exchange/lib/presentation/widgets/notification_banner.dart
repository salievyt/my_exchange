import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/app_notification.dart';

/// Compact news banner displayed at the top of the main screen.
class NotificationBanner extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationBanner({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  Color _getTypeColor() {
    switch (notification.type) {
      case AppNotificationType.update:
        return AppColors.info;
      case AppNotificationType.news:
        return AppColors.primary;
      case AppNotificationType.newFeature:
        return AppColors.success;
      case AppNotificationType.maintenance:
        return AppColors.warning;
      case AppNotificationType.info:
        return AppColors.secondary;
      case AppNotificationType.banner:
        return AppColors.info;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case AppNotificationType.update:
        return Icons.system_update_rounded;
      case AppNotificationType.news:
        return Icons.campaign_rounded;
      case AppNotificationType.newFeature:
        return Icons.auto_awesome_rounded;
      case AppNotificationType.maintenance:
        return Icons.construction_rounded;
      case AppNotificationType.info:
        return Icons.info_outline_rounded;
      case AppNotificationType.banner:
        return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getTypeIcon(),
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        notification.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: isDark ? Colors.white.withValues(alpha: 0.3) : AppColors.textHint,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
