import 'package:equatable/equatable.dart';

class UserProfileEntity extends Equatable {
  final String name;
  final DateTime? dob;
  final String dietType;
  final List<String> allergies;
  final List<String> likes;
  final List<String> dislikes;

  const UserProfileEntity({
    required this.name,
    this.dob,
    required this.dietType,
    required this.allergies,
    required this.likes,
    required this.dislikes,
  });

  @override
  List<Object?> get props => [name, dob, dietType, allergies, likes, dislikes];
}

class UserEntity extends Equatable {
  final String userId;
  final String email;
  final String role; // 'user' | 'admin'
  final String status; // 'active' | 'banned'
  final UserProfileEntity profile;
  final DateTime createdAt;

  const UserEntity({
    required this.userId,
    required this.email,
    required this.role,
    required this.status,
    required this.profile,
    required this.createdAt,
  });

  UserEntity copyWith({
    String? userId,
    String? email,
    String? role,
    String? status,
    UserProfileEntity? profile,
    DateTime? createdAt,
  }) {
    return UserEntity(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      profile: profile ?? this.profile,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [userId, email, role, status, profile, createdAt];
}
