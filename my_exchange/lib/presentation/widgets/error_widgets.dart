import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A compact error banner that appears at the top of content when an error occurs.
/// Used when there IS existing data but an error happened during refresh.
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              color: AppColors.error,
              onPressed: onRetry,
              tooltip: 'Повторить',
              visualDensity: VisualDensity.compact,
            ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.error.withValues(alpha: 0.7),
              onPressed: onDismiss,
              tooltip: 'Закрыть',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

/// A full-screen error state shown when there's no data AND an error occurred.
/// Includes a retry button so the user can try loading again.
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.details,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child:              const Icon(
                Icons.warning_amber_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows an error via SnackBar with proper styling.
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 4),

      ),
    );
}

/// Shows a success SnackBar.
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
}
