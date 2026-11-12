import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/whatsapp.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../finance/presentation/widgets/payment_actions.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/services/trainer_updates.dart';
import '../providers/trainer_provider.dart';
import 'create_workout_page.dart';
import 'physical_assessment_page.dart';
import 'student_detail_page.dart';

/// Atualizações calculadas a partir dos alunos (tempo real).
final trainerUpdatesProvider = Provider<List<TrainerUpdate>>((ref) {
  final students = ref.watch(trainerDashboardProvider).students;
  return computeTrainerUpdates(students);
});

/// Ícone "Atualizações" da barra do personal, com o número de pendências.
class TrainerUpdatesButton extends ConsumerWidget {
  const TrainerUpdatesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref
        .watch(trainerUpdatesProvider)
        .where((u) => u.kind.countsInBadge)
        .length;
    return IconButton(
      tooltip: 'Atualizações',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TrainerUpdatesPage()),
      ),
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: AppColors.warning,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.fact_check_outlined,
            color: AppColors.textPrimary),
      ),
    );
  }
}

class TrainerUpdatesPage extends ConsumerWidget {
  const TrainerUpdatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updates = ref.watch(trainerUpdatesProvider);
    final loading = ref.watch(trainerDashboardProvider).isLoading;

    // Agrupa mantendo a ordem do cálculo.
    final sections = <UpdateKind, List<TrainerUpdate>>{};
    for (final u in updates) {
      sections.putIfAbsent(u.kind, () => []).add(u);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('ATUALIZAÇÕES', style: AppTextStyles.displaySmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal))
          : updates.isEmpty
              ? const _AllDone()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    Text(
                      'O que precisa da sua atenção em cada aluno. '
                      'Os itens somem sozinhos quando você resolve.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    for (final entry in sections.entries) ...[
                      _SectionHeader(kind: entry.key, count: entry.value.length),
                      const SizedBox(height: 8),
                      for (final u in entry.value) _UpdateCard(update: u),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
    );
  }
}

IconData _icon(UpdateKind k) => switch (k) {
      UpdateKind.workoutExpired => Icons.event_busy,
      UpdateKind.workoutExpiring => Icons.update,
      UpdateKind.noWorkout => Icons.fitness_center,
      UpdateKind.birthdayToday => Icons.cake,
      UpdateKind.birthdaySoon => Icons.cake_outlined,
      UpdateKind.assessmentDue => Icons.monitor_weight_outlined,
      UpdateKind.inactive => Icons.directions_run,
      UpdateKind.paymentOverdue => Icons.attach_money,
    };

Color _color(UpdateKind k) => switch (k) {
      UpdateKind.workoutExpired => AppColors.error,
      UpdateKind.workoutExpiring => AppColors.warning,
      UpdateKind.noWorkout => AppColors.warning,
      UpdateKind.birthdayToday => const Color(0xFFEC4899),
      UpdateKind.birthdaySoon => const Color(0xFFEC4899),
      UpdateKind.assessmentDue => AppColors.info,
      UpdateKind.inactive => AppColors.lightTeal,
      UpdateKind.paymentOverdue => AppColors.error,
    };

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.kind, required this.count});
  final UpdateKind kind;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(_icon(kind), color: _color(kind), size: 18),
        const SizedBox(width: 8),
        Text(
          '${kind.section.toUpperCase()} ($count)',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _UpdateCard extends ConsumerWidget {
  const _UpdateCard({required this.update});
  final TrainerUpdate update;

  StudentEntity get s => update.student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _color(update.kind);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _open(context, StudentDetailPage(student: s)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        style: AppTextStyles.headlineSmall
                            .copyWith(fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(update.detail,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: color)),
                  ],
                ),
              ),
            ),
            ..._actions(context, ref),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Widget _action(String tooltip, IconData icon, VoidCallback onTap) =>
      IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: AppColors.textPrimary, size: 22),
        onPressed: onTap,
      );

  List<Widget> _actions(BuildContext context, WidgetRef ref) {
    final trainer = ref.read(authProvider).user?.name ?? '';
    final sign = trainer.isEmpty ? '' : '\n$trainer';
    final name = firstName(s.name);
    switch (update.kind) {
      case UpdateKind.workoutExpired:
      case UpdateKind.workoutExpiring:
      case UpdateKind.noWorkout:
        return [
          _action('Prescrever treino', Icons.edit_note,
              () => _open(context, CreateWorkoutPage(student: s))),
        ];
      case UpdateKind.birthdayToday:
        return [
          _action(
              'Parabenizar no WhatsApp',
              Icons.chat,
              () => openWhatsApp(
                  context,
                  s.phone,
                  'Parabéns, $name! 🎉 Muita saúde, energia e conquistas '
                  'nesse novo ciclo. Conte comigo nos treinos!$sign')),
        ];
      case UpdateKind.birthdaySoon:
        return const [];
      case UpdateKind.assessmentDue:
        return [
          _action('Nova avaliação', Icons.add_chart,
              () => _open(context, PhysicalAssessmentPage(initialStudent: s))),
        ];
      case UpdateKind.inactive:
        return [
          _action(
              'Chamar no WhatsApp',
              Icons.chat,
              () => openWhatsApp(
                  context,
                  s.phone,
                  'Oi, $name! Tudo bem? Senti sua falta nos treinos. '
                  'Bora voltar? Se precisar ajustar algo no treino, me avisa!$sign')),
        ];
      case UpdateKind.paymentOverdue:
        return [
          _action('Cobrar no WhatsApp', Icons.chat,
              () => chargeOnWhatsApp(context, s, trainerName: trainer)),
          _action('Registrar pagamento', Icons.check_circle_outline,
              () => showRegisterPaymentSheet(context, s)),
        ];
    }
  }
}

class _AllDone extends StatelessWidget {
  const _AllDone();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.task_alt, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text('Tudo em dia!', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Nenhum treino vencendo, avaliação atrasada ou aniversário por perto.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
