import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Card de seleção de perfil (Professor ou Aluno)
class ProfileCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final List<String> features;

  const ProfileCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isSelected
              ? AppColors.primaryGradient
              : LinearGradient(
                  colors: [AppColors.surface, AppColors.surface],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.surfaceLight,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? AppColors.shadowLarge
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com ícone e checkbox
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ícone
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.teal,
                  ),
                ),

                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textTertiary,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 20,
                          color: AppColors.teal,
                        )
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Título
            Text(
              title,
              style: AppTextStyles.headlineMedium.copyWith(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // Descrição
            Text(
              description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? AppColors.textPrimary.withValues(alpha: 0.9)
                    : AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            // Divisor
            Container(
              height: 1,
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.surfaceLight,
            ),

            const SizedBox(height: 16),

            // Features
            ...features.map((feature) => _buildFeatureItem(feature, isSelected)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 18,
            color: isSelected
                ? AppColors.textPrimary
                : AppColors.teal,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? AppColors.textPrimary.withValues(alpha: 0.9)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}