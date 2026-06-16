import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/operation.dart';
import '../../../presentation/providers/currency_provider.dart';
import '../../../presentation/providers/operation_provider.dart';

class CreateOperationScreen extends StatefulWidget {
  const CreateOperationScreen({super.key});

  @override
  State<CreateOperationScreen> createState() => _CreateOperationScreenState();
}

class _CreateOperationScreenState extends State<CreateOperationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientCompanyController = TextEditingController();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  OperationType _operationType = OperationType.buy;
  int? _selectedCurrencyId;
  double _rate = 0.0;
  double _totalAmount = 0.0;

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientCompanyController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    setState(() {
      _totalAmount = amount * _rate;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCurrencyId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите валюту')));
      return;
    }

    final provider = context.read<OperationProvider>();
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    final operation = await provider.createOperation(
      operationType: _operationType.value,
      currencyId: _selectedCurrencyId!,
      rate: _rate,
      amount: amount,
      clientName: _clientNameController.text.trim().isEmpty
          ? null
          : _clientNameController.text.trim(),
      clientCompany: _clientCompanyController.text.trim().isEmpty
          ? null
          : _clientCompanyController.text.trim(),
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );

    if (mounted) {
      if (operation != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Операция успешно создана'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Ошибка создания операции'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новая операция')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Operation type selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Тип операции',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _OperationTypeButton(
                              type: OperationType.buy,
                              isSelected: _operationType == OperationType.buy,
                              onTap: () {
                                setState(() {
                                  _operationType = OperationType.buy;
                                  _updateRate();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _OperationTypeButton(
                              type: OperationType.sell,
                              isSelected: _operationType == OperationType.sell,
                              onTap: () {
                                setState(() {
                                  _operationType = OperationType.sell;
                                  _updateRate();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Currency selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Валюта',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Consumer<CurrencyProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Выберите валюту',
                            ),
                            items: provider.currencies.map((currency) {
                              return DropdownMenuItem(
                                value: currency.id,
                                child: Text(
                                  '${currency.code} - ${currency.name}',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCurrencyId = value;
                                _updateRate();
                              });
                            },
                            validator: (value) {
                              if (value == null) return 'Выберите валюту';
                              return null;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Rate (read-only)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Курс обмена',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _rate > 0 ? CurrencyFormatter.formatRate(_rate) : '—',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Сумма',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Сумма валюты',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        onChanged: (_) => _calculateTotal(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите сумму';
                          }
                          final amount = double.tryParse(
                            value.replaceAll(',', '.'),
                          );
                          if (amount == null || amount <= 0) {
                            return 'Некорректная сумма';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Total amount
              Card(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Итого к выдаче',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(_totalAmount, symbol: 'сом'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Client info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Информация о клиенте',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Имя клиента (необязательно)',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _clientCompanyController,
                        decoration: const InputDecoration(
                          labelText: 'Компания (необязательно)',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Comment
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Комментарий',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _commentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Комментарий (необязательно)',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              Consumer<OperationProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: provider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Создать операцию',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _updateRate() {
    if (_selectedCurrencyId != null) {
      final currency = context.read<CurrencyProvider>().getCurrencyById(
        _selectedCurrencyId!,
      );
      if (currency != null) {
        setState(() {
          _rate = _operationType == OperationType.buy
              ? (currency.buyRate ?? 0.0)
              : (currency.sellRate ?? 0.0);
          _calculateTotal();
        });
      }
    }
  }
}

class _OperationTypeButton extends StatelessWidget {
  final OperationType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _OperationTypeButton({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = type == OperationType.buy
        ? AppColors.buyColor
        : AppColors.sellColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              type == OperationType.buy
                  ? Icons.trending_up
                  : Icons.trending_down,
              color: isSelected ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              type.displayName,
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
