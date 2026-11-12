import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void _initQuestionControllers(List<String> questions) {
    // Apenas inicializa se estiver vazio para não perder foco durante rebuilds
    if (_questionControllers.isEmpty) {
      _questionControllers = questions.map((q) => TextEditingController(text: q)).toList();
    }
  }

  void _saveQuestions() {
    final updatedQuestions = _questionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    ref.read(anamneseProvider.notifier).saveQuestions(updatedQuestions);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulário de anamnese atualizado com sucesso!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _addQuestion() {
    setState(() {
      _questionControllers.add(TextEditingController());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
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
          bottom: const TabBar(
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
    final answers = state.studentAnswers[_selectedStudent!.id] ?? {};
    
    if (answers.isEmpty) {
      return [
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

    final widgets = <Widget>[];
    for (int i = 0; i < state.questions.length; i++) {
      final question = state.questions[i];
      final answer = answers[i] ?? 'Não respondido.';

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
