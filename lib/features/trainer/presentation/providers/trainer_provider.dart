import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/student_entity.dart';

/// Estado do Dashboard do Trainer
class TrainerDashboardState {
  final List<StudentEntity> students;
  final bool isLoading;
  final String? errorMessage;
  final int totalStudents;
  final int activeStudents;
  final int pendingPayments;
  final double monthlyRevenue;

  const TrainerDashboardState({
    this.students = const [],
    this.isLoading = false,
    this.errorMessage,
    this.totalStudents = 0,
    this.activeStudents = 0,
    this.pendingPayments = 0,
    this.monthlyRevenue = 0.0,
  });

  TrainerDashboardState copyWith({
    List<StudentEntity>? students,
    bool? isLoading,
    String? errorMessage,
    int? totalStudents,
    int? activeStudents,
    int? pendingPayments,
    double? monthlyRevenue,
  }) {
    return TrainerDashboardState(
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      totalStudents: totalStudents ?? this.totalStudents,
      activeStudents: activeStudents ?? this.activeStudents,
      pendingPayments: pendingPayments ?? this.pendingPayments,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
    );
  }
}

/// Provider do Dashboard do Trainer
class TrainerDashboardNotifier extends Notifier<TrainerDashboardState> {
  
  @override
  TrainerDashboardState build() {
    // No Riverpod 3.0, o estado inicial é definido no build.
    // Usamos microtask para disparar o fetch sem bloquear a construção do widget.
    Future.microtask(() => loadDashboardData());
    
    return const TrainerDashboardState();
  }

  /// Carrega dados do dashboard
  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Simulação de busca no Firebase (está no seu TODO)
      await Future.delayed(const Duration(seconds: 1));

      final mockStudents = _generateMockStudents();
      
      final activeCount = mockStudents.where((s) => s.isActive).length;
      final pendingCount = mockStudents
          .where((s) => s.paymentStatus == PaymentStatus.pending || 
                      s.paymentStatus == PaymentStatus.overdue)
          .length;
      final revenue = mockStudents
          .where((s) => s.isActive && s.monthlyFee != null)
          .fold(0.0, (sum, s) => sum + s.monthlyFee!);

