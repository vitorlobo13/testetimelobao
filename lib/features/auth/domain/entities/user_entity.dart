/// Entidade de Usuário (Domain Layer)
class UserEntity {
  final String id;
  final String name;
  final String email;
  final UserType userType;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.photoUrl,
    required this.createdAt,
    this.isActive = true,
  });

  /// Verifica se é Professor
  bool get isTrainer => userType == UserType.trainer;

  /// Verifica se é Aluno
  bool get isStudent => userType == UserType.student;

  @override
  String toString() {
    return 'UserEntity(id: $id, name: $name, email: $email, type: $userType)';
  }
}

/// Tipo de Usuário
enum UserType {
  trainer,  // Professor/Personal Trainer
  student,  // Aluno
}

/// Extensão para converter string em enum
extension UserTypeExtension on UserType {
  String get value {
    switch (this) {
      case UserType.trainer:
        return 'trainer';
      case UserType.student:
        return 'student';
    }
  }

  static UserType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'trainer':
        return UserType.trainer;
      case 'student':
        return UserType.student;
      default:
        throw Exception('Invalid user type: $value');
    }
  }
}