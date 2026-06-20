import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/operation.dart';
import '../../operations/screens/create_operation_screen.dart';

class OperationDetailScreen extends StatelessWidget {
  final Operation operation;
  final VoidCallback? onEdit;

  const OperationDetailScreen({super.key, required this.operation, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isBuy = operation.operationType == OperationType.buy;
    final typeColor = isBuy ? colors.tertiary : colors.error;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar with gradient ─────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      typeColor,
                      typeColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DotsPatternPainter(),
                      ),
                    ),
                    // Main info overlay
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Badge(
                                label: operation.operationType.displayName,
                                color: Colors.white,
                                bgColor: Colors.white.withValues(alpha: 0.25),
                              ),
                              const SizedBox(width: 8),
                              _Badge(
                                label: operation.status.displayName,
                                color: Colors.white,
                                bgColor: Colors.white.withValues(alpha: 0.25),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '№ ${operation.operationNumber}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${operation.currencyCode} • ${operation.currencyName}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Edit button
              if (operation.canBeCancelled)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  tooltip: 'Редактировать',
                  onPressed: () => _editOperation(context),
                ),
            ],
          ),

          // ── Body content ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Amount section — prominent
                _SectionCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _InfoBlock(
                              label: 'Сумма операции',
                              value: CurrencyFormatter.formatWithSymbol(
                                operation.amount,
                                operation.currencyCode,
                              ),
                              valueStyle: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Курс',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.formatRate(operation.rate),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: typeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Icon(
                            Icons.calculate,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Итого в сомах',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyFormatter.format(
                              operation.totalAmount,
                              symbol: 'сом',
                            ),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Client info section
                if (operation.clientName != null ||
                    operation.clientCompany != null)
                  _SectionCard(
                    title: 'Клиент',
                    icon: Icons.person_outline,
                    child: Column(
                      children: [
                        if (operation.clientName != null)
                          _InfoRow(
                            label: 'Имя',
                            value: operation.clientName!,
                          ),
                        if (operation.clientCompany != null) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'Компания',
                            value: operation.clientCompany!,
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Cashier & details section
                _SectionCard(
                  title: 'Детали',
                  icon: Icons.info_outline,
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Кассир',
                        value: operation.cashierName,
                        trailing: Text(
                          '@${operation.cashierUsername}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.outline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Дата создания',
                        value: DateFormatter.formatDateTime(
                          operation.createdAt,
                          format: 'dd.MM.yyyy HH:mm',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Последнее изменение',
                        value: DateFormatter.formatDateTime(
                          operation.updatedAt,
                          format: 'dd.MM.yyyy HH:mm',
                        ),
                      ),
                      if (operation.id > 0) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          label: 'ID операции',
                          value: '#${operation.id}',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Comment section
                if (operation.comment != null &&
                    operation.comment!.isNotEmpty)
                  _SectionCard(
                    title: 'Комментарий',
                    icon: Icons.notes_rounded,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        operation.comment!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),

                // Edit button at bottom
                if (operation.canBeCancelled)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _editOperation(context),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Редактировать операцию'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Status timeline
                _SectionCard(
                  title: 'Статус',
                  icon: Icons.timeline_rounded,
                  child: _StatusTimeline(status: operation.status),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _editOperation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOperationScreen(
          operation: operation,
        ),
      ),
    ).then((result) {
      if (result == true) {
        onEdit?.call();
        if (context.mounted) {
          Navigator.pop(context); // Go back to list
        }
      }
    });
  }
}

// ─── Sub-widgets (kept from original) ─────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget child;

  const _SectionCard({
    this.title,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
            ],
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoBlock({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _DotsPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    const radius = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatusTimeline extends StatelessWidget {
  final OperationStatus status;

  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final steps = [
      _TimelineStepData(
        label: 'Операция создана',
        subtitle: 'Проведена в системе',
        isCompleted: true,
        isLast: false,
      ),
      _TimelineStepData(
        label: status == OperationStatus.active
            ? 'Исполнена'
            : status == OperationStatus.cancelled
                ? 'Отменена'
                : 'Частично отменена',
        subtitle: status == OperationStatus.active
            ? 'Операция завершена успешно'
            : status == OperationStatus.cancelled
                ? 'Операция отменена'
                : 'Часть операции отменена',
        isCompleted: true,
        isLast: true,
        color: status == OperationStatus.active
            ? colors.tertiary
            : status == OperationStatus.cancelled
                ? colors.error
                : Colors.orange,
      ),
    ];

    return Column(
      children: steps.map((step) => _TimelineStepWidget(data: step)).toList(),
    );
  }
}

class _TimelineStepData {
  final String label;
  final String subtitle;
  final bool isCompleted;
  final bool isLast;
  final Color? color;

  const _TimelineStepData({
    required this.label,
    required this.subtitle,
    required this.isCompleted,
    required this.isLast,
    this.color,
  });
}

class _TimelineStepWidget extends StatelessWidget {
  final _TimelineStepData data;

  const _TimelineStepWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dotColor = data.color ?? colors.tertiary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: Border.all(
                      color: dotColor.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                ),
                if (!data.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colors.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: data.isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    data.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
