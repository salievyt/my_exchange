import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../presentation/providers/cash_provider.dart';
import '../../../presentation/providers/currency_provider.dart';

class TransactionDialog extends StatefulWidget {
  const TransactionDialog({super.key});

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientCompanyController = TextEditingController();
  final _rateController = TextEditingController();
  final _commentController = TextEditingController();

  String _transactionType = 'deposit';
  int? _selectedCurrencyId;

  @override
  void dispose() {
    _amountController.dispose();
    _clientNameController.dispose();
    _clientCompanyController.dispose();
    _rateController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCurrencyId == null) {
      final loc = context.read<LocalizationProvider>();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.t('transaction_currency_placeholder'))));
      return;
    }

    final provider = context.read<CashProvider>();
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    final clientName = _clientNameController.text.trim().isEmpty
        ? null
        : _clientNameController.text.trim();
    final clientCompany = _clientCompanyController.text.trim().isEmpty
        ? null
        : _clientCompanyController.text.trim();
    final rateText = _rateController.text.trim();
    final rate = rateText.isNotEmpty
        ? double.tryParse(rateText.replaceAll(',', '.'))
        : null;

    final loc = context.read<LocalizationProvider>();
    final success = await provider.createTransaction(
      transactionType: _transactionType,
      currencyId: _selectedCurrencyId!,
      amount: amount,
      clientName: clientName,
      clientCompany: clientCompany,
      rate: rate,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );

    if (mounted) {
      final colors = Theme.of(context).colorScheme;
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('transaction_success')),
            backgroundColor: colors.tertiary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? loc.t('transaction_error'),
            ),
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
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add_circle,
                      color: colors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    local.t('transaction_title'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              
              Row(
                children: [
                  Expanded(
                    child: _TransactionTypeButton(
                      type: 'deposit',
                      label: local.t('transaction_deposit'),
                      icon: Icons.add,
                      isSelected: _transactionType == 'deposit',
                      onTap: () => setState(() => _transactionType = 'deposit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TransactionTypeButton(
                      type: 'withdrawal',
                      label: local.t('transaction_withdrawal'),
                      icon: Icons.remove,
                      isSelected: _transactionType == 'withdrawal',
                      onTap: () =>
                          setState(() => _transactionType = 'withdrawal'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              
              Consumer<CurrencyProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: local.t('transaction_currency'),
                    ),
                    items: provider.currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency.id,
                        child: Text('${currency.code} - ${currency.name}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCurrencyId = value);
                    },
                    validator: (value) {
                      if (value == null) return local.t('transaction_currency_placeholder');
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: local.t('transaction_amount'),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return local.t('transaction_amount_required');
                  final amount = double.tryParse(value.replaceAll(',', '.'));
                  if (amount == null || amount <= 0) {
                    return local.t('transaction_amount_invalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              
              TextFormField(
                controller: _clientNameController,
                decoration: InputDecoration(
                  labelText: local.t('transaction_client_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              
              TextFormField(
                controller: _clientCompanyController,
                decoration: InputDecoration(
                  labelText: local.t('transaction_client_company'),
                  prefixIcon: const Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 16),

              
              TextFormField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: local.t('transaction_rate'),
                  hintText: local.t('transaction_rate_hint'),
                  prefixIcon: const Icon(Icons.trending_up),
                ),
              ),
              const SizedBox(height: 16),

              
              TextFormField(
                controller: _commentController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: local.t('transaction_comment'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(local.t('transaction_cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text(local.t('transaction_create')),
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

class _TransactionTypeButton extends StatelessWidget {
  final String type;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TransactionTypeButton({
    required this.type,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
      final colors = Theme.of(context).colorScheme;
    final color = type == 'deposit' ? colors.tertiary : Colors.orange;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
