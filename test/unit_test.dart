import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:smartbite/data/models/recipe_model.dart';
import 'package:smartbite/data/models/user_model.dart';
import 'package:smartbite/data/datasources/on_device_detector.dart';
import 'package:smartbite/presentation/home/calorie_tracker_cubit.dart';
import 'package:smartbite/data/datasources/sqlite_helper.dart';

class FakeStorage implements Storage {
  @override
  dynamic read(String key) => null;

  @override
  Future<void> write(String key, dynamic value) async {}

  @override
  Future<void> delete(String key) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> close() async {}
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    HydratedBloc.storage = FakeStorage();
  });

  group('SmartBite Unit Tests', () {
    test('Regex JSON block extraction parses wrapping text correctly', () {
      const rawResponse = '''
Chào bạn! Dưới đây là công thức nấu ăn sáng tạo tôi dành cho bạn:
```json
{
  "recipe_name": "Salad Cá Hồi Keto",
  "prep_time": "15 mins",
  "calories": "320 kcal",
  "difficulty": "Dễ",
  "ingredients": [
    {"name": "Cá hồi", "amount": "150g"}
  ],
  "instructions": [
    "Bước 1: Áp chảo cá hồi",
    "Bước 2: Trộn salad"
  ]
}
```
Hy vọng bạn sẽ thích món ăn này!
''';

      final recipe = RecipeModel.fromRawJson(rawResponse);
      expect(recipe.recipeName, 'Salad Cá Hồi Keto');
      expect(recipe.prepTime, 15);
      expect(recipe.calories, 320);
      expect(recipe.difficulty, 'Dễ');
      expect(recipe.ingredients.first['name'], 'Cá hồi');
      expect(recipe.ingredients.first['amount'], '150g');
    });

    test('Safe value parser converts non-numeric strings to fallback defaults', () {
      const invalidResponse = '''
{
  "recipe_name": "Súp Nấm Chay",
  "prep_time": "không rõ",
  "calories": null,
  "difficulty": "Dễ",
  "ingredients": [],
  "instructions": []
}
''';

      final recipe = RecipeModel.fromRawJson(invalidResponse);
      expect(recipe.recipeName, 'Súp Nấm Chay');
      expect(recipe.prepTime, 15); // Fallback default
      expect(recipe.calories, 350); // Fallback default
    });

    test('UserProfileModel.fromJson should parse Firestore data correctly', () {
      final jsonMap = {
        'name': 'Nguyễn Văn A',
        'diet_type': 'Chay',
        'allergies': ['Đậu phộng'],
        'likes': ['Rau', 'Trái cây'],
        'dislikes': ['Hành lá']
      };

      final profile = UserProfileModel.fromJson(jsonMap);

      expect(profile.name, 'Nguyễn Văn A');
      expect(profile.dietType, 'Chay');
      expect(profile.allergies, ['Đậu phộng']);
      expect(profile.likes, ['Rau', 'Trái cây']);
      expect(profile.dislikes, ['Hành lá']);
    });

    test('OnDeviceDetector should return mock fallback list under test environments', () async {
      final detector = OnDeviceDetector.instance;
      final ingredients = await detector.detectIngredientsFromFile('dummy_path.jpg');
      expect(ingredients, contains('Cá hồi'));
      expect(ingredients, contains('Cà chua'));
      expect(ingredients, contains('Hành tây'));
    });

    test('RecipeModel serialization/deserialization matches SQLite row format', () {
      final original = RecipeModel(
        recipeName: 'Salad Cá Hồi Keto',
        prepTime: 15,
        calories: 320,
        difficulty: 'Dễ',
        ingredients: const [
          {'name': 'Cá hồi', 'amount': '150g'}
        ],
        instructions: const [
          'Bước 1: Áp chảo cá hồi',
          'Bước 2: Trộn salad'
        ],
      );

      final row = {
        'recipe_name': original.recipeName,
        'prep_time': original.prepTime,
        'calories': original.calories,
        'difficulty': original.difficulty,
        'ingredients_json': jsonEncode(original.ingredients),
        'instructions_json': jsonEncode(original.instructions),
      };

      expect(row['recipe_name'], 'Salad Cá Hồi Keto');
      expect(row['prep_time'], 15);
      expect(row['calories'], 320);
      expect(row['difficulty'], 'Dễ');
      expect(row['ingredients_json'], '[{"name":"Cá hồi","amount":"150g"}]');
      expect(row['instructions_json'], '["Bước 1: Áp chảo cá hồi","Bước 2: Trộn salad"]');
    });

    test('CalorieTrackerCubit fromJson/toJson should serialize and deserialize correctly', () {
      final cubit = CalorieTrackerCubit();
      
      final initialJson = cubit.toJson(cubit.state);
      expect(initialJson?['consumedCalories'], 650);
      expect(initialJson?['targetCalories'], 2000);
      expect(initialJson?['eatenRecipes'], isEmpty);

      final mutatedJson = {
        'consumedCalories': 860,
        'targetCalories': 2200,
        'eatenRecipes': {'Smoothie Việt Quất': true}
      };

      final restoredState = cubit.fromJson(mutatedJson);
      expect(restoredState?.consumedCalories, 860);
      expect(restoredState?.targetCalories, 2200);
      expect(restoredState?.eatenRecipes['Smoothie Việt Quất'], isTrue);
    });

    test('SqliteHelper sync queue operations write, query and delete tasks correctly', () async {
      final helper = SqliteHelper.instance;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final taskRow = {
        'action': 'SAVE',
        'table_name': 'recipes',
        'record_id': 'Món ăn Test',
        'data_json': '{"calories": 200}',
        'timestamp': timestamp,
      };

      final taskId = await helper.insertSyncTask(taskRow);
      expect(taskId, isNotNull);

      final pendingTasks = await helper.queryPendingSyncTasks();
      final addedTask = pendingTasks.firstWhere((t) => t['record_id'] == 'Món ăn Test');
      expect(addedTask['action'], 'SAVE');
      expect(addedTask['data_json'], '{"calories": 200}');
      expect(addedTask['timestamp'], timestamp);

      final int idToDelete = addedTask['id'] as int;
      await helper.deleteSyncTask(idToDelete);
      
      final pendingAfterDelete = await helper.queryPendingSyncTasks();
      expect(pendingAfterDelete.any((t) => t['record_id'] == 'Món ăn Test'), isFalse);
    });
  });
}
