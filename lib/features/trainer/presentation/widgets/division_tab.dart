import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Etiqueta (pílula) de divisão do treino: nome + nº de exercícios em uma
/// linha só, altura fixa de 44 px (cabe sem espremer).
class DivisionTab extends StatelessWidget {
  final String name;
  final int exerciseCount;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const DivisionTab({
    super.key,
    required this.name,
    required this.exerciseCount,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isSelected ? Colors.white : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? AppColors.blue : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? AppColors.blue : AppColors.outline,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 44,
            padding: EdgeInsets.only(
                left: 16, right: onDelete != null && !isSelected ? 8 : 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$exerciseCount',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppColors.textTertiary,
                  ),
                ),
                if (onDelete != null && !isSelected) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Remover divisão',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: onDelete,
                    icon: const Icon(Icons.close,
                        size: 16, color: AppColors.textTertiary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
