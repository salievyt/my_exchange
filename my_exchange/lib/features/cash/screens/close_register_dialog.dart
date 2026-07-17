import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/cash_provider.dart';
import '../../../presentation/providers/currency_provider.dart';
import '../../../presentation/providers/operation_provider.dart';

class CloseRegisterDialog extends StatefulWidget {
  const CloseRegisterDialog({super.key});

  @override
  State<CloseRegisterDialog> createState() => _CloseRegisterDialogState();
}

class _CloseRegisterDialogState extends State<CloseRegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, TextEditingController> _controllers = {};
  String _comment = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OperationProvider>().loadTodayStats();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final loc = context.read<LocalizationProvider>();
    final closingBalance = <String, double>{};
    for (var entry in _controllers.entries) {
      final value = entry.value.text.trim();
      final amount = double.tryParse(value.replaceAll(',', '.'));
      if (amount != null) {
        final currency = context.read<CurrencyProvider>().getCurrencyById(
          entry.key,
        );
        if (currency != null) {
          closingBalance[currency.code] = amount;
        }
      }
    }

    final provider = context.read<CashProvider>();
    final success = await provider.closeRegister(
      closingBalance: closingBalance,
      comment: _comment.isEmpty ? null : _comment,
    );

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final colors = Theme.of(context).colorScheme;
      Navigator.pop(context);
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(loc.t('close_register_success')),
            backgroundColor: colors.tertiary,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? loc.t('close_register_error')),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final local = context.read<LocalizationProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.close,
                      color: colors.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      local.t('close_register_title'),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              
              Consumer<OperationProvider>(
                builder: (context, opProvider, child) {
                  final stats = opProvider.todayStats;
                  if (stats == null || stats.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          local.t('close_register_loading'),
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }

                  final totalOps = stats['total_operations'] ?? 0;
                  final buyOps = stats['buy_operations'] ?? 0;
                  final sellOps = stats['sell_operations'] ?? 0;
                  final totalAmount = (stats['total_amount'] as num?)?.toDouble() ?? 0.0;
                  final cancelledCount = stats['cancelled_count'] ?? 0;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.today, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              local.t('close_register_summary'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatItem(
                                label: local.t('close_register_total_ops'),
                                value: '$totalOps',
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatItem(
                                label: local.t('close_register_buys'),
                                value: '$buyOps',
                                color: AppColors.buyColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatItem(
                                label: local.t('close_register_sells'),
                                value: '$sellOps',
                                color: AppColors.sellColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calculate, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${local.t('close_register_turnover').replaceFirst('{amount}', CurrencyFormatter.format(totalAmount, symbol: local.t('general_som')))}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            if (cancelledCount > 0)
                              Text(
                                local.t('close_register_cancelled').replaceFirst('{count}', cancelledCount.toString()),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              Text(
                local.t('close_register_enter_balances'),
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Consumer<CurrencyProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final displayCurrencies = provider.foreignCurrencies;
                  return Column(
                    children: displayCurrencies.map((currency) {
                      _controllers.putIfAbsent(
                        currency.id,
                        () {
                          final controller = TextEditingController();
                          final cashProvider = context.read<CashProvider>();
                          try {
                            final balance = cashProvider.balances.firstWhere(
                              (b) => b.currencyId == currency.id,
                            );
                            controller.text = balance.balance.toString();
                          } catch (_) {
                            controller.text = '0';
                          }
                          return controller;
                        },
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _controllers[currency.id],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: '${currency.name} (${currency.code})',
                            prefixText: currency.symbol,
                            suffixText: currency.code,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return local.t('close_register_required');
                            }
                            final amount = double.tryParse(
                              value.replaceAll(',', '.'),
                            );
                            if (amount == null || amount < 0) {
                              return local.t('close_register_invalid');
                            }
                            return null;
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: local.t('close_register_comment'),
                  alignLabelWithHint: true,
                ),
                onChanged: (value) => _comment = value,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(local.t('close_register_cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.error,
                      ),
                      child: Text(local.t('close_register_confirm')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
