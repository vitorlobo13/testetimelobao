import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/workout_library_provider.dart';
import 'create_workout_page.dart';

/// Tela de Biblioteca de Modelos de Treinos
class WorkoutLibraryPage extends ConsumerStatefulWidget {
  const WorkoutLibraryPage({super.key});

  @override
  ConsumerState<WorkoutLibraryPage> createState() => _WorkoutLibraryPageState();
}

class _WorkoutLibraryPageState extends ConsumerState<WorkoutLibraryPage> {
  String _selectedCategory = 'Todos';

  @override
  Widget build(BuildContext context) {
    final categories = ['Todos', 'Hipertrofia', 'Emagrecimento', 'Força', 'Adaptação'];
    final templates = ref.watch(workoutLibraryProvider);

    final filteredTemplates = _selectedCategory == 'Todos'
        ? templates
        : templates.where((t) => t.goal == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('BIBLIOTECA DE TREINOS', style: AppTextStyles.displaySmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    selectedColor: AppColors.teal,
                    backgroundColor: AppColors.surface,
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? AppColors.teal : AppColors.surfaceLight,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Lista de Modelos
          Expanded(
            child: filteredTemplates.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum modelo nesta categoria.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTemplates.length,
                    itemBuilder: (context, index) {
                      final template = filteredTemplates[index];
                      return _TemplateCard(template: template);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateWorkoutPage(student: null),
            ),
          );
        },
        backgroundColor: AppColors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Criar Treino',
          style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final WorkoutTemplate template;

  const _TemplateCard({required this.template});

  void _showWorkoutExercisesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.title,
                          style: AppTextStyles.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${template.exercises} exercícios • ${template.divisions} divisões',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: template.workoutDivisions.length,
                itemBuilder: (context, divIndex) {
                  final division = template.workoutDivisions[divIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.folder_open, color: AppColors.teal, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              division.name,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.teal,
                              ),
                            ),
                            if (division.description != null && division.description!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '- ${division.description}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (division.exercises.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 28.0, bottom: 12.0),
                          child: Text(
                            'Nenhum exercício nesta divisão.',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                          ),
                        )
                      else
                        ...division.exercises.map((workoutExercise) {
                          final exercise = workoutExercise.exercise;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12, left: 8),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.surfaceLight),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.teal.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.fitness_center,
                                      color: AppColors.teal,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.name,
                                          style: AppTextStyles.bodyLarge.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${workoutExercise.sets} séries • ${workoutExercise.reps}'
                                          '${workoutExercise.rest != null ? " • Descanso: ${workoutExercise.rest}s" : ""}'
                                          '${workoutExercise.load != null && workoutExercise.load!.isNotEmpty ? " • Carga: ${workoutExercise.load}" : ""}',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (workoutExercise.notes != null && workoutExercise.notes!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Nota: ${workoutExercise.notes}',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textTertiary,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceLight),
      ),
      color: AppColors.surface,
      elevation: 0,
      child: InkWell(
        onTap: () => _showWorkoutExercisesBottomSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      template.goal.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.lightTeal,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    template.level,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(template.title, style: AppTextStyles.headlineSmall),
              const SizedBox(height: 6),
              Text(
                template.description,
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildFeatureItem(Icons.folder_open, '${template.divisions} Divisões'),
                  const SizedBox(width: 24),
                  _buildFeatureItem(Icons.fitness_center, '${template.exercises} Exercícios'),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
