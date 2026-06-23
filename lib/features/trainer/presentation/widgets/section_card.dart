import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Card de seção com título
class SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final VoidCallback? onTap;
  final String? actionLabel;

  const SectionCard({
    super.key,
    required this.title,
    this.icon,
    required this.child,
    this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.headlineSmall,
                  ),
                ),
                if (onTap != null)
                  TextButton(
                    onPressed: onTap,
                    child: Text(
                      actionLabel ?? 'Ver mais',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.surfaceLight),

          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}