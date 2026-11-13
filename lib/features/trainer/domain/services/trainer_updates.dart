import '../entities/student_entity.dart';

/// Tipos de atualização que o personal precisa fazer (a aba "Atualizações",
/// como no MFit): cada item some sozinho quando a pendência é resolvida.
enum UpdateKind {
  workoutExpired,
  workoutExpiring,
  noWorkout,
  birthdayToday,
  birthdaySoon,
  assessmentDue,
  inactive,
  paymentOverdue,
}

extension UpdateKindInfo on UpdateKind {
  String get section => switch (this) {
        UpdateKind.workoutExpired => 'Treinos vencidos',
        UpdateKind.workoutExpiring => 'Treinos vencendo',
        UpdateKind.noWorkout => 'Alunos sem treino',
        UpdateKind.birthdayToday => 'Aniversariantes de hoje',
        UpdateKind.birthdaySoon => 'Próximos aniversários',
        UpdateKind.assessmentDue => 'Avaliações a refazer',
        UpdateKind.inactive => 'Alunos sem treinar',
        UpdateKind.paymentOverdue => 'Mensalidades atrasadas',
      };

  /// Entra no número do ícone (o resto só aparece na lista).
  bool get countsInBadge =>
      this != UpdateKind.birthdaySoon;
}

/// Limites usados no cálculo. Ficam num lugar só para virarem
/// configuração do personal depois.
class UpdateSettings {
  const UpdateSettings({
    this.workoutExpiringDays = 7,
    this.birthdaySoonDays = 7,
    this.assessmentEveryDays = 90,
    this.inactiveDays = 7,
  });

  final int workoutExpiringDays;
  final int birthdaySoonDays;
  final int assessmentEveryDays;
  final int inactiveDays;

  static int _int(Object? v, int fallback) =>
      v is num && v > 0 ? v.toInt() : fallback;

  factory UpdateSettings.fromMap(Map<String, dynamic>? d) {
    const def = UpdateSettings();
    if (d == null) return def;
    return UpdateSettings(
      workoutExpiringDays: _int(d['workoutExpiringDays'], def.workoutExpiringDays),
      birthdaySoonDays: _int(d['birthdaySoonDays'], def.birthdaySoonDays),
      assessmentEveryDays: _int(d['assessmentEveryDays'], def.assessmentEveryDays),
      inactiveDays: _int(d['inactiveDays'], def.inactiveDays),
    );
  }

  Map<String, dynamic> toMap() => {
        'workoutExpiringDays': workoutExpiringDays,
        'birthdaySoonDays': birthdaySoonDays,
        'assessmentEveryDays': assessmentEveryDays,
        'inactiveDays': inactiveDays,
      };
}

class TrainerUpdate {
  const TrainerUpdate({
    required this.kind,
    required this.student,
    required this.detail,
    this.days,
  });

  final UpdateKind kind;
  final StudentEntity student;

  /// Texto curto: "Venceu há 3 dias", "Faz 31 anos hoje"...
  final String detail;

