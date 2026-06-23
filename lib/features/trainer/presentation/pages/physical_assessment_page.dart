import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/trainer_provider.dart';

/// Tela de Registro de Avaliação Física
class PhysicalAssessmentPage extends ConsumerStatefulWidget {
  final StudentEntity? initialStudent;

  const PhysicalAssessmentPage({super.key, this.initialStudent});

  @override
  ConsumerState<PhysicalAssessmentPage> createState() => _PhysicalAssessmentPageState();
}

class _PhysicalAssessmentPageState extends ConsumerState<PhysicalAssessmentPage> {
  final _formKey = GlobalKey<FormState>();
  StudentEntity? _selectedStudent;

  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _fatPercentageController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _chestController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStudent = widget.initialStudent;
    if (_selectedStudent != null) {
      _weightController.text = _selectedStudent!.weight?.toString() ?? '';
      _heightController.text = _selectedStudent!.height?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _fatPercentageController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _chestController.dispose();
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
        title: Text('AVALIAÇÃO FÍSICA', style: AppTextStyles.displaySmall),
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
                // Medidas Básicas
                _buildSectionTitle('MEDIDAS BÁSICAS'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Peso (kg)',
                        hint: 'Ex: 80.0',
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v == null || v.isEmpty ? 'Insira o peso' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Altura (cm)',
                        hint: 'Ex: 178',
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? 'Insira a altura' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Composição Corporal
                _buildSectionTitle('COMPOSIÇÃO CORPORAL'),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Percentual de Gordura (%)',
                  hint: 'Ex: 14.5',
                  controller: _fatPercentageController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 24),

                // Perímetros (cm)
                _buildSectionTitle('PERÍMETROS (CM)'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Cintura',
                        hint: 'Ex: 82.0',
                        controller: _waistController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Quadril',
                        hint: 'Ex: 95.0',
                        controller: _hipController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Tórax',
                  hint: 'Ex: 100.0',
                  controller: _chestController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 32),

                // Botão Salvar
                CustomButton(
                  text: 'SALVAR AVALIAÇÃO',
                  onPressed: _saveAssessment,
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
                _weightController.text = student.weight?.toString() ?? '';
                _heightController.text = student.height?.toString() ?? '';
              });
            }
          },
        ),
      ),
    );
  }

  void _saveAssessment() {
    if (_formKey.currentState?.validate() ?? false) {
      final double weight = double.parse(_weightController.text);
      final double height = double.parse(_heightController.text);

      // Atualiza os dados do aluno no provider
      final updatedStudent = StudentEntity(
        id: _selectedStudent!.id,
        trainerId: _selectedStudent!.trainerId,
        name: _selectedStudent!.name,
        email: _selectedStudent!.email,
        phone: _selectedStudent!.phone,
        enrollmentDate: _selectedStudent!.enrollmentDate,
        isActive: _selectedStudent!.isActive,
        status: _selectedStudent!.status,
        weight: weight,
        height: height,
        age: _selectedStudent!.age,
        gender: _selectedStudent!.gender,
        planType: _selectedStudent!.planType,
        monthlyFee: _selectedStudent!.monthlyFee,
        nextPaymentDate: _selectedStudent!.nextPaymentDate,
        paymentStatus: _selectedStudent!.paymentStatus,
        currentWorkoutId: _selectedStudent!.currentWorkoutId,
        lastWorkoutDate: _selectedStudent!.lastWorkoutDate,
        totalWorkouts: _selectedStudent!.totalWorkouts,
      );

      ref.read(trainerDashboardProvider.notifier).updateStudent(updatedStudent);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Avaliação física de "${updatedStudent.name}" salva com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop();
    }
  }
}
