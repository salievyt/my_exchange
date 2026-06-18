import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final _commentController = TextEditingController();

  String _transactionType = 'deposit';
  int? _selectedCurrencyId;

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCurrencyId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите валюту')));
      return;
    }

    final provider = context.read<CashProvider>();
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    final success = await provider.createTransaction(
      transactionType: _transactionType,
      currencyId: _selectedCurrencyId!,
      amount: amount,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Транзакция успешно создана'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Ошибка создания транзакции',
            ),
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
                  const Text(
                    'Транзакция',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Transaction type
              Row(
                children: [
                  Expanded(
                    child: _TransactionTypeButton(
                      type: 'deposit',
                      label: 'Внесение',
                      icon: Icons.add,
                      isSelected: _transactionType == 'deposit',
                      onTap: () => setState(() => _transactionType = 'deposit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TransactionTypeButton(
                      type: 'withdrawal',
                      label: 'Выдача',
                      icon: Icons.remove,
                      isSelected: _transactionType == 'withdrawal',
                      onTap: () =>
                          setState(() => _transactionType = 'withdrawal'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Currency selector
              Consumer<CurrencyProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Валюта'),
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
                      if (value == null) return 'Выберите валюту';
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Сумма',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Введите сумму';
                  final amount = double.tryParse(value.replaceAll(',', '.'));
                  if (amount == null || amount <= 0) {
                    return 'Некорректная сумма';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Comment
              TextFormField(
                controller: _commentController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Комментарий (необязательно)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
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
                      child: const Text('Создать'),
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
