import 'dart:async';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart' hide ServerException;
import '../../core/errors/exceptions.dart';
import '../models/recipe_model.dart';

import 'package:injectable/injectable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class GeminiDataSource {
  bool get hasApiKey;

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

  Future<Map<String, dynamic>> generateMealPlan({
    required String diet,
    required List<String> allergies,
    required List<String> dislikes,
    required List<String> likes,
    required int targetCalories,
  });
}

@LazySingleton(as: GeminiDataSource)
class GeminiDataSourceImpl implements GeminiDataSource {
  final String _apiKey;

  GeminiDataSourceImpl()
      : _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  @override
  bool get hasApiKey => _apiKey.isNotEmpty && (_apiKey.startsWith('AIzaSy') || _apiKey.startsWith('AQ.'));

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
        const Duration(minutes: 2),
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
        const Duration(minutes: 2),
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

Quy định đặt tên món ăn ("recipe_name") để hỗ trợ tính điểm huy hiệu:
- Nếu là món chay: Tên món bắt buộc phải chứa một trong các từ: 'chay', 'đậu hũ', 'rau củ', 'salad', 'quinoa'.
- Nếu là món ít béo, giảm cân: Tên món bắt buộc phải chứa một trong các từ: 'ức gà', 'cá hồi', 'salad', 'súp lơ', 'rau'.
- Nếu là món giàu đạm, tăng cơ: Tên món bắt buộc phải chứa một trong các từ: 'bò', 'ức gà', 'cá hồi', 'trứng', 'đùi gà'.
- Nếu là món tinh bột tốt: Tên món bắt buộc phải chứa một trong các từ: 'gạo lứt', 'yến mạch', 'khoai lang', 'quinoa'.

BẠN PHẢI TRẢ VỀ DỮ LIỆU DẠNG JSON duy nhất, không thêm bất kỳ văn bản giải thích nào khác ngoài khối JSON. Cấu trúc JSON bắt buộc phải như sau:
{
  "recipe_name": "Tên món ăn sáng tạo chứa từ khóa theo quy định trên",
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

Quy định đặt tên món ăn ("recipe_name") để hỗ trợ tính điểm huy hiệu:
- Nếu là món chay: Tên món bắt buộc phải chứa một trong các từ: 'chay', 'đậu hũ', 'rau củ', 'salad', 'quinoa'.
- Nếu là món ít béo, giảm cân: Tên món bắt buộc phải chứa một trong các từ: 'ức gà', 'cá hồi', 'salad', 'súp lơ', 'rau'.
- Nếu là món giàu đạm, tăng cơ: Tên món bắt buộc phải chứa một trong các từ: 'bò', 'ức gà', 'cá hồi', 'trứng', 'đùi gà'.
- Nếu là món tinh bột tốt: Tên món bắt buộc phải chứa một trong các từ: 'gạo lứt', 'yến mạch', 'khoai lang', 'quinoa'.

Yêu cầu định dạng: BẠN PHẢI TRẢ VỀ DỮ LIỆU DẠNG JSON duy nhất, không thêm bất kỳ văn bản giải thích nào khác ngoài khối JSON. Cấu trúc JSON bắt buộc phải như sau:
{
  "recipe_name": "Tên món ăn sáng tạo chứa từ khóa theo quy định trên",
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

  @override
  Future<Map<String, dynamic>> generateMealPlan({
    required String diet,
    required List<String> allergies,
    required List<String> dislikes,
    required List<String> likes,
    required int targetCalories,
  }) async {
    if (_apiKey.isEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      return _generateMockMealPlan(diet);
    }

    final prompt = _buildMealPlanPrompt(diet, allergies, dislikes, likes, targetCalories);
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      final response = await model.generateContent([Content.text(prompt)]).timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw TimeoutException('Kết nối đến Gemini AI bị quá hạn khi tạo thực đơn.'),
      );
      final rawResult = response.text ?? '';
      return jsonDecode(rawResult) as Map<String, dynamic>;
    } catch (e) {
      print('Gemini error generating meal plan: $e');
      if (e is TimeoutException) {
        throw GeminiTimeoutException(e.message ?? 'Đầu bếp AI đang quá tải khi tạo thực đơn, vui lòng thử lại sau!');
      }
      throw ServerException('Lỗi tạo thực đơn từ Gemini AI: $e');
    }
  }

