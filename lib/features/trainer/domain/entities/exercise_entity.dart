/// Entidade de Exercício
class ExerciseEntity {
  final String id;
  final String name;
  final String category; // Peito, Costas, Pernas, etc.
  final String muscleGroup; // Músculo principal trabalhado
  final String equipment; // Barra, Halteres, Máquina, etc.
  final String difficulty; // Iniciante, Intermediário, Avançado
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? description;
  final List<String> instructions;

  const ExerciseEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
    required this.equipment,
    required this.difficulty,
    this.videoUrl,
    this.thumbnailUrl,
    this.description,
    this.instructions = const [],
  });
}

/// Categorias de exercícios
class ExerciseCategory {
  static const String chest = 'Peito';
  static const String back = 'Costas';
  static const String legs = 'Pernas';
  static const String shoulders = 'Ombros';
  static const String biceps = 'Bíceps';
  static const String triceps = 'Tríceps';
  static const String abs = 'Abdômen';
  static const String cardio = 'Cardio';
  
  static List<String> get all => [
    chest, back, legs, shoulders, biceps, triceps, abs, cardio,
  ];
}