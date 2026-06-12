import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';

class CalorieTrackerState extends Equatable {
  final int consumedCalories;
  final int targetCalories;
  final Map<String, bool> eatenRecipes;

  const CalorieTrackerState({
    required this.consumedCalories,
    required this.targetCalories,
    required this.eatenRecipes,
  });

  factory CalorieTrackerState.initial() {
    return const CalorieTrackerState(
      consumedCalories: 650, // Default baseline consumed calories
      targetCalories: 2000,
      eatenRecipes: {},
    );
  }

  CalorieTrackerState copyWith({
    int? consumedCalories,
    int? targetCalories,
    Map<String, bool>? eatenRecipes,
  }) {
    return CalorieTrackerState(
      consumedCalories: consumedCalories ?? this.consumedCalories,
      targetCalories: targetCalories ?? this.targetCalories,
      eatenRecipes: eatenRecipes ?? this.eatenRecipes,
    );
  }

  @override
  List<Object?> get props => [consumedCalories, targetCalories, eatenRecipes];
}

@injectable
class CalorieTrackerCubit extends HydratedCubit<CalorieTrackerState> {
  CalorieTrackerCubit() : super(CalorieTrackerState.initial());

  void toggleEaten(String recipeName, int calories) {
    final currentlyEaten = state.eatenRecipes[recipeName] ?? false;
    final nextEaten = !currentlyEaten;

    final updatedMap = Map<String, bool>.from(state.eatenRecipes);
    updatedMap[recipeName] = nextEaten;

    final nextConsumed = nextEaten
        ? state.consumedCalories + calories
        : state.consumedCalories - calories;

    emit(state.copyWith(
      consumedCalories: nextConsumed,
      eatenRecipes: updatedMap,
    ));
  }

  void updateTargetCalories(int target) {
    emit(state.copyWith(targetCalories: target));
  }

  void reset() {
    emit(CalorieTrackerState.initial());
  }

  @override
  CalorieTrackerState? fromJson(Map<String, dynamic> json) {
    return CalorieTrackerState(
      consumedCalories: json['consumedCalories'] as int? ?? 650,
      targetCalories: json['targetCalories'] as int? ?? 2000,
      eatenRecipes: Map<String, bool>.from(json['eatenRecipes'] as Map? ?? {}),
    );
  }

  @override
  Map<String, dynamic>? toJson(CalorieTrackerState state) {
    return {
      'consumedCalories': state.consumedCalories,
      'targetCalories': state.targetCalories,
      'eatenRecipes': state.eatenRecipes,
    };
  }
}
