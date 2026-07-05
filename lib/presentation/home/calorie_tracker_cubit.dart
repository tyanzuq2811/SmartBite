import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../core/di/injection.dart';
import '../../data/datasources/firebase_datasource.dart';
import '../../data/models/meal_plan_model.dart';

class CalorieTrackerState extends Equatable {
  final Map<String, int> consumedCaloriesByDate;
  final int targetCalories;
  final Map<String, Map<String, bool>> eatenRecipesByDate;
  final Map<String, List<MealItemModel>> eatenMealsByDate;

  const CalorieTrackerState({
    required this.consumedCaloriesByDate,
    required this.targetCalories,
    required this.eatenRecipesByDate,
    required this.eatenMealsByDate,
  });

  factory CalorieTrackerState.initial() {
    return const CalorieTrackerState(
      consumedCaloriesByDate: {},
      targetCalories: 2000,
      eatenRecipesByDate: {},
      eatenMealsByDate: {},
    );
  }

  int getConsumedCaloriesForDate(String date) {
    return consumedCaloriesByDate[date] ?? 0;
  }

  Map<String, bool> getEatenRecipesForDate(String date) {
    return eatenRecipesByDate[date] ?? {};
  }

  List<MealItemModel> getEatenMealsForDate(String date) {
    return eatenMealsByDate[date] ?? [];
  }

  int get consumedCalories {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return getConsumedCaloriesForDate(todayStr);
  }

  Map<String, bool> get eatenRecipes {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return getEatenRecipesForDate(todayStr);
  }

  List<MealItemModel> get eatenMeals {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return getEatenMealsForDate(todayStr);
  }

  CalorieTrackerState copyWith({
    Map<String, int>? consumedCaloriesByDate,
    int? targetCalories,
    Map<String, Map<String, bool>>? eatenRecipesByDate,
    Map<String, List<MealItemModel>>? eatenMealsByDate,
  }) {
    return CalorieTrackerState(
      consumedCaloriesByDate: consumedCaloriesByDate ?? this.consumedCaloriesByDate,
      targetCalories: targetCalories ?? this.targetCalories,
      eatenRecipesByDate: eatenRecipesByDate ?? this.eatenRecipesByDate,
      eatenMealsByDate: eatenMealsByDate ?? this.eatenMealsByDate,
    );
  }

  @override
  List<Object?> get props => [consumedCaloriesByDate, targetCalories, eatenRecipesByDate, eatenMealsByDate];
}

@injectable
class CalorieTrackerCubit extends HydratedCubit<CalorieTrackerState> {
  CalorieTrackerCubit() : super(CalorieTrackerState.initial());

  Future<void> loadFirebaseData(String userId) async {
    try {
      final ds = getIt<FirebaseDataSource>();
      final records = await ds.getDailyCalorieRecords(userId);
      final stats = await ds.getUserStats(userId);

      emit(CalorieTrackerState(
        consumedCaloriesByDate: Map<String, int>.from(records['consumed']),
        targetCalories: stats.targetCalories > 0 ? stats.targetCalories : state.targetCalories,
        eatenRecipesByDate: Map<String, Map<String, bool>>.from(records['recipes']),
        eatenMealsByDate: Map<String, List<MealItemModel>>.from(records['meals']),
      ));
    } catch (e) {
      print('[CalorieTrackerCubit] Lỗi khi load dữ liệu Firebase: $e');
    }
  }

