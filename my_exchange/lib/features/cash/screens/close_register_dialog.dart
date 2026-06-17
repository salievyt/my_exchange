import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/cash_provider.dart';
import '../../../presentation/providers/currency_provider.dart';

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
    final currencies = context.read<CurrencyProvider>().currencies;

    for (var currency in currencies) {
      _controllers[currency.id] = TextEditingController();
      // Set current balance as placeholder, default to 0 if not loaded
      try {
        final balance = provider.balances.firstWhere(
          (b) => b.currencyId == currency.id,
        );
        _controllers[currency.id]!.text = balance.balance.toString();
      } catch (_) {
        _controllers[currency.id]!.text = '0';
      }
    }
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
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Смена успешно закрыта'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Ошибка закрытия смены'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Закрытие смены',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Внесите фактические остатки по валютам',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Consumer<CurrencyProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    children: provider.currencies.map((currency) {
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
                        backgroundColor: AppColors.error,
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
