/// Item de alimento
class FoodItem {
  final String id;
  final String name;
  final double quantity; // Quantidade em gramas ou ml
  final String unit; // g, ml, unidade
  final double calories;
  final double protein; // Proteína em g
  final double carbs; // Carboidratos em g
  final double fats; // Gorduras em g
  final String? notes;

  const FoodItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.notes,
  });

  FoodItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    double? calories,
    double? protein,
    double? carbs,
    double? fats,
    String? notes,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      notes: notes ?? this.notes,
    );
  }
}

/// Refeição
class MealEntity {
  final String id;
  final String name; // Café da manhã, Almoço, etc.
  final String time; // Horário sugerido
  final List<FoodItem> foods;
  final String? notes;
  final int order;

  const MealEntity({
    required this.id,
    required this.name,
    required this.time,
    required this.foods,
    this.notes,
    required this.order,
  });

  /// Total de calorias da refeição
  double get totalCalories => foods.fold(0.0, (sum, food) => sum + food.calories);

  /// Total de proteínas
  double get totalProtein => foods.fold(0.0, (sum, food) => sum + food.protein);

  /// Total de carboidratos
  double get totalCarbs => foods.fold(0.0, (sum, food) => sum + food.carbs);

  /// Total de gorduras
  double get totalFats => foods.fold(0.0, (sum, food) => sum + food.fats);
}