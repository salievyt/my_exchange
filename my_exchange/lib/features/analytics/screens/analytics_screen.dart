import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../presentation/providers/analytics_provider.dart';
import '../../../presentation/widgets/error_widgets.dart';
import '../../../presentation/widgets/staggered_fade_in.dart';
import '../../reports/screens/reports_screen.dart';
import '../widgets/analytics_charts.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _chartPeriodDays = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadAll();
    });
  }

  void _setPeriod(int days) {
    setState(() => _chartPeriodDays = days);
    context.read<AnalyticsProvider>().loadOperationsAnalytics(periodDays: days);
    context.read<AnalyticsProvider>().loadCashierLoad(periodDays: days);
    if (days >= 30) {
      context.read<AnalyticsProvider>().loadProfitability(periodDays: days);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final local = context.watch<LocalizationProvider>();
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
      appBar: AppBar(
        title: Text(local.t('analytics_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: local.t('analytics_reports'),
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AnalyticsProvider>().loadAll(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AnalyticsProvider>().loadAll(),
        child: Consumer<AnalyticsProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.data == null) {
              return _buildSkeletonLoading(isDark);
            }
            if (provider.errorMessage != null && provider.data == null) {
              return ErrorStateWidget(
                message: provider.errorMessage!,
                details: '${local.t('analytics_title')} — ${provider.errorMessage!}',
                onRetry: () => provider.loadAll(),
              );
            }
            if (provider.data == null) return _buildEmptyState(isDark, local);

            final data = provider.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (provider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ErrorBanner(
                        message: provider.errorMessage!,
                        onRetry: () => provider.loadAll(),
                        onDismiss: () => provider.clearError(),
                      ),
                    ),

                  
                  if (isWide) _buildWideSummary(data, isDark)
                  else _buildNarrowSummary(data, isDark),

                  const SizedBox(height: 16),

                  
                  _buildPeriodSelector(isDark),
                  const SizedBox(height: 12),

                  
                  if (provider.dailyData.isNotEmpty)
                    _buildCard(
                      title: local.t('analytics_daily_chart'),
                      icon: Icons.bar_chart_rounded,
                      color: AppColors.primary, isDark: isDark, index: 0,
                      children: [
                        ChartLegend(items: [
                          LegendItem(color: AppColors.buyColor, label: local.t('operations_buy')),
                          LegendItem(color: AppColors.sellColor, label: local.t('operations_sell')),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: isWide ? 260 : 220,
                          child: OperationsBarChart(dailyData: provider.dailyData),
                        ),
                      ],
                    ),

                  if (provider.dailyData.isNotEmpty) const SizedBox(height: 14),

                  
                  if (provider.shiftStats.isNotEmpty && provider.shiftOpen)
                    _buildCard(
                      title: 'Операции по валютам (смена)',
                      icon: Icons.currency_exchange_rounded,
                      color: AppColors.secondary, isDark: isDark, index: provider.dailyData.isNotEmpty ? 2 : 1,
                      children: provider.shiftStats.map((stat) => _ShiftCurrencyRow(stat: stat, isDark: isDark)).toList(),
                    ),
                  if (provider.shiftStats.isNotEmpty && provider.shiftOpen) const SizedBox(height: 14),

                  
                  if (provider.cashValuation.isNotEmpty && provider.shiftOpen)
                    _buildCashValuationCard(provider, isDark),
                  if (provider.cashValuation.isNotEmpty && provider.shiftOpen) const SizedBox(height: 14),

                  
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (provider.currencyStats.isNotEmpty)
                          Expanded(child: _buildCard(
                            title: local.t('analytics_popular_currencies'),
                            icon: Icons.trending_up_rounded, color: AppColors.secondary,
                            isDark: isDark, index: 1,
                            children: [SizedBox(height: 200, child: CurrencyBarChart(currencyStats: provider.currencyStats))],
                          )),
                        if (provider.currencyStats.isNotEmpty) const SizedBox(width: 14),
                        if (provider.profitability.isNotEmpty)
                          Expanded(child: _buildCard(
                            title: local.t('analytics_profitability'),
                            icon: Icons.monetization_on_rounded, color: AppColors.warning,
                            isDark: isDark, index: 2,
                            children: [SizedBox(height: 200, child: ProfitabilityChart(profitability: provider.profitability))],
                          )),
                      ],
                    )
                  else ...[
                    if (provider.currencyStats.isNotEmpty)
                      _buildCard(title: local.t('analytics_popular_currencies'), icon: Icons.trending_up_rounded,
                        color: AppColors.secondary, isDark: isDark, index: 1,
                        children: [SizedBox(height: 200, child: CurrencyBarChart(currencyStats: provider.currencyStats))]),
                    if (provider.currencyStats.isNotEmpty) const SizedBox(height: 14),
                    if (provider.profitability.isNotEmpty)
                      _buildCard(title: local.t('analytics_profitability'), icon: Icons.monetization_on_rounded,
                        color: AppColors.warning, isDark: isDark, index: 2,
                        children: [SizedBox(height: 200, child: ProfitabilityChart(profitability: provider.profitability))]),
                  ],

                  if (provider.currencyStats.isNotEmpty || provider.profitability.isNotEmpty)
                    const SizedBox(height: 14),

                  
                  if (data.exchangeRates.isNotEmpty)
                    _buildCard(title: local.t('analytics_rates'), icon: Icons.currency_exchange,
                      color: AppColors.primary, isDark: isDark, index: 3,
                      children: data.exchangeRates.take(5).map((rate) {
                        final code = rate['currency'] as String? ?? '';
                        final buy = (rate['buy'] as num?)?.toDouble();
                        final sell = (rate['sell'] as num?)?.toDouble();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              _CurrencyCodeChip(code: code, color: _currencyColor(code)),
                              const SizedBox(width: 12),
                              Expanded(child: Text(rate['currency_name'] as String? ?? '',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87),
                                maxLines: 1, overflow: TextOverflow.ellipsis)),
                              _RateTag(label: 'П', value: buy != null ? CurrencyFormatter.formatRate(buy) : '—',
                                color: AppColors.buyColor, isDark: isDark),
                              const SizedBox(width: 8),
                              _RateTag(label: 'ПР', value: sell != null ? CurrencyFormatter.formatRate(sell) : '—',
                                color: AppColors.sellColor, isDark: isDark),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  if (data.exchangeRates.isNotEmpty) const SizedBox(height: 14),

                  
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (provider.cashierStats.isNotEmpty)
                          Expanded(child: _buildCard(title: local.t('analytics_cashiers'),
                            icon: Icons.people_rounded, color: AppColors.info, isDark: isDark, index: 4,
                            children: provider.cashierStats.map((s) => _CashierRow(stat: s, isDark: isDark)).toList())),
                        if (provider.cashierStats.isNotEmpty) const SizedBox(width: 14),
                        if (data.cashBalances.isNotEmpty)
                          Expanded(child: _buildCard(title: local.t('analytics_cash_balances'),
                            icon: Icons.account_balance_rounded, color: AppColors.success, isDark: isDark, index: 5,
                            children: data.cashBalances.map((b) => _CashBalanceRow(balance: b, isDark: isDark)).toList())),
                      ],
                    )
                  else ...[
                    if (provider.cashierStats.isNotEmpty)
                      _buildCard(title: local.t('analytics_cashiers'), icon: Icons.people_rounded,
                        color: AppColors.info, isDark: isDark, index: 4,
                        children: provider.cashierStats.map((s) => _CashierRow(stat: s, isDark: isDark)).toList()),
                    if (provider.cashierStats.isNotEmpty) const SizedBox(height: 14),
                    if (data.cashBalances.isNotEmpty)
                      _buildCard(title: local.t('analytics_cash_balances'), icon: Icons.account_balance_rounded,
                        color: AppColors.success, isDark: isDark, index: 5,
                        children: data.cashBalances.map((b) => _CashBalanceRow(balance: b, isDark: isDark)).toList()),
                  ],

                  if (data.operationsToday == 0 && data.exchangeRates.isEmpty &&
                      data.cashBalances.isEmpty && provider.currencyStats.isEmpty &&
                      provider.cashierStats.isEmpty)
                    _buildNoDataCard(isDark, local),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  

  Widget _buildNarrowSummary(AnalyticsData data, bool isDark) => Column(children: [
    Row(children: [
      Expanded(child: _SummaryTile(label: 'Операций', value: '${data.operationsToday}',
        icon: Icons.swap_horiz_rounded, color: AppColors.primary, isDark: isDark)),
      const SizedBox(width: 12),
      Expanded(child: _SummaryTile(label: 'Оборот', value: CurrencyFormatter.format(data.turnoverToday),
        icon: Icons.trending_up_rounded, color: AppColors.success, isDark: isDark)),
    ]),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _SummaryTile(label: 'Покупок/Продаж', value: '${data.buyOperations} / ${data.sellOperations}',
        icon: Icons.compare_arrows_rounded, color: AppColors.secondary, isDark: isDark)),
      const SizedBox(width: 12),
      Expanded(child: _SummaryTile(label: 'Клиентов', value: '${data.clientsToday}',
        icon: Icons.people_rounded, color: AppColors.info, isDark: isDark)),
    ]),
  ]);

  Widget _buildWideSummary(AnalyticsData data, bool isDark) => Row(children: [
    Expanded(child: _SummaryTile(label: 'Операций сегодня', value: '${data.operationsToday}',
      icon: Icons.swap_horiz_rounded, color: AppColors.primary, isDark: isDark)),
    const SizedBox(width: 12),
    Expanded(child: _SummaryTile(label: 'Оборот сегодня', value: CurrencyFormatter.format(data.turnoverToday),
      icon: Icons.trending_up_rounded, color: AppColors.success, isDark: isDark)),
    const SizedBox(width: 12),
    Expanded(child: _SummaryTile(label: 'Покупок / Продаж', value: '${data.buyOperations} / ${data.sellOperations}',
      icon: Icons.compare_arrows_rounded, color: AppColors.secondary, isDark: isDark)),
    const SizedBox(width: 12),
    Expanded(child: _SummaryTile(label: 'Клиентов', value: '${data.clientsToday}',
      icon: Icons.people_rounded, color: AppColors.info, isDark: isDark)),
  ]);

  

  Widget _buildPeriodSelector(bool isDark) {
    const periods = [(7, '7 дней'), (14, '14 дней'), (30, '30 дней')];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: periods.map((p) {
          final isSelected = _chartPeriodDays == p.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => _setPeriod(p.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.primary.withValues(alpha: 0.3) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Center(
                  child: Text(p.$2, style: TextStyle(
                    fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary
                        : (isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.textSecondary),
                  )),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  

  Widget _buildCard({
    required String title, required IconData icon, required Color color,
    required bool isDark, required int index, required List<Widget> children,
  }) {
    return StaggeredFadeIn(index: index, itemDuration: const Duration(milliseconds: 400),
      child: _ModernCard(isDark: isDark, color: color, title: title, icon: icon, children: children),
    );
  }

  

  Widget _buildSkeletonLoading(bool isDark) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: List.generate(4, (i) => Padding(
      padding: EdgeInsets.only(bottom: i < 3 ? 14 : 0),
      child: Container(height: 160,
        decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16)),
      ),
    ))),
  );

  Widget _buildEmptyState(bool isDark, LocalizationProvider local) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.analytics_outlined, size: 72,
        color: isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.textHint),
      const SizedBox(height: 16),
      Text(local.t('cash_no_data'),
        style: TextStyle(fontSize: 18, color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.textSecondary)),
      const SizedBox(height: 24),
      ElevatedButton.icon(onPressed: () => context.read<AnalyticsProvider>().loadAll(),
        icon: const Icon(Icons.refresh), label: Text(local.t('operations_load'))),
    ]),
  );

  Widget _buildCashValuationCard(AnalyticsProvider provider, bool isDark) {
    final breakdown = provider.cashValuation;
    final totalKgs = provider.totalCashKgs;

    final rows = breakdown.map((b) => _CashValuationRow(
      data: b,
      isDark: isDark,
    )).toList();

    return _buildCard(
      title: 'Стоимость кассы (средний курс)',
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.success,
      isDark: isDark,
      index: provider.dailyData.isNotEmpty || (provider.shiftStats.isNotEmpty && provider.shiftOpen) ? 4 : 2,
      children: [
        ...rows,
        if (breakdown.length > 1) ...[        
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Итого',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '${CurrencyFormatter.format(totalKgs)} сом',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNoDataCard(bool isDark, LocalizationProvider local) => StaggeredFadeIn(index: 6,
    itemDuration: const Duration(milliseconds: 400),
    child: Container(
      margin: const EdgeInsets.only(top: 14), padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.info.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Icon(Icons.info_outline_rounded, size: 44,
          color: isDark ? Colors.white.withValues(alpha: 0.3) : AppColors.info),
        const SizedBox(height: 12),
        Text(local.t('analytics_no_data'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 6),
        Text(local.t('analytics_no_data_desc'), textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13,
            color: isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.textSecondary)),
      ]),
    ),
  );
}





