import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/currency_provider.dart';
import '../../../presentation/widgets/error_widgets.dart';
import '../../../presentation/widgets/skeleton_widgets.dart';
import '../../../presentation/widgets/empty_state_illustration.dart';
import '../../../presentation/widgets/staggered_fade_in.dart';
import '../../../domain/entities/currency.dart';
import '../services/nbkr_service.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
      appBar: AppBar(
        title: Text(
          context.watch<LocalizationProvider>().t('currencies_title'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance, size: 22),
            tooltip: 'Загрузить курсы НБ КР',
            onPressed: () => _showNbkrRatesDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: () => context.read<CurrencyProvider>().loadCurrencies(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<CurrencyProvider>().loadCurrencies(),
        child: Consumer<CurrencyProvider>(
          builder: (context, provider, child) {
            final local = context.watch<LocalizationProvider>();
            final displayCurrencies = provider.foreignCurrencies;

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

            if (displayCurrencies.isEmpty) {
              return EmptyStateIllustration(
                type: EmptyStateType.cash,
                title: local.t('cash_no_data'),
                subtitle: 'Курсы валют появятся после загрузки данных',
                action: ElevatedButton.icon(
                  onPressed: () => provider.loadCurrencies(),
                  icon: const Icon(Icons.refresh),
                  label: Text(local.t('operations_load')),
                ),
              );
            }

            return Column(
              children: [
                
                _buildSummaryBar(displayCurrencies, isDark),
                
                if (provider.errorMessage != null)
                  ErrorBanner(
                    message: provider.errorMessage!,
                    onRetry: () => provider.loadCurrencies(),
                    onDismiss: () => provider.clearError(),
                  ),
                
                Expanded(
                  child: isWide
                      ? _buildGrid(displayCurrencies, isDark)
                      : _buildList(displayCurrencies, isDark),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  

  Widget _buildSummaryBar(List<Currency> currencies, bool isDark) {
    final activeCount = currencies.where((c) => c.isActive).length;
    final hasRatesCount =
        currencies.where((c) => c.buyRate != null && c.buyRate! > 0).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          _SummaryStat(
            icon: Icons.currency_exchange,
            value: '${currencies.length}',
            label: 'Всего',
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _SummaryStat(
            icon: Icons.check_circle_outline,
            value: '$activeCount',
            label: 'Активных',
            color: AppColors.success,
          ),
          const SizedBox(width: 12),
          _SummaryStat(
            icon: Icons.trending_up,
            value: '$hasRatesCount',
            label: 'С курсами',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  

  Widget _buildList(List<Currency> currencies, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: currencies.length,
      itemBuilder: (context, index) {
        final currency = currencies[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index < currencies.length - 1 ? 14 : 0),
          child: StaggeredFadeIn(
            index: index,
            itemDuration: const Duration(milliseconds: 400),
            child: _ModernCurrencyCard(
              currency: currency,
              isDark: isDark,
              onTap: () => _showEditRateDialog(context, currency),
            ),
          ),
        );
      },
    );
  }

  

  Widget _buildGrid(List<Currency> currencies, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.0,
      ),
      itemCount: currencies.length,
      itemBuilder: (context, index) {
        final currency = currencies[index];
        return StaggeredFadeIn(
          index: index,
          itemDuration: const Duration(milliseconds: 400),
          offset: 10,
          child: _ModernCurrencyCard(
            currency: currency,
            isDark: isDark,
            compact: true,
            onTap: () => _showEditRateDialog(context, currency),
          ),
        );
      },
    );
  }

  

  void _showNbkrRatesDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nbkrService = NbkrService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Map<String, NbkrRate>? nbkrRates;
            bool isLoading = true;
            bool hasStartedLoading = false;
            String? error;

            loadNbkrRates() async {
              try {
                final rates = await nbkrService.fetchDailyRates();
                if (context.mounted) {
                  setDialogState(() {
                    nbkrRates = rates;
                    isLoading = false;
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  setDialogState(() {
                    error = e.toString();
                    isLoading = false;
                  });
                }
              }
            }

            if (!hasStartedLoading && isLoading && nbkrRates == null && error == null) {
              hasStartedLoading = true;
              loadNbkrRates();
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Курсы НБ КР',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : error != null
                        ?                            Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.error),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setDialogState(() {
                                    isLoading = true;
                                    error = null;
                                  });
                                  loadNbkrRates();
                                },
                                child: const Text('Повторить'),
                              ),
                            ],
                          )
                        : _buildNbkrRatesList(
                            context, nbkrRates!, isDark,
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Закрыть'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNbkrRatesList(
    BuildContext context,
    Map<String, NbkrRate> nbkrRates,
    bool isDark,
  ) {
    final currencies = context.read<CurrencyProvider>().foreignCurrencies;

    final matchedCurrencies = currencies.where(
      (c) => nbkrRates.containsKey(c.code),
    ).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Официальные курсы Национального Банка КР',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: Text(
                'Валюта',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Курс НБ КР',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                'Ваш курс',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 40),
          ],
        ),
        const Divider(height: 8),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: matchedCurrencies.length,
            itemBuilder: (context, index) {
              final currency = matchedCurrencies[index];
              final nbkrRate = nbkrRates[currency.code]!;
              final userBuyRate = currency.buyRate;
              final userSellRate = currency.sellRate;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _currencyColor(currency.code)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                currency.code,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: _currencyColor(currency.code),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              currency.name,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        CurrencyFormatter.formatRate(nbkrRate.rate),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (userBuyRate != null)
                            Text(
                              'П: ${CurrencyFormatter.formatRate(userBuyRate)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.buyColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (userSellRate != null)
                            Text(
                              'Пр: ${CurrencyFormatter.formatRate(userSellRate)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.sellColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (userBuyRate == null && userSellRate == null)
                            Text(
                              '—',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.3),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (matchedCurrencies.length < currencies.length) ...[
          const SizedBox(height: 8),
          Text(
            '${currencies.length - matchedCurrencies.length} валют не найдено в курсах НБ КР',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange,
            ),
          ),
        ],
      ],
    );
  }

  void _showEditRateDialog(BuildContext context, Currency currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyColor = _currencyColor(currency.code);

    final buyRateController = TextEditingController(
      text: currency.buyRate != null
          ? CurrencyFormatter.formatRate(currency.buyRate!)
          : '',
    );
    final sellRateController = TextEditingController(
      text: currency.sellRate != null
          ? CurrencyFormatter.formatRate(currency.sellRate!)
          : '',
    );

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              bool saving = false;

              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: currencyColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                currency.code,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: currencyColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currency.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Редактирование курсов',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.45)
                                        : Colors.black.withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _RateField(
                        label: 'Покупка',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.buyColor,
                        controller: buyRateController,
                        enabled: !saving,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      
                      _RateField(
                        label: 'Продажа',
                        icon: Icons.trending_down_rounded,
                        color: AppColors.sellColor,
                        controller: sellRateController,
                        enabled: !saving,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Отмена'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setDialogState(() => saving = true);
                                      final buyRate = double.tryParse(
                                        buyRateController.text
                                            .replaceAll(',', '.'),
                                      ) ??
                                          0.0;
                                      final sellRate = double.tryParse(
                                        sellRateController.text
                                            .replaceAll(',', '.'),
                                      ) ??
                                          0.0;
                                      final provider =
                                          context.read<CurrencyProvider>();
                                      await provider.updateCurrency(
                                        id: currency.id,
                                        buyRate: buyRate,
                                        sellRate: sellRate,
                                      );
                                      if (ctx.mounted) {
                                        setDialogState(() => saving = false);
                                        Navigator.pop(ctx);
                                      }
                                    },
                              icon: const Icon(Icons.save_rounded, size: 20),
                              label: Text('Сохранить'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

}

/// Distinct color for each currency code
Color _currencyColor(String code) {
  switch (code) {
    case 'USD':
      return AppColors.buyColor;
    case 'EUR':
      return const Color(0xFF2196F3);
    case 'RUB':
      return AppColors.sellColor;
    case 'GBP':
      return const Color(0xFF9C27B0);
    case 'CNY':
      return const Color(0xFFFF5722);
    case 'KZT':
      return const Color(0xFFFFC107);
    case 'TRY':
      return const Color(0xFF009688);
    default:
      return AppColors.primary;
  }
}





class _ModernCurrencyCard extends StatefulWidget {
  final Currency currency;
  final bool isDark;
  final bool compact;
  final VoidCallback onTap;

  const _ModernCurrencyCard({
    required this.currency,
    required this.isDark,
    this.compact = false,
    required this.onTap,
  });

  @override
  State<_ModernCurrencyCard> createState() => _ModernCurrencyCardState();
}

class _ModernCurrencyCardState extends State<_ModernCurrencyCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final currency = widget.currency;
    final currencyColor = _getCurrencyColor(currency.code);
    final hasBuy = currency.buyRate != null && currency.buyRate! > 0;
    final hasSell = currency.sellRate != null && currency.sellRate! > 0;
    final bgColor = widget.isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: widget.onTap,
      onHighlightChanged: (value) => setState(() => _isHovered = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered ? (Matrix4.identity()..setTranslationRaw(0, -2, 0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? currencyColor.withValues(alpha: widget.isDark ? 0.2 : 0.15)
                  : Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.06),
              blurRadius: _isHovered ? 20 : 12,
              offset: Offset(0, _isHovered ? 6 : 3),
            ),
          ],
        ),
        child: widget.compact ? _buildCompact(textColor, currencyColor) : _buildFull(textColor, currencyColor),
      ),
    );
  }

  

  Widget _buildFull(Color textColor, Color currencyColor) {
    final currency = widget.currency;
    final hasBuy = currency.buyRate != null && currency.buyRate! > 0;
    final hasSell = currency.sellRate != null && currency.sellRate! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                currencyColor,
                currencyColor.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Row(
                children: [
                  
                  _CodeBadge(
                    code: currency.code,
                    color: currencyColor,
                  ),
                  const SizedBox(width: 14),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currency.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _StatusBadge(
                              label: currency.isActive ? 'Активна' : 'Неактивна',
                              color: currency.isActive
                                  ? AppColors.success
                                  : AppColors.textHint,
                            ),
                            if (currency.symbol.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                currency.symbol,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: widget.isDark
                                      ? Colors.white.withValues(alpha: 0.4)
                                      : Colors.black.withValues(alpha: 0.3),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  _EditButton(color: currencyColor),
                ],
              ),
              const SizedBox(height: 20),
              
              if (hasBuy || hasSell)
                _buildFullRates(currency, currencyColor, hasBuy, hasSell)
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Курсы не установлены',
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullRates(
    Currency currency,
    Color currencyColor,
    bool hasBuy,
    bool hasSell,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          
          if (hasBuy) ...[
            Expanded(
              child: _RateDisplay(
              label: 'Покупка',
              rate: currency.buyRate!,
              color: AppColors.buyColor,
              icon: Icons.arrow_upward_rounded,
              isDark: widget.isDark,
            ),
            ),
          ],
          
          if (hasBuy && hasSell)
            Container(
              width: 1,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          
          if (hasSell)
            Expanded(
              child: _RateDisplay(
                label: 'Продажа',
                rate: currency.sellRate!,
                color: AppColors.sellColor,
                icon: Icons.arrow_downward_rounded,
                isDark: widget.isDark,
              ),
            ),
        ],
      ),
    );
  }

  

  Widget _buildCompact(Color textColor, Color currencyColor) {
    final currency = widget.currency;
    final hasBuy = currency.buyRate != null && currency.buyRate! > 0;
    final hasSell = currency.sellRate != null && currency.sellRate! > 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            children: [
              _CompactCodeBadge(
                code: currency.code,
                color: currencyColor,
              ),
              const Spacer(),
              _EditButton(color: currencyColor, size: 28),
            ],
          ),
          const SizedBox(height: 8),
          
          Text(
            currency.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: currency.isActive
                      ? AppColors.success
                      : AppColors.textHint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                currency.isActive ? 'Активна' : 'Неактивна',
                style: TextStyle(
                  fontSize: 10,
                  color: currency.isActive
                      ? AppColors.success
                      : AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          
          if (hasBuy || hasSell) ...[
            _CompactRateLine(
              label: 'Покупка',
              rate: currency.buyRate,
              color: AppColors.buyColor,
            ),
            const SizedBox(height: 4),
            _CompactRateLine(
              label: 'Продажа',
              rate: currency.sellRate,
              color: AppColors.sellColor,
            ),
          ] else
            Text(
              'Курсы не указаны',
              style: TextStyle(
                fontSize: 11,
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.25),
              ),
            ),
        ],
      ),
    );
  }

  Color _getCurrencyColor(String code) => _currencyColor(code);
}





