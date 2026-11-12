import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../trainer/data/repositories/assessment_repository.dart';
import '../../../trainer/presentation/providers/anamnese_provider.dart';

/// Aluno responde o formulário de anamnese enviado pelo personal.
class StudentAnamnesePage extends ConsumerStatefulWidget {
  const StudentAnamnesePage({super.key, required this.linkId});

  final String linkId;

  @override
  ConsumerState<StudentAnamnesePage> createState() =>
      _StudentAnamnesePageState();
}

class _StudentAnamnesePageState extends ConsumerState<StudentAnamnesePage> {
  List<TextEditingController>? _controllers;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers ?? const <TextEditingController>[]) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers(StudentAnamnese anamnese) {
    _controllers ??= [
      for (var i = 0; i < anamnese.questions.length; i++)
        TextEditingController(text: anamnese.answers[i] ?? ''),
    ];
  }

  Future<void> _save() async {
    final controllers = _controllers;
    if (controllers == null) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(anamneseRepositoryProvider).saveAnswers(widget.linkId, {
        for (var i = 0; i < controllers.length; i++)
          if (controllers[i].text.trim().isNotEmpty) i: controllers[i].text.trim(),
      });
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Respostas enviadas ao seu personal!'),
        backgroundColor: AppColors.success,
      ));
    } on FirebaseException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erro ao salvar: ${e.message}'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anamnese = ref.watch(studentAnamneseProvider(widget.linkId));
    return Scaffold(
      appBar: AppBar(title: Text('ANAMNESE', style: AppTextStyles.headlineMedium)),
      body: anamnese.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          if (data == null || data.questions.isEmpty) {
            return Center(
              child: Text('Seu personal ainda não enviou a anamnese.',
                  style: AppTextStyles.bodyMedium),
            );
          }
          _initControllers(data);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Responda com calma. Essas informações ajudam seu personal a '
                'montar um treino seguro para você e ficam visíveis só para '
                'vocês dois.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < data.questions.length; i++) ...[
                CustomTextField(
                  label: data.questions[i],
                  controller: _controllers![i],
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              CustomButton(
                text: 'ENVIAR RESPOSTAS',
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          );
        },
      ),
    );
  }
}