      state = state.copyWith(
        students: mockStudents,
        isLoading: false,
        totalStudents: mockStudents.length,
        activeStudents: activeCount,
        pendingPayments: pendingCount,
        monthlyRevenue: revenue,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar dados: ${e.toString()}',
      );
    }
  }

  /// Atualiza dados (pull to refresh)
  Future<void> refresh() async {
    await loadDashboardData();
  }

  /// Adiciona um novo aluno
  void addStudent(StudentEntity newStudent) {
    final updatedList = [newStudent, ...state.students];
    _recalculateTotals(updatedList);
  }

  /// Atualiza os dados de um aluno
  void updateStudent(StudentEntity updatedStudent) {
    final updatedList = state.students.map((s) => s.id == updatedStudent.id ? updatedStudent : s).toList();
    _recalculateTotals(updatedList);
  }

  void _recalculateTotals(List<StudentEntity> list) {
    final activeCount = list.where((s) => s.isActive).length;
    final pendingCount = list
        .where((s) => s.paymentStatus == PaymentStatus.pending || 
                    s.paymentStatus == PaymentStatus.overdue)
        .length;
    final revenue = list
        .where((s) => s.isActive && s.monthlyFee != null)
        .fold(0.0, (sum, s) => sum + s.monthlyFee!);

    state = state.copyWith(
      students: list,
      totalStudents: list.length,
      activeStudents: activeCount,
      pendingPayments: pendingCount,
      monthlyRevenue: revenue,
    );
  }

  /// Gera alunos mockados para demonstração
  List<StudentEntity> _generateMockStudents() {
    return [
      StudentEntity(
        id: '1',
        trainerId: 'trainer_123',
        name: 'Carlos Mendes',
        email: 'carlos@email.com',
        phone: '(11) 98765-4321',
        enrollmentDate: DateTime.now().subtract(const Duration(days: 90)),
        isActive: true,
        status: StudentStatus.active,
        weight: 85.5,
        height: 178,
        age: 28,
        gender: Gender.male,
        planType: 'Premium',
        monthlyFee: 250.00,
        nextPaymentDate: DateTime.now().add(const Duration(days: 5)),
        paymentStatus: PaymentStatus.paid,
        lastWorkoutDate: DateTime.now().subtract(const Duration(days: 1)),
        totalWorkouts: 45,
      ),
      StudentEntity(
        id: '2',
        trainerId: 'trainer_123',
        name: 'Ana Paula Silva',
        email: 'ana@email.com',
        phone: '(11) 91234-5678',
        enrollmentDate: DateTime.now().subtract(const Duration(days: 60)),
        isActive: true,
        status: StudentStatus.active,
        weight: 62.0,
        height: 165,
        age: 32,
        gender: Gender.female,
        planType: 'Básico',
        monthlyFee: 150.00,
        nextPaymentDate: DateTime.now().subtract(const Duration(days: 3)),
        paymentStatus: PaymentStatus.overdue,
        lastWorkoutDate: DateTime.now().subtract(const Duration(days: 2)),
        totalWorkouts: 28,
      ),
      StudentEntity(
        id: '3',
        trainerId: 'trainer_123',
        name: 'Roberto Santos',
        email: 'roberto@email.com',
        phone: '(11) 99876-5432',
        enrollmentDate: DateTime.now().subtract(const Duration(days: 30)),
        isActive: true,
        status: StudentStatus.trial,
        weight: 92.0,
        height: 182,
        age: 25,
        gender: Gender.male,
        planType: 'Trial',
        monthlyFee: 0.0,
        nextPaymentDate: DateTime.now().add(const Duration(days: 7)),
        paymentStatus: PaymentStatus.exempt,
        lastWorkoutDate: DateTime.now().subtract(const Duration(days: 5)),
        totalWorkouts: 12,
      ),
      StudentEntity(
        id: '4',
        trainerId: 'trainer_123',
        name: 'Juliana Costa',
        email: 'juliana@email.com',
        phone: '(11) 97654-3210',
        enrollmentDate: DateTime.now().subtract(const Duration(days: 120)),
        isActive: true,
        status: StudentStatus.active,
        weight: 58.5,
        height: 160,
        age: 29,
        gender: Gender.female,
        planType: 'Premium',
        monthlyFee: 250.00,
        nextPaymentDate: DateTime.now().add(const Duration(days: 12)),
        paymentStatus: PaymentStatus.paid,
        lastWorkoutDate: DateTime.now(),
        totalWorkouts: 67,
      ),
      StudentEntity(
        id: '5',
        trainerId: 'trainer_123',
        name: 'Pedro Oliveira',
        email: 'pedro@email.com',
        phone: '(11) 96543-2109',
        enrollmentDate: DateTime.now().subtract(const Duration(days: 45)),
        isActive: false,
        status: StudentStatus.inactive,
        weight: 78.0,
        height: 175,
        age: 35,
        gender: Gender.male,
        planType: 'Básico',
        monthlyFee: 150.00,
        nextPaymentDate: DateTime.now().subtract(const Duration(days: 15)),
        paymentStatus: PaymentStatus.overdue,
        lastWorkoutDate: DateTime.now().subtract(const Duration(days: 20)),
        totalWorkouts: 18,
      ),
      StudentEntity(
        id: '6',
        trainerId: 'trainer_123',
        name: 'Mariana Lima',
        email: 'mariana@email.com',
        phone: '(11) 95555-4444',
        enrollmentDate: DateTime.now().subtract(const Duration(days: 75)),
        isActive: true,
        status: StudentStatus.active,
        weight: 65.2,
        height: 168,
        age: 27,
        gender: Gender.female,
        planType: 'Premium',
        monthlyFee: 250.00,
        nextPaymentDate: DateTime.now().add(const Duration(days: 10)),
        paymentStatus: PaymentStatus.paid,
        lastWorkoutDate: DateTime.now().subtract(const Duration(days: 3)),
        totalWorkouts: 32,
      ),
      StudentEntity(
        id: '7',
        trainerId: 'trainer_123',
        name: 'Bruno Souza',
        email: 'bruno@email.com',
        phone: '(11) 94444-3333',
        enrollmentDate: DateTime.now().subtract(const Duration(days: 15)),
        isActive: true,
        status: StudentStatus.active,
        weight: 80.0,
        height: 180,
        age: 22,
        gender: Gender.male,
        planType: 'Básico',
        monthlyFee: 150.00,
        nextPaymentDate: DateTime.now().add(const Duration(days: 15)),
        paymentStatus: PaymentStatus.paid,
        lastWorkoutDate: DateTime.now().subtract(const Duration(days: 4)),
        totalWorkouts: 8,
      ),
      StudentEntity(
        id: '8',
        trainerId: 'trainer_123',
        name: 'Amanda Rocha',
        email: 'amanda@email.com',
        phone: '(11) 93333-2222',
        enrollmentDate: DateTime.now().subtract(const Duration(days: 110)),
        isActive: true,
        status: StudentStatus.active,
        weight: 59.0,
        height: 163,
        age: 30,
        gender: Gender.female,
        planType: 'Premium',
        monthlyFee: 250.00,
        nextPaymentDate: DateTime.now().add(const Duration(days: 2)),
        paymentStatus: PaymentStatus.paid,
        lastWorkoutDate: DateTime.now().subtract(const Duration(days: 1)),
        totalWorkouts: 50,
      ),
      StudentEntity(
        id: '9',
        trainerId: 'trainer_123',
        name: 'Lucas Ferreira',
        email: 'lucas@email.com',
        phone: '(11) 92222-1111',
        enrollmentDate: DateTime.now().subtract(const Duration(days: 50)),
        isActive: true,
        status: StudentStatus.active,
        weight: 88.0,
        height: 176,
        age: 26,
        gender: Gender.male,
        planType: 'Básico',
        monthlyFee: 150.00,
        nextPaymentDate: DateTime.now().subtract(const Duration(days: 1)),
        paymentStatus: PaymentStatus.pending,
        lastWorkoutDate: DateTime.now().subtract(const Duration(days: 2)),
        totalWorkouts: 21,
      ),
    ];
  }
}

/// Provider global atualizado para NotifierProvider
final trainerDashboardProvider =
    NotifierProvider<TrainerDashboardNotifier, TrainerDashboardState>(() {
  return TrainerDashboardNotifier();
});