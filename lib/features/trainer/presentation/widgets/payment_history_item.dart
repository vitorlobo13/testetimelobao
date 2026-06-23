import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Item do histórico de pagamentos
class PaymentHistoryItem extends StatelessWidget {
  final DateTime date;
  final double amount;
  final bool paid;
  final String? reference;

  const PaymentHistoryItem({
    super.key,
    required this.date,
    required this.amount,
    required this.paid,
    this.reference,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: paid ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ícone
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: paid
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.error.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              paid ? Icons.check_circle : Icons.error,
              color: paid ? AppColors.success : AppColors.error,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Informações
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currencyFormat.format(amount),
                  style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM yyyy', 'pt_BR').format(date),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (reference != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    reference!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: paid
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              paid ? 'PAGO' : 'PENDENTE',
              style: AppTextStyles.bodySmall.copyWith(
                color: paid ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}