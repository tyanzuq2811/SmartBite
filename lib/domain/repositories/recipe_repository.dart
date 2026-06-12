import '../entities/recipe.dart';
import '../entities/user.dart';

abstract class RecipeRepository {
  Future<Recipe> generateRecipeFromIngredients(List<String> ingredients, UserProfileEntity profile);
  Future<Recipe> generateRecipeFromImage(String imageBase64, UserProfileEntity profile);
  Future<List<Recipe>> getSavedRecipes();
  Future<void> saveRecipe(Recipe recipe);
}
