import 'package:injectable/injectable.dart';
import '../entities/recipe.dart';
import '../entities/user.dart';
import '../repositories/recipe_repository.dart';

@lazySingleton
class GenerateRecipe {
  final RecipeRepository repository;

  GenerateRecipe(this.repository);

  Future<Recipe> fromIngredients(List<String> ingredients, UserProfileEntity profile) {
    return repository.generateRecipeFromIngredients(ingredients, profile);
  }

  Future<Recipe> fromImage(String imageBase64, UserProfileEntity profile) {
    return repository.generateRecipeFromImage(imageBase64, profile);
  }
}
