import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../domain/entities/physical_measurement_entity.dart';

final assessmentRepositoryProvider =
    Provider<AssessmentRepository>((ref) => AssessmentRepository());

/// Histórico de medidas/avaliações de um aluno (id do vínculo), em tempo
/// real e do mais recente para o mais antigo.
final assessmentsProvider =
    StreamProvider.family<List<PhysicalMeasurementEntity>, String>(
  (ref, linkId) => ref.watch(assessmentRepositoryProvider).watch(linkId),
);

/// Estado do provider de medidas físicas (mantido para as telas antigas).
class PhysicalMeasurementState {
  final bool isLoading;
  final String? errorMessage;

  const PhysicalMeasurementState({this.isLoading = false, this.errorMessage});
}

/// Grava medidas no Firestore. Quem leu o histórico usa [assessmentsProvider].
class PhysicalMeasurementNotifier extends Notifier<PhysicalMeasurementState> {
  @override
  PhysicalMeasurementState build() => const PhysicalMeasurementState();

  /// Adiciona uma medição. `measurement.studentId` é o id do vínculo.
  /// O autor (aluno ou personal) vem do papel de quem está logado.
  Future<void> addMeasurement(PhysicalMeasurementEntity measurement) {
    final user = ref.read(authProvider).user;
    return ref.read(assessmentRepositoryProvider).add(
          measurement,
          recordedBy: (user?.isStudent ?? false) ? 'student' : 'trainer',
        );
  }

  Future<void> deleteMeasurement(PhysicalMeasurementEntity measurement) => ref
      .read(assessmentRepositoryProvider)
      .delete(measurement.studentId, measurement.id);
}

/// Provider global de medidas físicas dos alunos.
final physicalMeasurementProvider =
    NotifierProvider<PhysicalMeasurementNotifier, PhysicalMeasurementState>(
  () => PhysicalMeasurementNotifier(),
);