  String _buildMealPlanPrompt(
    String diet,
    List<String> allergies,
    List<String> dislikes,
    List<String> likes,
    int targetCalories,
  ) {
    return '''
Bạn là chuyên gia dinh dưỡng cao cấp. Hãy lập một thực đơn ăn sạch, khoa học cho hôm nay gồm 3 bữa chính: Bữa sáng, Bữa trưa, Bữa tối.
Thông tin khách hàng:
- Chế độ ăn: $diet
- Dị ứng thực phẩm: ${allergies.join(', ')}
- Thực phẩm ghét (không dùng): ${dislikes.join(', ')}
- Thực phẩm thích (ưu tiên dùng): ${likes.join(', ')}
- Tổng mục tiêu calo trong ngày: khoảng $targetCalories calo.

Yêu cầu cụ thể:
1. Bữa sáng khoảng 25-30% calo, Bữa trưa khoảng 35-40% calo, Bữa tối khoảng 30-35% calo.
2. Với mỗi bữa ăn, cung cấp 2 phương án thay thế (swaps) khác nhau phù hợp VÀ danh sách các bước nấu ăn chi tiết (instructions) gồm các bước cụ thể, ngắn gọn bằng tiếng Việt (hoặc tiếng Anh nếu diet/ngôn ngữ phù hợp).
3. Quy định đặt tên món ăn ("meals[].name") bắt buộc phải chứa từ khóa đặc trưng sau tùy theo tính chất để hệ thống của ứng dụng nhận diện được:
   - Nếu là món chay: Tên món bắt buộc phải chứa một trong các từ: 'chay', 'đậu hũ', 'rau củ', 'salad', 'quinoa'.
   - Nếu là món ít béo, giảm cân: Tên món bắt buộc phải chứa một trong các từ: 'ức gà', 'cá hồi', 'salad', 'súp lơ', 'rau'.
   - Nếu là món giàu đạm, tăng cơ: Tên món bắt buộc phải chứa một trong các từ: 'bò', 'ức gà', 'cá hồi', 'trứng', 'đùi gà'.
   - Nếu là món tinh bột tốt: Tên món bắt buộc phải chứa một trong các từ: 'gạo lứt', 'yến mạch', 'khoai lang', 'quinoa'.
4. Tạo danh sách nguyên liệu đi chợ (grocery_list) tổng hợp phân loại theo các nhóm (ví dụ: "Đạm & Thịt", "Rau củ", "Khác") với số lượng (qty) cụ thể.
5. Cung cấp URL ảnh minh hoạ chất lượng cao và hoạt động tốt từ Unsplash (unsplash.com) phù hợp với món ăn (tránh link chung chung, hãy dùng url ảnh cụ thể như: https://images.unsplash.com/photo-1525351484163-7529414344d8?w=200).

BẠN BẮT BUỘC TRẢ VỀ DỮ LIỆU DẠNG JSON DUY NHẤT, KHÔNG THÊM BẤT KỲ VĂN BẢN GIẢI THÍCH NÀO KHÁC NGOÀI KHỐI JSON. Cấu trúc JSON bắt buộc phải như sau:
{
  "meals": [
    {
      "type": "Bữa sáng",
      "name": "Tên món ăn sáng chứa từ khóa theo quy định ở mục 3",
      "calories": 350,
      "image_url": "URL ảnh cụ thể từ Unsplash",
      "swaps": ["Món thay thế 1 chứa từ khóa", "Món thay thế 2 chứa từ khóa"],
      "instructions": ["Bước 1: Chuẩn bị yến mạch...", "Bước 2: Cho sữa vào nấu chín..."]
    },
    {
      "type": "Bữa trưa",
      "name": "Tên món ăn trưa chứa từ khóa theo quy định ở mục 3",
      "calories": 450,
      "image_url": "URL ảnh cụ thể từ Unsplash",
      "swaps": ["Món thay thế 1 chứa từ khóa", "Món thay thế 2 chứa từ khóa"],
      "instructions": ["Bước 1: Sơ chế thịt bò...", "Bước 2: Xào nhanh tay..."]
    },
    {
      "type": "Bữa tối",
      "name": "Tên món ăn tối chứa từ khóa theo quy định ở mục 3",
      "calories": 500,
      "image_url": "URL ảnh cụ thể từ Unsplash",
      "swaps": ["Món thay thế 1 chứa từ khóa", "Món thay thế 2 chứa từ khóa"],
      "instructions": ["Bước 1: Ướp cá hồi...", "Bước 2: Áp chảo cá hồi..."]
    }
  ],
  "grocery_list": {
    "Đạm & Thịt": [
      {"name": "Tên nguyên liệu", "qty": "200g", "checked": false}
    ],
    "Rau củ": [
      {"name": "Tên nguyên liệu", "qty": "2 quả", "checked": false}
    ]
  }
}
''';
  }

