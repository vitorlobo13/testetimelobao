import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/diet_repository.dart';
import 'diet_provider.dart';
import '../../domain/entities/meal_entity.dart';

/// Modelo de template de dieta da biblioteca do professor.
/// Diferente de [DietEntity] (que pertence a um aluno), este template
/// é de uso geral e serve como base para prescrever dietas personalizadas.
class DietTemplateModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<MealEntity> meals;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Metas nutricionais
  final double? targetCalories;
  final double? targetProtein;
  final double? targetCarbs;
  final double? targetFats;

  const DietTemplateModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.meals,
    required this.createdAt,
    this.updatedAt,
    this.targetCalories,
    this.targetProtein,
    this.targetCarbs,
    this.targetFats,
  });

  /// Total de calorias calculado com base nas refeições.
  double get totalCalories =>
      meals.fold(0.0, (sum, meal) => sum + meal.totalCalories);

  /// Total de proteínas.
  double get totalProtein =>
      meals.fold(0.0, (sum, meal) => sum + meal.totalProtein);

  /// Total de carboidratos.
  double get totalCarbs =>
      meals.fold(0.0, (sum, meal) => sum + meal.totalCarbs);

  /// Total de gorduras.
  double get totalFats =>
      meals.fold(0.0, (sum, meal) => sum + meal.totalFats);

  DietTemplateModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    List<MealEntity>? meals,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFats,
  }) {
    return DietTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      meals: meals ?? this.meals,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFats: targetFats ?? this.targetFats,
    );
  }
}

/// Estado da biblioteca de dietas
class DietLibraryState {
  final List<DietTemplateModel> templates;
  final bool isLoading;
  final String? errorMessage;

