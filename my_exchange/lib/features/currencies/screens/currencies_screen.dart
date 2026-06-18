import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../presentation/providers/currency_provider.dart';
import '../../../presentation/widgets/error_widgets.dart';
import '../../../presentation/widgets/skeleton_widgets.dart';

class CurrenciesScreen extends StatefulWidget {
  const CurrenciesScreen({super.key});

  @override
  State<CurrenciesScreen> createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends State<CurrenciesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrencyProvider>().loadCurrencies();
    });
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const SkeletonCurrencyCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<LocalizationProvider>().t('currencies_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CurrencyProvider>().loadCurrencies(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<CurrencyProvider>().loadCurrencies(),
        child: Consumer<CurrencyProvider>(
          builder: (context, provider, child) {
            final local = context.watch<LocalizationProvider>();
            if (provider.isLoading && provider.currencies.isEmpty) {
              return _buildSkeletonList();
            }

            // Error state with retry (no data)
            if (provider.errorMessage != null && provider.currencies.isEmpty) {
              return ErrorStateWidget(
                message: provider.errorMessage!,
                details: '${local.t('currencies_title')} — ${provider.errorMessage!}',
                onRetry: () => provider.loadCurrencies(),
              );
            }

            // Empty state
            if (provider.currencies.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.currency_exchange,
                      size: 80,
                      color: colors.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      local.t('cash_no_data'),
                      style: TextStyle(
                        fontSize: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.loadCurrencies(),
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
                    onRetry: () => provider.loadCurrencies(),
                    onDismiss: () => provider.clearError(),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.currencies.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final currency = provider.currencies[index];
                      return _CurrencyCard(currency: currency);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  final dynamic currency;

  const _CurrencyCard({required this.currency});

  @override
  Widget build(BuildContext context) {
      final colors = Theme.of(context).colorScheme;
    final local = context.watch<LocalizationProvider>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colors.primary, colors.primary.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  currency.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (currency.buyRate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.tertiary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 14,
                                color: colors.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${local.t('currencies_buy')}: ${CurrencyFormatter.formatRate(currency.buyRate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.tertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (currency.sellRate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_down,
                                size: 14,
                                color: colors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${local.t('currencies_sell')}: ${CurrencyFormatter.formatRate(currency.sellRate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: currency.isActive
                    ? colors.tertiary.withValues(alpha: 0.1)
                    : colors.outline.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                currency.isActive ? Icons.check_circle : Icons.cancel,
                color: currency.isActive
                    ? colors.tertiary
                    : colors.outline,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
