import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/operation.dart';
import '../../../presentation/providers/operation_provider.dart';
import '../../../presentation/providers/currency_provider.dart';
import '../../../presentation/widgets/operation_card.dart';
import '../../../presentation/widgets/error_widgets.dart';
import '../../../presentation/widgets/columns_toggle.dart';
import '../../../presentation/widgets/skeleton_widgets.dart';
import '../../../presentation/widgets/staggered_fade_in.dart';
import '../../../presentation/widgets/empty_state_illustration.dart';
import 'create_operation_screen.dart';
import 'operation_detail_screen.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _hasSearchText = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OperationProvider>().loadOperations();
      context.read<OperationProvider>().loadTodayStats();
      context.read<OperationProvider>().loadColumnsSetting();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _hasSearchText = query.isNotEmpty);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<OperationProvider>().setSearchQuery(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _hasSearchText = false);
    context.read<OperationProvider>().setSearchQuery('');
  }

  void _setPeriodFilter(String period) {
    final now = DateTime.now();
    String? from;
    String? to;

    switch (period) {
      case 'today':
        from = DateFormatter.formatDate(now, format: 'yyyy-MM-dd');
        to = from;
        break;
      case 'week':
        from = DateFormatter.formatDate(
          now.subtract(const Duration(days: 7)),
          format: 'yyyy-MM-dd',
        );
        to = DateFormatter.formatDate(now, format: 'yyyy-MM-dd');
        break;
      case 'month':
        from = DateFormatter.formatDate(
          now.subtract(const Duration(days: 30)),
          format: 'yyyy-MM-dd',
        );
        to = DateFormatter.formatDate(now, format: 'yyyy-MM-dd');
        break;
    }

    context.read<OperationProvider>().setDateFilter(from: from, to: to);
  }

  Future<void> _showCustomDateRangePicker() async {
    DateTime initialFrom = DateTime.now().subtract(const Duration(days: 7));
    DateTime initialTo = DateTime.now();

    if (context.read<OperationProvider>().dateFrom != null) {
      try {
        initialFrom = DateTime.parse(
          context.read<OperationProvider>().dateFrom!,
        );
      } catch (_) {}
    }
    if (context.read<OperationProvider>().dateTo != null) {
      try {
        initialTo = DateTime.parse(context.read<OperationProvider>().dateTo!);
      } catch (_) {}
    }

    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: initialFrom, end: initialTo),
      locale: const Locale('ru'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      context.read<OperationProvider>().setDateFilter(
        from: DateFormatter.formatDate(result.start, format: 'yyyy-MM-dd'),
        to: DateFormatter.formatDate(result.end, format: 'yyyy-MM-dd'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = context.watch<LocalizationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(local.t('operations_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<OperationProvider>().loadOperations();
              context.read<OperationProvider>().loadTodayStats();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          
          _buildSearchBar(local),

          
          _buildFilters(local),

          
          Expanded(
            child: Consumer<OperationProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.operations.isEmpty) {
                  return _buildSkeletonList();
                }

                if (provider.errorMessage != null &&
                    provider.operations.isEmpty) {
                  return ErrorStateWidget(
                    message: provider.errorMessage!,
                    details:
                        '${local.t('operations_title')} — ${provider.errorMessage!}',
                    onRetry: () {
                      provider.loadOperations();
                      provider.loadTodayStats();
                    },
                  );
                }

                if (provider.operations.isEmpty) {
                  return EmptyStateIllustration(
                    type: EmptyStateType.operations,
                    title: local.t('operations_empty'),
                    subtitle: provider.hasActiveFilters
                        ? local.t('operations_filter_empty')
                        : local.t('operations_empty_action'),
                    action: provider.hasActiveFilters
                        ? OutlinedButton.icon(
                            onPressed: () => provider.clearFilters(),
                            icon: const Icon(Icons.clear_all),
                            label: Text(local.t('operations_clear_filters')),
                          )
                        : ElevatedButton.icon(
                            onPressed: () {
                              provider.loadOperations();
                              provider.loadTodayStats();
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(local.t('operations_load')),
                          ),
                  );
                }

                return Column(
                  children: [
                    if (provider.errorMessage != null)
                      ErrorBanner(
                        message: provider.errorMessage!,
                        onRetry: () {
                          provider.loadOperations();
                          provider.loadTodayStats();
                        },
                        onDismiss: () => provider.clearError(),
                      ),

                    if (provider.hasActiveFilters)
                      _buildFoundCount(local, provider.operations.length),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await provider.loadOperations();
                          await provider.loadTodayStats();
                        },
                        child: provider.columnsCount == 2
                            ? _buildTwoColumnList(provider, local)
                            : _buildSingleColumnList(provider, local),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'operations_create',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateOperationScreen(),
            ),
          ).then((result) {
            if (result == true && context.mounted) {
              context.read<OperationProvider>().loadOperations();
              context.read<OperationProvider>().loadTodayStats();
            }
          });
        },
        icon: const Icon(Icons.add),
        label: Text(local.t('operations_create')),
      ),
    );
  }

  Widget _buildSingleColumnList(
    OperationProvider provider,
    LocalizationProvider local,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: provider.operations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final operation = provider.operations[index];
        return StaggeredFadeIn(
          index: index,
          child: OperationCard(
            operation: operation,
            onTap: () => _openOperationDetail(operation),
            onEdit: () => _editOperation(operation),
            onCancel: () => _cancelOperation(context, operation),
          ),
        );
      },
    );
  }

  Widget _buildTwoColumnList(
    OperationProvider provider,
    LocalizationProvider local,
  ) {
    final ops = provider.operations;
    final buys = ops.where((o) => o.operationType == OperationType.buy).toList();
    final sells = ops.where((o) => o.operationType == OperationType.sell).toList();

    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Expanded(
                child: _OperationColumn(
                  title: local.t('operations_sell'),
                  icon: Icons.trending_down_rounded,
                  color: AppColors.sellColor,
                  operations: sells,
                  onTap: _openOperationDetail,
                  onEdit: _editOperation,
                  onCancel: (op) => _cancelOperation(context, op),
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: _OperationColumn(
                  title: local.t('operations_buy'),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.buyColor,
                  operations: buys,
                  onTap: _openOperationDetail,
                  onEdit: _editOperation,
                  onCancel: (op) => _cancelOperation(context, op),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editOperation(Operation operation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOperationScreen(operation: operation),
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        context.read<OperationProvider>().loadOperations();
        context.read<OperationProvider>().loadTodayStats();
      }
    });
  }

  void _cancelOperation(BuildContext context, Operation operation) {
    final local = context.read<LocalizationProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.cancel_outlined,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              local.t('operations_cancel_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          local.t('operations_cancel_confirm').replaceAll('{number}', operation.operationNumber.toString()),
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Theme.of(ctx).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(local.t('operations_cancel_button')),
          ),
          Consumer<OperationProvider>(
            builder: (context, provider, child) {
              return ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        final success = await provider.cancelOperation(
                          operation.id.toString(),
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (success && context.mounted) {
                          context.read<OperationProvider>().loadOperations();
                          context.read<OperationProvider>().loadTodayStats();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(local.t('operations_cancel_success')),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        } else if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.errorMessage ??
                                    local.t('operations_cancel_error'),
                              ),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(local.t('operations_cancel_confirm_button')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openOperationDetail(Operation operation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OperationDetailScreen(
          operation: operation,
          onEdit: () {
            
            context.read<OperationProvider>().loadOperations();
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < 4 ? 12 : 0),
            child: const SkeletonOperationCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(LocalizationProvider local) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: local.t('operations_search_hint'),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _hasSearchText
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: _clearSearch,
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(LocalizationProvider local) {
    return Consumer<OperationProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: local.t('operations_filter_all'),
                            isSelected: provider.operationTypeFilter == null,
                            onSelected: () {
                              provider.setOperationTypeFilter(null);
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: local.t('operations_buy'),
                            isSelected: provider.operationTypeFilter == 'buy',
                            onSelected: () {
                              provider.setOperationTypeFilter('buy');
                            },
                            color: AppColors.buyColor,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: local.t('operations_sell'),
                            isSelected: provider.operationTypeFilter == 'sell',
                            onSelected: () {
                              provider.setOperationTypeFilter('sell');
                            },
                            color: AppColors.sellColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  ColumnsToggle(
                    columnsCount: provider.columnsCount,
                    onChanged: (count) => provider.setColumnsCount(count),
                  ),
                  const SizedBox(width: 4),
                  _SortButton(local: local),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: local.t('operations_filter_period_today'),
                      isSelected: _isPeriodSelected(provider, 'today'),
                      onSelected: () => _setPeriodFilter('today'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: local.t('operations_filter_period_week'),
                      isSelected: _isPeriodSelected(provider, 'week'),
                      onSelected: () => _setPeriodFilter('week'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: local.t('operations_filter_period_month'),
                      isSelected: _isPeriodSelected(provider, 'month'),
                      onSelected: () => _setPeriodFilter('month'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: local.t('operations_filter_period_custom'),
                      isSelected:
                          provider.dateFrom != null &&
                          !_isPeriodSelected(provider, 'today') &&
                          !_isPeriodSelected(provider, 'week') &&
                          !_isPeriodSelected(provider, 'month'),
                      onSelected: _showCustomDateRangePicker,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: local.t('operations_filter_period_all'),
                      isSelected:
                          provider.dateFrom == null && provider.dateTo == null,
                      onSelected: () {
                        provider.setDateFilter(from: null, to: null);
                      },
                    ),
                    const SizedBox(width: 8),
                    
                    Consumer<CurrencyProvider>(
                      builder: (context, currencyProv, child) {
                        return _CurrencyFilterChip(
                          selectedCurrencyId: provider.currencyIdFilter,
                          currencies: currencyProv.foreignCurrencies,
                          onSelected: (id) {
                            provider.setCurrencyIdFilter(id);
                          },
                          local: local,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            if (provider.hasActiveFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      if (_hasSearchText) {
                        _searchController.clear();
                        setState(() => _hasSearchText = false);
                      }
                      provider.clearFilters();
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: Text(local.t('operations_clear_filters')),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _isPeriodSelected(OperationProvider provider, String period) {
    final now = DateTime.now();
    switch (period) {
      case 'today':
        final today = DateFormatter.formatDate(now, format: 'yyyy-MM-dd');
        return provider.dateFrom == today && provider.dateTo == today;
      case 'week':
        final weekAgo = DateFormatter.formatDate(
          now.subtract(const Duration(days: 7)),
          format: 'yyyy-MM-dd',
        );
        final today = DateFormatter.formatDate(now, format: 'yyyy-MM-dd');
        return provider.dateFrom == weekAgo && provider.dateTo == today;
      case 'month':
        final monthAgo = DateFormatter.formatDate(
          now.subtract(const Duration(days: 30)),
          format: 'yyyy-MM-dd',
        );
        final today = DateFormatter.formatDate(now, format: 'yyyy-MM-dd');
        return provider.dateFrom == monthAgo && provider.dateTo == today;
      default:
        return false;
    }
  }

  Widget _buildFoundCount(LocalizationProvider local, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        '${local.t('operations_found')} $count',
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}



/// A vertical column displaying filtered operations with a colored header.
class _OperationColumn extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Operation> operations;
  final void Function(Operation) onTap;
  final void Function(Operation) onEdit;
  final void Function(Operation) onCancel;

  const _OperationColumn({
    required this.title,
    required this.icon,
    required this.color,
    required this.operations,
    required this.onTap,
    required this.onEdit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final local = context.watch<LocalizationProvider>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${operations.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        if (operations.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                local.t('operations_no_results'),
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.4),
                ),
              ),
            ),
          )
        else
          ...List.generate(operations.length, (index) {
            final operation = operations[index];
            final canSwipe = operation.canBeCancelled;
            return Padding(
              padding: EdgeInsets.only(bottom: index < operations.length - 1 ? 8 : 0),
              child: StaggeredFadeIn(
                index: index,
                itemDuration: const Duration(milliseconds: 300),
                child: Slidable(
                  key: ValueKey('col_${operation.id}'),
                  enabled: canSwipe,
                  endActionPane: ActionPane(
                    motion: const BehindMotion(),
                    extentRatio: 0.25,
                    children: [
                      SlidableAction(
                        onPressed: (_) => onCancel(operation),
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        icon: Icons.cancel_outlined,
                        label: context.watch<LocalizationProvider>().t('operation_card_cancel'),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  startActionPane: ActionPane(
                    motion: const BehindMotion(),
                    extentRatio: 0.25,
                    children: [
                      SlidableAction(
                        onPressed: (_) => onEdit(operation),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        icon: Icons.edit_rounded,
                        label: context.watch<LocalizationProvider>().t('operation_card_edit'),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  child: _CompactOperationCard(
                    operation: operation,
                    onTap: () => onTap(operation),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}



class _CompactOperationCard extends StatelessWidget {
  final Operation operation;
  final VoidCallback? onTap;

  const _CompactOperationCard({required this.operation, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBuy = operation.operationType == OperationType.buy;
    final typeColor = isBuy ? AppColors.buyColor : AppColors.sellColor;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isBuy ? Icons.trending_up : Icons.trending_down,
                          color: typeColor,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          operation.operationType.displayName,
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    operation.currencyCode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '№ ${operation.operationNumber}',
                style: TextStyle(fontSize: 10, color: AppColors.textHint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.formatWithSymbol(
                  operation.amount,
                  operation.currencyCode,
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                context.watch<LocalizationProvider>().t('operation_card_rate').replaceAll('{rate}', CurrencyFormatter.formatRate(operation.rate)),
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
              const Divider(height: 12),
              Row(
                children: [
                  Text(
                    CurrencyFormatter.format(operation.totalAmount, symbol: context.watch<LocalizationProvider>().t('general_som')),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    DateFormatter.formatTime(operation.createdAt),
                    style: TextStyle(fontSize: 10, color: AppColors.textHint),
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



class _CurrencyFilterChip extends StatefulWidget {
  final String? selectedCurrencyId;
  final List<dynamic> currencies;
  final ValueChanged<String?> onSelected;
  final LocalizationProvider local;

  const _CurrencyFilterChip({
    required this.selectedCurrencyId,
    required this.currencies,
    required this.onSelected,
    required this.local,
  });

  @override
  State<_CurrencyFilterChip> createState() => _CurrencyFilterChipState();
}

class _CurrencyFilterChipState extends State<_CurrencyFilterChip> {
  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedCurrencyId != null;
    String label = widget.local.t('operations_filter_currency');
    if (isSelected) {
      try {
        final currency = widget.currencies.firstWhere(
          (c) => c.id.toString() == widget.selectedCurrencyId,
        );
        label = currency.code;
      } catch (_) {
        label = widget.local.t('operations_filter_currency');
      }
    }

    return InkWell(
      onTap: () => _showCurrencyPicker(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.currency_exchange,
              size: 14,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.local.t('operations_filter_currency_title'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: Text(widget.local.t('operations_filter_currency_all')),
                selected: widget.selectedCurrencyId == null,
                onTap: () {
                  widget.onSelected(null);
                  Navigator.pop(ctx);
                },
              ),
              ...widget.currencies.map((currency) {
                final isSelected =
                    currency.id.toString() == widget.selectedCurrencyId;
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        currency.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  title: Text('${currency.code} - ${currency.name}'),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  selected: isSelected,
                  onTap: () {
                    widget.onSelected(currency.id.toString());
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}



class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? chipColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final LocalizationProvider local;

  const _SortButton({required this.local});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OperationProvider>();
    return PopupMenuButton<String>(
      onSelected: (value) => provider.setOrdering(value),
      icon: const Icon(Icons.sort, size: 22),
      tooltip: local.t('operations_filter_sort'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: '-created_at',
          child: Row(
            children: [
              if (provider.ordering == '-created_at')
                const Icon(Icons.check, size: 18, color: AppColors.primary),
              if (provider.ordering == '-created_at') const SizedBox(width: 8),
              Text(local.t('operations_filter_sort_newest')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'created_at',
          child: Row(
            children: [
              if (provider.ordering == 'created_at')
                const Icon(Icons.check, size: 18, color: AppColors.primary),
              if (provider.ordering == 'created_at') const SizedBox(width: 8),
              Text(local.t('operations_filter_sort_oldest')),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: '-amount',
          child: Row(
            children: [
              if (provider.ordering == '-amount')
                const Icon(Icons.check, size: 18, color: AppColors.primary),
              if (provider.ordering == '-amount') const SizedBox(width: 8),
              Text(local.t('operations_filter_sort_amount_desc')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'amount',
          child: Row(
            children: [
              if (provider.ordering == 'amount')
                const Icon(Icons.check, size: 18, color: AppColors.primary),
              if (provider.ordering == 'amount') const SizedBox(width: 8),
              Text(local.t('operations_filter_sort_amount_asc')),
            ],
          ),
        ),
      ],
    );
  }
}
