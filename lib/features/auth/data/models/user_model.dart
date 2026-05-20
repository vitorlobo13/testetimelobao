import '../../domain/entities/user_entity.dart';

/// Model de Usuário (Data Layer) - com métodos de serialização
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.userType,
    super.photoUrl,
    required super.createdAt,
    super.isActive,
  });

  /// Criar UserModel a partir de JSON (Firebase/Supabase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      userType: UserTypeExtension.fromString(json['user_type'] as String),
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Converter UserModel para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'user_type': userType.value,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Criar cópia com alterações
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserType? userType,
    String? photoUrl,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Converter Entity para Model
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      userType: entity.userType,
      photoUrl: entity.photoUrl,
      createdAt: entity.createdAt,
      isActive: entity.isActive,
    );
  }
}