import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/student_entity.dart';

/// Card de aluno resumido
class StudentCard extends StatelessWidget {
  final StudentEntity student;
  final VoidCallback onTap;

  const StudentCard({
    super.key,
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.surfaceLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(),

            const SizedBox(width: 16),

            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome
                  Text(
                    student.name,
                    style: AppTextStyles.headlineSmall.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Status e último treino
                  Row(
                    children: [
                      _buildStatusBadge(),
                      const SizedBox(width: 8),
                      if (student.daysSinceLastWorkout != null)
                        Text(
                          'Último treino: ${student.daysSinceLastWorkout}d atrás',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Indicador de pagamento
            if (student.isPaymentOverdue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Atrasado',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else if (student.paymentStatus == PaymentStatus.paid)
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: student.photoUrl != null
          ? ClipOval(
              child: Image.network(
                student.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitials(),
              ),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    final initials = student.name
        .split(' ')
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();

    return Center(
      child: Text(
        initials,
        style: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (student.status) {
      case StudentStatus.active:
        color = AppColors.success;
        text = 'Ativo';
        break;
      case StudentStatus.inactive:
        color = AppColors.textTertiary;
        text = 'Inativo';
        break;
      case StudentStatus.suspended:
        color = AppColors.error;
        text = 'Suspenso';
        break;
      case StudentStatus.trial:
        color = AppColors.warning;
        text = 'Trial';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}