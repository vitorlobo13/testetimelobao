import 'package:flutter_test/flutter_test.dart';
import 'package:time_lobao/features/trainer/domain/entities/student_entity.dart';
import 'package:time_lobao/features/trainer/domain/services/trainer_updates.dart';

void main() {
  final now = DateTime(2026, 11, 12, 10);

  StudentEntity student({
    String name = 'Ana',
    String? workoutId = 'w1',
    DateTime? workoutEnd,
    DateTime? birth,
    DateTime? lastAssessment,
    DateTime? lastWorkout,
    DateTime? due,
    LinkStatus link = LinkStatus.active,
    bool active = true,
  }) =>
      StudentEntity(
        id: name,
        trainerId: 't',
        name: name,
        email: '$name@x.test',
        enrollmentDate: DateTime(2026, 1, 1),
        isActive: active,
        currentWorkoutId: workoutId,
        currentWorkoutName: 'Hipertrofia',
        currentWorkoutEndDate: workoutEnd,
        birthDate: birth,
        lastAssessmentAt: lastAssessment ?? DateTime(2026, 11, 1),
        lastWorkoutDate: lastWorkout ?? DateTime(2026, 11, 11),
        nextPaymentDate: due ?? DateTime(2026, 12, 1),
        studentUid: link == LinkStatus.pending ? null : 'uid-$name',
        linkStatus: link,
      );

  List<UpdateKind> kinds(StudentEntity s) =>
      computeTrainerUpdates([s], now: now).map((u) => u.kind).toList();

  test('aluno em dia não gera atualização', () {
    expect(kinds(student()), isEmpty);
  });

  test('treino vencido e vencendo', () {
    expect(kinds(student(workoutEnd: DateTime(2026, 11, 9))),
        [UpdateKind.workoutExpired]);
    expect(kinds(student(workoutEnd: DateTime(2026, 11, 15))),
        [UpdateKind.workoutExpiring]);
    expect(kinds(student(workoutEnd: DateTime(2026, 12, 30))), isEmpty);
  });

  test('sem treino', () {
    expect(kinds(student(workoutId: null)), [UpdateKind.noWorkout]);
  });

  test('aniversário hoje e em breve (inclui virada de ano)', () {
    final today = computeTrainerUpdates(
        [student(birth: DateTime(1990, 11, 12))],
        now: now);
    expect(today.single.kind, UpdateKind.birthdayToday);
    expect(today.single.detail, 'Faz 36 anos hoje');
    expect(kinds(student(birth: DateTime(1990, 11, 16))),
        [UpdateKind.birthdaySoon]);
    expect(kinds(student(birth: DateTime(1990, 11, 11))), isEmpty);
    final dec = computeTrainerUpdates([student(birth: DateTime(2000, 1, 2))],
        now: DateTime(2026, 12, 30));
    expect(dec.map((u) => u.kind), contains(UpdateKind.birthdaySoon));
  });

  test('avaliação vencida após 90 dias', () {
    expect(kinds(student(lastAssessment: DateTime(2026, 8, 1))),
        [UpdateKind.assessmentDue]);
  });

  test('aluno sem treinar há 7 dias', () {
    expect(kinds(student(lastWorkout: DateTime(2026, 11, 2))),
        [UpdateKind.inactive]);
  });

  test('mensalidade atrasada', () {
    expect(kinds(student(due: DateTime(2026, 11, 5))),
        [UpdateKind.paymentOverdue]);
  });

  test('arquivado, suspenso ou inativo fica de fora', () {
    for (final s in [
      student(workoutId: null, link: LinkStatus.archived),
      student(workoutId: null, link: LinkStatus.suspended),
      student(workoutId: null, active: false),
    ]) {
      expect(kinds(s), isEmpty);
    }
  });
}
