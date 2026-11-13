import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/trainer_provider.dart';
import '../providers/anamnese_provider.dart';

/// Tela de Anamnese do Professor
class AnamnesePage extends ConsumerStatefulWidget {
  const AnamnesePage({super.key});

  @override
  ConsumerState<AnamnesePage> createState() => _AnamnesePageState();
}

class _AnamnesePageState extends ConsumerState<AnamnesePage> {
  StudentEntity? _selectedStudent;
  late List<TextEditingController> _questionControllers;

  @override
  void initState() {
    super.initState();
    _questionControllers = [];
  }

  @override
  void dispose() {
    for (var controller in _questionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _formEdited = false;
  List<String>? _loadedQuestions;

  void _initQuestionControllers(List<String> questions) {
    // Recarrega quando o formulário salvo chega do Firebase, desde que o
    // personal ainda não tenha começado a editar.
    if (_questionControllers.isEmpty ||
        (!_formEdited && _loadedQuestions != questions)) {
      for (final c in _questionControllers) {
        c.dispose();
      }
      _questionControllers =
          questions.map((q) => TextEditingController(text: q)).toList();
      _loadedQuestions = questions;
    }
  }

  void _saveQuestions() {
    final updatedQuestions = _questionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    ref.read(anamneseProvider.notifier).saveQuestions(updatedQuestions);
    _formEdited = false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulário de anamnese atualizado com sucesso!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _addQuestion() {
    setState(() {
      _formEdited = true;
      _questionControllers.add(TextEditingController());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _formEdited = true;
      _questionControllers[index].dispose();
      _questionControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(trainerDashboardProvider);
    final anamneseState = ref.watch(anamneseProvider);
    final students = dashboardState.students;

    _initQuestionControllers(anamneseState.questions);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text('ANAMNESE', style: AppTextStyles.displaySmall),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            labelColor: AppColors.teal,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.teal,
            tabs: [
              Tab(text: 'Respostas dos Alunos', icon: Icon(Icons.people)),
              Tab(text: 'Editar Formulário', icon: Icon(Icons.edit_document)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAnswersView(students, anamneseState),
            _buildEditFormView(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswersView(List<StudentEntity> students, AnamneseState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECIONAR ALUNO',
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildStudentSelector(students),
          const SizedBox(height: 24),

          if (_selectedStudent != null) ...[
            Text(
              'RESPOSTAS',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildStudentAnswersList(state),
          ] else ...[
             Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Selecione um aluno para visualizar as respostas.',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            )
          ],
        ],
      ),
    );
  }

  List<Widget> _buildStudentAnswersList(AnamneseState state) {
    final student = _selectedStudent!;
    final anamnese = ref.watch(studentAnamneseProvider(student.id)).value;
    final format = DateFormat("dd/MM/yyyy 'às' HH:mm");

    Future<void> send() async {
      final messenger = ScaffoldMessenger.of(context);
      await ref.read(anamneseProvider.notifier).sendToStudent(student.id);
      messenger.showSnackBar(SnackBar(
        content: Text(student.hasAccount
            ? 'Anamnese enviada! ${student.name} vai ver no app para responder.'
            : 'Anamnese pronta: ${student.name} responde assim que aceitar o convite.'),
        backgroundColor: AppColors.success,
      ));
    }

    final header = <Widget>[
      if (anamnese?.answeredAt != null)
        Text('Respondida em ${format.format(anamnese!.answeredAt!)}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.success))
      else if (anamnese?.sentAt != null)
        Text('Enviada em ${format.format(anamnese!.sentAt!)} · aguardando resposta',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning)),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.send),
              label: Text(anamnese == null ? 'Enviar ao aluno' : 'Reenviar formulário'),
              onPressed: send,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_note),
              label: const Text('Preencher agora'),
              onPressed: () => _fillWithStudent(student.id, anamnese, state),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ];

    if (anamnese == null || anamnese.answers.isEmpty) {
      return [
        ...header,
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Este aluno ainda não respondeu ao formulário de anamnese.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        )
      ];
    }

    final widgets = <Widget>[...header];
    for (int i = 0; i < anamnese.questions.length; i++) {
      final question = anamnese.questions[i];
      final answer = anamnese.answers[i] ?? 'Não respondido.';

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question,
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                answer,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  /// Personal preenche a anamnese junto com o aluno (ex.: na academia).
  Future<void> _fillWithStudent(
      String linkId, StudentAnamnese? current, AnamneseState state) async {
    final questions = (current?.questions.isNotEmpty ?? false)
        ? current!.questions
        : state.questions;
    if (current == null || current.questions.isEmpty) {
      await ref.read(anamneseProvider.notifier).sendToStudent(linkId);
    }
    if (!mounted) return;
    final controllers = [
      for (var i = 0; i < questions.length; i++)
        TextEditingController(text: current?.answers[i] ?? ''),
    ];
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('PREENCHER ANAMNESE', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              for (var i = 0; i < questions.length; i++) ...[
                CustomTextField(
                  label: questions[i],
                  controller: controllers[i],
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
              ],
              CustomButton(
                text: 'SALVAR RESPOSTAS',
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) {
      await ref.read(anamneseProvider.notifier).saveAnswers(linkId, {
        for (var i = 0; i < controllers.length; i++)
          if (controllers[i].text.trim().isNotEmpty) i: controllers[i].text.trim(),
      });
    }
    for (final c in controllers) {
      c.dispose();
    }
  }

  Widget _buildEditFormView() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _questionControllers.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Pergunta ${index + 1}',
                        hint: 'Digite a pergunta...',
                        controller: _questionControllers[index],
                        maxLines: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => _removeQuestion(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CustomButton(
                text: 'ADICIONAR PERGUNTA',
                onPressed: _addQuestion,
                type: ButtonType.outline,
                icon: Icons.add,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'SALVAR FORMULÁRIO',
                onPressed: _saveQuestions,
                type: ButtonType.primary,
                icon: Icons.save,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSelector(List<StudentEntity> students) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StudentEntity>(
          hint: Text('Escolha um aluno...', style: AppTextStyles.bodyMedium),
          value: _selectedStudent != null && students.any((s) => s.id == _selectedStudent!.id)
              ? students.firstWhere((s) => s.id == _selectedStudent!.id)
              : null,
          dropdownColor: AppColors.surface,
          isExpanded: true,
          style: AppTextStyles.bodyLarge,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          items: students.map((student) {
            return DropdownMenuItem(
              value: student,
              child: Text(student.name),
            );
          }).toList(),
          onChanged: (student) {
            if (student != null) {
              setState(() {
                _selectedStudent = student;
              });
            }
          },
        ),
      ),
    );
  }
}
