import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../trainer/domain/entities/workout_entity.dart';
import '../../domain/entities/workout_session_entity.dart';
import '../../../trainer/domain/entities/exercise_entity.dart';



/// Estado do treino do aluno
class StudentWorkoutState {
  final WorkoutEntity? currentWorkout;
  final WorkoutSessionEntity? activeSession;
  final List<WorkoutSessionEntity> history;
  final bool isLoading;
  final String? errorMessage;

  const StudentWorkoutState({
    this.currentWorkout,
    this.activeSession,
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  StudentWorkoutState copyWith({
    WorkoutEntity? currentWorkout,
    WorkoutSessionEntity? activeSession,
    List<WorkoutSessionEntity>? history,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StudentWorkoutState(
      currentWorkout: currentWorkout ?? this.currentWorkout,
      activeSession: activeSession ?? this.activeSession,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier do treino do aluno
class StudentWorkoutNotifier extends Notifier<StudentWorkoutState> {
  final _uuid = const Uuid();

  @override
  StudentWorkoutState build() {
    loadCurrentWorkout();
    return const StudentWorkoutState();
  }

  /// Carrega treino atual do aluno
  Future<void> loadCurrentWorkout() async {
    state = state.copyWith(isLoading: true);

    try {
      // TODO: Buscar treino do Firebase/Supabase
      await Future.delayed(const Duration(seconds: 1));

      // Treino mockado para demonstração
      final mockWorkout = _generateMockWorkout();

      state = state.copyWith(
        currentWorkout: mockWorkout,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar treino',
      );
    }
  }

  /// Inicia uma nova sessão de treino
  void startSession(String divisionId) {
    final workout = state.currentWorkout;
    if (workout == null) return;

    final division = workout.divisions.firstWhere((d) => d.id == divisionId);

    // Cria sessões de exercícios
    final exerciseSessions = division.exercises.map((exercise) {
      final sets = List.generate(
        exercise.sets,
        (index) => SetSessionEntity(
          setNumber: index + 1,
          completed: false,
        ),
      );

      return ExerciseSessionEntity(
        id: _uuid.v4(),
        workoutExerciseId: exercise.id,
        sets: sets,
        completed: false,
      );
    }).toList();

    final session = WorkoutSessionEntity(
      id: _uuid.v4(),
      studentId: 'student_123', // TODO: Pegar do usuário logado
      workoutId: workout.id,
      divisionId: divisionId,
      startTime: DateTime.now(),
      exerciseSessions: exerciseSessions,
    );

    state = state.copyWith(activeSession: session);
  }

  /// Completa uma série
  void completeSet(int exerciseIndex, int setIndex, {int? reps, double? load}) {
    final session = state.activeSession;
    if (session == null) return;

    final updatedExerciseSessions = List<ExerciseSessionEntity>.from(
      session.exerciseSessions,
    );

    final exerciseSession = updatedExerciseSessions[exerciseIndex];
    final updatedSets = List<SetSessionEntity>.from(exerciseSession.sets);

    updatedSets[setIndex] = updatedSets[setIndex].copyWith(
      actualReps: reps,
      actualLoad: load,
      completedAt: DateTime.now(),
      completed: true,
    );

    // Verifica se todas as séries foram completadas
    final allSetsCompleted = updatedSets.every((s) => s.completed);

    updatedExerciseSessions[exerciseIndex] = ExerciseSessionEntity(
      id: exerciseSession.id,
      workoutExerciseId: exerciseSession.workoutExerciseId,
      sets: updatedSets,
      completed: allSetsCompleted,
    );

    final updatedSession = WorkoutSessionEntity(
      id: session.id,
      studentId: session.studentId,
      workoutId: session.workoutId,
      divisionId: session.divisionId,
      startTime: session.startTime,
      endTime: session.endTime,
      completed: session.completed,
      exerciseSessions: updatedExerciseSessions,
    );

    state = state.copyWith(activeSession: updatedSession);
  }

  /// Finaliza a sessão de treino
  Future<bool> finishSession() async {
    final session = state.activeSession;
    if (session == null) return false;

    try {
      final completedSession = WorkoutSessionEntity(
        id: session.id,
        studentId: session.studentId,
        workoutId: session.workoutId,
        divisionId: session.divisionId,
        startTime: session.startTime,
        endTime: DateTime.now(),
        completed: true,
        exerciseSessions: session.exerciseSessions,
      );

      // TODO: Salvar no Firebase/Supabase
      await Future.delayed(const Duration(milliseconds: 500));

      // Adiciona ao histórico
      final updatedHistory = [completedSession, ...state.history];

      state = state.copyWith(
        activeSession: null,
        history: updatedHistory,
      );

      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao finalizar treino');
      return false;
    }
  }

  /// Cancela a sessão atual
  void cancelSession() {
    state = state.copyWith(activeSession: null);
  }

  /// Gera treino mockado
  WorkoutEntity _generateMockWorkout() {
    return WorkoutEntity(
      id: 'workout_1',
      trainerId: 'trainer_123',
      studentId: 'student_123',
      name: 'Treino ABC - Hipertrofia',
      description: 'Divisão Push/Pull/Legs focada em ganho de massa muscular',
      divisions: [
        WorkoutDivision(
          id: 'div_1',
          name: 'Treino A - Push (Peito, Ombro, Tríceps)',
          description: 'Foco em empurrar',
          order: 0,
          exercises: [
            WorkoutExercise(
              id: 'ex_1',
              exercise: const ExerciseEntity(
                id: '1',
                name: 'Supino Reto com Barra',
                category: 'Peito',
                muscleGroup: 'Peitoral Maior',
                equipment: 'Barra',
                difficulty: 'Intermediário',
              ),
              sets: 4,
              reps: '8-10',
              rest: '90',
              load: '60',
              notes: 'Controlar a descida, explodir na subida',
              order: 0,
            ),
            WorkoutExercise(
              id: 'ex_2',
              exercise: const ExerciseEntity(
                id: '2',
                name: 'Supino Inclinado com Halteres',
                category: 'Peito',
                muscleGroup: 'Peitoral Superior',
                equipment: 'Halteres',
                difficulty: 'Intermediário',
              ),
              sets: 3,
              reps: '10-12',
              rest: '60',
              load: '20',
              order: 1,
            ),
            WorkoutExercise(
              id: 'ex_3',
              exercise: const ExerciseEntity(
                id: '13',
                name: 'Desenvolvimento com Barra',
                category: 'Ombros',
                muscleGroup: 'Deltóide',
                equipment: 'Barra',
                difficulty: 'Intermediário',
              ),
              sets: 3,
              reps: '10-12',
              rest: '60',
              load: '30',
              order: 2,
            ),
          ],
        ),
        WorkoutDivision(
          id: 'div_2',
          name: 'Treino B - Pull (Costas, Bíceps)',
          description: 'Foco em puxar',
          order: 1,
          exercises: [
            WorkoutExercise(
              id: 'ex_4',
              exercise: const ExerciseEntity(
                id: '5',
                name: 'Barra Fixa',
                category: 'Costas',
                muscleGroup: 'Dorsal',
                equipment: 'Barra Fixa',
                difficulty: 'Intermediário',
              ),
              sets: 4,
              reps: '8-10',
              rest: '90',
              notes: 'Usar pegada pronada',
              order: 0,
            ),
            WorkoutExercise(
              id: 'ex_5',
              exercise: const ExerciseEntity(
                id: '6',
                name: 'Remada Curvada',
                category: 'Costas',
                muscleGroup: 'Dorsal',
                equipment: 'Barra',
                difficulty: 'Intermediário',
              ),
              sets: 3,
              reps: '10-12',
              rest: '60',
              load: '40',
              order: 1,
            ),
          ],
        ),
        WorkoutDivision(
          id: 'div_3',
          name: 'Treino C - Legs (Pernas)',
          description: 'Foco em membros inferiores',
          order: 2,
          exercises: [
            WorkoutExercise(
              id: 'ex_6',
              exercise: const ExerciseEntity(
                id: '9',
                name: 'Agachamento Livre',
                category: 'Pernas',
                muscleGroup: 'Quadríceps',
                equipment: 'Barra',
                difficulty: 'Avançado',
              ),
              sets: 4,
              reps: '8-10',
              rest: '120',
              load: '80',
              notes: 'Descer até paralelo, manter costas retas',
              order: 0,
            ),
            WorkoutExercise(
              id: 'ex_7',
              exercise: const ExerciseEntity(
                id: '10',
                name: 'Leg Press 45°',
                category: 'Pernas',
                muscleGroup: 'Quadríceps',
                equipment: 'Máquina',
                difficulty: 'Iniciante',
              ),
              sets: 3,
              reps: '12-15',
              rest: '90',
              load: '100',
              order: 1,
            ),
          ],
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      isActive: true,
    );
  }
}

  /// Provider global do treino do aluno
  final studentWorkoutProvider =
      NotifierProvider<StudentWorkoutNotifier, StudentWorkoutState>(() {
    return StudentWorkoutNotifier();
  }
  );