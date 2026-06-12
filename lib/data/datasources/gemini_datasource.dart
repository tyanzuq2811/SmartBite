import 'dart:async';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart' hide ServerException;
import '../../core/errors/exceptions.dart';
import '../models/recipe_model.dart';

import 'package:injectable/injectable.dart';

abstract class GeminiDataSource {
  Future<RecipeModel> generateRecipeFromIngredients({
    required List<String> ingredients,
    required String diet,
    required List<String> allergies,
    required List<String> dislikes,
    required List<String> likes,
  });

  Future<RecipeModel> generateRecipeFromImage({
    required String imageBase64,
    required String diet,
    required List<String> allergies,
    required List<String> dislikes,
    required List<String> likes,
  });
}

@LazySingleton(as: GeminiDataSource)
class GeminiDataSourceImpl implements GeminiDataSource {
  final String _apiKey;

  GeminiDataSourceImpl()
      : _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  @override
  Future<RecipeModel> generateRecipeFromIngredients({
    required List<String> ingredients,
    required String diet,
    required List<String> allergies,
    required List<String> dislikes,
    required List<String> likes,
  }) async {
    final prompt = _buildTextPrompt(ingredients, diet, allergies, dislikes, likes);
    return _generateWithRetry(() async {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      final response = await model.generateContent([Content.text(prompt)]).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Kết nối đến Gemini AI bị quá hạn.'),
      );
      return response.text ?? '';
    });
  }

  @override
  Future<RecipeModel> generateRecipeFromImage({
    required String imageBase64,
    required String diet,
    required List<String> allergies,
    required List<String> dislikes,
    required List<String> likes,
  }) async {
    final prompt = _buildImagePrompt(diet, allergies, dislikes, likes);
    final imageBytes = base64Decode(imageBase64);
    return _generateWithRetry(() async {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Kết nối đến Gemini AI bị quá hạn.'),
      );
      return response.text ?? '';
    });
  }

  // --- Core execution with Timeout & Silent Retry ---
  Future<RecipeModel> _generateWithRetry(Future<String> Function() apiCall) async {
    if (_apiKey.isEmpty) {
      // Return a simulated mock recipe if no API key is provided for easier local testing
      await Future.delayed(const Duration(seconds: 2));
      return _generateMockRecipe();
    }

    try {
      final rawResult = await apiCall();
      return _parseResponse(rawResult);
    } catch (e) {
      if (e is FormatException || e is GeminiFormatException) {
        // Silent retry once on JSON structure failures
        try {
          final rawResult = await apiCall();
          return _parseResponse(rawResult);
        } catch (_) {
          rethrow;
        }
      }
      if (e is TimeoutException) {
        throw GeminiTimeoutException(e.message ?? 'Đầu bếp AI đang quá tải, vui lòng thử lại sau giây lát!');
      }
      throw ServerException(e.toString());
    }
  }

  RecipeModel _parseResponse(String rawText) {
    if (rawText.contains('not_food') || rawText.contains('"error": "not_food"')) {
      throw NotFoodException('Không tìm thấy thực phẩm nào trong hình ảnh.');
    }
    try {
      return RecipeModel.fromRawJson(rawText);
    } catch (e) {
      throw GeminiFormatException('Sai cấu trúc JSON trả về từ AI: $e');
    }
  }

  String _buildTextPrompt(
    List<String> ingredients,
    String diet,
    List<String> allergies,
    List<String> dislikes,
    List<String> likes,
  ) {
    return '''
Bạn là một chuyên gia dinh dưỡng và đầu bếp chuyên nghiệp. Hãy tạo một công thức nấu ăn sáng tạo từ danh sách nguyên liệu sau: ${ingredients.join(', ')}.
Thông tin người dùng (vui lòng tuân thủ tuyệt đối):
- Chế độ ăn: $diet
- Dị ứng: ${allergies.join(', ')}
- Không thích: ${dislikes.join(', ')}
- Thích: ${likes.join(', ')}

BẠN PHẢI TRẢ VỀ DỮ LIỆU DẠNG JSON duy nhất, không thêm bất kỳ văn bản giải thích nào khác ngoài khối JSON. Cấu trúc JSON bắt buộc phải như sau:
{
  "recipe_name": "Tên món ăn sáng tạo",
  "prep_time": 15,
  "calories": 350,
  "difficulty": "Dễ",
  "ingredients": [
    {"name": "Tên nguyên liệu", "amount": "Liều lượng"}
  ],
  "instructions": [
    "Bước 1: Sơ chế...",
    "Bước 2: Chế biến..."
  ]
}
''';
  }

  String _buildImagePrompt(
    String diet,
    List<String> allergies,
    List<String> dislikes,
    List<String> likes,
  ) {
    return '''
Hãy phân tích hình ảnh này.
Nhiệm vụ 1: Kiểm tra xem trong ảnh có chứa thực phẩm, nguyên liệu nấu ăn hay món ăn nào không. Nếu KHÔNG chứa thực phẩm hay nguyên liệu nào (ví dụ ảnh chụp đồ vật, phòng ốc, giày dép...), bạn BẮT BUỘC phải trả về chính xác cấu trúc JSON sau và dừng lại:
{"error": "not_food"}

Nhiệm vụ 2: Nếu ảnh có chứa thực phẩm/nguyên liệu, hãy nhận diện các nguyên liệu đó và tạo ra một công thức nấu ăn phù hợp kết hợp với profile người dùng dưới đây:
- Chế độ ăn: $diet
- Dị ứng: ${allergies.join(', ')}
- Không thích: ${dislikes.join(', ')}
- Thích: ${likes.join(', ')}

Yêu cầu định dạng: BẠN PHẢI TRẢ VỀ DỮ LIỆU DẠNG JSON duy nhất, không thêm bất kỳ văn bản giải thích nào khác ngoài khối JSON. Cấu trúc JSON bắt buộc phải như sau:
{
  "recipe_name": "Tên món ăn sáng tạo",
  "prep_time": 15,
  "calories": 350,
  "difficulty": "Trung Bình",
  "ingredients": [
    {"name": "Tên nguyên liệu", "amount": "Liều lượng"}
  ],
  "instructions": [
    "Bước 1:...",
    "Bước 2:..."
  ]
}
''';
  }

  RecipeModel _generateMockRecipe() {
    return const RecipeModel(
      recipeName: 'Salad Trái Cây & Ức Gà Sốt Mật Ong',
      prepTime: 15,
      calories: 320,
      difficulty: 'Dễ',
      ingredients: [
        {'name': 'Ức gà filet', 'amount': '150g'},
        {'name': 'Xà lách thủy canh', 'amount': '100g'},
        {'name': 'Cà chua bi', 'amount': '50g'},
        {'name': 'Mật ong', 'amount': '1 muỗng cà phê'},
        {'name': 'Dầu ô liu', 'amount': '1 muỗng canh'},
      ],
      instructions: [
        'Rửa sạch ức gà, luộc chín hoặc áp chảo xé sợi nhỏ vừa ăn.',
        'Nhặt sạch xà lách cắt khúc vừa ăn, cà chua bi bổ đôi cho vào tô lớn.',
        'Pha nước sốt gồm dầu ô liu, mật ong, một chút muối và tiêu đen.',
        'Trộn đều ức gà xé sợi, xà lách, cà chua bi và nước sốt trong tô.',
        'Bày ra đĩa và thưởng thức lạnh để giữ độ giòn của rau.'
      ],
    );
  }
}
