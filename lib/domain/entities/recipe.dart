import 'package:equatable/equatable.dart';

class Recipe extends Equatable {
  final String recipeName;
  final int prepTime; // in minutes
  final int calories;
  final String difficulty;
  final List<Map<String, String>> ingredients; // e.g. [{"name": "Thịt bò", "amount": "200g"}]
  final List<String> instructions;

  const Recipe({
    required this.recipeName,
    required this.prepTime,
    required this.calories,
    required this.difficulty,
    required this.ingredients,
    required this.instructions,
  });

  @override
  List<Object?> get props => [
        recipeName,
        prepTime,
        calories,
        difficulty,
        ingredients,
        instructions,
      ];
}
