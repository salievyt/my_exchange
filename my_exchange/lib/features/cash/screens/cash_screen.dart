import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../presentation/providers/cash_provider.dart';
import '../../../presentation/widgets/error_widgets.dart';
import '../../../presentation/widgets/skeleton_widgets.dart';
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
      context.read<CashProvider>().loadBalances();
      context.read<CashProvider>().checkCurrentRegister();
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
    final colors = Theme.of(context).colorScheme;
    final local = context.watch<LocalizationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(local.t('cash_title')),
        actions: [
          Consumer<CashProvider>(
            builder: (context, provider, child) {
              final loc = context.watch<LocalizationProvider>();
              if (provider.isRegisterOpen) {
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
              context.read<CashProvider>().loadBalances();
              context.read<CashProvider>().checkCurrentRegister();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final cashProvider = context.read<CashProvider>();
          await cashProvider.loadBalances();
          await cashProvider.checkCurrentRegister();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Register status card
              _buildRegisterCard(),
              const SizedBox(height: 16),

              // Error banner (if error and we have data)
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

              // Balances
              Text(
                local.t('cash_balances'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Consumer<CashProvider>(
                builder: (context, provider, child) {
                  final loc = context.watch<LocalizationProvider>();
                  if (provider.isLoading && provider.balances.isEmpty) {
                    return _buildSkeletonBalanceList();
                  }

                  // Error state with retry (no data)
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
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            loc.t('cash_no_data'),
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ),
                      ),
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
      floatingActionButton: Consumer<CashProvider>(
        builder: (context, provider, child) {
          final loc = context.watch<LocalizationProvider>();
          if (!provider.isRegisterOpen) {
            return FloatingActionButton.extended(
              onPressed: () => _showOpenRegisterDialog(),
              icon: const Icon(Icons.play_arrow),
              label: Text(loc.t('cash_open_shift')),
            );
          }
          return FloatingActionButton.extended(
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
    return Consumer<CashProvider>(
      builder: (context, provider, child) {
        final loc = context.watch<LocalizationProvider>();
        final register = provider.currentRegister;

        // Show loading shimmer while checking register status
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

        if (register == null) {
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

  const _BalanceCard({required this.balance});

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
      ),
    );
  }
}
