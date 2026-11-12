import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/physical_measurement_entity.dart';

/// Estado do provider de medidas físicas
class PhysicalMeasurementState {
  final Map<String, List<PhysicalMeasurementEntity>> measurementsByStudent;
  final bool isLoading;
  final String? errorMessage;

  const PhysicalMeasurementState({
    this.measurementsByStudent = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  PhysicalMeasurementState copyWith({
    Map<String, List<PhysicalMeasurementEntity>>? measurementsByStudent,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PhysicalMeasurementState(
      measurementsByStudent:
          measurementsByStudent ?? this.measurementsByStudent,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Retorna o histórico de medidas de um aluno ordenado por data (mais recente primeiro).
  List<PhysicalMeasurementEntity> historyFor(String studentId) {
    final list = measurementsByStudent[studentId] ?? [];
    return [...list]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }
}

/// Notifier para gerenciar o histórico de medidas físicas dos alunos.
class PhysicalMeasurementNotifier
    extends Notifier<PhysicalMeasurementState> {
  @override
  PhysicalMeasurementState build() {
    Future.microtask(() => _loadMockData());
    return const PhysicalMeasurementState(isLoading: true);
  }

  /// Simula carregamento de dados do Firebase.
  /// TODO: Substituir pela integração real com Firestore.
  Future<void> _loadMockData() async {
    await Future.delayed(const Duration(milliseconds: 400));

    final now = DateTime.now();

    final mockData = <String, List<PhysicalMeasurementEntity>>{
      '1': _generateHistory(
        studentId: '1',
        baseWeight: 90.0,
        baseHeight: 178.0,
        baseWaist: 95.0,
        baseChest: 105.0,
        baseHip: 100.0,
        baseFat: 22.0,
        count: 6,
        now: now,
      ),
      '2': _generateHistory(
        studentId: '2',
        baseWeight: 68.0,
        baseHeight: 165.0,
        baseWaist: 72.0,
        baseChest: 88.0,
        baseHip: 94.0,
        baseFat: 26.0,
        count: 5,
        now: now,
      ),
      '3': _generateHistory(
        studentId: '3',
        baseWeight: 98.0,
        baseHeight: 182.0,
        baseWaist: 104.0,
        baseChest: 112.0,
        baseHip: 108.0,
        baseFat: 28.0,
        count: 3,
        now: now,
      ),
      '4': _generateHistory(
        studentId: '4',
        baseWeight: 63.0,
        baseHeight: 160.0,
        baseWaist: 68.0,
        baseChest: 85.0,
        baseHip: 91.0,
        baseFat: 24.0,
        count: 8,
        now: now,
      ),
      '6': _generateHistory(
        studentId: '6',
        baseWeight: 72.0,
        baseHeight: 168.0,
        baseWaist: 76.0,
        baseChest: 90.0,
        baseHip: 96.0,
        baseFat: 25.0,
        count: 4,
        now: now,
      ),
    };

    state = state.copyWith(
      measurementsByStudent: mockData,
      isLoading: false,
    );
  }

  /// Gera um histórico de medidas simulando evolução positiva ao longo do tempo.
  List<PhysicalMeasurementEntity> _generateHistory({
    required String studentId,
    required double baseWeight,
    required double baseHeight,
    required double baseWaist,
    required double baseChest,
    required double baseHip,
    required double baseFat,
    required int count,
    required DateTime now,
  }) {
    return List.generate(count, (index) {
      // Simula melhora progressiva: quanto mais antigo, maiores os valores
      final daysAgo = (count - 1 - index) * 30;
      final progress = index / (count == 1 ? 1 : count - 1);

      return PhysicalMeasurementEntity(
        id: '${studentId}_m$index',
        studentId: studentId,
        recordedAt: now.subtract(Duration(days: daysAgo)),
        weight: double.parse(
          (baseWeight - (progress * baseWeight * 0.06)).toStringAsFixed(1),
        ),
        height: baseHeight,
        fatPercentage: double.parse(
          (baseFat - (progress * baseFat * 0.12)).toStringAsFixed(1),
        ),
        waist: double.parse(
          (baseWaist - (progress * baseWaist * 0.08)).toStringAsFixed(1),
        ),
        chest: double.parse(
          (baseChest - (progress * baseChest * 0.04)).toStringAsFixed(1),
        ),
        hip: double.parse(
          (baseHip - (progress * baseHip * 0.05)).toStringAsFixed(1),
        ),
        leftArm: double.parse((33.0 + progress * 2.5).toStringAsFixed(1)),
        rightArm: double.parse((33.5 + progress * 2.5).toStringAsFixed(1)),
        leftThigh: double.parse(
          (baseHip * 0.58 - progress * 1.5).toStringAsFixed(1),
        ),
        rightThigh: double.parse(
          (baseHip * 0.59 - progress * 1.5).toStringAsFixed(1),
        ),
      );
    });
  }

  /// Adiciona uma nova medição para um aluno.
  /// Chamado pela visão do aluno quando ele atualiza seu perfil.
  void addMeasurement(PhysicalMeasurementEntity measurement) {
    final current = Map<String, List<PhysicalMeasurementEntity>>.from(
      state.measurementsByStudent,
    );

    final existing = List<PhysicalMeasurementEntity>.from(
      current[measurement.studentId] ?? [],
    );
    existing.add(measurement);
    current[measurement.studentId] = existing;

    state = state.copyWith(measurementsByStudent: current);
  }
}

/// Provider global de medidas físicas dos alunos.
final physicalMeasurementProvider = NotifierProvider<
    PhysicalMeasurementNotifier, PhysicalMeasurementState>(
  () => PhysicalMeasurementNotifier(),
);