class _CodeBadge extends StatelessWidget {
  final String code;
  final Color color;

  const _CodeBadge({required this.code, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          code,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _CompactCodeBadge extends StatelessWidget {
  final String code;
  final Color color;

  const _CompactCodeBadge({required this.code, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          code,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EditButton extends StatefulWidget {
  final Color color;
  final double size;

  const _EditButton({required this.color, this.size = 36});

  @override
  State<_EditButton> createState() => _EditButtonState();
}

class _EditButtonState extends State<_EditButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withValues(alpha: 0.25)
              : widget.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.edit_outlined,
          size: widget.size * 0.5,
          color: widget.color,
        ),
      ),
    );
  }
}

class _RateDisplay extends StatelessWidget {
  final String label;
  final double rate;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _RateDisplay({
    required this.label,
    required this.rate,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, size: 12, color: color),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatRate(rate),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _CompactRateLine extends StatelessWidget {
  final String label;
  final double? rate;
  final Color color;

  const _CompactRateLine({
    required this.label,
    required this.rate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          rate != null && rate! > 0
              ? CurrencyFormatter.formatRate(rate!)
              : '—',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RateField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final TextEditingController controller;
  final bool enabled;
  final bool isDark;

  const _RateField({
    required this.label,
    required this.icon,
    required this.color,
    required this.controller,
    required this.enabled,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: color.withValues(alpha: 0.8),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, size: 22, color: color),
        filled: true,
        fillColor: isDark
            ? color.withValues(alpha: 0.08)
            : color.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Введите курс';
        if (double.tryParse(v.replaceAll(',', '.')) == null) {
          return 'Неверное число';
        }
        return null;
      },
    );
  }
}
