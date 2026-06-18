import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../presentation/providers/operation_provider.dart';
import '../../../presentation/widgets/operation_card.dart';
import '../../../presentation/widgets/error_widgets.dart';
import 'create_operation_screen.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OperationProvider>().loadOperations();
      context.read<OperationProvider>().loadTodayStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = context.watch<LocalizationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(local.t('operations_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<OperationProvider>().loadOperations();
              context.read<OperationProvider>().loadTodayStats();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Today stats
          _buildTodayStats(),

          // Operations list
          Expanded(
            child: Consumer<OperationProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.operations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error state with retry (no data)
                if (provider.errorMessage != null &&
                    provider.operations.isEmpty) {
                  return ErrorStateWidget(
                    message: provider.errorMessage!,
                    details: '${local.t('operations_title')} — ${provider.errorMessage!}',
                    onRetry: () {
                      provider.loadOperations();
                      provider.loadTodayStats();
                    },
                  );
                }

                if (provider.operations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          local.t('operations_empty'),
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            provider.loadOperations();
                            provider.loadTodayStats();
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(local.t('operations_load')),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Error banner when refresh fails but we have data
                    if (provider.errorMessage != null)
                      ErrorBanner(
                        message: provider.errorMessage!,
                        onRetry: () {
                          provider.loadOperations();
                          provider.loadTodayStats();
                        },
                        onDismiss: () => provider.clearError(),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await provider.loadOperations();
                          await provider.loadTodayStats();
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.operations.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final operation = provider.operations[index];
                            return OperationCard(operation: operation);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateOperationScreen(),
            ),
          ).then((_) {
            if (!context.mounted) return;
            context.read<OperationProvider>().loadOperations();
            context.read<OperationProvider>().loadTodayStats();
          });
        },
        icon: const Icon(Icons.add),
        label: Text(local.t('operations_create')),
      ),
    );
  }

  Widget _buildTodayStats() {
    return Consumer<OperationProvider>(
      builder: (context, provider, child) {
        final stats = provider.todayStats;
        if (stats == null) return const SizedBox.shrink();

        final buyCount = stats['buy_count'] ?? 0;
        final sellCount = stats['sell_count'] ?? 0;
        final buyAmount = (stats['buy_amount'] as num?)?.toDouble() ?? 0.0;
        final sellAmount = (stats['sell_amount'] as num?)?.toDouble() ?? 0.0;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.today, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    context.watch<LocalizationProvider>().t('operations_today'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: Icons.trending_up,
                      color: AppColors.buyColor,
                      label: context.watch<LocalizationProvider>().t('operations_buys'),
                      value: '$buyCount',
                      amount: CurrencyFormatter.format(
                        buyAmount,
                        symbol: 'сом',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.trending_down,
                      color: AppColors.sellColor,
                      label: context.watch<LocalizationProvider>().t('operations_sells'),
                      value: '$sellCount',
                      amount: CurrencyFormatter.format(
                        sellAmount,
                        symbol: 'сом',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String amount;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
