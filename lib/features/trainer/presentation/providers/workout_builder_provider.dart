import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/workout_entity.dart';
import '../../domain/entities/exercise_entity.dart';

/// Estado do construtor de treino (Imutável)
class WorkoutBuilderState {
  final String workoutName;
  final String? workoutDescription;
  final List<WorkoutDivision> divisions;
  final int currentDivisionIndex;

  const WorkoutBuilderState({
    this.workoutName = '',
    this.workoutDescription,
    this.divisions = const [],
    this.currentDivisionIndex = 0,
  });

  WorkoutBuilderState copyWith({
    String? workoutName,
    String? workoutDescription,
    List<WorkoutDivision>? divisions,
    int? currentDivisionIndex,
  }) {
    return WorkoutBuilderState(
      workoutName: workoutName ?? this.workoutName,
      workoutDescription: workoutDescription ?? this.workoutDescription,
      divisions: divisions ?? this.divisions,
      currentDivisionIndex: currentDivisionIndex ?? this.currentDivisionIndex,
    );
  }

  WorkoutDivision? get currentDivision {
    if (divisions.isEmpty || currentDivisionIndex >= divisions.length) {
      return null;
    }
    return divisions[currentDivisionIndex];
  }

  int get totalExercises => divisions.fold(
        0,
        (sum, division) => sum + division.exercises.length,
      );
}

/// Provider do construtor de treino (Sintaxe Notifier)
class WorkoutBuilderNotifier extends Notifier<WorkoutBuilderState> {
  final _uuid = const Uuid();

  @override
  WorkoutBuilderState build() {
    // Estado inicial definido aqui na nova sintaxe
    return const WorkoutBuilderState();
  }

  /// Atualiza nome do treino
  void setWorkoutName(String name) {
    state = state.copyWith(workoutName: name);
  }

  /// Atualiza descrição do treino
  void setWorkoutDescription(String description) {
    state = state.copyWith(workoutDescription: description);
  }

  /// Adiciona nova divisão
  void addDivision(String name, {String? description}) {
    final newDivision = WorkoutDivision(
      id: _uuid.v4(),
      name: name,
      description: description,
      exercises: [],
      order: state.divisions.length,
    );

    state = state.copyWith(
      divisions: [...state.divisions, newDivision],
    );
  }

  /// Remove divisão
  void removeDivision(int index) {
    if (index < 0 || index >= state.divisions.length) return;

    final updatedDivisions = List<WorkoutDivision>.from(state.divisions);
    updatedDivisions.removeAt(index);

    // Reordena
    for (var i = 0; i < updatedDivisions.length; i++) {
      updatedDivisions[i] = WorkoutDivision(
        id: updatedDivisions[i].id,
        name: updatedDivisions[i].name,
        description: updatedDivisions[i].description,
        exercises: updatedDivisions[i].exercises,
        order: i,
      );
    }

    state = state.copyWith(
      divisions: updatedDivisions,
      currentDivisionIndex: state.currentDivisionIndex >= updatedDivisions.length
          ? (updatedDivisions.length - 1).clamp(0, updatedDivisions.length)
          : state.currentDivisionIndex,
    );
  }

  /// Altera divisão atual
  void setCurrentDivision(int index) {
    if (index >= 0 && index < state.divisions.length) {
      state = state.copyWith(currentDivisionIndex: index);
    }
  }

  /// Adiciona exercício na divisão atual
  void addExercise(ExerciseEntity exercise) {
    final currentDiv = state.currentDivision;
    if (currentDiv == null) return;

    final newExercise = WorkoutExercise(
      id: _uuid.v4(),
      exercise: exercise,
      sets: 3,
      reps: '10-12',
      rest: '60',
      order: currentDiv.exercises.length,
    );

    final updatedDivision = WorkoutDivision(
      id: currentDiv.id,
      name: currentDiv.name,
      description: currentDiv.description,
      exercises: [...currentDiv.exercises, newExercise],
      order: currentDiv.order,
    );

    _updateDivision(state.currentDivisionIndex, updatedDivision);
  }

  /// Remove exercício
  void removeExercise(int exerciseIndex) {
    final currentDiv = state.currentDivision;
    if (currentDiv == null) return;

    final updatedExercises = List<WorkoutExercise>.from(currentDiv.exercises);
    updatedExercises.removeAt(exerciseIndex);

    // Reordena
    for (var i = 0; i < updatedExercises.length; i++) {
      updatedExercises[i] = updatedExercises[i].copyWith(order: i);
    }

    final updatedDivision = WorkoutDivision(
      id: currentDiv.id,
      name: currentDiv.name,
      description: currentDiv.description,
      exercises: updatedExercises,
      order: currentDiv.order,
    );

    _updateDivision(state.currentDivisionIndex, updatedDivision);
  }

  /// Atualiza configuração de exercício
  void updateExercise(int exerciseIndex, WorkoutExercise updatedExercise) {
    final currentDiv = state.currentDivision;
    if (currentDiv == null) return;

    final updatedExercises = List<WorkoutExercise>.from(currentDiv.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final updatedDivision = WorkoutDivision(
      id: currentDiv.id,
      name: currentDiv.name,
      description: currentDiv.description,
      exercises: updatedExercises,
      order: currentDiv.order,
    );

    _updateDivision(state.currentDivisionIndex, updatedDivision);
  }

  /// Atualiza uma divisão específica
  void _updateDivision(int index, WorkoutDivision updatedDivision) {
    final updatedDivisions = List<WorkoutDivision>.from(state.divisions);
    updatedDivisions[index] = updatedDivision;
    state = state.copyWith(divisions: updatedDivisions);
  }

  /// Carrega o construtor a partir de divisões e dados de um modelo existente
  void loadFromTemplate({
    required String name,
    required String? description,
    required List<WorkoutDivision> divisions,
  }) {
    state = WorkoutBuilderState(
      workoutName: name,
      workoutDescription: description,
      divisions: divisions,
      currentDivisionIndex: 0,
    );
  }

  /// Reseta o construtor
  void reset() {
    state = const WorkoutBuilderState();
  }

  /// Salva o treino
  Future<bool> saveWorkout(String studentId, String trainerId) async {
    if (state.workoutName.isEmpty || state.divisions.isEmpty) {
      return false;
    }

    try {
      await Future.delayed(const Duration(seconds: 1));

      final workout = WorkoutEntity(
        id: _uuid.v4(),
        trainerId: trainerId,
        studentId: studentId,
        name: state.workoutName,
        description: state.workoutDescription,
        divisions: state.divisions,
        createdAt: DateTime.now(),
        isActive: true,
      );

      developer.log('Treino salvo: ${workout.name}');
      return true;
    } catch (e) {
      return false;
    }
  }
} // <--- Chave de fechamento da classe movida para o final

/// Provider global
final workoutBuilderProvider =
    NotifierProvider<WorkoutBuilderNotifier, WorkoutBuilderState>(() {
  return WorkoutBuilderNotifier();
});