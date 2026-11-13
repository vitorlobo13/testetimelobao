import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../finance/data/payment_repository.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/trainer_provider.dart';
import '../providers/trainer_sessions_provider.dart';
import 'frequency_report_page.dart';
import 'student_detail_page.dart';

const _monthsShort = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

/// Relatórios do personal: visão geral de alunos, frequência e faturamento.
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  int _days = 30;
  final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    final today = startOfDay(DateTime.now());
    final since = today.subtract(Duration(days: _days - 1));

    final dashboard = ref.watch(trainerDashboardProvider);
    final sessionsAsync = ref.watch(trainerSessionsSinceProvider(since));
    final payments = ref.watch(trainerPaymentsProvider).value ?? const [];

    final current = dashboard.students
        .where((s) => s.linkStatus != LinkStatus.archived)
        .toList();
    final active = current.where((s) => s.isActive).toList();
    final newStudents =
        current.where((s) => !s.enrollmentDate.isBefore(since)).length;

    final sessions = sessionsAsync.value ?? const <SessionSummary>[];
    final weeks = _days / 7;
    final perStudentWeek =
        active.isEmpty ? 0.0 : sessions.length / active.length / weeks;

    final receivedPeriod = payments
        .where((p) => !p.paidAt.isBefore(since))
        .fold<double>(0, (s, p) => s + p.amount);

    // Faturamento dos últimos 6 meses (inclui o atual).
    final months = [
      for (var i = 5; i >= 0; i--) DateTime(today.year, today.month - i)
    ];
    final revenue = [
      for (final m in months)
        payments
            .where((p) => p.paidAt.year == m.year && p.paidAt.month == m.month)
            .fold<double>(0, (s, p) => s + p.amount)
    ];

    // Treinos por semana no período (semanas terminando hoje).
    final weekCount = (_days / 7).ceil();
    final weekly = List<double>.filled(weekCount, 0);
    for (final s in sessions) {
      final idx =
          weekCount - 1 - (today.difference(startOfDay(s.startTime)).inDays ~/ 7);
      if (idx >= 0 && idx < weekCount) weekly[idx]++;
    }
    final weekLabels = [
      for (var i = 0; i < weekCount; i++)
        DateFormat('dd/MM').format(
            today.subtract(Duration(days: (weekCount - 1 - i) * 7 + 6)))
    ];

    // Ranking de frequência por aluno ativo com conta.
    final counts = <String, int>{};
    for (final s in sessions) {
      counts[s.linkId] = (counts[s.linkId] ?? 0) + 1;
    }
    final ranking = active.where((s) => s.hasAccount).toList()
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    final noTraining =
        ranking.where((s) => (counts[s.id] ?? 0) == 0).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('RELATÓRIOS', style: AppTextStyles.displaySmall),
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
                Wrap(
                  spacing: 8,
                  children: [
                    for (final d in const [7, 30, 90])
                      ChoiceChip(
                        label: Text('Últimos $d dias'),
                        selected: _days == d,
                        selectedColor: AppColors.teal,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                            color: _days == d
                                ? Colors.white
                                : AppColors.textSecondary),
                        onSelected: (_) => setState(() => _days = d),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (sessionsAsync.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                        'Erro ao carregar treinos: ${sessionsAsync.error}',
                        style: const TextStyle(color: AppColors.error)),
                  ),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // Altura fixa: não estica os cartões em tela larga.
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 112,
                  ),
                  children: [
                    _Kpi(Icons.people, 'Alunos ativos', '${active.length}',
                        '$newStudents novo(s) no período'),
                    _Kpi(
                        Icons.fitness_center,
                        'Treinos concluídos',
                        sessionsAsync.isLoading ? '…' : '${sessions.length}',
                        'no período'),
                    _Kpi(Icons.speed, 'Média semanal',
                        perStudentWeek.toStringAsFixed(1),
                        'treinos por aluno'),
                    _Kpi(Icons.attach_money, 'Recebido',
                        _money.format(receivedPeriod), 'no período'),
                  ],
                ),
                const SizedBox(height: 20),
                _Card(
                  title: 'Faturamento (últimos 6 meses)',
                  icon: Icons.bar_chart,
                  child: _Bars(
                    values: revenue,
                    labels: [for (final m in months) _monthsShort[m.month - 1]],
                    color: AppColors.success,
                    format: (v) => v == 0
                        ? ''
                        : NumberFormat.compactCurrency(
                                locale: 'pt_BR', symbol: 'R\$')
                            .format(v),
                  ),
                ),
                _Card(
                  title: 'Treinos por semana',
                  icon: Icons.calendar_view_week,
                  child: _Bars(
                    values: weekly,
                    labels: weekLabels,
                    color: AppColors.lightTeal,
                    format: (v) => v == 0 ? '' : v.toInt().toString(),
                  ),
                ),
                _Card(
                  title: 'Frequência por aluno',
                  icon: Icons.leaderboard,
                  trailing: TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const FrequencyReportPage())),
                    child: const Text('Ver detalhado'),
                  ),
                  child: ranking.isEmpty
                      ? const Text('Nenhum aluno com conta ativa ainda.',
                          style: TextStyle(color: AppColors.textSecondary))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (noTraining > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '$noTraining aluno(s) sem nenhum treino no período',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.warning),
                                ),
                              ),
                            for (final s in ranking.take(10))
                              _RankRow(
                                student: s,
                                count: counts[s.id] ?? 0,
                                max: counts[ranking.first.id] ?? 0,
                              ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.icon, this.title, this.value, this.caption);
  final IconData icon;
  final String title;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.lightTeal, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(title,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ]),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: AppTextStyles.displaySmall.copyWith(fontSize: 24)),
          ),
          Text(caption,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card(
      {required this.title,
      required this.icon,
      required this.child,
      this.trailing});
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.lightTeal, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: AppTextStyles.headlineSmall)),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Gráfico de barras simples (sem biblioteca externa).
class _Bars extends StatelessWidget {
  const _Bars({
    required this.values,
    required this.labels,
    required this.color,
    required this.format,
  });
  final List<double> values;
  final List<String> labels;
  final Color color;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final max = values.fold<double>(0, (m, v) => v > m ? v : m);
    const height = 120.0;
    return SizedBox(
      height: height + 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(format(values[i]),
                          style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10, color: AppColors.textSecondary)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: max == 0 ? 2 : (values[i] / max * height).clamp(2, height),
                      decoration: BoxDecoration(
                        color: values[i] == 0
                            ? AppColors.surfaceLight
                            : color,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(labels[i],
                          style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10, color: AppColors.textTertiary)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow(
      {required this.student, required this.count, required this.max});
  final StudentEntity student;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StudentDetailPage(student: student))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(student.name,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium),
            ),
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: max == 0 ? 0 : count / max,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceLight,
                  color: count == 0 ? AppColors.warning : AppColors.teal,
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text('$count',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
