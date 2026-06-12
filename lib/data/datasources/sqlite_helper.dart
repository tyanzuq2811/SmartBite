import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SqliteHelper {
  static final SqliteHelper instance = SqliteHelper._init();
  static Database? _database;

  // Web in-memory fallbacks
  final List<Map<String, dynamic>> _webSavedRecipes = [];
  final List<Map<String, dynamic>> _webLocalRecipes = [];
  final List<Map<String, dynamic>> _webSyncQueue = [];

  SqliteHelper._init() {
    if (kIsWeb) {
      _prepopulateWebRecipes();
    }
  }

  @factoryMethod
  factory SqliteHelper() => instance;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on Web. Using web in-memory fallback.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('smartbite.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recipes (
        recipe_name TEXT PRIMARY KEY,
        prep_time INTEGER,
        calories INTEGER,
        difficulty TEXT,
        ingredients_json TEXT,
        instructions_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE local_recipes (
        recipe_name TEXT PRIMARY KEY,
        prep_time INTEGER,
        calories INTEGER,
        difficulty TEXT,
        ingredients_json TEXT,
        instructions_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT,
        table_name TEXT,
        record_id TEXT,
        data_json TEXT,
        timestamp INTEGER
      )
    ''');

    await db.execute('''
      CREATE VIRTUAL TABLE local_recipes_fts USING fts5(
        recipe_name,
        ingredients_text,
        tokenize="unicode61"
      )
    ''');

    await _prepopulateLocalRecipes(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS recipes');
      await db.execute('DROP TABLE IF EXISTS local_recipes');
      await _createDB(db, newVersion);
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          action TEXT,
          table_name TEXT,
          record_id TEXT,
          data_json TEXT,
          timestamp INTEGER
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS local_recipes_fts');
      await db.execute('''
        CREATE VIRTUAL TABLE local_recipes_fts USING fts5(
          recipe_name,
          ingredients_text,
          tokenize="unicode61"
        )
      ''');
      // Populate FTS5 table from existing local_recipes
      final existing = await db.query('local_recipes');
      final batch = db.batch();
      for (var r in existing) {
        final ingredientsJson = r['ingredients_json'] as String? ?? '[]';
        final List<dynamic> ingredientsList = jsonDecode(ingredientsJson);
        final ingredientsText = ingredientsList
            .map((ing) => (ing['name'] as String? ?? '').toLowerCase())
            .join(' ');
        batch.insert(
          'local_recipes_fts',
          {
            'recipe_name': r['recipe_name'],
            'ingredients_text': ingredientsText,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    }
  }

  // Common list of pre-populated recipes shared between SQLite and Web fallback
  static List<Map<String, dynamic>> get _prepopulatedData {
    return [
      {
        'recipe_name': 'Salad Ức Gà Sốt Sữa Chua',
        'prep_time': 15,
        'calories': 280,
        'difficulty': 'Dễ',
        'ingredients_json': jsonEncode([
          {'name': 'Ức gà', 'amount': '150g'},
          {'name': 'Xà lách', 'amount': '100g'},
          {'name': 'Cà chua', 'amount': '50g'},
          {'name': 'Dưa leo', 'amount': '1 quả'},
          {'name': 'Sữa chua không đường', 'amount': '1 hộp'}
        ]),
        'instructions_json': jsonEncode([
          'Luộc chín ức gà và xé sợi nhỏ vừa ăn.',
          'Rửa sạch xà lách cắt khúc, cà chua bổ múi cau, dưa leo xắt lát.',
          'Trộn đều các loại rau củ và ức gà vào một tô lớn.',
          'Rưới sữa chua không đường lên trên, trộn đều và thưởng thức lạnh.'
        ]),
      },
      {
        'recipe_name': 'Cá Hồi Áp Chảo Sốt Chanh Dây',
        'prep_time': 20,
        'calories': 350,
        'difficulty': 'Trung bình',
        'ingredients_json': jsonEncode([
          {'name': 'Cá hồi', 'amount': '150g'},
          {'name': 'Chanh dây', 'amount': '2 quả'},
          {'name': 'Măng tây', 'amount': '100g'},
          {'name': 'Bơ lạt', 'amount': '10g'},
          {'name': 'Tỏi', 'amount': '1 củ'}
        ]),
        'instructions_json': jsonEncode([
          'Ướp cá hồi với một chút muối, tiêu và tỏi băm trong 10 phút.',
          'Áp chảo cá hồi với bơ lạt, mỗi mặt chiên khoảng 2-3 phút cho vàng đều.',
          'Lọc lấy nước cốt chanh dây, đun sôi nhỏ lửa với một chút đường và bơ lạt.',
          'Chần sơ măng tây trong nước sôi có pha chút muối để măng giòn xanh.',
          'Bày cá hồi ra đĩa cùng măng tây, rưới nước sốt chanh dây lên và thưởng thức.'
        ]),
      },
      {
        'recipe_name': 'Bò Né Cà Chua',
        'prep_time': 15,
        'calories': 420,
        'difficulty': 'Dễ',
        'ingredients_json': jsonEncode([
          {'name': 'Thịt bò', 'amount': '150g'},
          {'name': 'Cà chua', 'amount': '2 quả'},
          {'name': 'Hành tây', 'amount': '1/2 quả'},
          {'name': 'Tỏi', 'amount': '3 tép'},
          {'name': 'Trứng gà', 'amount': '1 quả'}
        ]),
        'instructions_json': jsonEncode([
          'Thái mỏng thịt bò, ướp với tỏi băm, dầu hào và hạt nêm trong 10 phút.',
          'Phi thơm tỏi trên chảo nóng, xào thịt bò chín tái nhanh tay ở lửa lớn rồi trút ra đĩa.',
          'Cho tiếp cà chua bổ múi cau và hành tây thái lát vào xào chín mềm để tạo nước sốt.',
          'Cho thịt bò lại vào đảo đều, đập một quả trứng gà vào chảo và tắt bếp khi trứng còn lòng đào.'
        ]),
      },
      {
        'recipe_name': 'Trứng Cuộn Hành Tây & Nấm',
        'prep_time': 10,
        'calories': 180,
        'difficulty': 'Dễ',
        'ingredients_json': jsonEncode([
          {'name': 'Trứng gà', 'amount': '2 quả'},
          {'name': 'Hành tây', 'amount': '30g'},
          {'name': 'Nấm hương', 'amount': '30g'},
          {'name': 'Hành lá', 'amount': '2 nhánh'}
        ]),
        'instructions_json': jsonEncode([
          'Đập trứng ra bát, nêm một chút nước mắm, hạt tiêu rồi đánh tan đều.',
          'Hành tây, nấm hương rửa sạch và băm nhỏ; hành lá xắt khoanh mỏng.',
          'Trộn đều hỗn hợp nấm, hành tây và hành lá vào bát trứng.',
          'Tráng một lớp dầu mỏng trên chảo, đổ trứng vào chiên lửa nhỏ và cuộn tròn lại khi trứng bắt đầu đông.'
        ]),
      },
      {
        'recipe_name': 'Canh Cà Chua Trứng',
        'prep_time': 10,
        'calories': 120,
        'difficulty': 'Dễ',
        'ingredients_json': jsonEncode([
          {'name': 'Trứng gà', 'amount': '1 quả'},
          {'name': 'Cà chua', 'amount': '2 quả'},
          {'name': 'Hành lá', 'amount': '2 nhánh'},
          {'name': 'Tỏi', 'amount': '2 tép'}
        ]),
        'instructions_json': jsonEncode([
          'Cà chua rửa sạch bổ múi cau; tỏi đập dập băm nhỏ.',
          'Phi tỏi thơm vàng, cho cà chua vào xào nhuyễn với chút muối để tạo màu đỏ đẹp.',
          'Thêm lượng nước vừa ăn đun sôi; đánh tan trứng trong bát.',
          'Nước sôi thì hạ nhỏ lửa, rót từ từ trứng vào nồi đồng thời khuấy nhẹ theo một chiều để tạo vân mây.',
          'Nêm lại gia vị cho vừa miệng, rắc hành lá cắt khúc lên và tắt bếp.'
        ]),
      },
      {
        'recipe_name': 'Thịt Heo Luộc Sốt Tỏi Ớt',
        'prep_time': 20,
        'calories': 310,
        'difficulty': 'Dễ',
        'ingredients_json': jsonEncode([
          {'name': 'Thịt heo', 'amount': '300g'},
          {'name': 'Tỏi', 'amount': '1 củ'},
          {'name': 'Ớt', 'amount': '2 quả'},
          {'name': 'Gừng', 'amount': '1 lát nhỏ'},
          {'name': 'Nước mắm', 'amount': '2 muỗng canh'}
        ]),
        'instructions_json': jsonEncode([
          'Rửa sạch thịt heo, luộc chín cùng lát gừng và một chút muối để khử mùi hôi.',
          'Khi thịt chín, vớt ra ngâm vào nước lạnh để thịt giòn và không bị thâm, sau đó thái lát mỏng.',
          'Pha nước sốt gồm nước mắm, đường, nước cốt chanh, tỏi băm và ớt băm khuấy đều.',
          'Xếp thịt ra đĩa, rưới sốt tỏi ớt chua ngọt lên trên hoặc chấm kèm rau thơm.'
        ]),
      },
      {
        'recipe_name': 'Súp Bí Đỏ Thịt Băm',
        'prep_time': 25,
        'calories': 220,
        'difficulty': 'Dễ',
        'ingredients_json': jsonEncode([
          {'name': 'Bí đỏ', 'amount': '200g'},
          {'name': 'Thịt bò', 'amount': '100g'},
          {'name': 'Cà rốt', 'amount': '50g'},
          {'name': 'Hành tây', 'amount': '1/2 quả'}
        ]),
        'instructions_json': jsonEncode([
          'Bí đỏ và cà rốt gọt vỏ, cắt miếng nhỏ rồi hấp chín mềm, sau đó xay nhuyễn mịn.',
          'Băm nhỏ thịt bò và hành tây; phi thơm hành tây và xào chín thịt bò với chút gia vị.',
          'Đổ hỗn hợp bí đỏ và cà rốt xay vào nồi, thêm nước dùng đun sôi nhỏ lửa.',
          'Cho thịt bò xào vào khuấy đều, nêm nếm lại gia vị vừa ăn và dùng nóng.'
        ]),
      },
      {
        'recipe_name': 'Tôm Rim Tỏi Gừng',
        'prep_time': 15,
        'calories': 240,
        'difficulty': 'Dễ',
        'ingredients_json': jsonEncode([
          {'name': 'Tôm tươi', 'amount': '200g'},
          {'name': 'Tỏi', 'amount': '3 tép'},
          {'name': 'Gừng', 'amount': '1 củ nhỏ'},
          {'name': 'Hành lá', 'amount': '2 nhánh'},
          {'name': 'Nước mắm', 'amount': '1 muỗng canh'}
        ]),
        'instructions_json': jsonEncode([
          'Tôm bóc vỏ, bỏ chỉ lưng, rửa sạch và để ráo.',
          'Tỏi gừng băm nhỏ; hành lá cắt khúc.',
          'Phi tỏi gừng thơm phức, trút tôm vào xào nhanh trên lửa lớn đến khi tôm chuyển đỏ hồng.',
          'Thêm nước mắm, một chút đường và rim nhỏ lửa đến khi nước sốt keo lại bám đều vào tôm.'
        ]),
      },
      {
        'recipe_name': 'Cải Bó Xôi Xào Thịt Bò',
        'prep_time': 15,
        'calories': 290,
        'difficulty': 'Dễ',
        'ingredients_json': jsonEncode([
          {'name': 'Thịt bò', 'amount': '100g'},
          {'name': 'Cải bó xôi', 'amount': '200g'},
          {'name': 'Tỏi', 'amount': '4 tép'},
          {'name': 'Dầu hào', 'amount': '1 muỗng canh'}
        ]),
        'instructions_json': jsonEncode([
          'Thái mỏng thịt bò, ướp với 1/2 tỏi băm, dầu hào và chút tiêu trong 10 phút.',
          'Cải bó xôi nhặt sạch, cắt khúc vừa ăn.',
          'Phi thơm phần tỏi còn lại, xào thịt bò chín tái rồi múc ra đĩa riêng.',
          'Cho cải bó xôi vào xào chín nhanh trên lửa lớn để rau giữ độ xanh giòn, sau đó cho thịt bò vào đảo cùng và tắt bếp.'
        ]),
      },
      {
        'recipe_name': 'Bắp Cải Cuộn Thịt Hấp',
        'prep_time': 30,
        'calories': 250,
        'difficulty': 'Trung bình',
        'ingredients_json': jsonEncode([
          {'name': 'Bắp cải', 'amount': '8 lá lớn'},
          {'name': 'Thịt heo', 'amount': '150g'},
          {'name': 'Nấm hương', 'amount': '20g'},
          {'name': 'Cà rốt', 'amount': '30g'}
        ]),
        'instructions_json': jsonEncode([
          'Lá bắp cải chần sơ qua nước sôi cho mềm dai dễ cuộn.',
          'Thịt heo xay trộn đều với nấm hương băm nhỏ, cà rốt xắt hạt lựu và gia vị.',
          'Trải lá bắp cải ra, đặt một lượng nhân thịt vừa đủ vào giữa và cuộn tròn lại chắc tay.',
          'Xếp các cuộn bắp cải vào xửng hấp cách thủy trong 20 phút cho thịt chín hoàn toàn.'
        ]),
      },
      {
        'recipe_name': 'Dưa Leo Trộn Chua Ngọt',
        'prep_time': 10,
        'calories': 80,
        'difficulty': 'Dễ',
        'ingredients_json': jsonEncode([
          {'name': 'Dưa leo', 'amount': '2 quả'},
          {'name': 'Tỏi', 'amount': '2 tép'},
          {'name': 'Ớt', 'amount': '1 quả'},
          {'name': 'Chanh', 'amount': '1/2 quả'},
          {'name': 'Đường', 'amount': '1 muỗng canh'}
        ]),
        'instructions_json': jsonEncode([
          'Dưa leo rửa sạch, xắt lát chéo dày vừa phải.',
          'Pha nước sốt gồm nước cốt chanh, đường, muối, tỏi ớt băm nhuyễn và khuấy tan.',
          'Rưới nước sốt lên dưa leo, trộn đều nhẹ tay.',
          'Để dưa leo ngấm gia vị trong ngăn mát tủ lạnh khoảng 15 phút trước khi ăn.'
        ]),
      },
      {
        'recipe_name': 'Cơm Chiên Dương Châu Sức Khỏe',
        'prep_time': 20,
        'calories': 390,
        'difficulty': 'Dễ',
        'ingredients_json': jsonEncode([
          {'name': 'Cơm', 'amount': '1 bát'},
          {'name': 'Trứng gà', 'amount': '1 quả'},
          {'name': 'Cà rốt', 'amount': '30g'},
          {'name': 'Đậu hũ', 'amount': '50g'},
          {'name': 'Hành lá', 'amount': '2 nhánh'}
        ]),
        'instructions_json': jsonEncode([
          'Đậu hũ xắt hạt lựu nhỏ chiên vàng giòn; cà rốt luộc sơ xắt hạt lựu.',
          'Đánh trứng đều, tráng mỏng trên chảo rồi xắt sợi nhỏ.',
          'Cho cơm nguội vào chảo đảo săn cùng chút dầu ô liu và gia vị.',
          'Cho cà rốt, đậu hũ chiên và trứng xắt sợi vào đảo đều cùng cơm, rắc hành lá thái nhỏ lên trên.'
        ]),
      },
      {
        'recipe_name': 'Canh Bí Đỏ Thịt Heo',
        'prep_time': 20,
        'calories': 190,
        'difficulty': 'Dễ',
        'ingredients_json': jsonEncode([
          {'name': 'Bí đỏ', 'amount': '200g'},
          {'name': 'Thịt heo', 'amount': '100g'},
          {'name': 'Hành lá', 'amount': '2 nhánh'}
        ]),
        'instructions_json': jsonEncode([
          'Bí đỏ gọt vỏ rửa sạch, xắt miếng vuông vừa ăn.',
          'Phi thơm đầu hành lá băm, cho thịt heo băm vào xào săn.',
          'Đổ nước vào đun sôi, cho bí đỏ vào nấu chín mềm trên lửa nhỏ.',
          'Nêm nếm gia vị vừa ăn, rắc hành lá cắt nhỏ vào canh rồi múc ra bát.'
        ]),
      },
      {
        'recipe_name': 'Nấm Hương Kho Đậu Hũ',
        'prep_time': 15,
        'calories': 210,
        'difficulty': 'Dễ',
        'ingredients_json': jsonEncode([
          {'name': 'Nấm hương', 'amount': '50g'},
          {'name': 'Đậu hũ', 'amount': '2 miếng'},
          {'name': 'Hành tây', 'amount': '1/2 quả'},
          {'name': 'Nước tương', 'amount': '2 muỗng canh'}
        ]),
        'instructions_json': jsonEncode([
          'Đậu hũ cắt miếng vuông vừa ăn, chiên vàng đều các mặt.',
          'Nấm hương ngâm nở, rửa sạch và khía hoa trên mũ nấm; hành tây thái múi cau.',
          'Xếp đậu hũ và nấm hương vào nồi, rưới nước tương, một chút đường và nước lọc ngập nửa đậu.',
          'Kho nhỏ lửa đến khi nước sốt cạn sệt lại, cho hành tây vào đảo đều chín tới rồi tắt bếp.'
        ]),
      },
      {
        'recipe_name': 'Sữa Đậu Nành Tự Nhiên',
        'prep_time': 40,
        'calories': 110,
        'difficulty': 'Trung bình',
        'ingredients_json': jsonEncode([
          {'name': 'Đậu nành', 'amount': '150g'},
          {'name': 'Lá dứa', 'amount': '3 lá'},
          {'name': 'Đường phèn', 'amount': '20g'}
        ]),
        'instructions_json': jsonEncode([
          'Ngâm đậu nành khoảng 6-8 tiếng, đãi sạch vỏ và để ráo nước.',
          'Xay mịn đậu nành với 1.2 lít nước lọc, dùng túi vải lọc lấy phần nước sữa cốt nguyên chất.',
          'Cho sữa đậu nành vào nồi cùng lá dứa đã rửa sạch cuộn tròn.',
          'Đun sôi sữa ở lửa vừa, khi sôi bùng thì hạ nhỏ lửa và khuấy đều liên tục trong 15 phút để sữa không bị khê.',
          'Thêm đường phèn khuấy tan, tắt bếp và thưởng thức nóng hoặc lạnh.'
        ]),
      }
    ];
  }

  Future<void> _prepopulateLocalRecipes(Database db) async {
    final batch = db.batch();
    for (var r in _prepopulatedData) {
      batch.insert(
        'local_recipes',
        r,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final ingredientsJson = r['ingredients_json'] as String? ?? '[]';
      final List<dynamic> ingredientsList = jsonDecode(ingredientsJson);
      final ingredientsText = ingredientsList
          .map((ing) => (ing['name'] as String? ?? '').toLowerCase())
          .join(' ');

      batch.insert(
        'local_recipes_fts',
        {
          'recipe_name': r['recipe_name'],
          'ingredients_text': ingredientsText,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  void _prepopulateWebRecipes() {
    _webLocalRecipes.addAll(_prepopulatedData);
  }

  // --- Core CRUD Operations ---

  Future<int> insertRecipe(Map<String, dynamic> row) async {
    if (kIsWeb) {
      _webSavedRecipes.removeWhere((r) => r['recipe_name'] == row['recipe_name']);
      _webSavedRecipes.add(row);
      return 1;
    }
    final db = await database;
    return await db.insert(
      'recipes',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryAllRecipes() async {
    if (kIsWeb) {
      return List.from(_webSavedRecipes);
    }
    final db = await database;
    return await db.query('recipes');
  }

  Future<void> deleteRecipe(String recipeName) async {
    if (kIsWeb) {
      _webSavedRecipes.removeWhere((r) => r['recipe_name'] == recipeName);
      return;
    }
    final db = await database;
    await db.delete(
      'recipes',
      where: 'recipe_name = ?',
      whereArgs: [recipeName],
    );
  }

  // --- Offline Matching Query ---

  Future<List<Map<String, dynamic>>> queryMatchingRecipes(List<String> ingredients) async {
    final List<Map<String, dynamic>> sourceList = kIsWeb ? _webLocalRecipes : await _queryAllLocalRecipesFromDb();

    if (ingredients.isEmpty) {
      return sourceList;
    }

    if (!kIsWeb) {
      try {
        final db = await database;
        final escapedTerms = ingredients
            .map((ing) => ing.replaceAll("'", "''").trim().toLowerCase())
            .where((ing) => ing.isNotEmpty)
            .map((ing) => '"$ing"*')
            .join(' OR ');

        if (escapedTerms.isNotEmpty) {
          final ftsQuery = 'SELECT recipe_name FROM local_recipes_fts WHERE ingredients_text MATCH ?';
          final ftsResults = await db.rawQuery(ftsQuery, [escapedTerms]);

          if (ftsResults.isNotEmpty) {
            final matchedNames = ftsResults.map((row) => row['recipe_name'] as String).toList();
            final placeholders = List.filled(matchedNames.length, '?').join(',');
            final recipesQuery = 'SELECT * FROM local_recipes WHERE recipe_name IN ($placeholders)';
            final dbResults = await db.rawQuery(recipesQuery, matchedNames);
            return dbResults;
          }
        }
      } catch (e) {
        // Fallback silently
      }
    }

    final List<Map<String, dynamic>> results = [];
    final List<int> matchCounts = [];

    for (var row in sourceList) {
      final ingredientsJson = row['ingredients_json'] as String? ?? '[]';
      final List<dynamic> ingredientsList = jsonDecode(ingredientsJson);
      int matchCount = 0;

      for (var ing in ingredientsList) {
        final ingName = (ing['name'] as String? ?? '').toLowerCase();
        for (var inputIng in ingredients) {
          final inputLower = inputIng.toLowerCase();
          if (ingName.contains(inputLower) || inputLower.contains(ingName)) {
            matchCount++;
            break;
          }
        }
      }

      if (matchCount > 0) {
        results.add(row);
        matchCounts.add(matchCount);
      }
    }

    if (results.isEmpty) {
      return sourceList.take(3).toList();
    }

    final List<_ZippedRecipe> zipped = List.generate(
      results.length,
      (i) => _ZippedRecipe(results[i], matchCounts[i]),
    );

    zipped.sort((a, b) => b.matchCount.compareTo(a.matchCount));

    return zipped.map((z) => z.row).toList();
  }

  Future<List<Map<String, dynamic>>> _queryAllLocalRecipesFromDb() async {
    final db = await database;
    return await db.query('local_recipes');
  }

  // --- Sync Queue Operations ---

  Future<int> insertSyncTask(Map<String, dynamic> row) async {
    if (kIsWeb) {
      final newRow = Map<String, dynamic>.from(row);
      newRow['id'] = _webSyncQueue.length + 1;
      _webSyncQueue.add(newRow);
      return newRow['id'] as int;
    }
    final db = await database;
    return await db.insert(
      'sync_queue',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryPendingSyncTasks() async {
    if (kIsWeb) {
      return List.from(_webSyncQueue);
    }
    final db = await database;
    return await db.query('sync_queue', orderBy: 'timestamp ASC');
  }

  Future<void> deleteSyncTask(int id) async {
    if (kIsWeb) {
      _webSyncQueue.removeWhere((r) => r['id'] == id);
      return;
    }
    final db = await database;
    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    if (kIsWeb) return;
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}

class _ZippedRecipe {
  final Map<String, dynamic> row;
  final int matchCount;

  _ZippedRecipe(this.row, this.matchCount);
}
