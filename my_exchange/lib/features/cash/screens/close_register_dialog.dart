import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final provider = context.read<CashProvider>();
    final currencies = context.read<CurrencyProvider>().foreignCurrencies;

    for (var currency in currencies) {
      _controllers[currency.id] = TextEditingController();
      try {
        final balance = provider.balances.firstWhere(
          (b) => b.currencyId == currency.id,
        );
        _controllers[currency.id]!.text = balance.balance.toString();
      } catch (_) {
        _controllers[currency.id]!.text = '0';
      }
    }

    // Load today's stats
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
      Navigator.pop(context);
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Смена успешно закрыта'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Ошибка закрытия смены'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
                  const Expanded(
                    child: Text(
                      'Закрытие смены',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Daily Totals Section ─────────────────────────
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
                      child: const Center(
                        child: Text(
                          'Итоги дня загружаются...',
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
                        const Row(
                          children: [
                            Icon(Icons.today, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Итоги дня',
                              style: TextStyle(
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
                                label: 'Всего операций',
                                value: '$totalOps',
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatItem(
                                label: 'Покупок',
                                value: '$buyOps',
                                color: AppColors.buyColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatItem(
                                label: 'Продаж',
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
                              'Оборот: ${CurrencyFormatter.format(totalAmount, symbol: 'сом')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            if (cancelledCount > 0)
                              Text(
                                'Отмен: $cancelledCount',
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
                'Внесите фактические остатки по валютам',
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
                              return 'Обязательное поле';
                            }
                            final amount = double.tryParse(
                              value.replaceAll(',', '.'),
                            );
                            if (amount == null || amount < 0) {
                              return 'Некорректная сумма';
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
                decoration: const InputDecoration(
                  labelText: 'Комментарий (необязательно)',
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
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.error,
                      ),
                      child: const Text('Закрыть смену'),
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
