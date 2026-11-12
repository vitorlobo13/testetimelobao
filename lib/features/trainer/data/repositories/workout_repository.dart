import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/workout_entity.dart';
import '../models/workout_model.dart';

/// Treinos dos alunos (`studentLinks/{id}/workouts`). Cada aluno tem um
/// único treino ativo; ao prescrever um novo, o anterior vai para o
/// histórico (isActive = false).
class WorkoutRepository {
  WorkoutRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _workouts(String linkId) =>
      _firestore.collection('studentLinks/$linkId/workouts');

  /// Todos os treinos do aluno, o ativo primeiro e depois os mais recentes.
  Stream<List<WorkoutEntity>> watchStudentWorkouts(String linkId) =>
      _workouts(linkId).snapshots().map((snap) {
        final list = snap.docs
            .map((d) => WorkoutModel.fromDoc(d, linkId: linkId))
            .toList()
          ..sort((a, b) {
            if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
            return b.createdAt.compareTo(a.createdAt);
          });
        return list;
      });

  /// Treino ativo do aluno (usado na área do aluno).
  Stream<WorkoutEntity?> watchActiveWorkout(String linkId) => _workouts(linkId)
      .where('isActive', isEqualTo: true)
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isEmpty
          ? null
          : WorkoutModel.fromDoc(snap.docs.first, linkId: linkId));

  /// Salva um treino novo como o ativo do aluno (ou atualiza o existente,
  /// se [workout.id] já existir). Arquiva qualquer outro treino ativo.
  Future<String> saveActive({
    required String linkId,
    required WorkoutEntity workout,
  }) async {
    final active =
        await _workouts(linkId).where('isActive', isEqualTo: true).get();
    final batch = _firestore.batch();

    final ref = workout.id.isEmpty
        ? _workouts(linkId).doc()
        : _workouts(linkId).doc(workout.id);

    for (final doc in active.docs) {
      if (doc.id != ref.id) {
        batch.update(doc.reference, {
          'isActive': false,
          'archivedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    batch.set(
      ref,
      {
        ...WorkoutModel.toMap(workout.copyWith(isActive: true)),
        if (workout.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.update(_firestore.doc('studentLinks/$linkId'), {
      'currentWorkoutId': ref.id,
      'currentWorkoutName': workout.name,
      'currentWorkoutEndDate':
          workout.endDate == null ? null : Timestamp.fromDate(workout.endDate!),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return ref.id;
  }

  /// Reativa um treino antigo do histórico.
  Future<void> reactivate(String linkId, WorkoutEntity workout) =>
      saveActive(linkId: linkId, workout: workout);

  Future<void> delete(String linkId, String workoutId) =>
      _workouts(linkId).doc(workoutId).delete();
}
