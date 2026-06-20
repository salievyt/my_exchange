import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A toggle button group to switch between 1-column (list) and 2-column (grid) layouts.
class ColumnsToggle extends StatelessWidget {
  final int columnsCount;
  final ValueChanged<int> onChanged;

  const ColumnsToggle({
    super.key,
    required this.columnsCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            icon: Icons.view_list,
            isSelected: columnsCount == 1,
            onTap: () => onChanged(1),
          ),
          _ToggleButton(
            icon: Icons.grid_view,
            isSelected: columnsCount == 2,
            onTap: () => onChanged(2),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}
