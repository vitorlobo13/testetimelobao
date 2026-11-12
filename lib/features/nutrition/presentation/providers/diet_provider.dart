import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/diet_entity.dart';
import '../../domain/entities/meal_entity.dart';
import '../../data/repositories/diet_repository.dart';

final dietRepositoryProvider =
    Provider<DietRepository>((ref) => DietRepository());

/// Estado da dieta
class DietState {
  final DietEntity? currentDiet;
  final List<MealEntity> meals;
  final bool isLoading;
  final String? errorMessage;

  const DietState({
    this.currentDiet,
    this.meals = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DietState copyWith({
    DietEntity? currentDiet,
    List<MealEntity>? meals,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DietState(
      currentDiet: currentDiet ?? this.currentDiet,
      meals: meals ?? this.meals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier da dieta
class DietNotifier extends Notifier<DietState> {
  final _uuid = const Uuid();

  @override
  DietState build() {
    ref.onDispose(() => _dietSub?.cancel());
    return const DietState();
  }

  StreamSubscription<DietEntity?>? _dietSub;
  String? _watchingLinkId;

  /// Carrega (em tempo real) a dieta ativa do aluno. [studentId] é o id do
  /// vínculo aluno ↔ personal.
  Future<void> loadDiet(String studentId) async {
    if (_watchingLinkId == studentId && _dietSub != null) return;
    await _dietSub?.cancel();
    _watchingLinkId = studentId;
    state = DietState(isLoading: true, meals: state.meals);
    _dietSub = ref.read(dietRepositoryProvider).watchActive(studentId).listen(
      (diet) => state = DietState(currentDiet: diet, meals: state.meals),
      onError: (Object e) => state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar dieta: $e',
      ),
    );
  }

  /// Inicia construtor de dieta
  void startDietBuilder() {
    state = state.copyWith(meals: []);
  }

  /// Inicia construtor de dieta com dados de uma dieta existente
  void startDietBuilderFrom(DietEntity diet) {
    state = state.copyWith(meals: List<MealEntity>.from(diet.meals));
  }

  /// Carrega uma lista de refeições no builder (para edição ou template)
  void loadMeals(List<MealEntity> meals) {
    state = state.copyWith(meals: List<MealEntity>.from(meals));
  }

  /// Adiciona refeição
  void addMeal(String name, String time) {
    final newMeal = MealEntity(
      id: _uuid.v4(),
      name: name,
      time: time,
      foods: [],
      order: state.meals.length,
    );

    state = state.copyWith(
      meals: [...state.meals, newMeal],
    );
  }

  /// Remove refeição
  void removeMeal(int index) {
    final updatedMeals = List<MealEntity>.from(state.meals);
    updatedMeals.removeAt(index);
    
    // Reordena
    for (var i = 0; i < updatedMeals.length; i++) {
      updatedMeals[i] = MealEntity(
        id: updatedMeals[i].id,
        name: updatedMeals[i].name,
        time: updatedMeals[i].time,
        foods: updatedMeals[i].foods,
        notes: updatedMeals[i].notes,
        order: i,
      );
    }

    state = state.copyWith(meals: updatedMeals);
  }

  /// Adiciona alimento a uma refeição
  void addFoodToMeal(int mealIndex, FoodItem food) {
    final updatedMeals = List<MealEntity>.from(state.meals);
    final meal = updatedMeals[mealIndex];

    updatedMeals[mealIndex] = MealEntity(
      id: meal.id,
      name: meal.name,
      time: meal.time,
      foods: [...meal.foods, food],
      notes: meal.notes,
      order: meal.order,
    );

    state = state.copyWith(meals: updatedMeals);
  }

  /// Remove alimento de uma refeição
  void removeFoodFromMeal(int mealIndex, int foodIndex) {
    final updatedMeals = List<MealEntity>.from(state.meals);
    final meal = updatedMeals[mealIndex];
    final updatedFoods = List<FoodItem>.from(meal.foods);
    updatedFoods.removeAt(foodIndex);

    updatedMeals[mealIndex] = MealEntity(
      id: meal.id,
      name: meal.name,
      time: meal.time,
      foods: updatedFoods,
      notes: meal.notes,
      order: meal.order,
    );

    state = state.copyWith(meals: updatedMeals);
  }

  /// Salva dieta
  Future<bool> saveDiet({
    required String studentId,
    required String trainerId,
    required String name,
    String? description,
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFats,
  }) async {
    if (state.meals.isEmpty) return false;

    try {
      final diet = DietEntity(
        id: _uuid.v4(),
        trainerId: trainerId,
        studentId: studentId,
        name: name,
        description: description,
        meals: state.meals,
        createdAt: DateTime.now(),
        isActive: true,
        targetCalories: targetCalories,
        targetProtein: targetProtein,
        targetCarbs: targetCarbs,
        targetFats: targetFats,
      );

      final id = await ref.read(dietRepositoryProvider).saveActive(diet);

      state = state.copyWith(currentDiet: diet.withId(id));
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao salvar dieta: $e');
      return false;
    }
  }

  /// Reseta construtor
  void reset() {
    _dietSub?.cancel();
    _dietSub = null;
    _watchingLinkId = null;
    state = const DietState();
  }
}

final dietProvider = NotifierProvider<DietNotifier, DietState>(() {
  return DietNotifier();
});