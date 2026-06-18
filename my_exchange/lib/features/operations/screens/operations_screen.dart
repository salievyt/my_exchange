import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../presentation/providers/operation_provider.dart';
import '../../../presentation/widgets/operation_card.dart';
import '../../../presentation/widgets/error_widgets.dart';
import '../../../presentation/widgets/skeleton_widgets.dart';
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
          // Search bar
          _buildSearchBar(local),

          // Filter chips
          _buildFilterChips(local),

          // Today stats
          // _buildTodayStats(),

          // Operations list
          Expanded(
            child: Consumer<OperationProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.operations.isEmpty) {
                  return _buildSkeletonList();
                }

                // Error state with retry (no data)
                if (provider.errorMessage != null &&
                    provider.operations.isEmpty) {
                  return ErrorStateWidget(
                    message: provider.errorMessage!,
                    details: '${local.t('operations_title')} — ${provider.errorMessage!}',
                    onRetry: () {
                      provider.loadOperations();
                      provider.loadTodayStats();
                    },
                  );
                }

                if (provider.operations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.hasActiveFilters
                              ? local.t('operations_empty')
                              : local.t('operations_empty'),
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (provider.hasActiveFilters)
                          OutlinedButton.icon(
                            onPressed: () => provider.clearFilters(),
                            icon: const Icon(Icons.clear_all),
                            label: Text(local.t('operations_clear_filters')),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () {
                              provider.loadOperations();
                              provider.loadTodayStats();
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(local.t('operations_load')),
                          ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Error banner when refresh fails but we have data
                    if (provider.errorMessage != null)
                      ErrorBanner(
                        message: provider.errorMessage!,
                        onRetry: () {
                          provider.loadOperations();
                          provider.loadTodayStats();
                        },
                        onDismiss: () => provider.clearError(),
                      ),

                    // Found count
                    if (provider.hasActiveFilters)
                      _buildFoundCount(local, provider.operations.length),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await provider.loadOperations();
                          await provider.loadTodayStats();
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: provider.operations.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final operation = provider.operations[index];
                            return OperationCard(
                              operation: operation,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OperationDetailScreen(
                                      operation: operation,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateOperationScreen(),
            ),
          ).then((_) {
            if (!context.mounted) return;
            context.read<OperationProvider>().loadOperations();
            context.read<OperationProvider>().loadTodayStats();
          });
        },
        icon: const Icon(Icons.add),
        label: Text(local.t('operations_create')),
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

  Widget _buildFilterChips(LocalizationProvider local) {
    return Consumer<OperationProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Type and period filter row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Operation type chips
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: local.t('operations_filter_all'),
                            isSelected:
                                provider.operationTypeFilter == null,
                            onSelected: () {
                              provider.setOperationTypeFilter(null);
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: local.t('operations_buy'),
                            isSelected:
                                provider.operationTypeFilter == 'buy',
                            onSelected: () {
                              provider.setOperationTypeFilter('buy');
                            },
                            color: AppColors.buyColor,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: local.t('operations_sell'),
                            isSelected:
                                provider.operationTypeFilter == 'sell',
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
                  // Sort dropdown
                  _SortButton(local: local),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Period chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: local.t('operations_filter_period_today'),
                      isSelected:
                          provider.dateFrom ==
                              DateFormatter.formatDate(
                                DateTime.now(),
                                format: 'yyyy-MM-dd',
                              ) &&
                          provider.dateTo ==
                              DateFormatter.formatDate(
                                DateTime.now(),
                                format: 'yyyy-MM-dd',
                              ),
                      onSelected: () => _setPeriodFilter('today'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: local.t('operations_filter_period_week'),
                      isSelected:
                          provider.dateFrom ==
                              DateFormatter.formatDate(
                                DateTime.now().subtract(
                                  const Duration(days: 7),
                                ),
                                format: 'yyyy-MM-dd',
                              ),
                      onSelected: () => _setPeriodFilter('week'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: local.t('operations_filter_period_month'),
                      isSelected:
                          provider.dateFrom ==
                              DateFormatter.formatDate(
                                DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                format: 'yyyy-MM-dd',
                              ),
                      onSelected: () => _setPeriodFilter('month'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: local.t('operations_filter_period_all'),
                      isSelected:
                          provider.dateFrom == null &&
                          provider.dateTo == null,
                      onSelected: () {
                        provider.setDateFilter(from: null, to: null);
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Clear filters button
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

  Widget _buildTodayStats() {
    return Consumer<OperationProvider>(
      builder: (context, provider, child) {
        final stats = provider.todayStats;
        if (provider.isLoading && stats == null) {
          return const SkeletonTodayStats();
        }
        if (stats == null) return const SizedBox.shrink();

        final buyCount = stats['buy_count'] ?? 0;
        final sellCount = stats['sell_count'] ?? 0;
        final buyAmount = (stats['buy_amount'] as num?)?.toDouble() ?? 0.0;
        final sellAmount = (stats['sell_amount'] as num?)?.toDouble() ?? 0.0;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.today, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    context.watch<LocalizationProvider>().t('operations_today'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: Icons.trending_up,
                      color: AppColors.buyColor,
                      label: context.watch<LocalizationProvider>().t('operations_buys'),
                      value: '$buyCount',
                      amount: CurrencyFormatter.format(
                        buyAmount,
                        symbol: 'сом',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.trending_down,
                      color: AppColors.sellColor,
                      label: context.watch<LocalizationProvider>().t('operations_sells'),
                      value: '$sellCount',
                      amount: CurrencyFormatter.format(
                        sellAmount,
                        symbol: 'сом',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String amount;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
              if (provider.ordering == '-created_at')
                const SizedBox(width: 8),
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
              if (provider.ordering == 'created_at')
                const SizedBox(width: 8),
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
              if (provider.ordering == '-amount')
                const SizedBox(width: 8),
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
              if (provider.ordering == 'amount')
                const SizedBox(width: 8),
              Text(local.t('operations_filter_sort_amount_asc')),
            ],
          ),
        ),
      ],
    );
  }
}
