import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

/// Resumo de um treino executado, só com o que os relatórios usam
/// (`studentLinks/{linkId}/sessions/{id}`).
class SessionSummary {
  const SessionSummary({
    required this.linkId,
    required this.startTime,
    required this.completed,
    this.durationMinutes,
    this.completionPercentage = 100,
  });

  final String linkId;
  final DateTime startTime;
  final bool completed;
  final int? durationMinutes;
  final int completionPercentage;

  static SessionSummary fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final start = m['startTime'];
    return SessionSummary(
      linkId: d.reference.parent.parent?.id ?? '',
      startTime: start is Timestamp ? start.toDate() : DateTime(2000),
      completed: m['completed'] as bool? ?? false,
      durationMinutes: (m['durationMinutes'] as num?)?.toInt(),
      completionPercentage: (m['completionPercentage'] as num?)?.toInt() ?? 100,
    );
  }
}

/// Treinos concluídos de todos os alunos do personal desde [since]
/// (consulta em grupo por trainerId + startTime).
final trainerSessionsSinceProvider =
    StreamProvider.family<List<SessionSummary>, DateTime>((ref, since) {
  final user = ref.watch(authProvider).user;
  if (user == null || !user.isTrainer) return Stream.value(const []);
  return FirebaseFirestore.instance
      .collectionGroup('sessions')
      .where('trainerId', isEqualTo: user.id)
      .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
      .orderBy('startTime', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map(SessionSummary.fromDoc)
          .where((x) => x.completed)
          .toList());
});

/// Início do dia (chave estável para o provider acima).
DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
