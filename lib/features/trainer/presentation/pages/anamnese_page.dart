import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/trainer_provider.dart';

/// Tela de Registro de Ficha de Anamnese
class AnamnesePage extends ConsumerStatefulWidget {
  const AnamnesePage({super.key});

  @override
  ConsumerState<AnamnesePage> createState() => _AnamnesePageState();
}

class _AnamnesePageState extends ConsumerState<AnamnesePage> {
  final _formKey = GlobalKey<FormState>();
  StudentEntity? _selectedStudent;

  final _goalsController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _injuriesController = TextEditingController();
  final _lifestyleController = TextEditingController();
  final _observationsController = TextEditingController();

  @override
  void dispose() {
    _goalsController.dispose();
    _medicalHistoryController.dispose();
    _injuriesController.dispose();
    _lifestyleController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(trainerDashboardProvider);
    final students = dashboardState.students;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('ANAMNESE', style: AppTextStyles.displaySmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seleção do Aluno
              Text(
                'SELECIONAR ALUNO',
                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStudentSelector(students),
              const SizedBox(height: 24),

              if (_selectedStudent != null) ...[
                // Objetivos
                _buildSectionTitle('OBJETIVOS DO ALUNO'),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Objetivos Principais',
                  hint: 'Ex: Perda de gordura, ganho de força, hipertrofia...',
                  controller: _goalsController,
                  maxLines: 2,
                  validator: (v) => v == null || v.isEmpty ? 'Insira os objetivos' : null,
                ),
                const SizedBox(height: 24),

                // Histórico Médico
                _buildSectionTitle('HISTÓRICO DE SAÚDE'),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Doenças Crônicas ou Histórico Médico',
                  hint: 'Ex: Hipertensão, diabetes, asma, problemas cardíacos...',
                  controller: _medicalHistoryController,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Lesões Atuais ou Passadas',
                  hint: 'Ex: Hérnia de disco, dor no joelho esquerdo, cirurgia no ombro...',
                  controller: _injuriesController,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Estilo de Vida
                _buildSectionTitle('ESTILO DE VIDA E ROTINA'),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Nível de Atividade Física / Rotina Diária',
                  hint: 'Ex: Sedentário, trabalha sentado, treina musculação há 6 meses...',
                  controller: _lifestyleController,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Observações Gerais',
                  hint: 'Qualquer outra informação relevante para o treinamento...',
                  controller: _observationsController,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Botão Salvar
                CustomButton(
                  text: 'SALVAR FICHA DE ANAMNESE',
                  onPressed: _saveAnamnese,
                  type: ButtonType.primary,
                  icon: Icons.save,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 1,
      ),
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

  void _saveAnamnese() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ficha de Anamnese de "${_selectedStudent!.name}" registrada com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }
}
