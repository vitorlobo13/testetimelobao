import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/student_link_repository.dart';
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

final studentLinkRepositoryProvider =
    Provider<StudentLinkRepository>((ref) => StudentLinkRepository());

/// Provider do Dashboard do Trainer — alunos reais do Firestore
/// (`studentLinks` do personal logado), atualizados em tempo real.
class TrainerDashboardNotifier extends Notifier<TrainerDashboardState> {
  StreamSubscription<List<StudentEntity>>? _subscription;

  StudentLinkRepository get _repository =>
      ref.read(studentLinkRepositoryProvider);

  String? get _trainerId => ref.read(authProvider).user?.id;

  @override
  TrainerDashboardState build() {
    ref.onDispose(() => _subscription?.cancel());
    // Reinicia a escuta se outro personal logar no mesmo aparelho.
    ref.listen(authProvider.select((a) => a.user?.id), (_, __) => _listen());
    Future.microtask(_listen);
    return const TrainerDashboardState(isLoading: true);
  }

  void _listen() {
    _subscription?.cancel();
    final trainerId = _trainerId;
    if (trainerId == null) {
      state = const TrainerDashboardState();
      return;
    }
    _subscription = _repository.watchTrainerStudents(trainerId).listen(
      (list) {
        _recalculateTotals(list);
        state = state.copyWith(isLoading: false);
      },
      onError: (Object e) => state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar alunos: $e',
      ),
    );
  }

  /// Mantido por compatibilidade com as telas: os dados já chegam em
  /// tempo real, então só garante que a escuta está ativa.
  Future<void> loadDashboardData() async {
    if (_subscription == null) _listen();
  }

  /// Atualiza dados (pull to refresh)
  Future<void> refresh() async => _listen();

  /// Cadastra um novo aluno (vínculo pendente até ele aceitar o convite).
  /// Retorna o id do vínculo criado.
  Future<String> addStudent(StudentEntity newStudent) {
    final trainerId = _trainerId;
    if (trainerId == null) throw StateError('Personal não logado.');
    return _repository.create(newStudent, trainerId);
  }

  /// Atualiza os dados de um aluno
  Future<void> updateStudent(StudentEntity updatedStudent) =>
      _repository.update(updatedStudent);

  Future<void> setSuspended(StudentEntity student, bool suspended) =>
      _repository.setSuspended(student, suspended);

  Future<void> deleteStudent(StudentEntity student) =>
      _repository.deleteWithData(student.id);

  void _recalculateTotals(List<StudentEntity> list) {
    // Alunos arquivados (foram para outro personal) não entram nos números.
    final current =
        list.where((s) => s.linkStatus != LinkStatus.archived).toList();
    final activeCount = current.where((s) => s.isActive).length;
    final pendingCount = current
        .where((s) => s.paymentStatus == PaymentStatus.pending ||
                    s.paymentStatus == PaymentStatus.overdue)
        .length;
    final revenue = current
        .where((s) => s.isActive && s.monthlyFee != null)
        .fold(0.0, (sum, s) => sum + s.monthlyFee!);

    state = state.copyWith(
      students: list,
      totalStudents: current.length,
      activeStudents: activeCount,
      pendingPayments: pendingCount,
      monthlyRevenue: revenue,
    );
  }
}

final trainerDashboardProvider =
    NotifierProvider<TrainerDashboardNotifier, TrainerDashboardState>(() {
  return TrainerDashboardNotifier();
});