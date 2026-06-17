import 'package:flutter/material.dart';
import 'package:my_exchange/presentation/providers/currency_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../presentation/widgets/error_widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Валюты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CurrencyProvider>().loadCurrencies(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<CurrencyProvider>().loadCurrencies(),          child: Consumer<CurrencyProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.currencies.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error state with retry (no data)
            if (provider.errorMessage != null && provider.currencies.isEmpty) {
              return ErrorStateWidget(
                message: provider.errorMessage!,
                details: 'Не удалось загрузить список валют',
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
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Нет данных',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.loadCurrencies(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Загрузить'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
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
                            color: AppColors.buyColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.trending_up,
                                size: 14,
                                color: AppColors.buyColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Покупка: ${CurrencyFormatter.formatRate(currency.buyRate!)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.buyColor,
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
                            color: AppColors.sellColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.trending_down,
                                size: 14,
                                color: AppColors.sellColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Продажа: ${CurrencyFormatter.formatRate(currency.sellRate!)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.sellColor,
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
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.textHint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                currency.isActive ? Icons.check_circle : Icons.cancel,
                color: currency.isActive
                    ? AppColors.success
                    : AppColors.textHint,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
