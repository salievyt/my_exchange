import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/reports_provider.dart';
import '../../../presentation/widgets/error_widgets.dart' show ErrorBanner;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final local = context.watch<LocalizationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(local.t('reports_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ReportsProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Card(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.description,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                local.t('reports_subtitle'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                local.t('reports_desc'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Daily Report ──────────────────────────────────
                _ReportCard(
                  icon: Icons.today,
                  title: local.t('reports_daily'),
                  subtitle: local.t('reports_daily_desc'),
                  color: AppColors.info,
                  formatOptions: [ReportFormat.csv],
                  onDownload: (format) => _downloadReport(
                    provider,
                    ReportType.daily,
                    format,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Monthly Report ────────────────────────────────
                _ReportCard(
                  icon: Icons.calendar_month,
                  title: local.t('reports_monthly'),
                  subtitle: local.t('reports_monthly_desc'),
                  color: AppColors.secondary,
                  formatOptions: [ReportFormat.csv],
                  onDownload: (format) => _downloadReport(
                    provider,
                    ReportType.monthly,
                    format,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Export Operations ─────────────────────────────
                _ReportCard(
                  icon: Icons.swap_horiz,
                  title: local.t('reports_operations'),
                  subtitle: local.t('reports_operations_desc'),
                  color: AppColors.success,
                  formatOptions: [ReportFormat.csv, ReportFormat.xlsx, ReportFormat.pdf],
                  onDownload: (format) => _downloadReport(
                    provider,
                    ReportType.operations,
                    format,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Export Cash ───────────────────────────────────
                _ReportCard(
                  icon: Icons.account_balance,
                  title: local.t('reports_cash'),
                  subtitle: local.t('reports_cash_desc'),
                  color: AppColors.warning,
                  formatOptions: [ReportFormat.csv, ReportFormat.xlsx, ReportFormat.pdf],
                  onDownload: (format) => _downloadReport(
                    provider,
                    ReportType.cash,
                    format,
                  ),
                ),
                const SizedBox(height: 24),

                // Progress indicator
                if (provider.isLoading) ...[
                  LinearProgressIndicator(
                    value: provider.progress > 0 ? provider.progress : null,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      local.t('reports_generating'),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (provider.progress > 0)
                    Center(
                      child: Text(
                        '${(provider.progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],

                // Error message
                if (provider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ErrorBanner(
                      message: provider.errorMessage!,
                      onDismiss: () => provider.clearMessages(),
                      onRetry: null,
                    ),
                  ),

                // Success message
                if (provider.successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  local.t('reports_saved'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 28,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => provider.clearMessages(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            local.t('reports_saved_desc'),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _shareFile(provider),
                              icon: const Icon(Icons.share, size: 16),
                              label: Text(local.t('reports_open_share')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadReport(
    ReportsProvider provider,
    ReportType type,
    ReportFormat format,
  ) async {
    await provider.downloadReport(
      type: type,
      format: format,
    );
  }

  Future<void> _shareFile(ReportsProvider provider) async {
    final path = provider.savedFilePath;
    if (path == null) return;

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        subject: 'My Exchange — ${path.split('/').last}',
      ),
    );
  }
}

// ─── Report Card Widget ───────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<ReportFormat> formatOptions;
  final void Function(ReportFormat format) onDownload;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.formatOptions,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final local = context.watch<LocalizationProvider>();
    final provider = context.watch<ReportsProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (formatOptions.length == 1)
              _DownloadButton(
                onPressed:
                    provider.isLoading ? null : () => onDownload(formatOptions.first),
                label: local.t('reports_download'),
                icon: Icons.download,
                color: color,
              )
            else
              PopupMenuButton<ReportFormat>(
                onSelected: provider.isLoading ? null : onDownload,
                tooltip: local.t('reports_download'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => formatOptions.map((format) {
                  return PopupMenuItem(
                    value: format,
                    child: Row(
                      children: [
                        Icon(
                          format == ReportFormat.csv
                              ? Icons.table_chart
                              : format == ReportFormat.pdf
                                  ? Icons.picture_as_pdf
                                  : Icons.grid_on,
                          size: 18,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Text('${local.t('reports_download')} .${format.value}'),
                      ],
                    ),
                  );
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download,
                        size: 18,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '.csv/.xlsx/.pdf',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, size: 18, color: color),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final Color color;

  const _DownloadButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

