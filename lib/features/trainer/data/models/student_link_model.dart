import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/student_entity.dart';

/// Conversão entre o documento `studentLinks/{id}` e [StudentEntity].
abstract final class StudentLinkModel {
  static StudentEntity fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return StudentEntity(
      id: doc.id,
      trainerId: d['trainerId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String?,
      photoUrl: d['photoUrl'] as String?,
      enrollmentDate: _date(d['enrollmentDate']) ?? DateTime.now(),
      isActive: d['isActive'] as bool? ?? true,
      status: _enum(StudentStatus.values, d['status'], StudentStatus.active),
      weight: (d['weight'] as num?)?.toDouble(),
      height: (d['height'] as num?)?.toDouble(),
      age: (d['age'] as num?)?.toInt(),
      birthDate: _date(d['birthDate']),
      gender: _enumOrNull(Gender.values, d['gender']),
      planType: d['planType'] as String?,
      monthlyFee: (d['monthlyFee'] as num?)?.toDouble(),
      nextPaymentDate: _date(d['nextPaymentDate']),
      paymentStatus:
          _enum(PaymentStatus.values, d['paymentStatus'], PaymentStatus.pending),
      currentWorkoutId: d['currentWorkoutId'] as String?,
      currentWorkoutName: d['currentWorkoutName'] as String?,
      currentWorkoutEndDate: _date(d['currentWorkoutEndDate']),
      lastAssessmentAt: _date(d['lastAssessmentAt']),
      lastWorkoutDate: _date(d['lastWorkoutDate']),
      totalWorkouts: (d['totalWorkouts'] as num?)?.toInt() ?? 0,
      studentUid: d['studentUid'] as String?,
      linkStatus: _enum(LinkStatus.values, d['linkStatus'], LinkStatus.pending),
    );
  }

  /// Campos que o personal pode gravar. `studentUid` e `linkStatus` de
  /// aceite ficam a cargo das Cloud Functions.
  static Map<String, dynamic> toEditableMap(StudentEntity s) => {
        'name': s.name.trim(),
        'email': s.email.trim().toLowerCase(),
        'phone': s.phone,
        'isActive': s.isActive,
        'status': s.status.name,
        'weight': s.weight,
        'height': s.height,
        'age': s.currentAge,
        'birthDate': _ts(s.birthDate),
        'gender': s.gender?.name,
        'planType': s.planType,
        'monthlyFee': s.monthlyFee,
        'nextPaymentDate': _ts(s.nextPaymentDate),
        'paymentStatus': s.paymentStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static Map<String, dynamic> toNewMap(StudentEntity s, String trainerId) => {
        ...toEditableMap(s),
        'trainerId': trainerId,
        'studentUid': null,
        'linkStatus': LinkStatus.pending.name,
        'enrollmentDate': _ts(s.enrollmentDate),
        'totalWorkouts': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;
  static Timestamp? _ts(DateTime? d) => d == null ? null : Timestamp.fromDate(d);

  static T _enum<T extends Enum>(List<T> values, Object? raw, T fallback) =>
      _enumOrNull(values, raw) ?? fallback;

  static T? _enumOrNull<T extends Enum>(List<T> values, Object? raw) {
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
