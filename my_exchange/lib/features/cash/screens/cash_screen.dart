import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../presentation/providers/cash_provider.dart';
import '../../../presentation/widgets/error_widgets.dart';
import '../../../presentation/widgets/skeleton_widgets.dart';
import '../../../presentation/widgets/empty_state_illustration.dart';
import 'open_register_dialog.dart';
import 'close_register_dialog.dart';
import 'transaction_dialog.dart';

class CashScreen extends StatefulWidget {
  const CashScreen({super.key});

  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CashProvider>();
      provider.loadBalances();
      provider.checkCurrentRegister();
      provider.loadAverageRates();
    });
  }

  Widget _buildSkeletonBalanceList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const SkeletonBalanceCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = context.watch<LocalizationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(local.t('cash_title')),
        actions: [
          Consumer<CashProvider>(
            builder: (context, provider, child) {
              if (provider.isRegisterOpen) {
                final loc = context.read<LocalizationProvider>();
                return IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _showCloseRegisterDialog(),
                  tooltip: loc.t('cash_register_close'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = context.read<CashProvider>();
              provider.loadBalances();
              provider.checkCurrentRegister();
              provider.loadAverageRates();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final cashProvider = context.read<CashProvider>();
          await cashProvider.loadBalances();
          await cashProvider.checkCurrentRegister();
          await cashProvider.loadAverageRates();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              _buildRegisterCard(),
              const SizedBox(height: 16),

              
              Consumer<CashProvider>(
                builder: (context, provider, child) {
                  if (provider.errorMessage != null &&
                      provider.balances.isNotEmpty) {
                    return ErrorBanner(
                      message: provider.errorMessage!,
                      onRetry: () {
                        provider.loadBalances();
                        provider.checkCurrentRegister();
                      },
                      onDismiss: () => provider.clearError(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              
              Text(
                local.t('cash_balances'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Consumer2<CashProvider, LocalizationProvider>(
                builder: (context, provider, loc, child) {
                  if (provider.isLoading && provider.balances.isEmpty) {
                    return _buildSkeletonBalanceList();
                  }

                  
                  if (provider.errorMessage != null &&
                      provider.balances.isEmpty) {
                    return ErrorStateWidget(
                      message: provider.errorMessage!,
                      details: '${loc.t('cash_title')} — ${provider.errorMessage!}',
                      onRetry: () {
                        provider.loadBalances();
                        provider.checkCurrentRegister();
                      },
                    );
                  }

                  if (provider.balances.isEmpty) {
                    return EmptyStateIllustration(
                      type: EmptyStateType.cash,
                      title: loc.t('cash_no_balances'),
                      subtitle: loc.t('cash_no_balances_desc'),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.balances.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final balance = provider.balances[index];
                      return _BalanceCard(balance: balance);
                    },
                  );
                },
              ),
              const SizedBox(height: 300),
            ],
          ),
        ),
      ),
      floatingActionButton: Consumer2<CashProvider, LocalizationProvider>(
        builder: (context, provider, loc, child) {
          if (!provider.isRegisterOpen) {
            return FloatingActionButton.extended(
              heroTag: 'cash_open_shift',
              onPressed: () => _showOpenRegisterDialog(),
              icon: const Icon(Icons.play_arrow),
              label: Text(loc.t('cash_open_shift')),
            );
          }
          return FloatingActionButton.extended(
            heroTag: 'cash_transaction',
            onPressed: () => _showTransactionDialog(),
            icon: const Icon(Icons.add),
            label: Text(loc.t('cash_transaction')),
          );
        },
      ),
    );
  }

  Widget _buildRegisterCard() {
    final colors = Theme.of(context).colorScheme;
    return Consumer2<CashProvider, LocalizationProvider>(
      builder: (context, provider, loc, child) {
        final register = provider.currentRegister;
        final isOpen = register?.isOpen ?? false;

        
        if (provider.isRegisterLoading && register == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.outline.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 18,
                          decoration: BoxDecoration(
                            color: colors.outline.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 200,
                          height: 14,
                          decoration: BoxDecoration(
                            color: colors.outline.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (register == null || !isOpen) {
          return Card(
            color: Colors.orange.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.t('cash_register_closed'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.t('cash_register_open_desc'),
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          color: colors.primary.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: colors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.t('cash_register_open'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${loc.t('cash_cashier')}: ${register.cashierName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.circle,
                      color: colors.primary,
                      size: 12,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${loc.t('cash_opened_at')}:',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    Text(
                      DateFormatter.formatDateTime(register.openedAt),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                
                if (register.openingBalance != null &&
                    register.openingBalance!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    loc.t('cash_opening_balance'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...register.openingBalance!.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(entry.value),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOpenRegisterDialog() {
    showDialog(
      context: context,
      builder: (context) => const OpenRegisterDialog(),
    );
  }

  void _showCloseRegisterDialog() {
    showDialog(
      context: context,
      builder: (context) => const CloseRegisterDialog(),
    );
  }

  void _showTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => const TransactionDialog(),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final dynamic balance;
  final double? averageRate;

  const _BalanceCard({required this.balance}) : averageRate = null;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final local = context.read<LocalizationProvider>();
    final availableRatio = balance.balance > 0
        ? balance.availableBalance / balance.balance
        : 0.0;
    final reservedRatio = balance.balance > 0
        ? balance.reserved / balance.balance
        : 0.0;
    final utilizationPercent = (availableRatio * 100).clamp(0, 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      balance.currencyCode,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colors.primary,
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
                        balance.currencyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${local.t('cash_available')}: ${CurrencyFormatter.format(balance.availableBalance, symbol: balance.currencySymbol)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(
                        balance.balance,
                        symbol: balance.currencySymbol,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (balance.reserved > 0)
                      Text(
                        '${local.t('cash_reserved')}: ${CurrencyFormatter.format(balance.reserved, symbol: balance.currencySymbol)}',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  
                  if (averageRate != null && balance.currencyCode != 'KGS')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up_rounded, size: 14, color: colors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${local.t('cash_avg_rate')}: ${CurrencyFormatter.formatRate(averageRate!)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  _BalanceVariantRow(
                    label: 'Фактический остаток',
                    amount: CurrencyFormatter.format(balance.balance, symbol: balance.currencySymbol),
                    color: colors.primary,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                  const SizedBox(height: 4),
                  _BalanceVariantRow(
                    label: 'Без транзакций',
                    amount: CurrencyFormatter.format(balance.balanceFromOperations, symbol: balance.currencySymbol),
                    color: AppColors.success,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                  if (balance.balance != balance.balanceFromOperations) ...[
                    const SizedBox(height: 4),
                    Divider(height: 1, color: colors.outline.withValues(alpha: 0.2)),
                    const SizedBox(height: 4),
                    _BalanceVariantRow(
                      label: 'Транзакции (внес/выд)',
                      amount: CurrencyFormatter.format(
                        balance.balance - balance.balanceFromOperations,
                        symbol: balance.currencySymbol,
                      ),
                      color: (balance.balance - balance.balanceFromOperations) >= 0
                          ? AppColors.info
                          : AppColors.warning,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    
                    Container(
                      decoration: BoxDecoration(
                        color: colors.outline.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    
                    if (reservedRatio > 0)
                      FractionallySizedBox(
                        widthFactor: (reservedRatio + availableRatio).clamp(0, 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    
                    if (availableRatio > 0)
                      FractionallySizedBox(
                        widthFactor: availableRatio.clamp(0, 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _progressColor(utilizationPercent),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            
            Text(
              '${utilizationPercent.toStringAsFixed(0)}% ${local.t('cash_available').toLowerCase()}',
              style: TextStyle(
                fontSize: 10,
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _progressColor(double percent) {
    if (percent > 80) return Colors.green;
    if (percent > 50) return Colors.lightGreen;
    if (percent > 20) return Colors.amber;
    return Colors.orange;
  }
}

class _BalanceVariantRow extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool isDark;

  const _BalanceVariantRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54,
              ),
            ),
          ],
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
