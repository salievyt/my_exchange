import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/operation.dart';
import '../../../presentation/providers/currency_provider.dart';
import '../../../presentation/providers/operation_provider.dart';
import '../../../presentation/providers/cash_provider.dart';

class CreateOperationScreen extends StatefulWidget {
  final Operation? operation; // if provided, we're editing

  const CreateOperationScreen({super.key, this.operation});

  @override
  State<CreateOperationScreen> createState() => _CreateOperationScreenState();
}

class _CreateOperationScreenState extends State<CreateOperationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientCompanyController = TextEditingController();
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _totalController = TextEditingController();
  final _commentController = TextEditingController();

  bool _isEditing = false;

  OperationType _operationType = OperationType.buy;
  int? _selectedCurrencyId;
  double _rate = 0.0;
  double _amount = 0.0;
  double _totalAmount = 0.0;

  // Track which field was last changed manually to avoid infinite loops
  String _lastChangedField = '';
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.operation != null;

    if (_isEditing && widget.operation != null) {
      final op = widget.operation!;
      _operationType = op.operationType;
      _selectedCurrencyId = op.currencyId;
      _rate = op.rate;
      _amount = op.amount;
      _totalAmount = op.totalAmount;
      _amountController.text = op.amount.toString();
      _rateController.text = op.rate.toStringAsFixed(4);
      _totalController.text = op.totalAmount.toStringAsFixed(2);
      if (op.clientName != null) _clientNameController.text = op.clientName!;
      if (op.clientCompany != null) _clientCompanyController.text = op.clientCompany!;
      if (op.comment != null) _commentController.text = op.comment!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashProvider>().loadBalances();
    });
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientCompanyController.dispose();
    _amountController.dispose();
    _rateController.dispose();
    _totalController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  double _getBalanceByCurrencyCode(String code) {
    final cashBalances = context.read<CashProvider>().balances;
    try {
      final balance = cashBalances.firstWhere((b) => b.currencyCode == code);
      return balance.availableBalance;
    } catch (_) {
      return 0.0;
    }
  }

  void _onAmountChanged(String value) {
    if (_isUpdating) return;
    _lastChangedField = 'amount';
    _recalculate();
  }

  void _onRateChanged(String value) {
    if (_isUpdating) return;
    _lastChangedField = 'rate';
    _recalculate();
  }

  void _onTotalChanged(String value) {
    if (_isUpdating) return;
    _lastChangedField = 'total';
    _recalculate();
  }

  void _recalculate() {
    final amount = CurrencyFormatter.parse(_amountController.text);
    final rate = CurrencyFormatter.parse(_rateController.text);
    final total = CurrencyFormatter.parse(_totalController.text);

    setState(() {
      _isUpdating = true;

      if (_lastChangedField == 'amount' && rate > 0) {
        // If amount changed, recalculate total
        _totalAmount = amount * rate;
        _totalController.text = _totalAmount.toStringAsFixed(2);
      } else if (_lastChangedField == 'rate' && amount > 0) {
        // If rate changed, recalculate total
        _totalAmount = amount * rate;
        _totalController.text = _totalAmount.toStringAsFixed(2);
      } else if (_lastChangedField == 'total' && amount > 0) {
        // If total changed, recalculate rate
        if (amount > 0) {
          _rate = total / amount;
          _rateController.text = _rate.toStringAsFixed(4);
        }
      } else if (_lastChangedField == 'total' && rate > 0) {
        // If total changed and amount is 0, recalculate amount
        if (rate > 0) {
          _amount = total / rate;
          _amountController.text = _amount.toStringAsFixed(2);
        }
      }

      _amount = amount;
      _rate = CurrencyFormatter.parse(_rateController.text);
      _totalAmount = CurrencyFormatter.parse(_totalController.text);

      _isUpdating = false;
    });
  }

  void _updateRateFromCurrency() {
    if (_selectedCurrencyId != null) {
      final currency = context.read<CurrencyProvider>().getCurrencyById(
        _selectedCurrencyId!,
      );
      if (currency != null) {
        setState(() {
          _rate = _operationType == OperationType.buy
              ? (currency.buyRate ?? 0.0)
              : (currency.sellRate ?? 0.0);
          _rateController.text = _rate.toStringAsFixed(4);
          _recalculate();
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCurrencyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите валюту')),
      );
      return;
    }

    final provider = context.read<OperationProvider>();
    final amount = CurrencyFormatter.parse(_amountController.text);
    final rate = CurrencyFormatter.parse(_rateController.text);

    // Check cash balance before submitting (only for new operations)
    if (!_isEditing) {
      if (_operationType == OperationType.buy) {
        final kgsBalance = _getBalanceByCurrencyCode('KGS');
        if (kgsBalance < _totalAmount) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Недостаточно сом (KGS) в кассе. Доступно: '
                  '${CurrencyFormatter.format(kgsBalance, symbol: "сом")}, '
                  'требуется: ${CurrencyFormatter.format(_totalAmount, symbol: "сом")}',
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      } else {
        final currency = context.read<CurrencyProvider>().getCurrencyById(
          _selectedCurrencyId!,
        );
        if (currency != null) {
          final currencyBalance = _getBalanceByCurrencyCode(currency.code);
          if (currencyBalance < amount) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Недостаточно ${currency.code} в кассе. Доступно: '
                    '${CurrencyFormatter.format(currencyBalance)}',
                  ),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            return;
          }
        }
      }
    }

    if (_isEditing && widget.operation != null) {
      // Update existing operation
      final success = await provider.updateOperation(
        id: widget.operation!.id.toString(),
        amount: amount,
        rate: rate,
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
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Операция обновлена'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Ошибка обновления операции'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else {
      // Create new operation
      final operation = await provider.createOperation(
        operationType: _operationType.value,
        currencyId: _selectedCurrencyId!,
        rate: rate,
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
          Navigator.pop(context, true);
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
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Редактирование операции' : 'Новая операция';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Operation type selector (disable in edit mode)
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
                              enabled: !_isEditing,
                              onTap: () {
                                setState(() {
                                  _operationType = OperationType.buy;
                                  _updateRateFromCurrency();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _OperationTypeButton(
                              type: OperationType.sell,
                              isSelected: _operationType == OperationType.sell,
                              enabled: !_isEditing,
                              onTap: () {
                                setState(() {
                                  _operationType = OperationType.sell;
                                  _updateRateFromCurrency();
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

              // Currency selector (disable in edit mode)
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
                            value: _selectedCurrencyId,
                            items: provider.currencies.map((currency) {
                              return DropdownMenuItem(
                                value: currency.id,
                                child: Text(
                                  '${currency.code} - ${currency.name}',
                                ),
                              );
                            }).toList(),
                            onChanged: _isEditing
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedCurrencyId = value;
                                      _updateRateFromCurrency();
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

              // Interconnected fields: Amount, Rate, Total
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Параметры операции',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Изменение любых двух полей автоматически пересчитывает третье',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Amount field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: _operationType == OperationType.buy
                              ? 'Сумма покупки (валюта)'
                              : 'Сумма продажи (валюта)',
                          prefixIcon: const Icon(Icons.currency_exchange),
                        ),
                        onChanged: _onAmountChanged,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите сумму';
                          }
                          final amt = CurrencyFormatter.parse(value);
                          if (amt <= 0) return 'Некорректная сумма';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Rate field (now editable!)
                      TextFormField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Курс обмена',
                          prefixIcon: const Icon(Icons.trending_up),
                          suffixText: 'сом',
                        ),
                        onChanged: _onRateChanged,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите курс';
                          }
                          final r = CurrencyFormatter.parse(value);
                          if (r <= 0) return 'Некорректный курс';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Total amount field (editable!)
                      TextFormField(
                        controller: _totalController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Итого к выдаче (сом)',
                          prefixIcon: const Icon(Icons.calculate),
                          suffixText: 'сом',
                        ),
                        onChanged: _onTotalChanged,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите итоговую сумму';
                          }
                          final t = CurrencyFormatter.parse(value);
                          if (t <= 0) return 'Некорректная сумма';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Summary card showing the calculation visually
              Card(
                color: AppColors.primary.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryItem(
                              label: 'Сумма',
                              value: CurrencyFormatter.format(_amount),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                          ),
                          Expanded(
                            child: _SummaryItem(
                              label: 'Курс',
                              value: _rate.toStringAsFixed(4),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward, size: 16, color: AppColors.textSecondary),
                          ),
                          Expanded(
                            child: _SummaryItem(
                              label: 'Итого',
                              value: '${CurrencyFormatter.format(_totalAmount)} сом',
                              isBold: true,
                            ),
                          ),
                        ],
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
                          : Text(
                              _isEditing ? 'Сохранить изменения' : 'Создать операцию',
                              style: const TextStyle(fontSize: 18),
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
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppColors.primary : null,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _OperationTypeButton extends StatelessWidget {
  final OperationType type;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _OperationTypeButton({
    required this.type,
    required this.isSelected,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = type == OperationType.buy
        ? AppColors.buyColor
        : AppColors.sellColor;
    return InkWell(
      onTap: enabled ? onTap : null,
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