  void toggleEaten(MealItemModel meal, String userId, [String? date]) {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final actualDate = date ?? todayStr;

    final recipeName = meal.name;
    final calories = meal.calories;

    final eatenForDate = Map<String, bool>.from(state.eatenRecipesByDate[actualDate] ?? {});
    final currentlyEaten = eatenForDate[recipeName] ?? false;
    final nextEaten = !currentlyEaten;

    eatenForDate[recipeName] = nextEaten;

    final currentConsumed = state.consumedCaloriesByDate[actualDate] ?? 0;
    final nextConsumed = nextEaten
        ? currentConsumed + calories
        : (currentConsumed - calories).clamp(0, 99999);

    final updatedConsumedMap = Map<String, int>.from(state.consumedCaloriesByDate);
    updatedConsumedMap[actualDate] = nextConsumed;

    final updatedEatenMap = Map<String, Map<String, bool>>.from(state.eatenRecipesByDate);
    updatedEatenMap[actualDate] = eatenForDate;

    // Cập nhật danh sách MealItemModel đầy đủ đã ăn
    final eatenMealsForDate = List<MealItemModel>.from(state.eatenMealsByDate[actualDate] ?? []);
    if (nextEaten) {
      if (!eatenMealsForDate.any((m) => m.name == recipeName)) {
        eatenMealsForDate.add(meal);
      }
    } else {
      eatenMealsForDate.removeWhere((m) => m.name == recipeName);
    }

    final updatedMealsMap = Map<String, List<MealItemModel>>.from(state.eatenMealsByDate);
    updatedMealsMap[actualDate] = eatenMealsForDate;

    emit(state.copyWith(
      consumedCaloriesByDate: updatedConsumedMap,
      eatenRecipesByDate: updatedEatenMap,
      eatenMealsByDate: updatedMealsMap,
    ));

    // Đồng bộ lên Firestore
    final ds = getIt<FirebaseDataSource>();
    ds.saveDailyCalorieRecord(
      userId,
      actualDate,
      nextConsumed,
      eatenForDate,
      eatenMealsForDate,
    );
  }

  void updateTargetCalories(int target, String userId) {
    emit(state.copyWith(targetCalories: target));
    final ds = getIt<FirebaseDataSource>();
    ds.getUserStats(userId).then((stats) {
      ds.updateUserStats(userId, stats.copyWith(targetCalories: target));
    }).catchError((e) {
      print('[CalorieTrackerCubit] Lỗi khi cập nhật target calories trên Firestore: $e');
    });
  }

  void reset() {
    emit(CalorieTrackerState.initial());
  }

  @override
  CalorieTrackerState? fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final Map<String, int> consumedMap = {};
    if (json['consumedCaloriesByDate'] != null) {
      final rawMap = json['consumedCaloriesByDate'] as Map;
      rawMap.forEach((key, val) {
        consumedMap[key.toString()] = val as int? ?? 0;
      });
    } else if (json['consumedCalories'] != null) {
      consumedMap[todayStr] = json['consumedCalories'] as int? ?? 0;
    }

    final Map<String, Map<String, bool>> eatenMap = {};
    if (json['eatenRecipesByDate'] != null) {
      final rawMap = json['eatenRecipesByDate'] as Map;
      rawMap.forEach((key, val) {
        final innerMap = <String, bool>{};
        if (val is Map) {
          val.forEach((ik, iv) {
            innerMap[ik.toString()] = iv as bool? ?? false;
          });
        }
        eatenMap[key.toString()] = innerMap;
      });
    } else if (json['eatenRecipes'] != null) {
      final innerMap = <String, bool>{};
      final rawInner = json['eatenRecipes'] as Map;
      rawInner.forEach((k, v) {
        innerMap[k.toString()] = v as bool? ?? false;
      });
      eatenMap[todayStr] = innerMap;
    }

    final Map<String, List<MealItemModel>> eatenMealsMap = {};
    if (json['eatenMealsByDate'] != null) {
      final rawMap = json['eatenMealsByDate'] as Map;
      rawMap.forEach((key, val) {
        if (val is List) {
          eatenMealsMap[key.toString()] = val
              .map((e) => MealItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      });
    }

    return CalorieTrackerState(
      consumedCaloriesByDate: consumedMap,
      targetCalories: json['targetCalories'] as int? ?? 2000,
      eatenRecipesByDate: eatenMap,
      eatenMealsByDate: eatenMealsMap,
    );
  }

  @override
  Map<String, dynamic>? toJson(CalorieTrackerState state) {
    final Map<String, List<Map<String, dynamic>>> serializedMeals = {};
    state.eatenMealsByDate.forEach((key, val) {
      serializedMeals[key] = val.map((m) => m.toJson()).toList();
    });

    return {
      'consumedCaloriesByDate': state.consumedCaloriesByDate,
      'targetCalories': state.targetCalories,
      'eatenRecipesByDate': state.eatenRecipesByDate,
      'eatenMealsByDate': serializedMeals,
    };
  }
}
