import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization_provider.dart';
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

    final loc = context.read<LocalizationProvider>();
    if (openingBalance.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('open_register_need_balance'))),
      );
      return;
    }

    final provider = context.read<CashProvider>();
    final success = await provider.openRegister(
      openingBalance: openingBalance,
      comment: _comment.isEmpty ? null : _comment,
    );

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final colors = Theme.of(context).colorScheme;
      Navigator.pop(context);
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(loc.t('open_register_success')),
            backgroundColor: colors.tertiary,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? loc.t('open_register_error')),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = context.read<LocalizationProvider>();
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
                      color: colors.tertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: colors.tertiary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    local.t('open_register_title'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                local.t('open_register_hint'),
                style: TextStyle(color: colors.onSurfaceVariant),
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
                                return local.t('open_register_invalid');
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
                decoration: InputDecoration(
                  labelText: local.t('open_register_comment'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(local.t('open_register_cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text(local.t('open_register_confirm')),
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