Color _currencyColor(String code) {
  switch (code) {
    case 'USD': return AppColors.buyColor;
    case 'EUR': return const Color(0xFF2196F3);
    case 'RUB': return AppColors.sellColor;
    case 'GBP': return const Color(0xFF9C27B0);
    case 'CNY': return const Color(0xFFFF5722);
    case 'KZT': return const Color(0xFFFFC107);
    default: return AppColors.primary;
  }
}





class _ModernCard extends StatelessWidget {
  final bool isDark; final Color color; final String title;
  final IconData icon; final List<Widget> children;

  const _ModernCard({
    required this.isDark, required this.color, required this.title,
    required this.icon, required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 12, offset: const Offset(0, 3))],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(height: 3, decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.3)]),
      )),
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: Row(children: [
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87)),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
    ]),
  );
}

class _SummaryTile extends StatelessWidget {
  final String label; final String value; final IconData icon;
  final Color color; final bool isDark;

  const _SummaryTile({
    required this.label, required this.value, required this.icon,
    required this.color, required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : Colors.black87, height: 1.1),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11,
          color: isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.textSecondary,
          fontWeight: FontWeight.w500)),
      ])),
    ]),
  );
}

class _RateTag extends StatelessWidget {
  final String label; final String value; final Color color; final bool isDark;

