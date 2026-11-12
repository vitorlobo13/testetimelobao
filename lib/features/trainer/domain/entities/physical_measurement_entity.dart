/// Entidade que representa um snapshot de medidas físicas de um aluno
/// registrado pelo próprio aluno em determinada data.
class PhysicalMeasurementEntity {
  final String id;
  final String studentId;
  final DateTime recordedAt;

  // Medidas básicas
  final double? weight; // kg
  final double? height; // cm

  // Composição corporal
  final double? fatPercentage; // %
  final double? muscleMass; // kg

  // Perímetros (cm)
  final double? waist;
  final double? hip;
  final double? chest;
  final double? leftArm;
  final double? rightArm;
  final double? leftThigh;
  final double? rightThigh;

  const PhysicalMeasurementEntity({
    required this.id,
    required this.studentId,
    required this.recordedAt,
    this.weight,
    this.height,
    this.fatPercentage,
    this.muscleMass,
    this.waist,
    this.hip,
    this.chest,
    this.leftArm,
    this.rightArm,
    this.leftThigh,
    this.rightThigh,
  });

  /// Calcula o IMC se peso e altura estiverem disponíveis.
  double? get bmi {
    if (weight != null && height != null && height! > 0) {
      final heightM = height! / 100;
      return weight! / (heightM * heightM);
    }
    return null;
  }

  PhysicalMeasurementEntity copyWith({
    String? id,
    String? studentId,
    DateTime? recordedAt,
    double? weight,
    double? height,
    double? fatPercentage,
    double? muscleMass,
    double? waist,
    double? hip,
    double? chest,
    double? leftArm,
    double? rightArm,
    double? leftThigh,
    double? rightThigh,
  }) {
    return PhysicalMeasurementEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      recordedAt: recordedAt ?? this.recordedAt,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      fatPercentage: fatPercentage ?? this.fatPercentage,
      muscleMass: muscleMass ?? this.muscleMass,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      chest: chest ?? this.chest,
      leftArm: leftArm ?? this.leftArm,
      rightArm: rightArm ?? this.rightArm,
      leftThigh: leftThigh ?? this.leftThigh,
      rightThigh: rightThigh ?? this.rightThigh,
    );
  }
}
