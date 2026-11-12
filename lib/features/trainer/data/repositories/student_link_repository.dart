import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/student_entity.dart';
import '../models/student_link_model.dart';

/// Alunos do personal = documentos `studentLinks` com `trainerId` dele.
class StudentLinkRepository {
  StudentLinkRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _links =>
      _firestore.collection('studentLinks');

  /// Todos os vínculos do personal, mais recentes primeiro.
  Stream<List<StudentEntity>> watchTrainerStudents(String trainerId) => _links
      .where('trainerId', isEqualTo: trainerId)
      .snapshots()
      .map((snap) => snap.docs.map(StudentLinkModel.fromDoc).toList()
        ..sort((a, b) => b.enrollmentDate.compareTo(a.enrollmentDate)));

  Future<String> create(StudentEntity student, String trainerId,
      {String? trainerName}) async {
    final ref = await _links.add({
      ...StudentLinkModel.toNewMap(student, trainerId),
      'trainerName': trainerName,
    });
    return ref.id;
  }

  Future<void> update(StudentEntity student) =>
      _links.doc(student.id).update(StudentLinkModel.toEditableMap(student));

  /// Suspende ou reativa o acesso do aluno ao app.
  Future<void> setSuspended(StudentEntity student, bool suspended) {
    final linkStatus = suspended
        ? LinkStatus.suspended
        : (student.hasAccount ? LinkStatus.active : LinkStatus.pending);
    return _links.doc(student.id).update({
      'status': (suspended ? StudentStatus.suspended : StudentStatus.active).name,
      'isActive': !suspended,
      'linkStatus': linkStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Exclui o aluno e TODOS os dados dele (treinos, histórico, avaliações) —
  /// feito no servidor para apagar também as subcoleções (LGPD).
  Future<void> deleteWithData(String linkId) => _functions
      .httpsCallable('deleteStudentLink')
      .call<void>({'linkId': linkId});
}