  const _RateTag({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
    child: Text('$label $value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}

class _CurrencyCodeChip extends StatelessWidget {
  final String code; final Color color;
  const _CurrencyCodeChip({required this.code, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 36, height: 36,
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
    child: Center(child: Text(code, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color))),
  );
}

class _CashierRow extends StatelessWidget {
  final Map<String, dynamic> stat; final bool isDark;
  const _CashierRow({required this.stat, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = stat['name'] as String? ?? '—';
    final opsCount = stat['operations'] as int? ?? 0;
    final turnover = (stat['turnover'] as num?)?.toDouble() ?? 0.0;

    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      CircleAvatar(radius: 18, backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '—',
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 2),
        Text('$opsCount оп. • ${CurrencyFormatter.format(turnover, symbol: 'сом')}',
          style: TextStyle(fontSize: 11, color: isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.textSecondary)),
      ])),
    ]));
  }
}

class _ShiftCurrencyRow extends StatelessWidget {
  final Map<String, dynamic> stat;
  final bool isDark;

  const _ShiftCurrencyRow({required this.stat, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final code = stat['currency'] as String? ?? '';
    final buyAmount = (stat['buy_amount'] as num?)?.toDouble() ?? 0.0;
    final sellAmount = (stat['sell_amount'] as num?)?.toDouble() ?? 0.0;
    final avgBuyRate = (stat['avg_buy_rate'] as num?)?.toDouble() ?? 0.0;
    final avgSellRate = (stat['avg_sell_rate'] as num?)?.toDouble() ?? 0.0;
    final buyTotalKgs = (stat['buy_total_kgs'] as num?)?.toDouble() ?? 0.0;
    final sellTotalKgs = (stat['sell_total_kgs'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CurrencyCodeChip(code: code, color: _currencyColor(code)),
              const SizedBox(width: 12),
              Text(code,
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _StatLine(
                  label: 'Покупка',
                  amount: '${CurrencyFormatter.format(buyAmount)} $code',
                  rate: avgBuyRate > 0 ? 'ср. ${CurrencyFormatter.formatRate(avgBuyRate)}' : '',
                  total: buyTotalKgs > 0 ? '${CurrencyFormatter.format(buyTotalKgs)} сом' : '',
                  color: AppColors.buyColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                const SizedBox(height: 6),
                _StatLine(
                  label: 'Продажа',
                  amount: '${CurrencyFormatter.format(sellAmount)} $code',
                  rate: avgSellRate > 0 ? 'ср. ${CurrencyFormatter.formatRate(avgSellRate)}' : '',
                  total: sellTotalKgs > 0 ? '${CurrencyFormatter.format(sellTotalKgs)} сом' : '',
                  color: AppColors.sellColor,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String amount;
  final String rate;
  final String total;
  final Color color;
  final bool isDark;

  const _StatLine({
    required this.label,
    required this.amount,
    required this.rate,
    required this.total,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(label,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(amount,
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        if (rate.isNotEmpty)
          Expanded(
            flex: 2,
            child: Text(rate,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (total.isNotEmpty)
          Expanded(
            flex: 2,
            child: Text(total,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
      ],
    );
  }
}

class _CashBalanceRow extends StatelessWidget {
  final Map<String, dynamic> balance; final bool isDark;
  const _CashBalanceRow({required this.balance, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final code = balance['currency'] as String? ?? '';
    final total = (balance['balance'] as num?)?.toDouble() ?? 0.0;
    final available = (balance['available'] as num?)?.toDouble() ?? 0.0;

    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      _CurrencyCodeChip(code: code, color: _currencyColor(code)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$code • ${CurrencyFormatter.format(total)}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 2),
        Text('Доступно: ${CurrencyFormatter.format(available)}',
          style: TextStyle(fontSize: 11,
            color: available > 0
                ? (isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.textSecondary)
                : AppColors.warning,
            fontWeight: FontWeight.w500)),
      ])),
    ]));
  }
}

class _CashValuationRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _CashValuationRow({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final code = data['currency'] as String? ?? '';
    final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
    final avgRate = (data['average_rate'] as num?)?.toDouble() ?? 0.0;
    final kgsEq = (data['kgs_equivalent'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _CurrencyCodeChip(code: code, color: _currencyColor(code)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$code \u2022 ${CurrencyFormatter.format(balance)}',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                if (avgRate > 0 && code != 'KGS')
                  Text(
                    '\u0441\u0440. ${CurrencyFormatter.formatRate(avgRate)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${CurrencyFormatter.format(kgsEq)} \u0441\u043e\u043c',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
