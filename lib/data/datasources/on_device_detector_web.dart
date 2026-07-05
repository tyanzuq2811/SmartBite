import 'on_device_detector.dart';
import '../../core/di/injection.dart';
import 'gemini_datasource.dart';

OnDeviceDetector getDetectorInstance() => OnDeviceDetectorWeb();

class OnDeviceDetectorWeb implements OnDeviceDetector {
  @override
  Future<List<String>> detectIngredientsFromFile(String filePath) async {
    return ['Cá hồi', 'Cà chua', 'Hành tây'];
  }

  @override
  Future<List<String>> detectIngredientsFromBase64(String base64Image) async {
    if (base64Image == 'SIMULATED_BASE64_IMAGE_DATA') {
      return ['Ức gà', 'Bông cải xanh', 'Cà rốt'];
    }

    try {
      final gemini = getIt<GeminiDataSource>();
      if (gemini.hasApiKey) {
        final results = await gemini.detectIngredientsFromImage(base64Image);
        if (results.isNotEmpty) {
          return results;
        }
      }
    } catch (e) {
      print('[OnDeviceDetectorWeb] Lỗi gọi Gemini API để nhận diện: $e. Dùng mock data.');
    }

    return ['Cá hồi', 'Cà chua', 'Hành tây'];
  }
}
