import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/services/trainer_updates.dart';

/// Preferências do personal em `trainers/{uid}/meta/settings`.
class TrainerSettingsRepository {
  TrainerSettingsRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.doc('trainers/$uid/meta/settings');

  Stream<UpdateSettings> watch(String uid) =>
      _doc(uid).snapshots().map((s) => UpdateSettings.fromMap(s.data()));

  Future<void> saveUpdateSettings(String uid, UpdateSettings s) =>
      _doc(uid).set({
        ...s.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}

final trainerSettingsRepositoryProvider =
    Provider<TrainerSettingsRepository>((ref) => TrainerSettingsRepository());

/// Prazos das Atualizações do personal logado (padrões até ele mudar).
final updateSettingsProvider = StreamProvider<UpdateSettings>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null || !user.isTrainer) {
    return Stream.value(const UpdateSettings());
  }
  return ref.watch(trainerSettingsRepositoryProvider).watch(user.id);
});
