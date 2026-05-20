import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/workout_builder_provider.dart';
import '../providers/exercises_provider.dart';
import '../widgets/division_tab.dart';
import '../widgets/workout_exercise_card.dart';
import 'exercise_selector_sheet.dart';
import 'exercise_config_sheet.dart';

/// Tela de criação de treino
class CreateWorkoutPage extends ConsumerStatefulWidget {
  final StudentEntity student;

  const CreateWorkoutPage({
    super.key,
    required this.student,
  });

  @override
  ConsumerState<CreateWorkoutPage> createState() => _CreateWorkoutPageState();
}

class _CreateWorkoutPageState extends ConsumerState<CreateWorkoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _workoutNameController = TextEditingController();
  final _workoutDescriptionController = TextEditingController();
  final _divisionNameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Reseta o construtor ao entrar
    Future.microtask(() {
      ref.read(workoutBuilderProvider.notifier).reset();
      ref.read(exercisesProvider.notifier).loadExercises();
    });
  }

  @override
  void dispose() {
    _workoutNameController.dispose();
    _workoutDescriptionController.dispose();
    _divisionNameController.dispose();
    super.dispose();
  }

  void _showAddDivisionDialog() {
    _divisionNameController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova Divisão', style: AppTextStyles.headlineMedium),
        content: CustomTextField(
          label: 'Nome da Divisão',
          hint: 'Ex: Treino A, Push, Peito e Tríceps...',
          controller: _divisionNameController,
          prefixIcon: Icons.fitness_center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (_divisionNameController.text.isNotEmpty) {
                ref.read(workoutBuilderProvider.notifier).addDivision(
                      _divisionNameController.text,
                    );
                Navigator.pop(context);
              }
            },
            child: Text(
              'Adicionar',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseSelectorSheet(
        onExerciseSelected: (exercise) {
          ref.read(workoutBuilderProvider.notifier).addExercise(exercise);
        },
      ),
    );
  }

  void _showExerciseConfig(int exerciseIndex) {
    final builderState = ref.read(workoutBuilderProvider);
    final currentDivision = builderState.currentDivision;

    if (currentDivision == null || exerciseIndex >= currentDivision.exercises.length) {
      return;
    }

    final workoutExercise = currentDivision.exercises[exerciseIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseConfigSheet(
        workoutExercise: workoutExercise,
        onSave: (updatedExercise) {
          ref.read(workoutBuilderProvider.notifier).updateExercise(
                exerciseIndex,
                updatedExercise,
              );
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    // Valida nome do treino
    if (_workoutNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o nome do treino'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final builderState = ref.read(workoutBuilderProvider);

    // Valida divisões
    if (builderState.divisions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma divisão'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Valida exercícios
    if (builderState.totalExercises == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um exercício'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Atualiza nome e descrição
    ref.read(workoutBuilderProvider.notifier).setWorkoutName(
          _workoutNameController.text,
        );
    ref.read(workoutBuilderProvider.notifier).setWorkoutDescription(
          _workoutDescriptionController.text,
        );

    // Salva treino
    final success = await ref.read(workoutBuilderProvider.notifier).saveWorkout(
          widget.student.id,
          'trainer_123', // TODO: Pegar ID do trainer logado
        );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treino criado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar treino'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(workoutBuilderProvider);
    final currentDivision = builderState.currentDivision;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Criar Treino', style: AppTextStyles.headlineMedium),
        actions: [
          if (!_isSaving)
            TextButton.icon(
              onPressed: _handleSave,
              icon: const Icon(Icons.check, color: AppColors.teal),
              label: Text(
                'Salvar',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.teal,
                ),
              ),
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.teal,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Informações do aluno
          _buildStudentHeader(),

          // Formulário de nome e descrição
          _buildWorkoutInfoForm(),

          // Divisões (Tabs)
          _buildDivisionsTabs(builderState),

          // Lista de exercícios da divisão atual
          Expanded(
            child: currentDivision == null
                ? _buildEmptyDivisionState()
                : _buildExercisesList(currentDivision),
          ),
        ],
      ),
      floatingActionButton: currentDivision != null
          ? FloatingActionButton.extended(
              onPressed: _showExerciseSelector,
              backgroundColor: AppColors.teal,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Adicionar Exercício',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStudentHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceLight),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: Center(
              child: Text(
                widget.student.name.split(' ').take(2).map((w) => w[0]).join(),
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Criando treino para:',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  widget.student.name,
                  style: AppTextStyles.headlineSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutInfoForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              label: 'Nome do Treino',
              hint: 'Ex: Treino ABC - Hipertrofia',
              controller: _workoutNameController,
              prefixIcon: Icons.fitness_center,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Descrição (Opcional)',
              hint: 'Ex: Divisão Push/Pull/Legs focada em hipertrofia',
              controller: _workoutDescriptionController,
              maxLines: 2,
              prefixIcon: Icons.description,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivisionsTabs(WorkoutBuilderState builderState) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Divisões do Treino',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ...builderState.divisions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final division = entry.value;
                  return DivisionTab(
                    name: division.name,
                    exerciseCount: division.exercises.length,
                    isSelected: builderState.currentDivisionIndex == index,
                    onTap: () {
                      ref.read(workoutBuilderProvider.notifier).setCurrentDivision(index);
                    },
                    onDelete: builderState.divisions.length > 1
                        ? () {
                            ref.read(workoutBuilderProvider.notifier).removeDivision(index);
                          }
                        : null,
                  );
                }),
                // Botão adicionar divisão
                GestureDetector(
                  onTap: _showAddDivisionDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.teal,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add,
                          color: AppColors.teal,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Nova Divisão',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(division) {
    if (division.exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nenhum exercício adicionado',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Toque no botão abaixo para adicionar',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: division.exercises.length,
      itemBuilder: (context, index) {
        final workoutExercise = division.exercises[index];
        return WorkoutExerciseCard(
          workoutExercise: workoutExercise,
          onTap: () => _showExerciseConfig(index),
          onDelete: () {
            ref.read(workoutBuilderProvider.notifier).removeExercise(index);
          },
        );
      },
    );
  }

  Widget _buildEmptyDivisionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open,
                size: 64,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma divisão criada',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Adicione uma divisão para começar',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'ADICIONAR DIVISÃO',
              onPressed: _showAddDivisionDialog,
              type: ButtonType.primary,
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }
}