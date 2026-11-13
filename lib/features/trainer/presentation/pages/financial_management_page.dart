import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../finance/data/payment_repository.dart';
import '../../../finance/presentation/widgets/payment_actions.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/trainer_provider.dart';
import 'student_detail_page.dart';

const _monthNames = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

/// Gestão financeira do personal: só controle (o app não cobra).
/// Mostra o que entrou no mês, quem está atrasado e quem vence logo,
/// com atalhos para registrar o pagamento e cobrar pelo WhatsApp.
class FinancialManagementPage extends ConsumerStatefulWidget {
  const FinancialManagementPage({super.key});

  @override
  ConsumerState<FinancialManagementPage> createState() =>
      _FinancialManagementPageState();
}

class _FinancialManagementPageState
    extends ConsumerState<FinancialManagementPage> {
  final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  late DateTime _month; // primeiro dia do mês exibido

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(trainerDashboardProvider);
    final paymentsAsync = ref.watch(trainerPaymentsProvider);

    final billable = dashboard.students.where((s) => s.isBillable).toList();
    final overdue = billable
        .where((s) => s.effectivePaymentStatus == PaymentStatus.overdue)
        .toList()
      ..sort((a, b) => (a.daysUntilDue ?? 0).compareTo(b.daysUntilDue ?? 0));
    final dueSoon = billable
        .where((s) => s.effectivePaymentStatus == PaymentStatus.pending)
        .toList()
      ..sort((a, b) =>
          (a.daysUntilDue ?? -999).compareTo(b.daysUntilDue ?? -999));

    final expected =
        billable.fold<double>(0, (sum, s) => sum + (s.monthlyFee ?? 0));
    final overdueAmount = overdue.fold<double>(
        0, (sum, s) => sum + (s.monthlyFee ?? 0) * s.planMonths);

    final monthPayments = (paymentsAsync.value ?? const <PaymentEntity>[])
        .where((p) =>
            p.paidAt.year == _month.year && p.paidAt.month == _month.month)
        .toList();
    final received =
        monthPayments.fold<double>(0, (sum, p) => sum + p.amount);
    final monthLabel = '${_monthNames[_month.month - 1]} ${_month.year}';

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
      body: dashboard.isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.teal))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _monthSelector(monthLabel),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        icon: Icons.trending_up,
                        color: AppColors.success,
                        title: 'Recebido',
                        value: _money.format(received),
                        caption: paymentsAsync.isLoading
                            ? 'Carregando...'
                            : '${monthPayments.length} pagamento(s) em $monthLabel',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        icon: Icons.calendar_month,
                        color: AppColors.lightTeal,
                        title: 'Previsto por mês',
                        value: _money.format(expected),
                        caption: '${billable.length} aluno(s) pagantes',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.error,
                        title: 'Em atraso',
                        value: _money.format(overdueAmount),
                        caption: '${overdue.length} aluno(s)',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        icon: Icons.schedule,
                        color: AppColors.warning,
                        title: 'A vencer',
                        value: '${dueSoon.length}',
                        caption:
                            'Nos próximos ${StudentEntity.dueSoonDays} dias',
                      ),
                    ),
                  ],
                ),
                if (paymentsAsync.hasError) ...[
                  const SizedBox(height: 12),
                  Text('Erro ao carregar pagamentos: ${paymentsAsync.error}',
                      style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 24),
                _sectionTitle('EM ATRASO (${overdue.length})'),
                if (overdue.isEmpty)
                  _emptyCard(Icons.check_circle_outline, 'Ninguém em atraso!')
                else
                  ...overdue.map((s) => _ChargeCard(student: s)),
                const SizedBox(height: 24),
                _sectionTitle('A VENCER (${dueSoon.length})'),
                if (dueSoon.isEmpty)
                  _emptyCard(Icons.event_available,
                      'Nenhum vencimento nos próximos ${StudentEntity.dueSoonDays} dias.')
                else
                  ...dueSoon.map((s) => _ChargeCard(student: s)),
                const SizedBox(height: 24),
                _sectionTitle(
                    'RECEBIMENTOS DE ${monthLabel.toUpperCase()}'),
                if (monthPayments.isEmpty)
                  _emptyCard(Icons.receipt_long,
                      'Nenhum pagamento registrado neste mês.')
                else
                  Container(
                    decoration: _box(),
                    child: Column(
                      children: [
                        for (var i = 0; i < monthPayments.length; i++) ...[
                          if (i > 0)
                            Divider(
                                color: AppColors.surfaceLight, height: 1),
                          PaymentTile(
                            payment: monthPayments[i],
                            showStudent: true,
                            onTap: () =>
                                _openStudent(monthPayments[i].linkId),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  void _openStudent(String linkId) {
    final student = ref
        .read(trainerDashboardProvider)
        .students
        .where((s) => s.id == linkId)
        .firstOrNull;
    if (student == null) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => StudentDetailPage(student: student)));
  }

  Widget _monthSelector(String label) => Container(
        decoration: _box(),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Mês anterior',
              icon: const Icon(Icons.chevron_left,
                  color: AppColors.textPrimary),
              onPressed: () => _shiftMonth(-1),
            ),
            Expanded(
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineSmall),
            ),
            IconButton(
              tooltip: 'Próximo mês',
              icon: Icon(Icons.chevron_right,
                  color: _isCurrentMonth
                      ? AppColors.textTertiary
                      : AppColors.textPrimary),
              onPressed: _isCurrentMonth ? null : () => _shiftMonth(1),
            ),
          ],
        ),
      );

  Widget _summaryCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String caption,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _box(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(title,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.textPrimary, fontSize: 22)),
            ),
            const SizedBox(height: 4),
            Text(caption,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
          ],
        ),
      );

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary)),
      );

  Widget _emptyCard(IconData icon, String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _box(),
        child: Row(
          children: [
            Icon(icon, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
                child: Text(text,
                    style: const TextStyle(color: AppColors.textSecondary))),
          ],
        ),
      );

  BoxDecoration _box() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      );
}

/// Cartão de cobrança: aluno, vencimento e os atalhos Cobrar / Recebido.
class _ChargeCard extends ConsumerWidget {
  const _ChargeCard({required this.student});
  final StudentEntity student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = student;
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final color = paymentStatusColor(s.effectivePaymentStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StudentDetailPage(student: s))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: AppTextStyles.headlineSmall
                              .copyWith(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(dueLabel(s),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: color)),
                      const SizedBox(height: 2),
                      Text('Plano ${s.planType ?? 'Regular'}',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Text(
                  s.monthlyFee == null
                      ? '—'
                      : money.format(s.monthlyFee! * s.planMonths),
                  style: AppTextStyles.headlineSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.surfaceLight),
                  ),
                  onPressed: () => chargeOnWhatsApp(context, s,
                      trainerName: ref.read(authProvider).user?.name),
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Cobrar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => showRegisterPaymentSheet(context, s),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Recebido'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
