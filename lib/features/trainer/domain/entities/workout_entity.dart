import 'exercise_entity.dart';

/// Entidade de Treino Completo
class WorkoutEntity {
  final String id;
  final String trainerId;
  final String studentId;
  final String name;
  final String? description;
  final List<WorkoutDivision> divisions;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  /// Validade do treino (o personal é avisado quando estiver vencendo).
  final DateTime? startDate;
  final DateTime? endDate;
  final String? goal;
  final String? level;

  const WorkoutEntity({
    required this.id,
    required this.trainerId,
    required this.studentId,
    required this.name,
    this.description,
    required this.divisions,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.goal,
    this.level,
  });

  int get totalExercises =>
      divisions.fold(0, (sum, div) => sum + div.exercises.length);
  int get totalDivisions => divisions.length;

  /// Treino vencido (passou da data final).
  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());

  /// Faltam 7 dias ou menos para vencer.
  bool get isExpiringSoon =>
      endDate != null &&
      !isExpired &&
      endDate!.difference(DateTime.now()).inDays <= 7;

  WorkoutEntity copyWith({
    String? id,
    String? trainerId,
    String? studentId,
    String? name,
    String? description,
    List<WorkoutDivision>? divisions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    String? goal,
    String? level,
  }) {
    return WorkoutEntity(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      description: description ?? this.description,
      divisions: divisions ?? this.divisions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      goal: goal ?? this.goal,
      level: level ?? this.level,
    );
  }
}

/// Divisão do Treino (A, B, C, D, etc.)
class WorkoutDivision {
  final String id;
  final String name;
  final String? description;
  final List<WorkoutExercise> exercises;
  final int order;

  const WorkoutDivision({
    required this.id,
    required this.name,
    this.description,
    required this.exercises,
    required this.order,
  });

  WorkoutDivision copyWith({
    String? id,
    String? name,
    String? description,
    List<WorkoutExercise>? exercises,
    int? order,
  }) {
    return WorkoutDivision(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      order: order ?? this.order,
    );
  }
}

/// Exercício dentro do treino (com configurações)
class WorkoutExercise {
  final String id;
  final ExerciseEntity exercise;
  final int sets;
  final String reps;
  final String? rest;
  final String? load;
  final String? notes;
  final int order;

  /// Exercícios da mesma divisão com o mesmo `groupId` formam um
  /// conjugado (bi-set / tri-set): feitos em sequência, sem descanso.
  final String? groupId;

  const WorkoutExercise({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.reps,
    this.rest,
    this.load,
    this.notes,
    required this.order,
    this.groupId,
  });

  bool get isGrouped => groupId != null;

  WorkoutExercise copyWith({
    String? id,
    ExerciseEntity? exercise,
    int? sets,
    String? reps,
    String? rest,
    String? load,
    String? notes,
    int? order,
    String? groupId,
    bool clearGroup = false,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      rest: rest ?? this.rest,
      load: load ?? this.load,
      notes: notes ?? this.notes,
      order: order ?? this.order,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
    );
  }
}
