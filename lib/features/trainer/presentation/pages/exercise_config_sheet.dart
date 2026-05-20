import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../domain/entities/workout_entity.dart';

/// Bottom Sheet para configurar exercício
class ExerciseConfigSheet extends StatefulWidget {
  final WorkoutExercise workoutExercise;
  final Function(WorkoutExercise) onSave;

  const ExerciseConfigSheet({
    super.key,
    required this.workoutExercise,
    required this.onSave,
  });

  @override
  State<ExerciseConfigSheet> createState() => _ExerciseConfigSheetState();
}

class _ExerciseConfigSheetState extends State<ExerciseConfigSheet> {
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _restController;
  late TextEditingController _loadController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(
      text: widget.workoutExercise.sets.toString(),
    );
    _repsController = TextEditingController(
      text: widget.workoutExercise.reps,
    );
    _restController = TextEditingController(
      text: widget.workoutExercise.rest ?? '',
    );
    _loadController = TextEditingController(
      text: widget.workoutExercise.load ?? '',
    );
    _notesController = TextEditingController(
      text: widget.workoutExercise.notes ?? '',
    );
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    _loadController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final updatedExercise = widget.workoutExercise.copyWith(
      sets: int.tryParse(_setsController.text) ?? 3,
      reps: _repsController.text,
      rest: _restController.text.isEmpty ? null : _restController.text,
      load: _loadController.text.isEmpty ? null : _loadController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    widget.onSave(updatedExercise);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Cabeçalho
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configurar Exercício',
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.workoutExercise.exercise.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
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

          // Formulário
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Séries e Repetições
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Séries',
                          controller: _setsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icons.repeat,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          label: 'Repetições',
                          hint: 'Ex: 10-12',
                          controller: _repsController,
                          keyboardType: TextInputType.text,
                          prefixIcon: Icons.fitness_center,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Descanso e Carga
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Descanso (seg)',
                          hint: 'Ex: 60',
                          controller: _restController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icons.timer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          label: 'Carga (kg)',
                          hint: 'Ex: 20',
                          controller: _loadController,
                          keyboardType: TextInputType.text,
                          prefixIcon: Icons.scale,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Observações
                  CustomTextField(
                    label: 'Observações',
                    hint: 'Ex: Fazer lentamente, controlar a descida...',
                    controller: _notesController,
                    maxLines: 3,
                    prefixIcon: Icons.notes,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Botão salvar
          Padding(
            padding: const EdgeInsets.all(20),
            child: CustomButton(
              text: 'SALVAR CONFIGURAÇÃO',
              onPressed: _handleSave,
              type: ButtonType.primary,
            ),
          ),
        ],
      ),
    );
  }
}