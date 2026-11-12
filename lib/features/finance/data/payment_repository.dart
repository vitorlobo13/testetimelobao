import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../../trainer/domain/entities/student_entity.dart';

/// Um pagamento de mensalidade registrado pelo personal
/// (`studentLinks/{linkId}/payments/{id}`). Só controle: o app não cobra.
class PaymentEntity {
  final String id;
  final String linkId;
  final String trainerId;
  final String studentName;
  final double amount;
  final DateTime paidAt;
  final int monthsCovered;
  final String method;
  final String? notes;

  /// Vencimento antes deste pagamento e o novo vencimento depois dele.
  /// Servem para desfazer o pagamento se ele for apagado.
  final DateTime? previousDueDate;
  final DateTime? newDueDate;

  const PaymentEntity({
    required this.id,
    required this.linkId,
    required this.trainerId,
    required this.studentName,
    required this.amount,
    required this.paidAt,
    this.monthsCovered = 1,
    this.method = 'Pix',
    this.notes,
    this.previousDueDate,
    this.newDueDate,
  });

  static PaymentEntity fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return PaymentEntity(
      id: doc.id,
      linkId: d['linkId'] as String? ?? doc.reference.parent.parent?.id ?? '',
      trainerId: d['trainerId'] as String? ?? '',
      studentName: d['studentName'] as String? ?? '',
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      paidAt: _date(d['paidAt']) ?? DateTime.now(),
      monthsCovered: (d['monthsCovered'] as num?)?.toInt() ?? 1,
      method: d['method'] as String? ?? 'Pix',
      notes: d['notes'] as String?,
      previousDueDate: _date(d['previousDueDate']),
      newDueDate: _date(d['newDueDate']),
    );
  }

  static DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;
}

/// Formas de pagamento oferecidas no registro.
const kPaymentMethods = ['Pix', 'Dinheiro', 'Cartão', 'Transferência', 'Outro'];

/// Soma [months] meses mantendo o dia (31/01 + 1 mês = 28 ou 29/02).
DateTime addMonths(DateTime d, int months) {
  final y = d.year + ((d.month - 1 + months) ~/ 12);
  final m = (d.month - 1 + months) % 12 + 1;
  final lastDay = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, d.day > lastDay ? lastDay : d.day);
}

class PaymentRepository {
  PaymentRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _link(String linkId) =>
      _db.collection('studentLinks').doc(linkId);

  CollectionReference<Map<String, dynamic>> _payments(String linkId) =>
      _link(linkId).collection('payments');

  /// Pagamentos de um aluno, do mais recente para o mais antigo.
  Stream<List<PaymentEntity>> watchForLink(String linkId) => _payments(linkId)
      .orderBy('paidAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(PaymentEntity.fromDoc).toList());

  /// Pagamentos de todos os alunos do personal (consulta em grupo).
  Stream<List<PaymentEntity>> watchForTrainer(String trainerId) => _db
      .collectionGroup('payments')
      .where('trainerId', isEqualTo: trainerId)
      .orderBy('paidAt', descending: true)
      .limit(500)
      .snapshots()
      .map((s) => s.docs.map(PaymentEntity.fromDoc).toList());

  /// Registra o pagamento e empurra o vencimento do aluno [months] meses
  /// para frente (a partir do vencimento atual; sem vencimento, da data paga).
  Future<void> register({
    required StudentEntity student,
    required String trainerId,
    required double amount,
    required DateTime paidAt,
    required int months,
    required String method,
    String? notes,
  }) async {
    final previousDue = student.nextPaymentDate;
    final base = previousDue ?? paidAt;
    final newDue = addMonths(DateTime(base.year, base.month, base.day), months);

    final batch = _db.batch();
    batch.set(_payments(student.id).doc(), {
      'linkId': student.id,
      'trainerId': trainerId,
      'studentName': student.name,
      'amount': amount,
      'paidAt': Timestamp.fromDate(paidAt),
      'monthsCovered': months,
      'method': method,
      'notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
      'previousDueDate':
          previousDue == null ? null : Timestamp.fromDate(previousDue),
      'newDueDate': Timestamp.fromDate(newDue),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_link(student.id), {
      'nextPaymentDate': Timestamp.fromDate(newDue),
      if (student.paymentStatus != PaymentStatus.exempt)
        'paymentStatus': PaymentStatus.paid.name,
      'lastPaymentAt': Timestamp.fromDate(paidAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Apaga o pagamento. Se ele foi o último a mexer no vencimento,
  /// o vencimento volta ao que era antes.
  Future<void> delete(PaymentEntity payment, StudentEntity student) async {
    final batch = _db.batch();
    batch.delete(_payments(payment.linkId).doc(payment.id));
    final current = student.nextPaymentDate;
    final undo = payment.newDueDate != null &&
        current != null &&
        _sameDay(current, payment.newDueDate!);
    if (undo) {
      batch.update(_link(payment.linkId), {
        'nextPaymentDate': payment.previousDueDate == null
            ? null
            : Timestamp.fromDate(payment.previousDueDate!),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

final paymentRepositoryProvider =
    Provider<PaymentRepository>((ref) => PaymentRepository());

/// Pagamentos de um vínculo (aba Pagamentos do aluno).
final linkPaymentsProvider =
    StreamProvider.family<List<PaymentEntity>, String>(
  (ref, linkId) => ref.watch(paymentRepositoryProvider).watchForLink(linkId),
);

/// Todos os pagamentos do personal logado (tela financeira).
final trainerPaymentsProvider = StreamProvider<List<PaymentEntity>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null || !user.isTrainer) return Stream.value(const []);
  return ref.watch(paymentRepositoryProvider).watchForTrainer(user.id);
});
