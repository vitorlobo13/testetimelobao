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

  // Vínculo com a conta do aluno (preenchido quando ele aceita o convite)
  final String? studentUid;
  final LinkStatus linkStatus;

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
    this.studentUid,
    this.linkStatus = LinkStatus.pending,
  });

  /// O aluno já aceitou o convite e tem conta no app.
  bool get hasAccount => studentUid != null;

  StudentEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    bool? isActive,
    StudentStatus? status,
    double? weight,
    double? height,
    int? age,
    Gender? gender,
    String? planType,
    double? monthlyFee,
    DateTime? nextPaymentDate,
    PaymentStatus? paymentStatus,
    String? currentWorkoutId,
    DateTime? lastWorkoutDate,
    int? totalWorkouts,
    LinkStatus? linkStatus,
  }) {
    return StudentEntity(
      id: id ?? this.id,
      trainerId: trainerId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl,
      enrollmentDate: enrollmentDate,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      planType: planType ?? this.planType,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      currentWorkoutId: currentWorkoutId ?? this.currentWorkoutId,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      studentUid: studentUid,
      linkStatus: linkStatus ?? this.linkStatus,
    );
  }

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

/// Situação do vínculo aluno ↔ personal (controla o acesso do aluno)
enum LinkStatus {
  pending,   // Convite ainda não aceito
  active,    // Aluno com acesso ao app
  suspended, // Acesso bloqueado pelo personal
  archived,  // Aluno passou para outro personal (histórico preservado)
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