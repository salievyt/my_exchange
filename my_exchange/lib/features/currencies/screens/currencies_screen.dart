import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/currency_provider.dart';
import '../../../presentation/widgets/error_widgets.dart';
import '../../../presentation/widgets/skeleton_widgets.dart';
import '../../../domain/entities/currency.dart';

class CurrenciesScreen extends StatefulWidget {
  const CurrenciesScreen({super.key});

  @override
  State<CurrenciesScreen> createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends State<CurrenciesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrencyProvider>().loadCurrencies();
    });
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => const SkeletonCurrencyCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          context.watch<LocalizationProvider>().t('currencies_title'),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 24),
            onPressed: () => context.read<CurrencyProvider>().loadCurrencies(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<CurrencyProvider>().loadCurrencies(),
        child: Consumer<CurrencyProvider>(
          builder: (context, provider, child) {
            final local = context.watch<LocalizationProvider>();
            if (provider.isLoading && provider.currencies.isEmpty) {
              return _buildSkeletonList();
            }

            if (provider.errorMessage != null && provider.currencies.isEmpty) {
              return ErrorStateWidget(
                message: provider.errorMessage!,
                details:
                    '${local.t('currencies_title')} — ${provider.errorMessage!}',
                onRetry: () => provider.loadCurrencies(),
              );
            }

            if (provider.currencies.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.currency_exchange,
                      size: 80,
                      color: colors.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      local.t('cash_no_data'),
                      style: TextStyle(
                        fontSize: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.loadCurrencies(),
                      icon: const Icon(Icons.refresh),
                      label: Text(local.t('operations_load')),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                if (provider.errorMessage != null)
                  ErrorBanner(
                    message: provider.errorMessage!,
                    onRetry: () => provider.loadCurrencies(),
                    onDismiss: () => provider.clearError(),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: provider.currencies.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final currency = provider.currencies[index];
                      return _CurrencyCard(
                        currency: currency,
                        onTap: () => _showEditRateDialog(context, currency),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showEditRateDialog(BuildContext context, Currency? currency) {
    final colors = Theme.of(context).colorScheme;
    final isEdit = currency != null;
    final cur = currency!;

    final codeController = TextEditingController(text: isEdit ? cur.code : '');
    final nameController = TextEditingController(text: isEdit ? cur.name : '');
    final symbolController = TextEditingController(
      text: isEdit ? cur.symbol : '',
    );
    final buyRateController = TextEditingController(
      text: cur.buyRate != null
          ? CurrencyFormatter.formatRate(cur.buyRate!)
          : '0',
    );
    final sellRateController = TextEditingController(
      text: cur.sellRate != null
          ? CurrencyFormatter.formatRate(cur.sellRate!)
          : '0',
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool saving = false;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isEdit ? 'Редактировать курс' : 'Новая валюта',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        
                        const SizedBox(height: 6),
                        const Text(
                          'Курсы (к KGS)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Buy rate
                        TextFormField(
                          controller: buyRateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Покупка',
                            prefixIcon: Icon(
                              Icons.trending_up,
                              size: 20,
                              color: colors.tertiary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: colors.tertiary.withValues(alpha: 0.08),
                          ),
                          enabled: !saving,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return '0';
                            if (double.tryParse(v) == null) {
                              return 'Неверное число';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Sell rate
                        TextFormField(
                          controller: sellRateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Продажа',
                            prefixIcon: Icon(
                              Icons.trending_down,
                              size: 20,
                              color: colors.error,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: colors.error.withValues(alpha: 0.08),
                          ),
                          enabled: !saving,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return '0';
                            if (double.tryParse(v) == null) {
                              return 'Неверное число';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => saving = true);

                          final buyRate =
                              double.tryParse(
                                buyRateController.text.replaceAll(',', '.'),
                              ) ??
                              0.0;
                          final sellRate =
                              double.tryParse(
                                sellRateController.text.replaceAll(',', '.'),
                              ) ??
                              0.0;

                          final provider = context.read<CurrencyProvider>();

                          if (isEdit) {
                            await provider.updateCurrency(
                              id: cur.id,
                              buyRate: buyRate,
                              sellRate: sellRate,
                            );
                          } else {
                            await provider.createCurrency(
                              code: codeController.text.trim(),
                              name: nameController.text.trim(),
                              symbol: symbolController.text.trim(),
                              buyRate: buyRate,
                              sellRate: sellRate,
                            );
                          }

                          if (ctx.mounted) {
                            setDialogState(() => saving = false);
                            Navigator.pop(ctx);
                          }
                        },
                  icon: const Icon(Icons.save),
                  label: Text(isEdit ? 'Сохранить' : 'Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  final Currency currency;
  final VoidCallback onTap;

  const _CurrencyCard({required this.currency, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasBuy = currency.buyRate != null && currency.buyRate! > 0;
    final hasSell = currency.sellRate != null && currency.sellRate! > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: code + name + icon
              Row(
                children: [
                  // Currency code badge with gradient
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primary,
                          colors.primary.withValues(alpha: 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        currency.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currency.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: currency.isActive
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currency.isActive ? 'Активна' : 'Неактивна',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: currency.isActive
                                      ? AppColors.success
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (currency.symbol.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${currency.symbol}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Edit icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Rates section
              if (hasBuy || hasSell)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Buy rate
                      if (hasBuy)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.buyColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.arrow_upward,
                                      size: 14,
                                      color: AppColors.buyColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Покупка',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                CurrencyFormatter.formatRate(currency.buyRate!),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.buyColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Divider
                      if (hasBuy && hasSell)
                        Container(
                          width: 1,
                          height: 70,
                          color: colors.outline.withValues(alpha: 0.2),
                        ),

                      // Sell rate
                      if (hasSell)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.sellColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.arrow_downward,
                                      size: 14,
                                      color: AppColors.sellColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Продажа',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                CurrencyFormatter.formatRate(
                                  currency.sellRate!,
                                ),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sellColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Курсы не установлены',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
