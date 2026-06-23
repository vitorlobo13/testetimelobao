import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/diet_entity.dart';
import '../../domain/entities/meal_entity.dart';

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
    return const DietState();
  }

  /// Carrega dieta do aluno
  Future<void> loadDiet(String studentId) async {
    state = state.copyWith(isLoading: true);

    try {
      // TODO: Buscar do Firebase/Supabase
      await Future.delayed(const Duration(seconds: 1));

      // Dieta mockada para demonstração
      final mockDiet = _generateMockDiet(studentId);

      state = state.copyWith(
        currentDiet: mockDiet,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar dieta',
      );
    }
  }

  /// Inicia construtor de dieta
  void startDietBuilder() {
    state = state.copyWith(meals: []);
  }

  /// Inicia construtor de dieta com dados de uma dieta existente
  void startDietBuilderFrom(DietEntity diet) {
    state = state.copyWith(meals: List<MealEntity>.from(diet.meals));
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

      // TODO: Salvar no Firebase/Supabase
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(currentDiet: diet);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao salvar dieta');
      return false;
    }
  }

  /// Reseta construtor
  void reset() {
    state = const DietState();
  }

  /// Gera dieta mockada
  DietEntity _generateMockDiet(String studentId) {
    return DietEntity(
      id: 'diet_1',
      trainerId: 'trainer_123',
      studentId: studentId,
      name: 'Dieta Hipertrofia - 3000 kcal',
      description: 'Dieta focada em ganho de massa muscular com alto teor proteico',
      targetCalories: 3000,
      targetProtein: 180,
      targetCarbs: 375,
      targetFats: 83,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isActive: true,
      meals: [
        MealEntity(
          id: 'meal_1',
          name: 'Café da Manhã',
          time: '07:00',
          order: 0,
          foods: const [
            FoodItem(
              id: 'food_1',
              name: 'Ovos mexidos',
              quantity: 3,
              unit: 'unidades',
              calories: 210,
              protein: 18,
              carbs: 2,
              fats: 14,
            ),
            FoodItem(
              id: 'food_2',
              name: 'Pão integral',
              quantity: 2,
              unit: 'fatias',
              calories: 160,
              protein: 8,
              carbs: 28,
              fats: 2,
            ),
            FoodItem(
              id: 'food_3',
              name: 'Banana',
              quantity: 1,
              unit: 'unidade',
              calories: 105,
              protein: 1,
              carbs: 27,
              fats: 0,
            ),
            FoodItem(
              id: 'food_4',
              name: 'Whey Protein',
              quantity: 30,
              unit: 'g',
              calories: 120,
              protein: 24,
              carbs: 3,
              fats: 1,
            ),
          ],
        ),
        MealEntity(
          id: 'meal_2',
          name: 'Lanche da Manhã',
          time: '10:00',
          order: 1,
          foods: const [
            FoodItem(
              id: 'food_5',
              name: 'Iogurte grego',
              quantity: 200,
              unit: 'g',
              calories: 130,
              protein: 10,
              carbs: 8,
              fats: 7,
            ),
            FoodItem(
              id: 'food_6',
              name: 'Granola',
              quantity: 30,
              unit: 'g',
              calories: 130,
              protein: 3,
              carbs: 20,
              fats: 4,
            ),
          ],
        ),
        MealEntity(
          id: 'meal_3',
          name: 'Almoço',
          time: '13:00',
          order: 2,
          notes: 'Refeição principal - maior volume',
          foods: const [
            FoodItem(
              id: 'food_7',
              name: 'Arroz integral',
              quantity: 150,
              unit: 'g',
              calories: 195,
              protein: 4,
              carbs: 41,
              fats: 2,
            ),
            FoodItem(
              id: 'food_8',
              name: 'Frango grelhado',
              quantity: 200,
              unit: 'g',
              calories: 330,
              protein: 62,
              carbs: 0,
              fats: 7,
            ),
            FoodItem(
              id: 'food_9',
              name: 'Brócolis',
              quantity: 100,
              unit: 'g',
              calories: 34,
              protein: 3,
              carbs: 7,
              fats: 0,
            ),
            FoodItem(
              id: 'food_10',
              name: 'Azeite',
              quantity: 10,
              unit: 'ml',
              calories: 90,
              protein: 0,
              carbs: 0,
              fats: 10,
            ),
          ],
        ),
        MealEntity(
          id: 'meal_4',
          name: 'Lanche da Tarde (Pré-treino)',
          time: '16:00',
          order: 3,
          notes: '1h antes do treino',
          foods: const [
            FoodItem(
              id: 'food_11',
              name: 'Batata doce',
              quantity: 200,
              unit: 'g',
              calories: 172,
              protein: 2,
              carbs: 40,
              fats: 0,
            ),
            FoodItem(
              id: 'food_12',
              name: 'Peito de peru',
              quantity: 50,
              unit: 'g',
              calories: 55,
              protein: 11,
              carbs: 1,
              fats: 1,
            ),
          ],
        ),
        MealEntity(
          id: 'meal_5',
          name: 'Pós-treino',
          time: '19:00',
          order: 4,
          notes: 'Imediatamente após o treino',
          foods: const [
            FoodItem(
              id: 'food_13',
              name: 'Whey Protein',
              quantity: 40,
              unit: 'g',
              calories: 160,
              protein: 32,
              carbs: 4,
              fats: 1,
            ),
            FoodItem(
              id: 'food_14',
              name: 'Dextrose',
              quantity: 30,
              unit: 'g',
              calories: 120,
              protein: 0,
              carbs: 30,
              fats: 0,
            ),
          ],
        ),
        MealEntity(
          id: 'meal_6',
          name: 'Jantar',
          time: '20:30',
          order: 5,
          foods: const [
            FoodItem(
              id: 'food_15',
              name: 'Tilápia grelhada',
              quantity: 200,
              unit: 'g',
              calories: 232,
              protein: 48,
              carbs: 0,
              fats: 5,
            ),
            FoodItem(
              id: 'food_16',
              name: 'Quinoa',
              quantity: 100,
              unit: 'g',
              calories: 120,
              protein: 4,
              carbs: 21,
              fats: 2,
            ),
            FoodItem(
              id: 'food_17',
              name: 'Salada verde',
              quantity: 100,
              unit: 'g',
              calories: 25,
              protein: 2,
              carbs: 5,
              fats: 0,
            ),
          ],
        ),
      ],
    );
  }
}

/// Provider global de dieta
final dietProvider = NotifierProvider<DietNotifier, DietState>(() {
  return DietNotifier();
});