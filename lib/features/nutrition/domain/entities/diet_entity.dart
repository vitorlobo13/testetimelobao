import 'meal_entity.dart';

/// Plano de Dieta
class DietEntity {
  final String id;
  final String trainerId;
  final String studentId;
  final String name;
  final String? description;
  final List<MealEntity> meals;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  
  // Metas nutricionais diárias
  final double? targetCalories;
  final double? targetProtein;
  final double? targetCarbs;
  final double? targetFats;

  const DietEntity({
    required this.id,
    required this.trainerId,
    required this.studentId,
    required this.name,
    this.description,
    required this.meals,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.targetCalories,
    this.targetProtein,
    this.targetCarbs,
    this.targetFats,
  });

  /// Total de calorias diárias
  double get totalDailyCalories => 
      meals.fold(0.0, (sum, meal) => sum + meal.totalCalories);

  /// Total de proteínas diárias
  double get totalDailyProtein => 
      meals.fold(0.0, (sum, meal) => sum + meal.totalProtein);

  /// Total de carboidratos diários
  double get totalDailyCarbs => 
      meals.fold(0.0, (sum, meal) => sum + meal.totalCarbs);

  /// Total de gorduras diárias
  double get totalDailyFats => 
      meals.fold(0.0, (sum, meal) => sum + meal.totalFats);

  /// Total de refeições
  int get totalMeals => meals.length;

  /// Verifica se atingiu meta de calorias (margem de 5%)
  bool get isCaloriesOnTarget {
    if (targetCalories == null) return false;
    final diff = (totalDailyCalories - targetCalories!).abs();
    return diff <= targetCalories! * 0.05;
  }
}