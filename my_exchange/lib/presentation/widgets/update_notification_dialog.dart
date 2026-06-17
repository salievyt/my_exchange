import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Dialog shown when a new app version is available.
class UpdateNotificationDialog extends StatelessWidget {
  final String version;
  final bool isRequired;
  final String? updateUrl;
  final String? changelog;

  const UpdateNotificationDialog({
    super.key,
    required this.version,
    required this.isRequired,
    this.updateUrl,
    this.changelog,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: AppColors.info,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Доступно обновление',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Версия $version',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Required badge
            if (isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Обязательное обновление',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            if (isRequired) const SizedBox(height: 16),

            // Changelog
            if (changelog != null && changelog!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Что нового:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      changelog!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            // Buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (updateUrl != null && updateUrl!.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ссылка для обновления: $updateUrl'),
                          backgroundColor: AppColors.info,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Обновить сейчас'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                if (!isRequired) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Позже'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
