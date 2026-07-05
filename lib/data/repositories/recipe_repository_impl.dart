import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/di/injection.dart';
import '../../core/utils/connectivity_service.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/gemini_datasource.dart';
import '../datasources/sqlite_helper.dart';
import '../datasources/on_device_detector.dart';
import '../models/recipe_model.dart';

@LazySingleton(as: RecipeRepository)
class RecipeRepositoryImpl implements RecipeRepository {
  final GeminiDataSource geminiDataSource;
  final SqliteHelper sqliteHelper;
  final ConnectivityService connectivityService;

  RecipeRepositoryImpl(
    this.geminiDataSource,
    this.sqliteHelper,
    this.connectivityService,
  );

  bool get _hasApiKey => geminiDataSource.hasApiKey;

  RecipeModel _mapRowToRecipe(Map<String, dynamic> row) {
    return RecipeModel(
      recipeName: row['recipe_name'] as String? ?? '',
      prepTime: row['prep_time'] as int? ?? 0,
      calories: row['calories'] as int? ?? 0,
      difficulty: row['difficulty'] as String? ?? 'Dễ',
      ingredients: (jsonDecode(row['ingredients_json'] as String? ?? '[]') as List)
          .map((item) => Map<String, String>.from(item as Map))
          .toList(),
      instructions: (jsonDecode(row['instructions_json'] as String? ?? '[]') as List)
          .map((item) => item as String)
          .toList(),
    );
  }

  @override
  Future<Recipe> generateRecipeFromIngredients(List<String> ingredients, UserProfileEntity profile) async {
    final hasInternet = await connectivityService.isConnected;
    
    // Switch to local offline recipe matcher if no internet or no API key is configured
    if (!hasInternet || !_hasApiKey) {
      try {
        final matches = await sqliteHelper.queryMatchingRecipes(ingredients);
        if (matches.isNotEmpty) {
          return _mapRowToRecipe(matches.first);
        }
        throw ServerException('Không tìm thấy công thức phù hợp trong cơ sở dữ liệu offline.');
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException('Lỗi khi tra cứu công thức offline: $e');
      }
    }

    return geminiDataSource.generateRecipeFromIngredients(
      ingredients: ingredients,
      diet: profile.dietType,
      allergies: profile.allergies,
      dislikes: profile.dislikes,
      likes: profile.likes,
    );
  }

  @override
  Future<Recipe> generateRecipeFromImage(String imageBase64, UserProfileEntity profile) async {
    // 1. Run local on-device image analysis to extract ingredient labels
    final detectedIngredients = await OnDeviceDetector.instance.detectIngredientsFromBase64(imageBase64);
    
    if (detectedIngredients.isEmpty) {
      throw NotFoodException('Không nhận diện được thực phẩm nào trong hình ảnh.');
    }

    final hasInternet = await connectivityService.isConnected;

    // 2. If online and API key exists, call Gemini for custom recipe generation
    if (hasInternet && _hasApiKey) {
      try {
        return await geminiDataSource.generateRecipeFromImage(
          imageBase64: imageBase64,
          diet: profile.dietType,
          allergies: profile.allergies,
          dislikes: profile.dislikes,
          likes: profile.likes,
        );
      } catch (e) {
        // Fallback to offline matcher if online call fails
        final matches = await sqliteHelper.queryMatchingRecipes(detectedIngredients);
        if (matches.isNotEmpty) {
          return _mapRowToRecipe(matches.first);
        }
        rethrow;
      }
    }

    // 3. Otherwise, use local offline recipe matcher using detected labels
    try {
      final matches = await sqliteHelper.queryMatchingRecipes(detectedIngredients);
      if (matches.isNotEmpty) {
        return _mapRowToRecipe(matches.first);
      }
      throw ServerException('Không tìm thấy công thức offline phù hợp với nguyên liệu nhận diện.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Lỗi khi tra cứu công thức offline: $e');
    }
  }

  @override
  Future<List<Recipe>> getSavedRecipes() async {
    try {
      final hasInternet = await connectivityService.isConnected;
      final user = _currentUser;
      final firestore = _firestore;

      if (hasInternet && user != null && firestore != null) {
        try {
          final snapshot = await firestore
              .collection('users')
              .doc(user.uid)
              .collection('saved_recipes')
              .get();
          
          final List<Recipe> recipes = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            recipes.add(_mapRowToRecipe(data));
            // Cập nhật SQLite để đồng bộ offline
            await sqliteHelper.insertRecipe(data);
          }
          return recipes;
        } catch (e) {
          print('[RecipeRepository] Lỗi tải từ Firestore: $e. Sử dụng SQLite fallback.');
        }
      }

      final list = await sqliteHelper.queryAllRecipes();
      return list.map((row) => _mapRowToRecipe(row)).toList();
    } catch (e) {
      throw ServerException('Lỗi khi tải công thức đã lưu: $e');
    }
  }

  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  User? get _currentUser {
    if (_isFirebaseInitialized) {
      try {
        return getIt<FirebaseAuth>().currentUser;
      } catch (_) {}
    }
    return null;
  }

  FirebaseFirestore? get _firestore {
    if (_isFirebaseInitialized) {
      try {
        return getIt<FirebaseFirestore>();
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<void> saveRecipe(Recipe recipe) async {
    try {
      final recipeModel = RecipeModel.fromEntity(recipe);
      final row = {
        'recipe_name': recipeModel.recipeName,
        'prep_time': recipeModel.prepTime,
        'calories': recipeModel.calories,
        'difficulty': recipeModel.difficulty,
        'ingredients_json': jsonEncode(recipeModel.ingredients),
        'instructions_json': jsonEncode(recipeModel.instructions),
      };

      // 1. Always save to local SQLite
      await sqliteHelper.insertRecipe(row);

      // 2. Try online sync if connected and logged in
      final hasInternet = await connectivityService.isConnected;
      final user = _currentUser;
      final firestore = _firestore;

      if (hasInternet && user != null && firestore != null) {
        try {
          await firestore
              .collection('users')
              .doc(user.uid)
              .collection('saved_recipes')
              .doc(recipeModel.recipeName)
              .set(row);
          return;
        } catch (_) {
          // Fall through to queue
        }
      }

      // 3. Store in sync queue for offline sync
      await sqliteHelper.insertSyncTask({
        'action': 'SAVE',
        'table_name': 'recipes',
        'record_id': recipeModel.recipeName,
        'data_json': jsonEncode(row),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw ServerException('Lỗi khi lưu công thức: $e');
    }
  }
}
