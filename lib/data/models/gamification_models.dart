import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for user gamification stats
class UserStatsModel {
  final int streak;
  final Map<String, bool> streakDays; // {'T2': true, 'T3': false, ...}
  final int xp;
  final int level;
  final String levelTitle;
  final int xpToNextLevel;
  final DateTime? lastActiveDate;
  final int aiRecipesCreatedCount;
  final int fatDestroyerCount;
  final int veggieChampionCount;
  final int proteinBeastCount;
  final int carbCleanerCount;

  const UserStatsModel({
    required this.streak,
    required this.streakDays,
    required this.xp,
    required this.level,
    required this.levelTitle,
    required this.xpToNextLevel,
    this.lastActiveDate,
    required this.aiRecipesCreatedCount,
    required this.fatDestroyerCount,
    required this.veggieChampionCount,
    required this.proteinBeastCount,
    required this.carbCleanerCount,
  });

  factory UserStatsModel.initial() {
    return UserStatsModel(
      streak: 0,
      streakDays: {
        'T2': false,
        'T3': false,
        'T4': false,
        'T5': false,
        'T6': false,
        'T7': false,
        'CN': false,
      },
      xp: 0,
      level: 1,
      levelTitle: 'Tân binh dinh dưỡng',
      xpToNextLevel: 200,
      lastActiveDate: DateTime.now(),
      aiRecipesCreatedCount: 0,
      fatDestroyerCount: 0,
      veggieChampionCount: 0,
      proteinBeastCount: 0,
      carbCleanerCount: 0,
    );
  }

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final rawDays = json['streak_days'] as Map<String, dynamic>? ?? {};
    final streakDays = <String, bool>{};
    for (final entry in rawDays.entries) {
      streakDays[entry.key] = entry.value as bool? ?? false;
    }

    return UserStatsModel(
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      streakDays: streakDays.isNotEmpty
          ? streakDays
          : {
              'T2': false,
              'T3': false,
              'T4': false,
              'T5': false,
              'T6': false,
              'T7': false,
              'CN': false,
            },
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      levelTitle: json['level_title']?.toString() ?? 'Tân binh dinh dưỡng',
      xpToNextLevel: (json['xp_to_next_level'] as num?)?.toInt() ?? 200,
      lastActiveDate: parseDate(json['last_active_date']),
      aiRecipesCreatedCount: (json['ai_recipes_created_count'] as num?)?.toInt() ?? 0,
      fatDestroyerCount: (json['fat_destroyer_count'] as num?)?.toInt() ?? 0,
      veggieChampionCount: (json['veggie_champion_count'] as num?)?.toInt() ?? 0,
      proteinBeastCount: (json['protein_beast_count'] as num?)?.toInt() ?? 0,
      carbCleanerCount: (json['carb_cleaner_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streak': streak,
      'streak_days': streakDays,
      'xp': xp,
      'level': level,
      'level_title': levelTitle,
      'xp_to_next_level': xpToNextLevel,
      'last_active_date':
          lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
      'ai_recipes_created_count': aiRecipesCreatedCount,
      'fat_destroyer_count': fatDestroyerCount,
      'veggie_champion_count': veggieChampionCount,
      'protein_beast_count': proteinBeastCount,
      'carb_cleaner_count': carbCleanerCount,
    };
  }

  UserStatsModel copyWith({
    int? streak,
    Map<String, bool>? streakDays,
    int? xp,
    int? level,
    String? levelTitle,
    int? xpToNextLevel,
    DateTime? lastActiveDate,
    int? aiRecipesCreatedCount,
    int? fatDestroyerCount,
    int? veggieChampionCount,
    int? proteinBeastCount,
    int? carbCleanerCount,
  }) {
    return UserStatsModel(
      streak: streak ?? this.streak,
      streakDays: streakDays ?? this.streakDays,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      aiRecipesCreatedCount: aiRecipesCreatedCount ?? this.aiRecipesCreatedCount,
      fatDestroyerCount: fatDestroyerCount ?? this.fatDestroyerCount,
      veggieChampionCount: veggieChampionCount ?? this.veggieChampionCount,
      proteinBeastCount: proteinBeastCount ?? this.proteinBeastCount,
      carbCleanerCount: carbCleanerCount ?? this.carbCleanerCount,
    );
  }
}

/// Model for user badge
class BadgeModel {
  final String id;
  final String title;
  final String description; // Explains badge meaning/criteria
  final String icon; // Material icon name
  final String color; // Color name
  final bool isLocked;
  final DateTime? unlockedAt;

  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isLocked,
    this.unlockedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return BadgeModel(
      id: id,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'emoji_events',
      color: json['color']?.toString() ?? 'grey',
      isLocked: json['is_locked'] as bool? ?? true,
      unlockedAt: parseDate(json['unlocked_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'color': color,
      'is_locked': isLocked,
      'unlocked_at':
          unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    };
  }
}

/// Model for weekly challenge
class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final int targetDays;
  final int completedDays;
  final bool isCompleted;
  final String weekOf; // 'yyyy-MM-dd' of Monday

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDays,
    required this.completedDays,
    required this.isCompleted,
    required this.weekOf,
  });

  double get progress =>
      targetDays > 0 ? (completedDays / targetDays).clamp(0.0, 1.0) : 0.0;

  String get progressText =>
      isCompleted ? 'Đã hoàn thành 🎉' : '$completedDays/$targetDays ngày';

  factory ChallengeModel.fromJson(Map<String, dynamic> json, String id) {
    return ChallengeModel(
      id: id,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      targetDays: (json['target_days'] as num?)?.toInt() ?? 5,
      completedDays: (json['completed_days'] as num?)?.toInt() ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      weekOf: json['week_of']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'target_days': targetDays,
      'completed_days': completedDays,
      'is_completed': isCompleted,
      'week_of': weekOf,
    };
  }
}
