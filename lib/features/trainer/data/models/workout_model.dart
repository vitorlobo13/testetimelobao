import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/exercise_entity.dart';
import '../../domain/entities/workout_entity.dart';

/// Conversão de treinos para o Firestore.
///
/// Cada exercício do treino guarda uma CÓPIA dos dados do exercício
/// (nome, grupo, vídeo...). Assim o aluno vê o treino sem precisar ler o
/// catálogo do personal, e editar o catálogo não muda treinos já entregues.
abstract final class WorkoutModel {
  static Map<String, dynamic> toMap(WorkoutEntity w) => {
        'trainerId': w.trainerId,
        'name': w.name.trim(),
        'description': w.description,
        'goal': w.goal,
        'level': w.level,
        'isActive': w.isActive,
        'startDate': _ts(w.startDate),
        'endDate': _ts(w.endDate),
        'divisions': w.divisions.map(divisionToMap).toList(),
        'totalExercises': w.totalExercises,
      };

  static WorkoutEntity fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String linkId,
  }) {
    final d = doc.data() ?? const <String, dynamic>{};
    return WorkoutEntity(
      id: doc.id,
      trainerId: d['trainerId'] as String? ?? '',
      studentId: linkId,
      name: d['name'] as String? ?? '',
      description: d['description'] as String?,
      goal: d['goal'] as String?,
      level: d['level'] as String?,
      isActive: d['isActive'] as bool? ?? false,
      startDate: _date(d['startDate']),
      endDate: _date(d['endDate']),
      createdAt: _date(d['createdAt']) ?? DateTime.now(),
      updatedAt: _date(d['updatedAt']),
      divisions: divisionsFromList(d['divisions']),
    );
  }

  static Map<String, dynamic> divisionToMap(WorkoutDivision div) => {
        'id': div.id,
        'name': div.name,
        'description': div.description,
        'order': div.order,
        'exercises': div.exercises.map(_exerciseToMap).toList(),
      };

  static List<WorkoutDivision> divisionsFromList(Object? raw) {
    final list = (raw as List?) ?? const [];
    return [
      for (final item in list)
        if (item is Map) _divisionFromMap(Map<String, dynamic>.from(item)),
    ]..sort((a, b) => a.order.compareTo(b.order));
  }

  static WorkoutDivision _divisionFromMap(Map<String, dynamic> m) =>
      WorkoutDivision(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        description: m['description'] as String?,
        order: (m['order'] as num?)?.toInt() ?? 0,
        exercises: [
          for (final e in (m['exercises'] as List?) ?? const [])
            if (e is Map) _exerciseFromMap(Map<String, dynamic>.from(e)),
        ]..sort((a, b) => a.order.compareTo(b.order)),
      );

  static Map<String, dynamic> _exerciseToMap(WorkoutExercise e) => {
        'id': e.id,
        'sets': e.sets,
        'reps': e.reps,
        'rest': e.rest,
        'load': e.load,
        'notes': e.notes,
        'order': e.order,
        'groupId': e.groupId,
        'exercise': {
          'id': e.exercise.id,
          'name': e.exercise.name,
          'category': e.exercise.category,
          'muscleGroup': e.exercise.muscleGroup,
          'equipment': e.exercise.equipment,
          'difficulty': e.exercise.difficulty,
          'videoUrl': e.exercise.videoUrl,
          'thumbnailUrl': e.exercise.thumbnailUrl,
          'description': e.exercise.description,
          'instructions': e.exercise.instructions,
        },
      };

  static WorkoutExercise _exerciseFromMap(Map<String, dynamic> m) {
    final ex = Map<String, dynamic>.from((m['exercise'] as Map?) ?? const {});
    return WorkoutExercise(
      id: m['id'] as String? ?? '',
      sets: (m['sets'] as num?)?.toInt() ?? 3,
      reps: m['reps']?.toString() ?? '',
      rest: m['rest']?.toString(),
      load: m['load']?.toString(),
      notes: m['notes'] as String?,
      order: (m['order'] as num?)?.toInt() ?? 0,
      groupId: m['groupId'] as String?,
      exercise: ExerciseEntity(
        id: ex['id'] as String? ?? '',
        name: ex['name'] as String? ?? '',
        category: ex['category'] as String? ?? '',
        muscleGroup: ex['muscleGroup'] as String? ?? '',
        equipment: ex['equipment'] as String? ?? '',
        difficulty: ex['difficulty'] as String? ?? '',
        videoUrl: ex['videoUrl'] as String?,
        thumbnailUrl: ex['thumbnailUrl'] as String?,
        description: ex['description'] as String?,
        instructions: (ex['instructions'] as List?)?.cast<String>() ?? const [],
      ),
    );
  }

  static DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;
  static Timestamp? _ts(DateTime? d) => d == null ? null : Timestamp.fromDate(d);
}
