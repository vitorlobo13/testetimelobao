import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/workout_session_entity.dart';

/// Vínculo ativo do aluno logado (com quem ele treina hoje).
class ActiveLink {
  const ActiveLink({
    required this.linkId,
    required this.trainerId,
    this.consentAt,
  });
  final String linkId;
  final String trainerId;
  final DateTime? consentAt;
}

/// Treinos executados (`studentLinks/{id}/sessions`). O aluno grava a
/// sessão no início e a cada exercício concluído, para não perder nada se
/// fechar o app no meio do treino.
class SessionRepository {
  SessionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _sessions(String linkId) =>
      _firestore.collection('studentLinks/$linkId/sessions');

  /// Vínculo ativo do aluno (null se ele não tiver personal no momento).
  Stream<ActiveLink?> watchActiveLink(String studentUid) => _firestore
      .collection('studentLinks')
      .where('studentUid', isEqualTo: studentUid)
      .where('linkStatus', isEqualTo: 'active')
      .limit(1)
      .snapshots()
      .map((snap) {
        if (snap.docs.isEmpty) return null;
        final d = snap.docs.first.data();
        final consent = d['consentAt'];
        return ActiveLink(
          linkId: snap.docs.first.id,
          trainerId: d['trainerId'] as String? ?? '',
          consentAt: consent is Timestamp ? consent.toDate() : null,
        );
      });

  /// Histórico de treinos FINALIZADOS (mais recentes primeiro). Treinos
  /// começados e abandonados ficam gravados, mas não entram aqui.
  Stream<List<WorkoutSessionEntity>> watchHistory(String linkId,
          {int limit = 100}) =>
      _sessions(linkId)
          .orderBy('startTime', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => snap.docs
              .map(_fromDoc)
              .where((session) => session.completed)
              .toList());

  Future<void> save({
    required String linkId,
    required String trainerId,
    required String studentUid,
    required WorkoutSessionEntity session,
  }) {
    return _sessions(linkId).doc(session.id).set({
      'studentUid': studentUid,
      'trainerId': trainerId,
      'workoutId': session.workoutId,
      'workoutName': session.workoutName,
      'divisionId': session.divisionId,
      'divisionName': session.divisionName,
      'startTime': Timestamp.fromDate(session.startTime),
      'endTime':
          session.endTime == null ? null : Timestamp.fromDate(session.endTime!),
      'completed': session.completed,
      'durationMinutes':
          session.endTime == null ? null : session.duration.inMinutes,
      'completionPercentage': session.completionPercentage.round(),
      'exerciseSessions': [
        for (final e in session.exerciseSessions)
          {
            'id': e.id,
            'workoutExerciseId': e.workoutExerciseId,
            'exerciseName': e.exerciseName,
            'completed': e.completed,
            'sets': [
              for (final s in e.sets)
                {
                  'setNumber': s.setNumber,
                  'actualReps': s.actualReps,
                  'actualLoad': s.actualLoad,
                  'completed': s.completed,
                  'completedAt': s.completedAt == null
                      ? null
                      : Timestamp.fromDate(s.completedAt!),
                },
            ],
          },
      ],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> registerConsent(String linkId) =>
      _firestore.doc('studentLinks/$linkId').update({
        'consentAt': FieldValue.serverTimestamp(),
        'consentVersion': 1,
      });

  static WorkoutSessionEntity _fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    DateTime? date(Object? v) => v is Timestamp ? v.toDate() : null;
    return WorkoutSessionEntity(
      id: doc.id,
      studentId: d['studentUid'] as String? ?? '',
      workoutId: d['workoutId'] as String? ?? '',
      workoutName: d['workoutName'] as String?,
      divisionId: d['divisionId'] as String? ?? '',
      divisionName: d['divisionName'] as String?,
      startTime: date(d['startTime']) ?? DateTime.now(),
      endTime: date(d['endTime']),
      completed: d['completed'] as bool? ?? false,
      exerciseSessions: [
        for (final raw in (d['exerciseSessions'] as List?) ?? const [])
          if (raw is Map)
            ExerciseSessionEntity(
              id: raw['id'] as String? ?? '',
              workoutExerciseId: raw['workoutExerciseId'] as String? ?? '',
              exerciseName: raw['exerciseName'] as String?,
              completed: raw['completed'] as bool? ?? false,
              sets: [
                for (final s in (raw['sets'] as List?) ?? const [])
                  if (s is Map)
                    SetSessionEntity(
                      setNumber: (s['setNumber'] as num?)?.toInt() ?? 0,
                      actualReps: (s['actualReps'] as num?)?.toInt(),
                      actualLoad: (s['actualLoad'] as num?)?.toDouble(),
                      completed: s['completed'] as bool? ?? false,
                      completedAt: date(s['completedAt']),
                    ),
              ],
            ),
      ],
    );
  }
}
