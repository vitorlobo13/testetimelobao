import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Notifier de Exercícios - VERSÃO CORRIGIDA
class ExercisesNotifier extends Notifier<ExercisesState> {
  @override
  ExercisesState build() {
    loadExercises();
    return const ExercisesState();
  }

  /// Carrega biblioteca de exercícios
  Future<void> loadExercises() async {
    state = state.copyWith(isLoading: true);

    try {
      // TODO: Buscar do Firebase/Supabase
      await Future.delayed(const Duration(seconds: 1));

      // Dados mockados (alguns exercícios populares)
      final mockExercises = _generateMockExercises();

      state = state.copyWith(
        exercises: mockExercises,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar exercícios',
      );
    }
  }

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

  /// Gera exercícios mockados
  List<ExerciseEntity> _generateMockExercises() {
    return [
      // PEITO
      const ExerciseEntity(
        id: '1',
        name: 'Supino Reto com Barra',
        category: ExerciseCategory.chest,
        muscleGroup: 'Peitoral Maior',
        equipment: 'Barra',
        difficulty: 'Intermediário',
        description: 'Exercício fundamental para desenvolvimento do peitoral',
      ),
      const ExerciseEntity(
        id: '2',
        name: 'Supino Inclinado com Halteres',
        category: ExerciseCategory.chest,
        muscleGroup: 'Peitoral Superior',
        equipment: 'Halteres',
        difficulty: 'Intermediário',
      ),
      const ExerciseEntity(
        id: '3',
        name: 'Crucifixo no Banco Reto',
        category: ExerciseCategory.chest,
        muscleGroup: 'Peitoral Maior',
        equipment: 'Halteres',
        difficulty: 'Iniciante',
      ),
      const ExerciseEntity(
        id: '4',
        name: 'Flexão de Braço',
        category: ExerciseCategory.chest,
        muscleGroup: 'Peitoral',
        equipment: 'Peso Corporal',
        difficulty: 'Iniciante',
      ),

      // COSTAS
      const ExerciseEntity(
        id: '5',
        name: 'Barra Fixa',
        category: ExerciseCategory.back,
        muscleGroup: 'Dorsal',
        equipment: 'Barra Fixa',
        difficulty: 'Intermediário',
      ),
      const ExerciseEntity(
        id: '6',
        name: 'Remada Curvada',
        category: ExerciseCategory.back,
        muscleGroup: 'Dorsal',
        equipment: 'Barra',
        difficulty: 'Intermediário',
      ),
      const ExerciseEntity(
        id: '7',
        name: 'Pulley Frontal',
        category: ExerciseCategory.back,
        muscleGroup: 'Dorsal',
        equipment: 'Máquina',
        difficulty: 'Iniciante',
      ),
      const ExerciseEntity(
        id: '8',
        name: 'Remada Unilateral',
        category: ExerciseCategory.back,
        muscleGroup: 'Dorsal',
        equipment: 'Halter',
        difficulty: 'Iniciante',
      ),

      // PERNAS
      const ExerciseEntity(
        id: '9',
        name: 'Agachamento Livre',
        category: ExerciseCategory.legs,
        muscleGroup: 'Quadríceps',
        equipment: 'Barra',
        difficulty: 'Avançado',
      ),
      const ExerciseEntity(
        id: '10',
        name: 'Leg Press 45°',
        category: ExerciseCategory.legs,
        muscleGroup: 'Quadríceps',
        equipment: 'Máquina',
        difficulty: 'Iniciante',
      ),
      const ExerciseEntity(
        id: '11',
        name: 'Cadeira Extensora',
        category: ExerciseCategory.legs,
        muscleGroup: 'Quadríceps',
        equipment: 'Máquina',
        difficulty: 'Iniciante',
      ),
      const ExerciseEntity(
        id: '12',
        name: 'Mesa Flexora',
        category: ExerciseCategory.legs,
        muscleGroup: 'Posteriores',
        equipment: 'Máquina',
        difficulty: 'Iniciante',
      ),

      // OMBROS
      const ExerciseEntity(
        id: '13',
        name: 'Desenvolvimento com Barra',
        category: ExerciseCategory.shoulders,
        muscleGroup: 'Deltóide',
        equipment: 'Barra',
        difficulty: 'Intermediário',
      ),
      const ExerciseEntity(
        id: '14',
        name: 'Elevação Lateral',
        category: ExerciseCategory.shoulders,
        muscleGroup: 'Deltóide Lateral',
        equipment: 'Halteres',
        difficulty: 'Iniciante',
      ),
      const ExerciseEntity(
        id: '15',
        name: 'Elevação Frontal',
        category: ExerciseCategory.shoulders,
        muscleGroup: 'Deltóide Anterior',
        equipment: 'Halteres',
        difficulty: 'Iniciante',
      ),

      // BÍCEPS
      const ExerciseEntity(
        id: '16',
        name: 'Rosca Direta com Barra',
        category: ExerciseCategory.biceps,
        muscleGroup: 'Bíceps',
        equipment: 'Barra',
        difficulty: 'Iniciante',
      ),
      const ExerciseEntity(
        id: '17',
        name: 'Rosca Alternada',
        category: ExerciseCategory.biceps,
        muscleGroup: 'Bíceps',
        equipment: 'Halteres',
        difficulty: 'Iniciante',
      ),

      // TRÍCEPS
      const ExerciseEntity(
        id: '18',
        name: 'Tríceps Testa',
        category: ExerciseCategory.triceps,
        muscleGroup: 'Tríceps',
        equipment: 'Barra',
        difficulty: 'Intermediário',
      ),
      const ExerciseEntity(
        id: '19',
        name: 'Tríceps Corda',
        category: ExerciseCategory.triceps,
        muscleGroup: 'Tríceps',
        equipment: 'Polia',
        difficulty: 'Iniciante',
      ),

      // ABDÔMEN
      const ExerciseEntity(
        id: '20',
        name: 'Abdominal Supra',
        category: ExerciseCategory.abs,
        muscleGroup: 'Reto Abdominal',
        equipment: 'Peso Corporal',
        difficulty: 'Iniciante',
      ),
      const ExerciseEntity(
        id: '21',
        name: 'Prancha Isométrica',
        category: ExerciseCategory.abs,
        muscleGroup: 'Core',
        equipment: 'Peso Corporal',
        difficulty: 'Iniciante',
      ),
    ];
  }
}

/// Provider global de exercícios - VERSÃO CORRIGIDA
final exercisesProvider = NotifierProvider<ExercisesNotifier, ExercisesState>(() {
  return ExercisesNotifier();
});