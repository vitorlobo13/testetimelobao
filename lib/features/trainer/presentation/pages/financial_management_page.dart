import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/trainer_provider.dart';
import '../../domain/entities/student_entity.dart';

/// Tela de Gestão Financeira para Personal Trainers
class FinancialManagementPage extends ConsumerWidget {
  const FinancialManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(trainerDashboardProvider);
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    // Filtra alunos com pagamentos pendentes ou atrasados
    final pendingStudents = dashboardState.students.where((s) =>
        s.paymentStatus == PaymentStatus.pending ||
        s.paymentStatus == PaymentStatus.overdue).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('GESTÃO FINANCEIRA', style: AppTextStyles.displaySmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: dashboardState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cards de Resumo Financeiro
                  _buildSummarySection(dashboardState, currencyFormat),
                  const SizedBox(height: 24),

                  // Lista de Pendências
                  Text(
                    'PAGAMENTOS PENDENTES OU ATRASADOS',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (pendingStudents.isEmpty)
                    _buildNoPendenciesCard()
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pendingStudents.length,
                      itemBuilder: (context, index) {
                        final student = pendingStudents[index];
                        return _PendingPaymentCard(
                          student: student,
                          currencyFormat: currencyFormat,
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // Histórico Recente de Recebimentos
                  Text(
                    'RECEBIMENTOS RECENTES',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentTransactionsSection(dashboardState, currencyFormat),
                ],
              ),
            ),
    );
  }

  Widget _buildSummarySection(TrainerDashboardState state, NumberFormat format) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Faturamento',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  format.format(state.monthlyRevenue),
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Este mês (estimado)',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Atrasados',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${state.pendingPayments} pendentes',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Necessitam cobrança',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoPendenciesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
          SizedBox(height: 12),
          Text(
            'Tudo em dia!',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Não há mensalidades atrasadas ou pendentes.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection(TrainerDashboardState state, NumberFormat format) {
    final paidStudents = state.students
        .where((s) => s.paymentStatus == PaymentStatus.paid && s.monthlyFee != null)
        .toList();

    if (paidStudents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Nenhum pagamento recebido recentemente.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: paidStudents.length,
        separatorBuilder: (context, index) => const Divider(color: AppColors.surfaceLight, height: 1),
        itemBuilder: (context, index) {
          final student = paidStudents[index];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.surfaceLight,
              child: Icon(Icons.arrow_downward, color: AppColors.success, size: 20),
            ),
            title: Text(student.name, style: AppTextStyles.bodyLarge),
            subtitle: Text('Mensalidade Plano ${student.planType ?? "Regular"}', style: AppTextStyles.bodySmall),
            trailing: Text(
              format.format(student.monthlyFee),
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.success),
            ),
          );
        },
      ),
    );
  }
}

class _PendingPaymentCard extends StatelessWidget {
  final StudentEntity student;
  final NumberFormat currencyFormat;

  const _PendingPaymentCard({
    required this.student,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = student.paymentStatus == PaymentStatus.overdue;
    final statusColor = isOverdue ? AppColors.error : AppColors.warning;
    final statusText = isOverdue ? 'Atrasado' : 'Pendente';

    final dateStr = student.nextPaymentDate != null
        ? DateFormat('dd/MM/yyyy').format(student.nextPaymentDate!)
        : 'Não definida';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOverdue ? Icons.error_outline : Icons.pending_actions,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: AppTextStyles.headlineSmall.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'Plano: ${student.planType ?? "Regular"}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vencimento: $dateStr',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(student.monthlyFee ?? 0.0),
                style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
