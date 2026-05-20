/// Entidade de Aluno
class StudentEntity {
  final String id;
  final String trainerId;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final DateTime enrollmentDate;
  final bool isActive;
  final StudentStatus status;
  
  // Dados físicos
  final double? weight;
  final double? height;
  final int? age;
  final Gender? gender;
  
  // Plano e pagamento
  final String? planType;
  final double? monthlyFee;
  final DateTime? nextPaymentDate;
  final PaymentStatus paymentStatus;
  
  // Treino atual
  final String? currentWorkoutId;
  final DateTime? lastWorkoutDate;
  final int totalWorkouts;

  const StudentEntity({
    required this.id,
    required this.trainerId,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    required this.enrollmentDate,
    this.isActive = true,
    this.status = StudentStatus.active,
    this.weight,
    this.height,
    this.age,
    this.gender,
    this.planType,
    this.monthlyFee,
    this.nextPaymentDate,
    this.paymentStatus = PaymentStatus.pending,
    this.currentWorkoutId,
    this.lastWorkoutDate,
    this.totalWorkouts = 0,
  });

  /// Calcula IMC
  double? get bmi {
    if (weight != null && height != null && height! > 0) {
      return weight! / ((height! / 100) * (height! / 100));
    }
    return null;
  }

  /// Verifica se pagamento está atrasado
  bool get isPaymentOverdue {
    if (nextPaymentDate == null) return false;
    return nextPaymentDate!.isBefore(DateTime.now());
  }

  /// Dias desde último treino
  int? get daysSinceLastWorkout {
    if (lastWorkoutDate == null) return null;
    return DateTime.now().difference(lastWorkoutDate!).inDays;
  }
}

/// Status do aluno
enum StudentStatus {
  active,      // Ativo
  inactive,    // Inativo
  suspended,   // Suspenso
  trial,       // Período experimental
}

/// Status de pagamento
enum PaymentStatus {
  paid,        // Pago
  pending,     // Pendente
  overdue,     // Atrasado
  exempt,      // Isento
}

/// Gênero
enum Gender {
  male,
  female,
  other,
}

/// Extensões para enums
extension StudentStatusExtension on StudentStatus {
  String get displayName {
    switch (this) {
      case StudentStatus.active:
        return 'Ativo';
      case StudentStatus.inactive:
        return 'Inativo';
      case StudentStatus.suspended:
        return 'Suspenso';
      case StudentStatus.trial:
        return 'Experimental';
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.paid:
        return 'Pago';
      case PaymentStatus.pending:
        return 'Pendente';
      case PaymentStatus.overdue:
        return 'Atrasado';
      case PaymentStatus.exempt:
        return 'Isento';
    }
  }
}