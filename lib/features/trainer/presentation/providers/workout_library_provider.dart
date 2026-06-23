import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workout_entity.dart';
import '../../domain/entities/exercise_entity.dart';

class WorkoutTemplate {
  final String title;
  final String description;
  final String goal;
  final String level;
  final int divisions;
  final int exercises;
  final List<String> exerciseList;
  final List<WorkoutDivision> workoutDivisions;

  const WorkoutTemplate({
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

class WorkoutLibraryNotifier extends Notifier<List<WorkoutTemplate>> {
  @override
  List<WorkoutTemplate> build() {
    return _generateDefaultTemplates();
  }

  void addTemplate(WorkoutTemplate template) {
    state = [...state, template];
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
