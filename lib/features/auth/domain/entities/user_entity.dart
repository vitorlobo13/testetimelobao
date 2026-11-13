/// Entidade de Usuário (Domain Layer)
class UserEntity {
  final String id;
  final String name;
  final String email;
  final UserType userType;
  final String? photoUrl;
  final String? phone;
  final DateTime createdAt;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.photoUrl,
    this.phone,
    required this.createdAt,
    this.isActive = true,
  });

  UserEntity copyWith(
          {String? name, String? phone, String? photoUrl, bool clearPhoto = false}) =>
      UserEntity(
        id: id,
        name: name ?? this.name,
        email: email,
        userType: userType,
        photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
        phone: phone ?? this.phone,
        createdAt: createdAt,
        isActive: isActive,
      );

  /// Verifica se é Professor
  bool get isTrainer => userType == UserType.trainer;

  /// Verifica se é Aluno
  bool get isStudent => userType == UserType.student;

  /// Verifica se é a conta administradora (só convida personais)
  bool get isAdmin => userType == UserType.admin;

  @override
  String toString() {
    return 'UserEntity(id: $id, name: $name, email: $email, type: $userType)';
  }
}

/// Tipo de Usuário
enum UserType {
  trainer,  // Professor/Personal Trainer
  student,  // Aluno
  admin,    // Conta administradora compartilhada
}

/// Extensão para converter string em enum
extension UserTypeExtension on UserType {
  String get value {
    switch (this) {
      case UserType.trainer:
        return 'trainer';
      case UserType.student:
        return 'student';
      case UserType.admin:
        return 'admin';
    }
  }

  static UserType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'trainer':
        return UserType.trainer;
      case 'student':
        return UserType.student;
      case 'admin':
        return UserType.admin;
      default:
        throw Exception('Invalid user type: $value');
    }
  }
}