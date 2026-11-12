import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../trainer/presentation/providers/anamnese_provider.dart';
import '../../../trainer/presentation/providers/physical_measurement_provider.dart';
import '../pages/student_anamnese_page.dart';
import '../providers/student_workout_provider.dart';

/// Na área do aluno: aviso de anamnese pendente e histórico das avaliações
/// (com as fotos de evolução).
class StudentEvolutionSection extends ConsumerWidget {
  const StudentEvolutionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(studentWorkoutProvider.select((s) => s.link));
    if (link == null) return const SizedBox.shrink();

    final anamnese = ref.watch(studentAnamneseProvider(link.linkId)).value;
    final history =
        ref.watch(assessmentsProvider(link.linkId)).value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (anamnese != null && anamnese.questions.isNotEmpty)
          Card(
            color: anamnese.isPending
                ? AppColors.warning.withValues(alpha: 0.12)
                : AppColors.surface,
            child: ListTile(
              leading: Icon(
                anamnese.isPending ? Icons.assignment_late : Icons.assignment_turned_in,
                color: anamnese.isPending ? AppColors.warning : AppColors.success,
              ),
              title: Text(
                anamnese.isPending
                    ? 'Responder anamnese'
                    : 'Anamnese respondida',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                anamnese.isPending
                    ? 'Seu personal precisa dessas informações para montar seu treino.'
                    : 'Toque para revisar ou atualizar suas respostas.',
                style: AppTextStyles.bodySmall,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StudentAnamnesePage(linkId: link.linkId),
              )),
            ),
          ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('MINHA EVOLUÇÃO', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          for (final m in history.take(6))
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(m.recordedAt)}'
                      '${m.recordedBy == 'trainer' ? ' · avaliação do personal' : ''}',
                      style: AppTextStyles.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (m.weight != null) '${m.weight!.toStringAsFixed(1)} kg',
                        if (m.fatPercentage != null)
                          '${m.fatPercentage!.toStringAsFixed(1)}% gordura',
                        if (m.waist != null) 'cintura ${m.waist!.toStringAsFixed(1)} cm',
                      ].join(' · '),
                      style: AppTextStyles.bodySmall,
                    ),
                    if (m.photoUrls.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: m.photoUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(m.photoUrls[i],
                                width: 60, height: 80, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Cartão na tela inicial do aluno quando há anamnese para responder.
class PendingAnamneseCard extends ConsumerWidget {
  const PendingAnamneseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(studentWorkoutProvider.select((s) => s.link));
    if (link == null) return const SizedBox.shrink();
    final anamnese = ref.watch(studentAnamneseProvider(link.linkId)).value;
    if (anamnese == null || !anamnese.isPending) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: const Icon(Icons.assignment_late, color: AppColors.warning),
          title: Text('Responda sua anamnese', style: AppTextStyles.bodyLarge),
          subtitle: Text('Seu personal enviou algumas perguntas para você.',
              style: AppTextStyles.bodySmall),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => StudentAnamnesePage(linkId: link.linkId),
          )),
        ),
      ),
    );
  }
}
