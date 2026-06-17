import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../presentation/providers/cash_provider.dart';
import '../../../presentation/widgets/error_widgets.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Касса'),
        actions: [
          Consumer<CashProvider>(
            builder: (context, provider, child) {
              if (provider.isRegisterOpen) {
                return IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _showCloseRegisterDialog(),
                  tooltip: 'Закрыть смену',
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
              const Text(
                'Остатки',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Consumer<CashProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.balances.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Error state with retry (no data)
                  if (provider.errorMessage != null &&
                      provider.balances.isEmpty) {
                    return ErrorStateWidget(
                      message: provider.errorMessage!,
                      details: 'Не удалось загрузить остатки',
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
                            'Нет данных',
                            style: TextStyle(color: AppColors.textSecondary),
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
            ],
          ),
        ),
      ),
      floatingActionButton: Consumer<CashProvider>(
        builder: (context, provider, child) {
          if (!provider.isRegisterOpen) {
            return FloatingActionButton.extended(
              onPressed: () => _showOpenRegisterDialog(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Открыть смену'),
            );
          }
          return FloatingActionButton.extended(
            onPressed: () => _showTransactionDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Транзакция'),
          );
        },
      ),
    );
  }

  Widget _buildRegisterCard() {
    return Consumer<CashProvider>(
      builder: (context, provider, child) {
        final register = provider.currentRegister;
        if (register == null) {
          return Card(
            color: AppColors.warning.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Смена не открыта',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Откройте смену для начала работы',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
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
          color: AppColors.success.withValues(alpha: 0.1),
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
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Смена открыта',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Кассир: ${register.cashierName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.circle,
                      color: AppColors.success,
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
                      'Открыта:',
                      style: TextStyle(color: AppColors.textSecondary),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  balance.currencyCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
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
                    'Доступно: ${CurrencyFormatter.format(balance.availableBalance, symbol: balance.currencySymbol)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
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
                    'Зарезервировано: ${CurrencyFormatter.format(balance.reserved, symbol: balance.currencySymbol)}',
                    style: TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
