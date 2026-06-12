import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.name,
    super.dob,
    required super.dietType,
    required super.allergies,
    required super.likes,
    required super.dislikes,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    List<String> parseList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      return [];
    }

    return UserProfileModel(
      name: json['name']?.toString() ?? '',
      dob: parseDate(json['dob']),
      dietType: json['diet_type']?.toString() ?? 'Bình thường',
      allergies: parseList(json['allergies']),
      likes: parseList(json['likes']),
      dislikes: parseList(json['dislikes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'diet_type': dietType,
      'allergies': allergies,
      'likes': likes,
      'dislikes': dislikes,
    };
  }

  factory UserProfileModel.fromEntity(UserProfileEntity entity) {
    return UserProfileModel(
      name: entity.name,
      dob: entity.dob,
      dietType: entity.dietType,
      allergies: entity.allergies,
      likes: entity.likes,
      dislikes: entity.dislikes,
    );
  }
}

class UserModel extends UserEntity {
  const UserModel({
    required super.userId,
    required super.email,
    required super.role,
    required super.status,
    required UserProfileModel super.profile,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return UserModel(
      userId: id,
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      status: json['status']?.toString() ?? 'active',
      profile: UserProfileModel.fromJson(Map<String, dynamic>.from(json['profile'] ?? {})),
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'role': role,
      'status': status,
      'profile': (profile as UserProfileModel).toJson(),
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      userId: entity.userId,
      email: entity.email,
      role: entity.role,
      status: entity.status,
      profile: UserProfileModel.fromEntity(entity.profile),
      createdAt: entity.createdAt,
    );
  }

  @override
  UserModel copyWith({
    String? userId,
    String? email,
    String? role,
    String? status,
    UserProfileEntity? profile,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      profile: profile != null
          ? UserProfileModel.fromEntity(profile)
          : this.profile as UserProfileModel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
