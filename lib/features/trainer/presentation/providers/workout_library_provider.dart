import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/workout_model.dart';
import '../../domain/entities/workout_entity.dart';
import '../../domain/entities/exercise_entity.dart';

class WorkoutTemplate {
  final String id;
  final String title;
  final String description;
  final String goal;
  final String level;
  final int divisions;
  final int exercises;
  final List<String> exerciseList;
  final List<WorkoutDivision> workoutDivisions;

  const WorkoutTemplate({
    this.id = '',
    required this.title,
    required this.description,
    required this.goal,
    required this.level,
    required this.divisions,
    required this.exercises,
    required this.exerciseList,
    required this.workoutDivisions,
  });
}

/// Modelos de treino do personal logado: `trainers/{uid}/templates`.
/// No primeiro acesso, recebe os modelos padrão abaixo (que ele pode apagar).
class WorkoutLibraryNotifier extends Notifier<List<WorkoutTemplate>> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? get _trainerId {
    final user = ref.read(authProvider).user;
    return (user != null && user.isTrainer) ? user.id : null;
  }

  CollectionReference<Map<String, dynamic>> _templates(String trainerId) =>
      _db.collection('trainers/$trainerId/templates');

  @override
  List<WorkoutTemplate> build() {
    ref.onDispose(() => _subscription?.cancel());
    ref.listen(authProvider.select((a) => a.user?.id), (_, __) => _listen());
    Future.microtask(_listen);
    return const [];
  }

  Future<void> _listen() async {
    await _subscription?.cancel();
    final trainerId = _trainerId;
    if (trainerId == null) {
      state = const [];
      return;
    }
    await _seedIfNeeded(trainerId);
    _subscription = _templates(trainerId).snapshots().listen((snap) {
      state = snap.docs.map(_fromDoc).toList()
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    });
  }

  Future<void> _seedIfNeeded(String trainerId) async {
    final meta = _db.doc('trainers/$trainerId/meta/templates');
    final snap = await meta.get();
    if (snap.exists && snap.data()?['seeded'] == true) return;
    final batch = _db.batch();
    for (final t in _generateDefaultTemplates()) {
      batch.set(_templates(trainerId).doc(), _toMap(t));
    }
    batch.set(meta, {'seeded': true, 'seededAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  Future<void> addTemplate(WorkoutTemplate template) async {
    final trainerId = _trainerId;
    if (trainerId == null) return;
    await _templates(trainerId).add(_toMap(template));
  }

  Future<void> deleteTemplate(String templateId) async {
    final trainerId = _trainerId;
    if (trainerId == null) return;
    await _templates(trainerId).doc(templateId).delete();
  }

  static Map<String, dynamic> _toMap(WorkoutTemplate t) => {
        'title': t.title,
        'description': t.description,
        'goal': t.goal,
        'level': t.level,
        'divisions': t.workoutDivisions.map(WorkoutModel.divisionToMap).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };

  static WorkoutTemplate _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final divisions = WorkoutModel.divisionsFromList(d['divisions']);
    final exerciseNames = divisions
        .expand((div) => div.exercises.map((e) => e.exercise.name))
        .toList();
    return WorkoutTemplate(
      id: doc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      goal: d['goal'] as String? ?? '',
      level: d['level'] as String? ?? '',
      divisions: divisions.length,
      exercises: exerciseNames.length,
      exerciseList: exerciseNames,
      workoutDivisions: divisions,
    );
  }

  List<WorkoutTemplate> _generateDefaultTemplates() {
    // Exercícios reais mockados
    const supinoReto = ExerciseEntity(
      id: '1',
      name: 'Supino Reto com Barra',
      category: 'Peito',
      muscleGroup: 'Peitoral Maior',
      equipment: 'Barra',
      difficulty: 'Intermediário',
    );
    const supinoInclinado = ExerciseEntity(
      id: '2',
      name: 'Supino Inclinado com Halteres',
      category: 'Peito',
      muscleGroup: 'Peitoral Superior',
      equipment: 'Halteres',
      difficulty: 'Intermediário',
    );
    const barraFixa = ExerciseEntity(
      id: '5',
      name: 'Barra Fixa',
      category: 'Costas',
      muscleGroup: 'Dorsal',
      equipment: 'Barra Fixa',
      difficulty: 'Intermediário',
    );
    const remadaCurvada = ExerciseEntity(
      id: '6',
      name: 'Remada Curvada',
      category: 'Costas',
      muscleGroup: 'Dorsal',
      equipment: 'Barra',
      difficulty: 'Intermediário',
    );
    const agachamentoLivre = ExerciseEntity(
      id: '9',
      name: 'Agachamento Livre',
      category: 'Pernas',
      muscleGroup: 'Quadríceps',
      equipment: 'Barra',
      difficulty: 'Avançado',
    );
    const legPress = ExerciseEntity(
      id: '10',
      name: 'Leg Press 45°',
      category: 'Pernas',
      muscleGroup: 'Quadríceps',
      equipment: 'Máquina',
      difficulty: 'Iniciante',
    );
    const desenvolvimento = ExerciseEntity(
      id: '13',
      name: 'Desenvolvimento com Barra',
      category: 'Ombros',
      muscleGroup: 'Deltóide',
      equipment: 'Barra',
      difficulty: 'Intermediário',
    );
    const elevacaoLateral = ExerciseEntity(
      id: '14',
      name: 'Elevação Lateral',
      category: 'Ombros',
      muscleGroup: 'Deltóide Lateral',
      equipment: 'Halteres',
      difficulty: 'Iniciante',
    );
    const roscaDireta = ExerciseEntity(
      id: '16',
      name: 'Rosca Direta com Barra',
      category: 'Bíceps',
      muscleGroup: 'Bíceps',
      equipment: 'Barra',
      difficulty: 'Iniciante',
    );
    const tricepsTesta = ExerciseEntity(
      id: '18',
      name: 'Tríceps Testa',
      category: 'Tríceps',
      muscleGroup: 'Tríceps',
      equipment: 'Barra',
      difficulty: 'Intermediário',
    );

    return [
      WorkoutTemplate(
        title: 'Ficha ABC - Hipertrofia Clássica',
        description: 'Foco em ganho de massa muscular com divisão Push/Pull/Legs.',
        goal: 'Hipertrofia',
        level: 'Intermediário',
        divisions: 3,
        exercises: 10,
        exerciseList: const [
          'Supino Reto com Barra',
          'Supino Inclinado com Halteres',
          'Desenvolvimento com Barra',
          'Elevação Lateral',
          'Tríceps Testa',
          'Barra Fixa',
          'Remada Curvada',
          'Rosca Direta com Barra',
          'Agachamento Livre',
          'Leg Press 45°',
        ],
        workoutDivisions: [
          WorkoutDivision(
            id: 'div_abc_a',
            name: 'Divisão A - Empurrar (Push)',
            order: 0,
            exercises: [
              WorkoutExercise(id: 'ex_abc_a1', exercise: supinoReto, sets: 4, reps: '8-10', rest: '90', order: 0),
              WorkoutExercise(id: 'ex_abc_a2', exercise: supinoInclinado, sets: 4, reps: '10-12', rest: '60', order: 1),
              WorkoutExercise(id: 'ex_abc_a3', exercise: desenvolvimento, sets: 3, reps: '10', rest: '90', order: 2),
              WorkoutExercise(id: 'ex_abc_a4', exercise: elevacaoLateral, sets: 4, reps: '12-15', rest: '60', order: 3),
              WorkoutExercise(id: 'ex_abc_a5', exercise: tricepsTesta, sets: 3, reps: '10', rest: '60', order: 4),
            ],
          ),
          WorkoutDivision(
            id: 'div_abc_b',
            name: 'Divisão B - Puxar (Pull)',
            order: 1,
            exercises: [
              WorkoutExercise(id: 'ex_abc_b1', exercise: barraFixa, sets: 3, reps: 'Falha', rest: '90', order: 0),
              WorkoutExercise(id: 'ex_abc_b2', exercise: remadaCurvada, sets: 4, reps: '8-10', rest: '90', order: 1),
              WorkoutExercise(id: 'ex_abc_b3', exercise: roscaDireta, sets: 3, reps: '10-12', rest: '60', order: 2),
            ],
          ),
          WorkoutDivision(
            id: 'div_abc_c',
            name: 'Divisão C - Pernas (Legs)',
            order: 2,
            exercises: [
              WorkoutExercise(id: 'ex_abc_c1', exercise: agachamentoLivre, sets: 4, reps: '8-10', rest: '120', order: 0),
              WorkoutExercise(id: 'ex_abc_c2', exercise: legPress, sets: 4, reps: '10-12', rest: '90', order: 1),
            ],
          ),
        ],
      ),
      WorkoutTemplate(
        title: 'Full Body 3x - Iniciantes',
        description: 'Treino de corpo inteiro ideal para adaptação muscular e consistência.',
        goal: 'Adaptação',
        level: 'Iniciante',
        divisions: 1,
        exercises: 5,
        exerciseList: const [
          'Agachamento Livre',
          'Supino Reto com Barra',
          'Remada Curvada',
          'Desenvolvimento com Barra',
          'Rosca Direta com Barra',
        ],
        workoutDivisions: [
          WorkoutDivision(
            id: 'div_fb_a',
            name: 'Full Body A',
            order: 0,
            exercises: [
              WorkoutExercise(id: 'ex_fb_1', exercise: agachamentoLivre, sets: 3, reps: '10-12', rest: '90', order: 0),
              WorkoutExercise(id: 'ex_fb_2', exercise: supinoReto, sets: 3, reps: '10', rest: '60', order: 1),
              WorkoutExercise(id: 'ex_fb_3', exercise: remadaCurvada, sets: 3, reps: '10', rest: '60', order: 2),
              WorkoutExercise(id: 'ex_fb_4', exercise: desenvolvimento, sets: 3, reps: '12', rest: '60', order: 3),
              WorkoutExercise(id: 'ex_fb_5', exercise: roscaDireta, sets: 3, reps: '12', rest: '60', order: 4),
            ],
          ),
        ],
      ),
    ];
  }
}

final workoutLibraryProvider = NotifierProvider<WorkoutLibraryNotifier, List<WorkoutTemplate>>(() {
  return WorkoutLibraryNotifier();
});