  const DietLibraryState({
    this.templates = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DietLibraryState copyWith({
    List<DietTemplateModel>? templates,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DietLibraryState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Retorna as categorias distintas presentes na biblioteca.
  List<String> get categories {
    final cats = templates.map((t) => t.category).toSet().toList()..sort();
    return cats;
  }
}

/// Notifier para gerenciar a biblioteca de templates de dietas.
class DietLibraryNotifier extends Notifier<DietLibraryState> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  String? get _trainerId {
    final user = ref.read(authProvider).user;
    return (user != null && user.isTrainer) ? user.id : null;
  }

  CollectionReference<Map<String, dynamic>> _col(String trainerId) =>
      ref.read(dietRepositoryProvider).templates(trainerId);

  @override
  DietLibraryState build() {
    ref.onDispose(() => _sub?.cancel());
    Future.microtask(_listen);
    return const DietLibraryState(isLoading: true);
  }

  /// Modelos do personal (`trainers/{uid}/dietTemplates`). No primeiro
  /// acesso recebe os modelos padrão abaixo, que ele pode editar ou apagar.
  Future<void> _listen() async {
    await _sub?.cancel();
    final trainerId = _trainerId;
    if (trainerId == null) {
      state = const DietLibraryState();
      return;
    }
    final meta = FirebaseFirestore.instance.doc('trainers/$trainerId/meta/dietTemplates');
    final seeded = await meta.get();
    if (!(seeded.data()?['seeded'] == true)) {
      final batch = FirebaseFirestore.instance.batch();
      for (final t in _buildMockTemplates()) {
        batch.set(_col(trainerId).doc(), _toMap(t));
      }
      batch.set(meta, {'seeded': true, 'seededAt': FieldValue.serverTimestamp()});
      await batch.commit();
    }
    _sub = _col(trainerId).snapshots().listen((snap) {
      state = DietLibraryState(
        templates: snap.docs.map(_fromDoc).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
      );
    });
  }

  /// Adiciona um novo template à biblioteca.
  Future<void> addTemplate({
    required String name,
    required String description,
    required String category,
    required List<MealEntity> meals,
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFats,
  }) async {
    final trainerId = _trainerId;
    if (trainerId == null) return;
    await _col(trainerId).add(_toMap(DietTemplateModel(
      id: '',
      name: name,
      description: description,
      category: category,
      meals: meals,
      createdAt: DateTime.now(),
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetCarbs: targetCarbs,
      targetFats: targetFats,
    )));
  }

  /// Atualiza um template existente.
  Future<void> updateTemplate(DietTemplateModel updated) async {
    final trainerId = _trainerId;
    if (trainerId == null) return;
    await _col(trainerId).doc(updated.id).set({
      ..._toMap(updated),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove um template pelo ID.
  Future<void> deleteTemplate(String id) async {
    final trainerId = _trainerId;
    if (trainerId == null) return;
    await _col(trainerId).doc(id).delete();
  }

  static Map<String, dynamic> _toMap(DietTemplateModel t) => {
        'name': t.name,
        'description': t.description,
        'category': t.category,
        'targetCalories': t.targetCalories,
        'targetProtein': t.targetProtein,
        'targetCarbs': t.targetCarbs,
        'targetFats': t.targetFats,
        'meals': t.meals.map(DietRepository.mealToMap).toList(),
        'createdAt': Timestamp.fromDate(t.createdAt),
      };

  static DietTemplateModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    DateTime? date(Object? v) => v is Timestamp ? v.toDate() : null;
    return DietTemplateModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      description: d['description'] as String? ?? '',
      category: d['category'] as String? ?? 'Geral',
      meals: DietRepository.mealsFromList(d['meals']),
      createdAt: date(d['createdAt']) ?? DateTime.now(),
      updatedAt: date(d['updatedAt']),
      targetCalories: (d['targetCalories'] as num?)?.toDouble(),
      targetProtein: (d['targetProtein'] as num?)?.toDouble(),
      targetCarbs: (d['targetCarbs'] as num?)?.toDouble(),
      targetFats: (d['targetFats'] as num?)?.toDouble(),
    );
  }

  List<DietTemplateModel> _buildMockTemplates() {
    return [
      DietTemplateModel(
        id: 'tpl_1',
        name: 'Bulk Limpo – Hipertrofia Masculina',
        description:
            'Dieta hipercalórica focada em ganho de massa magra com mínimo acúmulo de gordura.',
        category: 'Hipertrofia',
        targetCalories: 3200,
        targetProtein: 180,
        targetCarbs: 450,
        targetFats: 80,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        meals: [
          MealEntity(
            id: 'tpl1_m1',
            name: 'Café da Manhã',
            time: '07:00',
            order: 0,
            foods: const [
              FoodItem(id: 'tpl1_f1', name: 'Ovos mexidos', quantity: 4, unit: 'unidades', calories: 280, protein: 24, carbs: 2, fats: 18),
              FoodItem(id: 'tpl1_f2', name: 'Aveia', quantity: 80, unit: 'g', calories: 296, protein: 10, carbs: 50, fats: 5),
              FoodItem(id: 'tpl1_f3', name: 'Whey Protein', quantity: 30, unit: 'g', calories: 120, protein: 24, carbs: 3, fats: 1),
            ],
          ),
          MealEntity(
            id: 'tpl1_m2',
            name: 'Almoço',
            time: '12:30',
            order: 1,
            foods: const [
              FoodItem(id: 'tpl1_f4', name: 'Frango grelhado', quantity: 250, unit: 'g', calories: 413, protein: 77, carbs: 0, fats: 9),
              FoodItem(id: 'tpl1_f5', name: 'Arroz integral', quantity: 200, unit: 'g', calories: 260, protein: 5, carbs: 54, fats: 2),
              FoodItem(id: 'tpl1_f6', name: 'Feijão', quantity: 100, unit: 'g', calories: 86, protein: 5, carbs: 16, fats: 0),
            ],
          ),
          MealEntity(
            id: 'tpl1_m3',
            name: 'Pós-treino',
            time: '18:30',
            order: 2,
            notes: 'Imediatamente após o treino',
            foods: const [
              FoodItem(id: 'tpl1_f7', name: 'Whey Protein', quantity: 40, unit: 'g', calories: 160, protein: 32, carbs: 4, fats: 1),
              FoodItem(id: 'tpl1_f8', name: 'Banana', quantity: 2, unit: 'unidades', calories: 210, protein: 3, carbs: 54, fats: 0),
            ],
          ),
          MealEntity(
            id: 'tpl1_m4',
            name: 'Jantar',
            time: '20:30',
            order: 3,
            foods: const [
              FoodItem(id: 'tpl1_f9', name: 'Carne bovina magra', quantity: 200, unit: 'g', calories: 330, protein: 52, carbs: 0, fats: 12),
              FoodItem(id: 'tpl1_f10', name: 'Batata doce', quantity: 200, unit: 'g', calories: 172, protein: 2, carbs: 40, fats: 0),
            ],
          ),
        ],
      ),
      DietTemplateModel(
        id: 'tpl_2',
        name: 'Low Carb Funcional – Emagrecimento',
        description:
            'Estrutura dietética com restrição moderada de carboidratos e gorduras saudáveis.',
        category: 'Emagrecimento',
        targetCalories: 1800,
        targetProtein: 140,
        targetCarbs: 100,
        targetFats: 70,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        meals: [
          MealEntity(
            id: 'tpl2_m1',
            name: 'Café da Manhã',
            time: '07:00',
            order: 0,
            foods: const [
              FoodItem(id: 'tpl2_f1', name: 'Ovos mexidos', quantity: 3, unit: 'unidades', calories: 210, protein: 18, carbs: 2, fats: 14),
              FoodItem(id: 'tpl2_f2', name: 'Abacate', quantity: 50, unit: 'g', calories: 80, protein: 1, carbs: 4, fats: 7),
            ],
          ),
          MealEntity(
            id: 'tpl2_m2',
            name: 'Almoço',
            time: '12:30',
            order: 1,
            foods: const [
              FoodItem(id: 'tpl2_f3', name: 'Tilápia grelhada', quantity: 200, unit: 'g', calories: 232, protein: 48, carbs: 0, fats: 5),
              FoodItem(id: 'tpl2_f4', name: 'Salada verde', quantity: 200, unit: 'g', calories: 50, protein: 4, carbs: 10, fats: 0),
              FoodItem(id: 'tpl2_f5', name: 'Azeite', quantity: 15, unit: 'ml', calories: 135, protein: 0, carbs: 0, fats: 15),
            ],
          ),
          MealEntity(
            id: 'tpl2_m3',
            name: 'Jantar',
            time: '19:30',
            order: 2,
            foods: const [
              FoodItem(id: 'tpl2_f6', name: 'Frango grelhado', quantity: 200, unit: 'g', calories: 330, protein: 62, carbs: 0, fats: 7),
              FoodItem(id: 'tpl2_f7', name: 'Brócolis', quantity: 150, unit: 'g', calories: 51, protein: 4, carbs: 10, fats: 0),
            ],
          ),
        ],
      ),
      DietTemplateModel(
        id: 'tpl_3',
        name: 'Déficit Moderado – Definição',
        description:
            'Manutenção de massa muscular enquanto reduz percentual de gordura.',
        category: 'Definição',
        targetCalories: 2200,
        targetProtein: 160,
        targetCarbs: 220,
        targetFats: 65,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        meals: [
          MealEntity(
            id: 'tpl3_m1',
            name: 'Café da Manhã',
            time: '07:00',
            order: 0,
            foods: const [
              FoodItem(id: 'tpl3_f1', name: 'Iogurte grego', quantity: 200, unit: 'g', calories: 130, protein: 10, carbs: 8, fats: 7),
              FoodItem(id: 'tpl3_f2', name: 'Granola', quantity: 30, unit: 'g', calories: 130, protein: 3, carbs: 20, fats: 4),
              FoodItem(id: 'tpl3_f3', name: 'Whey Protein', quantity: 30, unit: 'g', calories: 120, protein: 24, carbs: 3, fats: 1),
            ],
          ),
          MealEntity(
            id: 'tpl3_m2',
            name: 'Almoço',
            time: '12:30',
            order: 1,
            foods: const [
              FoodItem(id: 'tpl3_f4', name: 'Peito de frango', quantity: 200, unit: 'g', calories: 330, protein: 62, carbs: 0, fats: 7),
              FoodItem(id: 'tpl3_f5', name: 'Quinoa', quantity: 100, unit: 'g', calories: 120, protein: 4, carbs: 21, fats: 2),
            ],
          ),
          MealEntity(
            id: 'tpl3_m3',
            name: 'Jantar',
            time: '20:00',
            order: 2,
            foods: const [
              FoodItem(id: 'tpl3_f6', name: 'Atum em água', quantity: 170, unit: 'g', calories: 190, protein: 42, carbs: 0, fats: 1),
              FoodItem(id: 'tpl3_f7', name: 'Batata doce', quantity: 150, unit: 'g', calories: 129, protein: 2, carbs: 30, fats: 0),
            ],
          ),
        ],
      ),
      DietTemplateModel(
        id: 'tpl_4',
        name: 'Vegetariana Equilibrada',
        description:
            'Plano nutricional baseado em proteínas vegetais, legumes e grãos integrais.',
        category: 'Saúde',
        targetCalories: 2000,
        targetProtein: 110,
        targetCarbs: 250,
        targetFats: 60,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        meals: [
          MealEntity(
            id: 'tpl4_m1',
            name: 'Café da Manhã',
            time: '07:30',
            order: 0,
            foods: const [
              FoodItem(id: 'tpl4_f1', name: 'Tofu mexido', quantity: 150, unit: 'g', calories: 120, protein: 13, carbs: 3, fats: 7),
              FoodItem(id: 'tpl4_f2', name: 'Pão integral', quantity: 2, unit: 'fatias', calories: 160, protein: 8, carbs: 28, fats: 2),
            ],
          ),
          MealEntity(
            id: 'tpl4_m2',
            name: 'Almoço',
            time: '12:30',
            order: 1,
            foods: const [
              FoodItem(id: 'tpl4_f3', name: 'Lentilha', quantity: 150, unit: 'g', calories: 165, protein: 12, carbs: 28, fats: 1),
              FoodItem(id: 'tpl4_f4', name: 'Arroz integral', quantity: 150, unit: 'g', calories: 195, protein: 4, carbs: 41, fats: 2),
              FoodItem(id: 'tpl4_f5', name: 'Salada variada', quantity: 200, unit: 'g', calories: 60, protein: 3, carbs: 12, fats: 0),
            ],
          ),
          MealEntity(
            id: 'tpl4_m3',
            name: 'Jantar',
            time: '19:30',
            order: 2,
            foods: const [
              FoodItem(id: 'tpl4_f6', name: 'Grão-de-bico', quantity: 150, unit: 'g', calories: 243, protein: 13, carbs: 41, fats: 4),
              FoodItem(id: 'tpl4_f7', name: 'Legumes refogados', quantity: 200, unit: 'g', calories: 80, protein: 3, carbs: 16, fats: 2),
            ],
          ),
        ],
      ),
    ];
  }
}

/// Provider global da biblioteca de dietas.
final dietLibraryProvider =
    NotifierProvider<DietLibraryNotifier, DietLibraryState>(
  () => DietLibraryNotifier(),
);