  /// Usado para ordenar dentro da seção.
  final int? days;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

String _plural(int n, String one, String many) => n == 1 ? '1 $one' : '$n $many';

/// Calcula as atualizações a partir da lista de alunos do personal.
List<TrainerUpdate> computeTrainerUpdates(
  List<StudentEntity> students, {
  UpdateSettings settings = const UpdateSettings(),
  DateTime? now,
}) {
  final today = _day(now ?? DateTime.now());
  final out = <TrainerUpdate>[];

  for (final s in students) {
    // Só alunos atuais e ativos.
    if (s.linkStatus == LinkStatus.archived ||
        s.linkStatus == LinkStatus.suspended ||
        !s.isActive) {
      continue;
    }

    // Treino: vencido, vencendo ou inexistente.
    if (s.currentWorkoutId == null) {
      out.add(TrainerUpdate(
        kind: UpdateKind.noWorkout,
        student: s,
        detail: s.hasAccount
            ? 'Nenhum treino prescrito'
            : 'Nenhum treino prescrito (convite pendente)',
      ));
    } else if (s.currentWorkoutEndDate != null) {
      final left = _day(s.currentWorkoutEndDate!).difference(today).inDays;
      final name = s.currentWorkoutName ?? 'Treino atual';
      if (left < 0) {
        out.add(TrainerUpdate(
          kind: UpdateKind.workoutExpired,
          student: s,
          detail: '$name venceu há ${_plural(-left, 'dia', 'dias')}',
          days: left,
        ));
      } else if (left <= settings.workoutExpiringDays) {
        out.add(TrainerUpdate(
          kind: UpdateKind.workoutExpiring,
          student: s,
          detail: left == 0
              ? '$name vence hoje'
              : '$name vence em ${_plural(left, 'dia', 'dias')}',
          days: left,
        ));
      }
    }

    // Aniversário (hoje ou nos próximos dias).
    final b = s.birthDate;
    if (b != null) {
      var next = DateTime(today.year, b.month, b.day);
      if (next.isBefore(today)) next = DateTime(today.year + 1, b.month, b.day);
      final left = next.difference(today).inDays;
      final turns = next.year - b.year;
      if (left == 0) {
        out.add(TrainerUpdate(
          kind: UpdateKind.birthdayToday,
          student: s,
          detail: 'Faz $turns anos hoje',
          days: 0,
        ));
      } else if (left <= settings.birthdaySoonDays) {
        out.add(TrainerUpdate(
          kind: UpdateKind.birthdaySoon,
          student: s,
          detail: 'Faz $turns anos em ${_plural(left, 'dia', 'dias')} '
              '(${next.day.toString().padLeft(2, '0')}/${next.month.toString().padLeft(2, '0')})',
          days: left,
        ));
      }
    }

    // Avaliação física vencida (ou nunca feita, depois da 1ª semana).
    final last = s.lastAssessmentAt;
    if (last == null) {
      if (today.difference(_day(s.enrollmentDate)).inDays >= 7) {
        out.add(TrainerUpdate(
          kind: UpdateKind.assessmentDue,
          student: s,
          detail: 'Nenhuma avaliação registrada',
          days: 99999,
        ));
      }
    } else {
      final since = today.difference(_day(last)).inDays;
      if (since >= settings.assessmentEveryDays) {
        out.add(TrainerUpdate(
          kind: UpdateKind.assessmentDue,
          student: s,
          detail: 'Última avaliação há ${_plural(since, 'dia', 'dias')}',
          days: since,
        ));
      }
    }

    // Aluno com treino e conta, mas sem treinar há um tempo.
    if (s.hasAccount && s.currentWorkoutId != null) {
      final lw = s.lastWorkoutDate;
      if (lw == null) {
        if (today.difference(_day(s.enrollmentDate)).inDays >=
            settings.inactiveDays) {
          out.add(TrainerUpdate(
            kind: UpdateKind.inactive,
            student: s,
            detail: 'Ainda não registrou nenhum treino',
            days: 99999,
          ));
        }
      } else {
        final since = today.difference(_day(lw)).inDays;
        if (since >= settings.inactiveDays) {
          out.add(TrainerUpdate(
            kind: UpdateKind.inactive,
            student: s,
            detail: 'Último treino há ${_plural(since, 'dia', 'dias')}',
            days: since,
          ));
        }
      }
    }

    // Mensalidade atrasada.
    if (s.isBillable && s.isPaymentOverdue) {
      final late = -(s.daysUntilDue ?? 0);
      out.add(TrainerUpdate(
        kind: UpdateKind.paymentOverdue,
        student: s,
        detail: 'Atrasada há ${_plural(late, 'dia', 'dias')}',
        days: late,
      ));
    }
  }

  // Ordem das seções = ordem do enum; dentro, o mais urgente primeiro.
  out.sort((a, b) {
    final k = a.kind.index.compareTo(b.kind.index);
    if (k != 0) return k;
    final da = a.days ?? 0, db = b.days ?? 0;
    // vencidos/sem treinar: maior atraso primeiro; vencendo/aniversário: mais perto primeiro
    final descending = a.kind == UpdateKind.assessmentDue ||
        a.kind == UpdateKind.inactive ||
        a.kind == UpdateKind.paymentOverdue;
    return descending ? db.compareTo(da) : da.compareTo(db);
  });
  return out;
}
