import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mensagem enviada pelo "Fale com a gente" (`feedback/{id}`).
/// Quem envia só cria; a conta admin lê e marca como resolvida.
class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    required this.message,
    required this.createdAt,
    this.resolved = false,
  });

  final String id;
  final String name;
  final String email;
  final String type;
  final String message;
  final DateTime createdAt;
  final bool resolved;

  static FeedbackEntry fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final at = m['createdAt'];
    return FeedbackEntry(
      id: d.id,
      name: m['name'] as String? ?? '',
      email: m['email'] as String? ?? '',
      type: m['type'] as String? ?? 'Dúvida',
      message: m['message'] as String? ?? '',
      createdAt: at is Timestamp ? at.toDate() : DateTime.now(),
      resolved: m['resolved'] as bool? ?? false,
    );
  }
}

const kFeedbackTypes = ['Dúvida', 'Erro no app', 'Sugestão'];

class FeedbackRepository {
  FeedbackRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('feedback');

  Future<void> send({
    required String uid,
    required String name,
    required String email,
    required String role,
    required String type,
    required String message,
  }) =>
      _col.add({
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'type': type,
        'message': message.trim(),
        'resolved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<List<FeedbackEntry>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(FeedbackEntry.fromDoc).toList());

  Future<void> setResolved(String id, bool resolved) =>
      _col.doc(id).update({'resolved': resolved});
}

final feedbackRepositoryProvider =
    Provider<FeedbackRepository>((ref) => FeedbackRepository());

/// Só a conta admin consegue ler (regra do Firestore).
final feedbackListProvider = StreamProvider<List<FeedbackEntry>>(
    (ref) => ref.watch(feedbackRepositoryProvider).watchAll());
