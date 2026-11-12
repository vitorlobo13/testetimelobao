import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../domain/entities/exercise_entity.dart';

/// Estado da biblioteca de exercícios
class ExercisesState {
  final List<ExerciseEntity> exercises;
  final bool isLoading;
  final String? errorMessage;

  const ExercisesState({
    this.exercises = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ExercisesState copyWith({
    List<ExerciseEntity>? exercises,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ExercisesState(
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final exerciseRepositoryProvider =
    Provider<ExerciseRepository>((ref) => ExerciseRepository());

/// Catálogo de exercícios do personal logado (Firestore, tempo real).
/// No primeiro acesso, copia a lista base de exercícios.
class ExercisesNotifier extends Notifier<ExercisesState> {
  StreamSubscription<List<ExerciseEntity>>? _subscription;

  ExerciseRepository get _repository => ref.read(exerciseRepositoryProvider);
  String? get _trainerId {
    final user = ref.read(authProvider).user;
    return (user != null && user.isTrainer) ? user.id : null;
  }

  @override
  ExercisesState build() {
    ref.onDispose(() => _subscription?.cancel());
    ref.listen(authProvider.select((a) => a.user?.id), (_, __) => _listen());
    Future.microtask(_listen);
    return const ExercisesState(isLoading: true);
  }

  Future<void> _listen() async {
    await _subscription?.cancel();
    _subscription = null;
    final trainerId = _trainerId;
    if (trainerId == null) {
      state = const ExercisesState();
      return;
    }
    try {
      await _repository.seedIfNeeded(trainerId);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Erro: $e');
      return;
    }
    _subscription = _repository.watch(trainerId).listen(
          (list) => state = ExercisesState(exercises: list),
          onError: (Object e) => state = state.copyWith(
            isLoading: false,
            errorMessage: 'Erro ao carregar exercícios: $e',
          ),
        );
  }

  /// Mantido por compatibilidade: os dados já chegam em tempo real.
  Future<void> loadExercises() async {
    if (_subscription == null) await _listen();
  }

  String get _requireTrainer {
    final id = _trainerId;
    if (id == null) throw StateError('Personal não logado.');
    return id;
  }

  Future<String> createExercise(ExerciseEntity exercise) =>
      _repository.create(_requireTrainer, exercise);

  /// Atualiza um exercício (nome, grupo, vídeo...)
  Future<void> updateExercise(ExerciseEntity updatedExercise) =>
      _repository.update(_requireTrainer, updatedExercise);

  Future<void> deleteExercise(String exerciseId) =>
      _repository.delete(_requireTrainer, exerciseId);

  /// Busca exercícios por nome ou categoria
  List<ExerciseEntity> search(String query, {String? category}) {
    var filtered = state.exercises;

    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((e) => e.category == category).toList();
    }

    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filtered = filtered.where((e) {
        return e.name.toLowerCase().contains(lowerQuery) ||
            e.muscleGroup.toLowerCase().contains(lowerQuery) ||
            e.category.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    return filtered;
  }
}

final exercisesProvider =
    NotifierProvider<ExercisesNotifier, ExercisesState>(() {
  return ExercisesNotifier();
});