  Map<String, dynamic> _generateMockMealPlan(String diet) {
    if (diet == 'Chay') {
      return {
        "meals": [
          {
            "type": "Bữa sáng",
            "name": "Cháo yến mạch và hạt chia dinh dưỡng",
            "calories": 310,
            "image_url": "https://images.unsplash.com/photo-1517881917430-e70dfb3610aa?w=200",
            "swaps": ["Sữa chua Hy Lạp mix dâu tây", "Bánh mì nướng bơ quả bơ"],
            "instructions": [
              "Ngâm hạt chia trong nước ấm khoảng 5 phút.",
              "Đun sôi yến mạch với nước hoặc sữa đậu nành trong 10 phút.",
              "Đổ cháo yến mạch ra bát, rắc hạt chia, chuối thái lát lên trên rồi dùng ấm."
            ]
          },
          {
            "type": "Bữa trưa",
            "name": "Đậu hũ sốt cà chua hành tây nấu nấm",
            "calories": 380,
            "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200",
            "swaps": ["Salad rau củ sốt mè rang", "Canh chua chay Nam Bộ"],
            "instructions": [
              "Cắt đậu hũ thành khối vuông nhỏ, áp chảo vàng đều các mặt.",
              "Phi thơm hành tây băm nhỏ, xào chung với nấm rơm và cà chua thái múi.",
              "Cho đậu hũ vào nước sốt cà chua, nêm gia vị chay, đun nhỏ lửa 5 phút rồi rắc hành lá."
            ]
          },
          {
            "type": "Bữa tối",
            "name": "Cơm gạo lứt muối mè trộn rau luộc",
            "calories": 450,
            "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200",
            "swaps": ["Súp bí đỏ kem tươi chay", "Mì Ý sốt pesto rau cải"],
            "instructions": [
              "Vo gạo lứt rồi nấu chín mềm trong nồi cơm điện.",
              "Luộc chín bông cải xanh, cà rốt và rau cải ngọt với chút muối.",
              "Trộn cơm gạo lứt ấm với muối mè, ăn kèm rau củ luộc thanh mát."
            ]
          }
        ],
        "grocery_list": {
          "Rau củ & Quả": [
            {"name": "Cà chua chín", "qty": "2 quả", "checked": false},
            {"name": "Hành tây", "qty": "1 củ", "checked": false},
            {"name": "Nấm tươi", "qty": "150g", "checked": false},
            {"name": "Rau cải ngọt", "qty": "200g", "checked": false}
          ],
          "Ngũ cốc & Đạm thực vật": [
            {"name": "Đậu hũ non", "qty": "2 bìa", "checked": false},
            {"name": "Yến mạch nguyên cám", "qty": "50g", "checked": false},
            {"name": "Gạo lứt đỏ", "qty": "100g", "checked": false}
          ]
        }
      };
    } else {
      return {
        "meals": [
          {
            "type": "Bữa sáng",
            "name": "Bánh mì sandwich trứng ốp la",
            "calories": 350,
            "image_url": "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=200",
            "swaps": ["Sinh tố bơ yến mạch hạt lanh", "Sữa chua hạt ngũ cốc"],
            "instructions": [
              "Đun nóng chảo với một ít bơ, đập trứng gà vào ốp la chín tới.",
              "Nướng nhẹ bánh mì sandwich cho giòn thơm.",
              "Đặt trứng ốp la lên bánh mì, rắc tiêu, muối và ăn kèm vài lát cà chua."
            ]
          },
          {
            "type": "Bữa trưa",
            "name": "Bò né xào cà chua hành tây dầu hào",
            "calories": 420,
            "image_url": "https://images.unsplash.com/photo-1544025162-d76694265947?w=200",
            "swaps": ["Ức gà áp chảo sốt mật ong", "Thịt heo rim nước dừa tươi"],
            "instructions": [
              "Thịt bò phi lê thái mỏng, ướp dầu hào, tỏi băm và một chút tiêu.",
              "Đun nóng chảo, xào nhanh thịt bò ở lửa lớn để giữ độ mềm.",
              "Thêm hành tây cắt múi, cà chua xào chín tái rồi bày ra đĩa ăn kèm cơm."
            ]
          },
          {
            "type": "Bữa tối",
            "name": "Cá hồi áp chảo sốt bơ tỏi chanh dây",
            "calories": 540,
            "image_url": "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=200",
            "swaps": ["Tôm nướng muối ớt chanh", "Sườn heo nướng thảo mộc"],
            "instructions": [
              "Cá hồi rửa sạch, thấm khô, ướp với chút muối và tiêu đen.",
              "Áp chảo cá hồi với dầu ô liu mỗi mặt khoảng 2-3 phút.",
              "Phi tỏi thơm trong chảo, đổ nước cốt chanh dây và chút đường đun sệt, rồi rưới lên cá hồi."
            ]
          }
        ],
        "grocery_list": {
          "Đạm & Thịt": [
            {"name": "Thịt bò phi lê", "qty": "200g", "checked": false},
            {"name": "Filet cá hồi tươi", "qty": "250g", "checked": false},
            {"name": "Trứng gà ta", "qty": "2 quả", "checked": false}
          ],
          "Rau củ quả": [
            {"name": "Cà chua chín", "qty": "2 quả", "checked": false},
            {"name": "Hành tây", "qty": "1 củ", "checked": false},
            {"name": "Tỏi tép", "qty": "1 củ", "checked": false}
          ],
          "Khác": [
            {"name": "Bánh mì sandwich", "qty": "2 lát", "checked": false},
            {"name": "Bơ thực vật", "qty": "30g", "checked": false}
          ]
        }
      };
    }
  }
}
