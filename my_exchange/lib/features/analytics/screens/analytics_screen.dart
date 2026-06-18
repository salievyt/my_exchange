import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../presentation/providers/analytics_provider.dart';
import '../../../presentation/widgets/error_widgets.dart';
import '../widgets/analytics_charts.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = context.watch<LocalizationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(local.t('analytics_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AnalyticsProvider>().loadAll(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AnalyticsProvider>().loadAll(),
        child: Consumer<AnalyticsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error state with retry (no data)
            if (provider.errorMessage != null && provider.data == null) {
              return ErrorStateWidget(
                message: provider.errorMessage!,
                details: '${local.t('analytics_title')} — ${provider.errorMessage!}',
                onRetry: () => provider.loadAll(),
              );
            }

            // No data yet
            if (provider.data == null) {
              return Center(
                child: Text(
                  local.t('cash_no_data'),
                  style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                ),
              );
            }

            final data = provider.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Error banner when refresh fails but we have data
                  if (provider.errorMessage != null)
                    ErrorBanner(
                      message: provider.errorMessage!,
                      onRetry: () => provider.loadAll(),
                      onDismiss: () => provider.clearError(),
                    ),

                  // Today stats card
                  _DashboardCard(
                    title: local.t('analytics_overall'),
                    icon: Icons.dashboard,
                    children: [
                      _StatRow(
                        label: local.t('analytics_operations_today'),
                        value: '${data.operationsToday}',
                      ),
                      const Divider(),
                      _StatRow(
                        label: local.t('analytics_buys_sells'),
                        value:
                            '${data.buyOperations} / ${data.sellOperations}',
                      ),
                      const Divider(),
                      _StatRow(
                        label: local.t('analytics_turnover'),
                        value: CurrencyFormatter.format(data.turnoverToday),
                      ),
                      const Divider(),
                      _StatRow(
                        label: local.t('analytics_clients'),
                        value: '${data.clientsToday}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Exchange rates card
                  if (data.exchangeRates.isNotEmpty)
                    _DashboardCard(
                      title: local.t('analytics_rates'),
                      icon: Icons.currency_exchange,
                      children: data.exchangeRates.take(5).map((rate) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    rate['currency'] as String? ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rate['currency_name'] as String? ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'П: ${rate['buy'] != null ? CurrencyFormatter.formatRate((rate['buy'] as num).toDouble()) : '—'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.buyColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ПР: ${rate['sell'] != null ? CurrencyFormatter.formatRate((rate['sell'] as num).toDouble()) : '—'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.sellColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),

                  // Daily operations chart
                  if (provider.dailyData.isNotEmpty)
                    _DashboardCard(
                      title: local.t('analytics_daily_chart'),
                      icon: Icons.bar_chart,
                      children: [
                        ChartLegend(items: [
                          LegendItem(color: AppColors.buyColor, label: local.t('operations_buy')),
                          LegendItem(color: AppColors.sellColor, label: local.t('operations_sell')),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: OperationsBarChart(
                            dailyData: provider.dailyData,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Currency popularity chart
                  if (provider.currencyStats.isNotEmpty)
                    _DashboardCard(
                      title: local.t('analytics_popular_currencies'),
                      icon: Icons.trending_up,
                      children: [
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 200,
                          child: CurrencyBarChart(
                            currencyStats: provider.currencyStats,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Profitability chart
                  if (provider.profitability.isNotEmpty)
                    _DashboardCard(
                      title: local.t('analytics_profitability'),
                      icon: Icons.trending_up,
                      children: [
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 200,
                          child: ProfitabilityChart(
                            profitability: provider.profitability,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Cashier stats card
                  if (provider.cashierStats.isNotEmpty)
                    _DashboardCard(
                      title: local.t('analytics_cashiers'),
                      icon: Icons.people,
                      children: provider.cashierStats.map((stat) {
                        final name = stat['name'] as String? ?? '—';
                        final opsCount = stat['operations'] as int? ?? 0;
                        final turnover =
                            (stat['turnover'] as num?)?.toDouble() ?? 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '—',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$opsCount оп.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(
                                      turnover,
                                      symbol: 'сом',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),

                  // Cash balances card
                  if (data.cashBalances.isNotEmpty)
                    _DashboardCard(
                      title: local.t('analytics_cash_balances'),
                      icon: Icons.account_balance,
                      children: data.cashBalances.map((bal) {
                        final code = bal['currency'] as String? ?? '';
                        final balance =
                            (bal['balance'] as num?)?.toDouble() ?? 0.0;
                        final available =
                            (bal['available'] as num?)?.toDouble() ?? 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Всего: ${CurrencyFormatter.format(balance)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                'Доступно: ${CurrencyFormatter.format(available)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: available > 0
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),

                  // Empty state when no overall data
                  if (data.operationsToday == 0 &&
                      data.exchangeRates.isEmpty &&
                      data.cashBalances.isEmpty &&
                      provider.currencyStats.isEmpty &&
                      provider.cashierStats.isEmpty)
                    Card(
                      color: AppColors.info.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: AppColors.info,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              local.t('analytics_no_data'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              local.t('analytics_no_data_desc'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
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
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
