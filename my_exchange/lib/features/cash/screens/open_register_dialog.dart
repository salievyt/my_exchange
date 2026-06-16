import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/cash_provider.dart';
import '../../../presentation/providers/currency_provider.dart';

class OpenRegisterDialog extends StatefulWidget {
  const OpenRegisterDialog({super.key});

  @override
  State<OpenRegisterDialog> createState() => _OpenRegisterDialogState();
}

class _OpenRegisterDialogState extends State<OpenRegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, TextEditingController> _controllers = {};
  String _comment = '';

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each currency
    final currencies = context.read<CurrencyProvider>().currencies;
    for (var currency in currencies) {
      _controllers[currency.id] = TextEditingController();
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

    final openingBalance = <String, double>{};
    for (var entry in _controllers.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty) {
        final amount = double.tryParse(value.replaceAll(',', '.'));
        if (amount != null && amount > 0) {
          final currency = context.read<CurrencyProvider>().getCurrencyById(
            entry.key,
          );
          if (currency != null) {
            openingBalance[currency.code] = amount;
          }
        }
      }
    }

    if (openingBalance.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите хотя бы один остаток')),
      );
      return;
    }

    final provider = context.read<CashProvider>();
    final success = await provider.openRegister(
      openingBalance: openingBalance,
      comment: _comment.isEmpty ? null : _comment,
    );

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Смена успешно открыта'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Ошибка открытия смены'),
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
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: AppColors.success,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Открытие смены',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Внесите начальные остатки по валютам',
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
                            if (value != null && value.isNotEmpty) {
                              final amount = double.tryParse(
                                value.replaceAll(',', '.'),
                              );
                              if (amount == null || amount < 0) {
                                return 'Некорректная сумма';
                              }
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
                onChanged: (value) => _comment = value,
                decoration: const InputDecoration(
                  labelText: 'Комментарий (необязательно)',
                  alignLabelWithHint: true,
                ),
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
                      child: const Text('Открыть смену'),
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
