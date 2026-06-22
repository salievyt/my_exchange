import 'package:flutter/material.dart';

class MadeByFooter extends StatelessWidget {
  final String? version;
  final String appName;

  const MadeByFooter({super.key, this.version, required this.appName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final mutedColor = isDark
        ? Colors.white.withValues(alpha: 0.30)
        : Colors.black.withValues(alpha: 0.25);
    final accentColor = isDark
        ? Colors.white.withValues(alpha: 0.50)
        : Colors.black.withValues(alpha: 0.45);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Thin divider
        Container(height: 1, color: dividerColor),
        const SizedBox(height: 20),

        // Logo
        Container(
          width: 120,
          height: 36,
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/made_by_deo.png',
            fit: BoxFit.contain,
            height: 36,
            color: isDark ? Colors.white : null,
          ),
        ),
        const SizedBox(height: 8),

        // Version + studio on one line
        Text(
          [
            if (version != null) 'v$version',
            '$appName',
          ].join('  ·  '),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
            color: mutedColor,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),

        // Tagline
        Text(
          'Сделано с любовью',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: accentColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
