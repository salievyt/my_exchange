import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Interactive operations bar chart with animated touch tooltips
class OperationsBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> dailyData;
  final bool compact;

  const OperationsBarChart({
    super.key,
    required this.dailyData,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (dailyData.isEmpty) {
      return const _EmptyChartPlaceholder(text: 'Нет данных за период');
    }

    final maxOps = dailyData.fold<int>(
      0,
      (prev, d) =>
          (d['operations'] as int? ?? 0) > prev
              ? (d['operations'] as int? ?? 0)
              : prev,
    );

    final height = compact ? 160.0 : 220.0;

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.only(
          left: compact ? 4 : 8,
          right: compact ? 8 : 16,
          top: 16,
          bottom: compact ? 4 : 8,
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (maxOps * 1.3).ceilToDouble().clamp(1, double.infinity),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                tooltipPadding: const EdgeInsets.all(10),
                getTooltipColor: (_) => isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFF1E1E1E),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final dayData = dailyData[groupIndex];
                  final date = dayData['date'] as String? ?? '';
                  final buy = dayData['buy_count'] as int? ?? 0;
                  final sell = dayData['sell_count'] as int? ?? 0;
                  final parts = date.split('-');
                  final label = parts.length >= 3
                      ? '${parts[2]}.${parts[1]}.${parts[0]}'
                      : date;
                  return BarTooltipItem(
                    '$label\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: 'Покупка: $buy  •  Продажа: $sell',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: compact ? 22 : 28,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= dailyData.length) {
                      return const SizedBox.shrink();
                    }
                    final date = dailyData[idx]['date'] as String? ?? '';
                    final parts = date.split('-');
                    final label = parts.length >= 3
                        ? '${parts[2]}.${parts[1]}'
                        : date;
                    return Padding(
                      padding: EdgeInsets.only(top: compact ? 4 : 8),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: compact ? 9 : 10,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                  interval: dailyData.length > 14 ? 2 : 1,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: compact ? 24 : 32,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(
                        fontSize: compact ? 9 : 10,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval:
                  (maxOps * 1.3 / 4).ceilToDouble().clamp(1, double.infinity),
              getDrawingHorizontalLine: (value) => FlLine(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.textHint.withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            barGroups: _buildBarGroups(),
          ),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final barWidth = compact ? 6.0 : 10.0;
    return dailyData.asMap().entries.map((entry) {
      final idx = entry.key;
      final day = entry.value;
      final buy = (day['buy_count'] as int? ?? 0).toDouble();
      final sell = (day['sell_count'] as int? ?? 0).toDouble();

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: buy,
            color: AppColors.buyColor,
            width: barWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: sell,
            color: AppColors.sellColor,
            width: barWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }
}

/// Interactive currency popularity chart
class CurrencyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> currencyStats;

  const CurrencyBarChart({super.key, required this.currencyStats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topCurrencies = currencyStats.take(6).toList();

    if (topCurrencies.isEmpty) {
      return const _EmptyChartPlaceholder(text: 'Нет данных');
    }

    final maxOps = topCurrencies.fold<int>(
      0,
      (prev, c) =>
          (c['operations'] as int? ?? 0) > prev
              ? (c['operations'] as int? ?? 0)
              : prev,
    );

    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 8),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (maxOps * 1.3).ceilToDouble().clamp(1, double.infinity),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                tooltipPadding: const EdgeInsets.all(10),
                getTooltipColor: (_) => isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFF1E1E1E),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final curr = topCurrencies[groupIndex];
                  final code = curr['currency'] as String? ?? '';
                  final ops = curr['operations'] as int? ?? 0;
                  final turnover =
                      (curr['turnover'] as num?)?.toDouble() ?? 0.0;
                  return BarTooltipItem(
                    '$code\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text:
                            'Операций: $ops\nОборот: ${CurrencyFormatter.format(turnover, symbol: 'сом')}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= topCurrencies.length) {
                      return const SizedBox.shrink();
                    }
                    final code = topCurrencies[idx]['currency'] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        code,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval:
                  (maxOps * 1.3 / 4).ceilToDouble().clamp(1, double.infinity),
              getDrawingHorizontalLine: (value) => FlLine(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.textHint.withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            barGroups: _buildBarGroups(topCurrencies),
          ),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<Map<String, dynamic>> currencies) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      AppColors.error,
    ];

    return currencies.asMap().entries.map((entry) {
      final idx = entry.key;
      final curr = entry.value;
      final ops = (curr['operations'] as int? ?? 0).toDouble();
      final color = colors[idx % colors.length];

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: ops,
            color: color.withValues(alpha: 0.85),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }
}

/// Profitability horizontal bar chart with color-coded bars
class ProfitabilityChart extends StatelessWidget {
  final List<Map<String, dynamic>> profitability;

  const ProfitabilityChart({super.key, required this.profitability});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = profitability.take(6).toList();

    if (data.isEmpty) {
      return const _EmptyChartPlaceholder(text: 'Нет данных о рентабельности');
    }

    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 8),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                tooltipPadding: const EdgeInsets.all(10),
                getTooltipColor: (_) => isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFF1E1E1E),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final d = data[groupIndex];
                  final code = d['currency'] as String? ?? '';
                  final spread = (d['spread'] as num?)?.toDouble() ?? 0.0;
                  final percent =
                      (d['spread_percent'] as num?)?.toDouble() ?? 0.0;
                  return BarTooltipItem(
                    '$code\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text:
                            'Прибыль: ${CurrencyFormatter.format(spread, symbol: 'сом')}\nМаржа: ${CurrencyFormatter.formatRate(percent)}%',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= data.length) {
                      return const SizedBox.shrink();
                    }
                    final code = data[idx]['currency'] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        code,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(
                      '${value.toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (value) => FlLine(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.textHint.withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            barGroups: _buildBarGroups(data),
          ),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<Map<String, dynamic>> items) {
    return items.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      final percent = (item['spread_percent'] as num?)?.toDouble() ?? 0.0;

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: percent.clamp(0, 100),
            color: percent > 5
                ? AppColors.success
                : percent > 2
                    ? AppColors.warning
                    : AppColors.error,
            width: 18,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }
}

/// Chart legend widget
class ChartLegend extends StatelessWidget {
  final List<LegendItem> items;

  const ChartLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class LegendItem {
  final Color color;
  final String label;

  const LegendItem({required this.color, required this.label});
}

/// Empty state placeholder for charts
class _EmptyChartPlaceholder extends StatelessWidget {
  final String text;

  const _EmptyChartPlaceholder({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 40,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : AppColors.textHint,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
