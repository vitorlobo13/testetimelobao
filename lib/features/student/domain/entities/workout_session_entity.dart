import '../../../trainer/domain/entities/workout_entity.dart';

/// Sessão de treino do aluno
class WorkoutSessionEntity {
  final String id;
  final String studentId;
  final String workoutId;
  final String divisionId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool completed;
  final List<ExerciseSessionEntity> exerciseSessions;

  const WorkoutSessionEntity({
    required this.id,
    required this.studentId,
    required this.workoutId,
    required this.divisionId,
    required this.startTime,
    this.endTime,
    this.completed = false,
    required this.exerciseSessions,
  });

  /// Duração total da sessão
  Duration get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }

  /// Porcentagem de conclusão
  double get completionPercentage {
    if (exerciseSessions.isEmpty) return 0.0;
    final completedCount = exerciseSessions.where((e) => e.completed).length;
    return (completedCount / exerciseSessions.length) * 100;
  }
}

/// Sessão de exercício individual
class ExerciseSessionEntity {
  final String id;
  final String workoutExerciseId;
  final List<SetSessionEntity> sets;
  final bool completed;

  const ExerciseSessionEntity({
    required this.id,
    required this.workoutExerciseId,
    required this.sets,
    this.completed = false,
  });

  /// Total de séries completadas
  int get completedSets => sets.where((s) => s.completed).length;
}

/// Sessão de série individual
class SetSessionEntity {
  final int setNumber;
  final int? actualReps; // Repetições realizadas
  final double? actualLoad; // Carga utilizada
  final DateTime? completedAt;
  final bool completed;

  const SetSessionEntity({
    required this.setNumber,
    this.actualReps,
    this.actualLoad,
    this.completedAt,
    this.completed = false,
  });

  SetSessionEntity copyWith({
    int? setNumber,
    int? actualReps,
    double? actualLoad,
    DateTime? completedAt,
    bool? completed,
  }) {
    return SetSessionEntity(
      setNumber: setNumber ?? this.setNumber,
      actualReps: actualReps ?? this.actualReps,
      actualLoad: actualLoad ?? this.actualLoad,
      completedAt: completedAt ?? this.completedAt,
      completed: completed ?? this.completed,
    );
  }
}