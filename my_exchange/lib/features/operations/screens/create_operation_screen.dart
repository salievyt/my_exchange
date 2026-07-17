import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/operation.dart';
import '../../../presentation/providers/currency_provider.dart';
import '../../../presentation/providers/operation_provider.dart';
import '../../../presentation/providers/cash_provider.dart';

class CreateOperationScreen extends StatefulWidget {
  final Operation? operation; 

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

  
  String _lastChangedField = '';
  String _firstField = '';
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
    if (_firstField.isEmpty && value.isNotEmpty) _firstField = 'amount';
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
    if (_firstField.isEmpty && value.isNotEmpty) _firstField = 'total';
    _recalculate();
  }

  void _recalculate() {
    final amount = CurrencyFormatter.parse(_amountController.text);
    final rate = CurrencyFormatter.parse(_rateController.text);
    final total = CurrencyFormatter.parse(_totalController.text);

    setState(() {
      _isUpdating = true;

      if (_lastChangedField == 'amount' && rate > 0) {
        // Сумма (валюта) введена → пересчитать итог (сомы)
        _totalAmount = amount * rate;
        _totalController.text = _totalAmount.toStringAsFixed(2);
      } else if (_lastChangedField == 'rate') {
        // Курс изменён — сохранить поле, которое пользователь заполнил первым
        if ((_firstField == 'amount' || _firstField.isEmpty) && amount > 0) {
          // Первым ввели сумму (или поле не определено, но сумма есть) → сохранить сумму
          _totalAmount = amount * rate;
          _totalController.text = _totalAmount.toStringAsFixed(2);
        } else if (_firstField == 'total' && total > 0) {
          // Первым ввели итог → сохранить итог, пересчитать сумму
          _amount = total / rate;
          _amountController.text = _amount.toStringAsFixed(2);
          _totalAmount = total;
        }
      } else if (_lastChangedField == 'total' && rate > 0) {
        // Итог (сомы) введён → сохранить итог, пересчитать сумму в валюте
        _amount = total / rate;
        _amountController.text = _amount.toStringAsFixed(2);
        _totalAmount = total;
      }

      _amount = CurrencyFormatter.parse(_amountController.text);
      _rate = CurrencyFormatter.parse(_rateController.text);
      _totalAmount = CurrencyFormatter.parse(_totalController.text);

      // Сбросить _firstField если оба поля пусты
      if (_amount <= 0 && _totalAmount <= 0) {
        _firstField = '';
      }

      _isUpdating = false;
    });
  }

  void _updateRateFromCurrency() {
    if (_selectedCurrencyId != null) {
      final currency = context.read<CurrencyProvider>().getCurrencyById(
        _selectedCurrencyId!,
      );
      if (currency != null) {
        final newRate = _operationType == OperationType.buy
            ? (currency.buyRate ?? 0.0)
            : (currency.sellRate ?? 0.0);

        setState(() {
          _rate = newRate;
          _rateController.text = _rate.toStringAsFixed(4);
          _isUpdating = true;

          final amount = CurrencyFormatter.parse(_amountController.text);
          final total = CurrencyFormatter.parse(_totalController.text);

          if (_firstField == 'total' && total > 0 && _rate > 0) {
            // Первым ввели итог → сохранить итог, пересчитать сумму
            _amount = total / _rate;
            _amountController.text = _amount.toStringAsFixed(2);
            _totalAmount = total;
          } else if (amount > 0 && _rate > 0) {
            // Во всех остальных случаях → сохранить сумму, пересчитать итог
            _totalAmount = amount * _rate;
            _totalController.text = _totalAmount.toStringAsFixed(2);
          }

          _amount = CurrencyFormatter.parse(_amountController.text);
          _totalAmount = CurrencyFormatter.parse(_totalController.text);

          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCurrencyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<LocalizationProvider>().t('create_operation_select_currency'))),
      );
      return;
    }

    final provider = context.read<OperationProvider>();
    final amount = CurrencyFormatter.parse(_amountController.text);
    final rate = CurrencyFormatter.parse(_rateController.text);

    
    if (!_isEditing) {
      if (_operationType == OperationType.buy) {
        final kgsBalance = _getBalanceByCurrencyCode('KGS');
        if (kgsBalance < _totalAmount) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:              Text(
                  context.read<LocalizationProvider>().t('create_operation_insufficient_kgs')
                    .replaceAll('{balance}', CurrencyFormatter.format(kgsBalance, symbol: context.read<LocalizationProvider>().t('general_som')))
                    .replaceAll('{required}', CurrencyFormatter.format(_totalAmount, symbol: context.read<LocalizationProvider>().t('general_som'))),
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
                    context.read<LocalizationProvider>().t('create_operation_insufficient_currency')
                      .replaceAll('{currency}', currency.code)
                      .replaceAll('{balance}', CurrencyFormatter.format(currencyBalance)),
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

final clientName = _clientNameController.text.trim().isEmpty
        ? null
        : _clientNameController.text.trim();
    final clientCompany = _clientCompanyController.text.trim().isEmpty
        ? null
        : _clientCompanyController.text.trim();
    final commentText = _commentController.text.trim().isEmpty
        ? null
        : _commentController.text.trim();

    debugPrint('[Screen] _submit: operationType=${_operationType.value} currencyId=$_selectedCurrencyId');
    debugPrint('[Screen]   amount=$amount rate=$rate total=$_totalAmount');
    debugPrint('[Screen]   clientName=$clientName clientCompany=$clientCompany');
    debugPrint('[Screen]   isEditing=$_isEditing');

    if (_isEditing && widget.operation != null) {
      
      final success = await provider.updateOperation(
        id: widget.operation!.id.toString(),
        amount: amount,
        rate: rate,
        clientName: clientName,
        clientCompany: clientCompany,
        comment: commentText,
      );

      if (mounted) {
        if (success) {
          debugPrint('[Screen] updateOperation SUCCESS, popping...');
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.read<LocalizationProvider>().t('create_operation_success_updated')),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          debugPrint('[Screen] updateOperation FAILED: ${provider.errorMessage}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? context.read<LocalizationProvider>().t('create_operation_error_update')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else {
      
      final operation = await provider.createOperation(
        operationType: _operationType.value,
        currencyId: _selectedCurrencyId!,
        rate: rate,
        amount: amount,
        totalAmount: _totalAmount,
        clientName: clientName,
        clientCompany: clientCompany,
        comment: commentText,
      );

      if (mounted) {
        if (operation != null) {
          debugPrint('[Screen] createOperation SUCCESS: id=${operation.id} number=${operation.operationNumber}, popping...');
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.read<LocalizationProvider>().t('create_operation_success_created')),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          debugPrint('[Screen] createOperation FAILED: ${provider.errorMessage}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? context.read<LocalizationProvider>().t('create_operation_error_create')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = context.watch<LocalizationProvider>();
    final title = _isEditing ? local.t('create_operation_title_edit') : local.t('create_operation_title_new');
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        local.t('create_operation_type'),
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
                                HapticFeedback.mediumImpact();
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
                                HapticFeedback.mediumImpact();
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

              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        local.t('create_operation_currency'),
                        style: const TextStyle(
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
                            decoration: InputDecoration(
                              labelText: local.t('create_operation_currency_select'),
                            ),
                            value: _selectedCurrencyId,
                            items: provider.foreignCurrencies.map((currency) {
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
                              if (value == null) return local.t('create_operation_currency_select');
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

              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        local.t('create_operation_params'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        local.t('create_operation_params_hint'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: _operationType == OperationType.buy
                              ? local.t('create_operation_amount_buy_label')
                              : local.t('create_operation_amount_sell_label'),
                          prefixIcon: const Icon(Icons.currency_exchange),
                        ),
                        onChanged: _onAmountChanged,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return local.t('create_operation_amount_required');
                          }
                          final amt = CurrencyFormatter.parse(value);
                          if (amt <= 0) return local.t('create_operation_amount_invalid');
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      
                      TextFormField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: local.t('create_operation_rate_label'),
                          prefixIcon: const Icon(Icons.trending_up),
                          suffixText: 'сом',
                        ),
                        onChanged: _onRateChanged,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return local.t('create_operation_rate_required');
                          }
                          final r = CurrencyFormatter.parse(value);
                          if (r <= 0) return local.t('create_operation_rate_invalid');
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      
                      TextFormField(
                        controller: _totalController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: local.t('create_operation_total_label'),
                          prefixIcon: const Icon(Icons.calculate),
                          suffixText: 'сом',
                        ),
                        onChanged: _onTotalChanged,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return local.t('create_operation_total_required');
                          }
                          final t = CurrencyFormatter.parse(value);
                          if (t <= 0) return local.t('create_operation_total_invalid');
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              
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
                              label: local.t('create_operation_summary_amount'),
                              value: CurrencyFormatter.format(_amount),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                          ),
                          Expanded(
                            child: _SummaryItem(
                              label: local.t('create_operation_summary_rate'),
                              value: _rate.toStringAsFixed(4),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward, size: 16, color: AppColors.textSecondary),
                          ),
                          Expanded(
                            child: _SummaryItem(
                              label: local.t('create_operation_summary_total'),
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

              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        local.t('create_operation_client_info'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _clientNameController,
                        decoration: InputDecoration(
                          labelText: local.t('create_operation_client_name'),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _clientCompanyController,
                        decoration: InputDecoration(
                          labelText: local.t('create_operation_client_company'),
                          prefixIcon: const Icon(Icons.business_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        local.t('create_operation_comment_label'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: local.t('create_operation_comment_optional'),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              
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
                              _isEditing ? local.t('create_operation_save') : local.t('create_operation_create'),
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
