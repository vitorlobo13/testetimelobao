import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trainer/domain/entities/workout_entity.dart';
import '../../../trainer/presentation/providers/workout_builder_provider.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/entities/workout_session_entity.dart';

/// Estado do treino do aluno
class StudentWorkoutState {
  final WorkoutEntity? currentWorkout;
  final WorkoutSessionEntity? activeSession;
  final List<WorkoutSessionEntity> history;
  final bool isLoading;
  final String? errorMessage;

  /// Vínculo ativo (null = aluno sem personal no momento).
  final ActiveLink? link;

  const StudentWorkoutState({
    this.currentWorkout,
    this.activeSession,
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
    this.link,
  });

  StudentWorkoutState copyWith({
    WorkoutEntity? currentWorkout,
    bool clearWorkout = false,
    WorkoutSessionEntity? activeSession,
    bool clearSession = false,
    List<WorkoutSessionEntity>? history,
    bool? isLoading,
    String? errorMessage,
    ActiveLink? link,
    bool clearLink = false,
  }) {
    return StudentWorkoutState(
      currentWorkout:
          clearWorkout ? null : (currentWorkout ?? this.currentWorkout),
      activeSession: clearSession ? null : (activeSession ?? this.activeSession),
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      link: clearLink ? null : (link ?? this.link),
    );
  }
}

final sessionRepositoryProvider =
    Provider<SessionRepository>((ref) => SessionRepository());

/// Treino ativo, execução e histórico do aluno logado (Firestore).
class StudentWorkoutNotifier extends Notifier<StudentWorkoutState> {
  final _uuid = const Uuid();
  StreamSubscription<ActiveLink?>? _linkSub;
  StreamSubscription<WorkoutEntity?>? _workoutSub;
  StreamSubscription<List<WorkoutSessionEntity>>? _historySub;

  SessionRepository get _sessions => ref.read(sessionRepositoryProvider);

  @override
  StudentWorkoutState build() {
    ref.onDispose(_cancelAll);
    ref.listen(authProvider.select((a) => a.user?.id), (_, __) => _listen());
    Future.microtask(_listen);
    return const StudentWorkoutState(isLoading: true);
  }

  void _cancelAll() {
    _linkSub?.cancel();
    _workoutSub?.cancel();
    _historySub?.cancel();
  }

  void _listen() {
    _cancelAll();
    final user = ref.read(authProvider).user;
    if (user == null || !user.isStudent) {
      state = const StudentWorkoutState();
      return;
    }
    _linkSub = _sessions.watchActiveLink(user.id).listen(
      (link) {
        final changed = link?.linkId != state.link?.linkId;
        state = link == null
            ? state.copyWith(clearLink: true, clearWorkout: true, isLoading: false)
            : state.copyWith(link: link);
        if (changed) _listenLinkData(link);
      },
      onError: (Object e) => state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar seu treino: $e',
      ),
    );
  }

  void _listenLinkData(ActiveLink? link) {
    _workoutSub?.cancel();
    _historySub?.cancel();
    if (link == null) {
      state = state.copyWith(history: const [], isLoading: false);
      return;
    }
    _workoutSub = ref
        .read(workoutRepositoryProvider)
        .watchActiveWorkout(link.linkId)
        .listen((workout) {
      state = workout == null
          ? state.copyWith(clearWorkout: true, isLoading: false)
          : state.copyWith(currentWorkout: workout, isLoading: false);
    });
    _historySub = _sessions.watchHistory(link.linkId).listen((history) {
      state = state.copyWith(history: history);
    });
  }

  /// Mantido por compatibilidade (pull to refresh): reinicia a escuta.
  Future<void> loadCurrentWorkout() async => _listen();

  /// Aluno aceita o termo de uso dos dados de saúde (LGPD).
  Future<void> acceptConsent() async {
    final link = state.link;
    if (link == null) return;
    await _sessions.registerConsent(link.linkId);
  }

  /// Inicia uma nova sessão de treino
  void startSession(String divisionId) {
    final workout = state.currentWorkout;
    if (workout == null) return;

    final division = workout.divisions.firstWhere((d) => d.id == divisionId);

    final exerciseSessions = division.exercises.map((exercise) {
      final sets = List.generate(
        exercise.sets,
        (index) => SetSessionEntity(setNumber: index + 1, completed: false),
      );
      return ExerciseSessionEntity(
        id: _uuid.v4(),
        workoutExerciseId: exercise.id,
        exerciseName: exercise.exercise.name,
        sets: sets,
        completed: false,
      );
    }).toList();

    final session = WorkoutSessionEntity(
      id: _uuid.v4(),
      studentId: ref.read(authProvider).user?.id ?? '',
      workoutId: workout.id,
      workoutName: workout.name,
      divisionId: divisionId,
      divisionName: division.name,
      startTime: DateTime.now(),
      exerciseSessions: exerciseSessions,
    );

    // Só grava quando o aluno concluir o primeiro exercício: abrir a tela
    // só para olhar o treino não cria registro no histórico.
    state = state.copyWith(activeSession: session);
  }

  /// Completa uma série
  void completeSet(int exerciseIndex, int setIndex, {int? reps, double? load}) {
    final session = state.activeSession;
    if (session == null) return;

    final exercises = List<ExerciseSessionEntity>.from(session.exerciseSessions);
    final exerciseSession = exercises[exerciseIndex];
    final sets = List<SetSessionEntity>.from(exerciseSession.sets);

    sets[setIndex] = sets[setIndex].copyWith(
      actualReps: reps,
      actualLoad: load,
      completedAt: DateTime.now(),
      completed: true,
    );

    final allSetsCompleted = sets.every((s) => s.completed);
    exercises[exerciseIndex] = ExerciseSessionEntity(
      id: exerciseSession.id,
      workoutExerciseId: exerciseSession.workoutExerciseId,
      exerciseName: exerciseSession.exerciseName,
      sets: sets,
      completed: allSetsCompleted,
    );

    final updated = session.copyWith(exerciseSessions: exercises);
    state = state.copyWith(activeSession: updated);

    // Grava a cada exercício concluído.
    if (allSetsCompleted) _persist(updated);
  }

  /// Finaliza a sessão de treino
  Future<bool> finishSession() async {
    final session = state.activeSession;
    if (session == null) return false;
    final completed = session.copyWith(endTime: DateTime.now(), completed: true);
    final ok = await _persist(completed);
    if (ok) state = state.copyWith(clearSession: true);
    return ok;
  }

  /// Cancela a sessão atual (o que já foi gravado fica como treino
  /// incompleto no histórico).
  void cancelSession() {
    state = state.copyWith(clearSession: true);
  }

  Future<bool> _persist(WorkoutSessionEntity session) async {
    final link = state.link;
    final user = ref.read(authProvider).user;
    if (link == null || user == null) return false;
    try {
      await _sessions.save(
        linkId: link.linkId,
        trainerId: link.trainerId,
        studentUid: user.id,
        session: session,
      );
      return true;
    } on FirebaseException catch (e) {
      developer.log('Erro ao salvar sessão', error: e);
      state = state.copyWith(errorMessage: 'Erro ao salvar treino: ${e.message}');
      return false;
    }
  }
}

final studentWorkoutProvider =
    NotifierProvider<StudentWorkoutNotifier, StudentWorkoutState>(() {
  return StudentWorkoutNotifier();
});
