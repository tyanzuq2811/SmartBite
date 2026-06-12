import 'on_device_detector.dart';

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
    return ['Cá hồi', 'Cà chua', 'Hành tây'];
  }
}
