import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/diet_entity.dart';
import '../../domain/entities/meal_entity.dart';

/// Dietas dos alunos (`studentLinks/{id}/diets`, uma ativa por aluno) e
/// biblioteca de modelos do personal (`trainers/{uid}/dietTemplates`).
class DietRepository {
  DietRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _diets(String linkId) =>
      _firestore.collection('studentLinks/$linkId/diets');

  CollectionReference<Map<String, dynamic>> templates(String trainerId) =>
      _firestore.collection('trainers/$trainerId/dietTemplates');

  Stream<DietEntity?> watchActive(String linkId) => _diets(linkId)
      .where('isActive', isEqualTo: true)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : dietFromDoc(s.docs.first, linkId));

  /// Salva a dieta como a ativa do aluno; a anterior vai para o histórico.
  Future<String> saveActive(DietEntity diet) async {
    final linkId = diet.studentId;
    final active = await _diets(linkId).where('isActive', isEqualTo: true).get();
    final batch = _firestore.batch();
    for (final d in active.docs) {
      batch.update(d.reference, {
        'isActive': false,
        'archivedAt': FieldValue.serverTimestamp(),
      });
    }
    final ref = _diets(linkId).doc();
    batch.set(ref, {
      ...dietToMap(diet),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return ref.id;
  }

  static Map<String, dynamic> dietToMap(DietEntity d) => {
        'trainerId': d.trainerId,
        'name': d.name,
        'description': d.description,
        'targetCalories': d.targetCalories,
        'targetProtein': d.targetProtein,
        'targetCarbs': d.targetCarbs,
        'targetFats': d.targetFats,
        'meals': d.meals.map(mealToMap).toList(),
      };

  static DietEntity dietFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, String linkId) {
    final d = doc.data() ?? const <String, dynamic>{};
    final created = d['createdAt'];
    return DietEntity(
      id: doc.id,
      trainerId: d['trainerId'] as String? ?? '',
      studentId: linkId,
      name: d['name'] as String? ?? '',
      description: d['description'] as String?,
      meals: mealsFromList(d['meals']),
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      isActive: d['isActive'] as bool? ?? false,
      targetCalories: (d['targetCalories'] as num?)?.toDouble(),
      targetProtein: (d['targetProtein'] as num?)?.toDouble(),
      targetCarbs: (d['targetCarbs'] as num?)?.toDouble(),
      targetFats: (d['targetFats'] as num?)?.toDouble(),
    );
  }

  static Map<String, dynamic> mealToMap(MealEntity m) => {
        'id': m.id,
        'name': m.name,
        'time': m.time,
        'notes': m.notes,
        'order': m.order,
        'foods': [
          for (final f in m.foods)
            {
              'id': f.id,
              'name': f.name,
              'quantity': f.quantity,
              'unit': f.unit,
              'calories': f.calories,
              'protein': f.protein,
              'carbs': f.carbs,
              'fats': f.fats,
              'notes': f.notes,
            },
        ],
      };

  static List<MealEntity> mealsFromList(Object? raw) {
    double n(Object? v) => (v as num?)?.toDouble() ?? 0;
    return [
      for (final m in (raw as List?) ?? const [])
        if (m is Map)
          MealEntity(
            id: m['id'] as String? ?? '',
            name: m['name'] as String? ?? '',
            time: m['time'] as String? ?? '',
            notes: m['notes'] as String?,
            order: (m['order'] as num?)?.toInt() ?? 0,
            foods: [
              for (final f in (m['foods'] as List?) ?? const [])
                if (f is Map)
                  FoodItem(
                    id: f['id'] as String? ?? '',
                    name: f['name'] as String? ?? '',
                    quantity: n(f['quantity']),
                    unit: f['unit'] as String? ?? 'g',
                    calories: n(f['calories']),
                    protein: n(f['protein']),
                    carbs: n(f['carbs']),
                    fats: n(f['fats']),
                    notes: f['notes'] as String?,
                  ),
            ],
          ),
    ]..sort((a, b) => a.order.compareTo(b.order));
  }
}

extension DietWithId on DietEntity {
  DietEntity withId(String id) => DietEntity(
        id: id,
        trainerId: trainerId,
        studentId: studentId,
        name: name,
        description: description,
        meals: meals,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isActive: isActive,
        targetCalories: targetCalories,
        targetProtein: targetProtein,
        targetCarbs: targetCarbs,
        targetFats: targetFats,
      );
}
