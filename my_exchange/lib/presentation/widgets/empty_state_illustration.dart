import 'dart:math' show cos, sin, pi;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// A beautiful empty state widget with a custom painted illustration.
/// Supports two illustration types: [EmptyStateType.operations] and
/// [EmptyStateType.cash].
class EmptyStateIllustration extends StatelessWidget {
  final EmptyStateType type;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double illustrationSize;

  const EmptyStateIllustration({
    super.key,
    required this.type,
    required this.title,
    this.subtitle,
    this.action,
    this.illustrationSize = 180,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Illustration ────────────────────────────────────
            SizedBox(
              width: illustrationSize,
              height: illustrationSize,
              child: type == EmptyStateType.operations
                  ? _OperationsIllustration(isDark: isDark)
                  : _CashIllustration(isDark: isDark),
            ),
            const SizedBox(height: 32),

            // ── Title ───────────────────────────────────────────
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                height: 1.3,
              ),
            ),

            // ── Subtitle ────────────────────────────────────────
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.4),
                  height: 1.4,
                ),
              ),
            ],

            // ── Action button ───────────────────────────────────
            if (action != null) ...[
              const SizedBox(height: 28),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Available illustration types
enum EmptyStateType { operations, cash }

// ═══════════════════════════════════════════════════════════════════
//  Operations Illustration — A stylized receipt with decorative curves
// ═══════════════════════════════════════════════════════════════════

class _OperationsIllustration extends StatelessWidget {
  final bool isDark;
  const _OperationsIllustration({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OperationsPainter(isDark: isDark),
      size: const Size.square(180),
    );
  }
}

class _OperationsPainter extends CustomPainter {
  final bool isDark;

  _OperationsPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Colors
    final primaryColor = isDark
        ? AppColors.primary.withValues(alpha: 0.6)
        : AppColors.primary;
    final accentColor = isDark
        ? AppColors.buyColor.withValues(alpha: 0.5)
        : AppColors.buyColor;
    final highlightColor = isDark
        ? AppColors.sellColor.withValues(alpha: 0.4)
        : AppColors.sellColor;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.primary.withValues(alpha: 0.06);

    // Draw background circle
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), size.width * 0.45, bgPaint);

    // Draw decorative dots around the circle
    final dotPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi - 1.57;
      final dotX = centerX + (size.width * 0.40) * cos(angle);
      final dotY = centerY + (size.width * 0.40) * sin(angle);
      canvas.drawCircle(Offset(dotX, dotY), 3, dotPaint);
    }

    // Draw receipt body
    final receiptRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY - 4),
        width: 52,
        height: 68,
      ),
      const Radius.circular(6),
    );

    final receiptBgPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(receiptRect, receiptBgPaint);

    final receiptBorderPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(receiptRect, receiptBorderPaint);

    // Draw receipt top decorative line
    final topLinePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX - 14, centerY - 24),
      Offset(centerX + 14, centerY - 24),
      topLinePaint,
    );

    // Draw receipt lines (simulated text)
    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.2)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX - 14, centerY - 14),
      Offset(centerX + 10, centerY - 14),
      linePaint,
    );
    canvas.drawLine(
      Offset(centerX - 14, centerY - 8),
      Offset(centerX + 14, centerY - 8),
      linePaint,
    );
    canvas.drawLine(
      Offset(centerX - 14, centerY - 2),
      Offset(centerX + 8, centerY - 2),
      linePaint,
    );

    // Draw divider
    final dividerPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(centerX - 14, centerY + 4),
      Offset(centerX + 14, centerY + 4),
      dividerPaint,
    );

    // Bottom line
    canvas.drawLine(
      Offset(centerX - 14, centerY + 10),
      Offset(centerX + 12, centerY + 10),
      linePaint,
    );
    canvas.drawLine(
      Offset(centerX - 14, centerY + 16),
      Offset(centerX + 6, centerY + 16),
      linePaint,
    );

    // Draw the receipt zigzag bottom cut
    final zigzagPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(centerX - 26, centerY + 30);
    path.lineTo(centerX - 26, centerY + 24);
    for (int i = 0; i < 6; i++) {
      final x = centerX - 26 + (52 / 6) * i;
      if (i.isEven) {
        path.lineTo(x + 52 / 12, centerY + 20);
      } else {
        path.lineTo(x + 52 / 12, centerY + 24);
      }
    }
    path.lineTo(centerX + 26, centerY + 30);
    path.close();
    canvas.drawPath(path, zigzagPaint);

    // Draw small checkmark circle
    final checkBgPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(centerX + 24, centerY - 26),
      16,
      checkBgPaint,
    );
    final checkPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final checkPath = Path()
      ..moveTo(centerX + 19, centerY - 26)
      ..lineTo(centerX + 23, centerY - 22)
      ..lineTo(centerX + 29, centerY - 30);
    canvas.drawPath(checkPath, checkPaint);

    // Draw small decorative arrow
    final arrowPaint = Paint()
      ..color = highlightColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final arrowPath = Path()
      ..moveTo(centerX - 38, centerY + 6)
      ..lineTo(centerX - 28, centerY + 6)
      ..lineTo(centerX - 32, centerY + 2);
    canvas.drawPath(arrowPath, arrowPaint);
    final arrowPath2 = Path()
      ..moveTo(centerX + 28, centerY - 6)
      ..lineTo(centerX + 38, centerY - 6)
      ..lineTo(centerX + 34, centerY - 2);
    canvas.drawPath(arrowPath2, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  Cash Illustration — A stylized coin stack with decorative elements
// ═══════════════════════════════════════════════════════════════════

class _CashIllustration extends StatelessWidget {
  final bool isDark;
  const _CashIllustration({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CashPainter(isDark: isDark),
      size: const Size.square(180),
    );
  }
}

class _CashPainter extends CustomPainter {
  final bool isDark;

  _CashPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Colors
    final primaryColor = isDark
        ? AppColors.primary.withValues(alpha: 0.6)
        : AppColors.primary;
    final accentColor = isDark
        ? Colors.amber.withValues(alpha: 0.5)
        : Colors.amber.shade700;
    final highlightColor = isDark
        ? AppColors.buyColor.withValues(alpha: 0.4)
        : AppColors.buyColor;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.primary.withValues(alpha: 0.06);

    // Draw background circle
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), size.width * 0.45, bgPaint);

    // Draw decorative dots
    final dotPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * pi - 1.57;
      final dotX = centerX + (size.width * 0.38) * cos(angle);
      final dotY = centerY + (size.width * 0.38) * sin(angle);
      canvas.drawCircle(Offset(dotX, dotY), 3.5, dotPaint);
    }

    // Draw coin stack
    final coinColors = [
      accentColor.withValues(alpha: 0.9),
      accentColor.withValues(alpha: 0.7),
      accentColor.withValues(alpha: 0.5),
      accentColor.withValues(alpha: 0.35),
    ];

    // Stack offset for 3D effect
    const stackOffset = 3.5;

    for (int i = coinColors.length - 1; i >= 0; i--) {
      final yOffset = centerY - 10 - stackOffset * i;
      final coinRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX - 20 + stackOffset * i, yOffset),
          width: 42,
          height: 18,
        ),
        const Radius.circular(9),
      );

      // Coin body
      final coinPaint = Paint()
        ..color = coinColors[i]
        ..style = PaintingStyle.fill;
      canvas.drawRRect(coinRect, coinPaint);

      // Coin border
      final coinBorderPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(coinRect, coinBorderPaint);

      // Coin inner circle (emboss effect)
      if (i == 0) {
        final innerPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(centerX - 20, yOffset),
          5,
          innerPaint,
        );
      }
    }

    // Draw a small plus badge on the right
    final plusBgPaint = Paint()
      ..color = highlightColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(centerX + 28, centerY - 20),
      14,
      plusBgPaint,
    );
    final plusPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX + 24, centerY - 20),
      Offset(centerX + 32, centerY - 20),
      plusPaint,
    );
    canvas.drawLine(
      Offset(centerX + 28, centerY - 24),
      Offset(centerX + 28, centerY - 16),
      plusPaint,
    );

    // Draw decorative curved lines
    final curvePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final curvePath1 = Path()
      ..moveTo(centerX - 44, centerY + 18)
      ..quadraticBezierTo(
        centerX - 30, centerY + 28,
        centerX - 16, centerY + 18,
      );
    canvas.drawPath(curvePath1, curvePaint);

    final curvePath2 = Path()
      ..moveTo(centerX + 16, centerY + 18)
      ..quadraticBezierTo(
        centerX + 30, centerY + 28,
        centerX + 44, centerY + 18,
      );
    canvas.drawPath(curvePath2, curvePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
