import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/physical_measurement_entity.dart';

/// Avaliações físicas e medidas (`studentLinks/{id}/assessments`) e fotos
/// de evolução (Storage `studentLinks/{id}/photos/...`). O aluno pode
/// registrar as próprias medidas; o personal registra avaliações completas.
class AssessmentRepository {
  AssessmentRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const maxPhotoBytes = 8 * 1024 * 1024;

  CollectionReference<Map<String, dynamic>> _col(String linkId) =>
      _firestore.collection('studentLinks/$linkId/assessments');

  /// Histórico do aluno, mais recente primeiro.
  Stream<List<PhysicalMeasurementEntity>> watch(String linkId) => _col(linkId)
      .orderBy('recordedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => _fromDoc(d, linkId)).toList());

  Future<void> add(PhysicalMeasurementEntity m,
      {required String recordedBy}) async {
    await _col(m.studentId).add({
      ..._toMap(m),
      'recordedBy': recordedBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // O personal já marca a data da última avaliação no vínculo (para as
    // Atualizações); as medidas lançadas pelo aluno a Function atualiza.
    if (recordedBy == 'trainer') {
      await _firestore.doc('studentLinks/${m.studentId}').update({
        'lastAssessmentAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> delete(String linkId, String id) => _col(linkId).doc(id).delete();

  /// Envia uma foto de evolução e devolve a URL de download.
  Future<String> uploadPhoto(String linkId, XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > maxPhotoBytes) {
      throw const FormatException('Foto maior que 8 MB.');
    }
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('studentLinks/$linkId/photos/$name');
    await ref.putData(
      bytes,
      SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  static Map<String, dynamic> _toMap(PhysicalMeasurementEntity m) => {
        'recordedAt': Timestamp.fromDate(m.recordedAt),
        'weight': m.weight,
        'height': m.height,
        'fatPercentage': m.fatPercentage,
        'muscleMass': m.muscleMass,
        'waist': m.waist,
        'hip': m.hip,
        'chest': m.chest,
        'leftArm': m.leftArm,
        'rightArm': m.rightArm,
        'leftThigh': m.leftThigh,
        'rightThigh': m.rightThigh,
        'notes': m.notes,
        'photoUrls': m.photoUrls,
      };

  static PhysicalMeasurementEntity _fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, String linkId) {
    final d = doc.data() ?? const <String, dynamic>{};
    double? n(String k) => (d[k] as num?)?.toDouble();
    final at = d['recordedAt'];
    return PhysicalMeasurementEntity(
      id: doc.id,
      studentId: linkId,
      recordedAt: at is Timestamp ? at.toDate() : DateTime.now(),
      weight: n('weight'),
      height: n('height'),
      fatPercentage: n('fatPercentage'),
      muscleMass: n('muscleMass'),
      waist: n('waist'),
      hip: n('hip'),
      chest: n('chest'),
      leftArm: n('leftArm'),
      rightArm: n('rightArm'),
      leftThigh: n('leftThigh'),
      rightThigh: n('rightThigh'),
      notes: d['notes'] as String?,
      photoUrls: (d['photoUrls'] as List?)?.cast<String>() ?? const [],
      recordedBy: d['recordedBy'] as String? ?? 'trainer',
    );
  }
}

/// Anamnese do aluno: um documento `studentLinks/{id}/anamnese/current`
/// com as perguntas enviadas pelo personal e as respostas do aluno.
class StudentAnamnese {
  const StudentAnamnese({
    required this.questions,
    required this.answers,
    this.sentAt,
    this.answeredAt,
  });

  final List<String> questions;
  final Map<int, String> answers;
  final DateTime? sentAt;
  final DateTime? answeredAt;

  bool get isPending => questions.isNotEmpty && answeredAt == null;
}

class AnamneseRepository {
  AnamneseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const defaultQuestions = [
    'Quais seus objetivos principais?',
    'Tem alguma doença crônica ou histórico médico importante?',
    'Usa algum medicamento contínuo?',
    'Tem ou já teve lesões? Onde?',
    'Sente dor ao fazer algum movimento?',
    'Como é sua rotina (trabalho, sono, alimentação)?',
    'Quantas vezes por semana pode treinar?',
    'Observações gerais',
  ];

  DocumentReference<Map<String, dynamic>> _doc(String linkId) =>
      _firestore.doc('studentLinks/$linkId/anamnese/current');

  DocumentReference<Map<String, dynamic>> _template(String trainerId) =>
      _firestore.doc('trainers/$trainerId/meta/anamnese');

  Stream<List<String>> watchTemplate(String trainerId) =>
      _template(trainerId).snapshots().map((s) {
        final list = (s.data()?['questions'] as List?)?.cast<String>();
        return (list == null || list.isEmpty) ? defaultQuestions : list;
      });

  Future<void> saveTemplate(String trainerId, List<String> questions) =>
      _template(trainerId).set({
        'questions': questions,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Stream<StudentAnamnese?> watch(String linkId) => _doc(linkId).snapshots().map((s) {
        final d = s.data();
        if (d == null) return null;
        DateTime? date(Object? v) => v is Timestamp ? v.toDate() : null;
        final raw = Map<String, dynamic>.from((d['answers'] as Map?) ?? const {});
        return StudentAnamnese(
          questions: (d['questions'] as List?)?.cast<String>() ?? const [],
          answers: {
            for (final e in raw.entries)
              if (int.tryParse(e.key) != null) int.parse(e.key): e.value.toString(),
          },
          sentAt: date(d['sentAt']),
          answeredAt: date(d['answeredAt']),
        );
      });

  /// Personal envia (ou reenvia) o formulário para o aluno responder.
  Future<void> sendToStudent(String linkId, List<String> questions) =>
      _doc(linkId).set({
        'questions': questions,
        'answers': <String, String>{},
        'sentAt': FieldValue.serverTimestamp(),
        'answeredAt': null,
      });

  /// Aluno (ou personal, numa conversa presencial) salva as respostas.
  Future<void> saveAnswers(String linkId, Map<int, String> answers) =>
      _doc(linkId).update({
        'answers': {for (final e in answers.entries) '${e.key}': e.value},
        'answeredAt': FieldValue.serverTimestamp(),
      });
}
