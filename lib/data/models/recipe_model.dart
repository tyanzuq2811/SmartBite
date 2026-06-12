import 'dart:convert';
import '../../domain/entities/recipe.dart';

class RecipeModel extends Recipe {
  const RecipeModel({
    required super.recipeName,
    required super.prepTime,
    required super.calories,
    required super.difficulty,
    required super.ingredients,
    required super.instructions,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    // Safe ingredients parsing
    final rawIngredients = json['ingredients'] as List?;
    final List<Map<String, String>> parsedIngredients = [];
    if (rawIngredients != null) {
      for (final item in rawIngredients) {
        if (item is Map) {
          parsedIngredients.add({
            'name': item['name']?.toString() ?? '',
            'amount': item['amount']?.toString() ?? '',
          });
        }
      }
    }

    // Safe instructions parsing
    final rawInstructions = json['instructions'] as List?;
    final List<String> parsedInstructions = [];
    if (rawInstructions != null) {
      for (final step in rawInstructions) {
        parsedInstructions.add(step.toString());
      }
    }

    return RecipeModel(
      recipeName: json['recipe_name']?.toString() ?? 'Món ăn dinh dưỡng',
      prepTime: _parseIntValue(json['prep_time'], 15),
      calories: _parseIntValue(json['calories'], 350),
      difficulty: json['difficulty']?.toString() ?? 'Trung Bình',
      ingredients: parsedIngredients,
      instructions: parsedInstructions,
    );
  }

  static RecipeModel fromRawJson(String rawJson) {
    final cleanJson = _extractJsonBlock(rawJson);
    final parsedMap = jsonDecode(cleanJson) as Map<String, dynamic>;
    return RecipeModel.fromJson(parsedMap);
  }

  Map<String, dynamic> toJson() {
    return {
      'recipe_name': recipeName,
      'prep_time': prepTime,
      'calories': calories,
      'difficulty': difficulty,
      'ingredients': ingredients,
      'instructions': instructions,
    };
  }

  factory RecipeModel.fromEntity(Recipe entity) {
    return RecipeModel(
      recipeName: entity.recipeName,
      prepTime: entity.prepTime,
      calories: entity.calories,
      difficulty: entity.difficulty,
      ingredients: entity.ingredients,
      instructions: entity.instructions,
    );
  }

  // --- Helper parsing methods ---
  static int _parseIntValue(dynamic val, int defaultValue) {
    if (val == null) return defaultValue;
    if (val is num) return val.toInt();
    if (val is String) {
      final numMatch = RegExp(r'\d+').firstMatch(val);
      if (numMatch != null) {
        return int.tryParse(numMatch.group(0)!) ?? defaultValue;
      }
    }
    return defaultValue;
  }

  static String _extractJsonBlock(String rawText) {
    // Greedy match between first { and last }
    final regExp = RegExp(r'\{[\s\S]*\}');
    final match = regExp.firstMatch(rawText);
    if (match != null) {
      return match.group(0)!;
    }
    return rawText;
  }
}
