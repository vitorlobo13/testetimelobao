import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/exercise_entity.dart';
import '../seed/base_exercises.dart';

/// Catálogo de exercícios do personal: `trainers/{uid}/exercises`.
class ExerciseRepository {
  ExerciseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _exercises(String trainerId) =>
      _firestore.collection('trainers/$trainerId/exercises');

  DocumentReference<Map<String, dynamic>> _meta(String trainerId) =>
      _firestore.doc('trainers/$trainerId/meta/catalog');

  Stream<List<ExerciseEntity>> watch(String trainerId) =>
      _exercises(trainerId).snapshots().map((snap) =>
          snap.docs.map(_fromDoc).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));

  /// Copia a lista base uma única vez por personal.
  Future<void> seedIfNeeded(String trainerId) async {
    final meta = await _meta(trainerId).get();
    if (meta.exists && meta.data()?['seeded'] == true) return;

    final batch = _firestore.batch();
    for (final (name, category, muscle, equipment, difficulty) in kBaseExercises) {
      batch.set(_exercises(trainerId).doc(), {
        'name': name,
        'category': category,
        'muscleGroup': muscle,
        'equipment': equipment,
        'difficulty': difficulty,
        'videoUrl': null,
        'description': null,
        'instructions': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    batch.set(_meta(trainerId), {
      'seeded': true,
      'seededAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<String> create(String trainerId, ExerciseEntity e) async {
    final ref = await _exercises(trainerId).add({
      ..._toMap(e),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> update(String trainerId, ExerciseEntity e) =>
      _exercises(trainerId).doc(e.id).update({
        ..._toMap(e),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> delete(String trainerId, String exerciseId) =>
      _exercises(trainerId).doc(exerciseId).delete();

  static Map<String, dynamic> _toMap(ExerciseEntity e) => {
        'name': e.name.trim(),
        'category': e.category,
        'muscleGroup': e.muscleGroup,
        'equipment': e.equipment,
        'difficulty': e.difficulty,
        'videoUrl': e.videoUrl,
        'thumbnailUrl': e.thumbnailUrl,
        'description': e.description,
        'instructions': e.instructions,
      };

  static ExerciseEntity _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return ExerciseEntity(
      id: doc.id,
      name: d['name'] as String? ?? '',
      category: d['category'] as String? ?? '',
      muscleGroup: d['muscleGroup'] as String? ?? '',
      equipment: d['equipment'] as String? ?? '',
      difficulty: d['difficulty'] as String? ?? '',
      videoUrl: d['videoUrl'] as String?,
      thumbnailUrl: d['thumbnailUrl'] as String?,
      description: d['description'] as String?,
      instructions: (d['instructions'] as List?)?.cast<String>() ?? const [],
    );
  }
}
