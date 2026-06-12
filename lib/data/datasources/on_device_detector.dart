import 'on_device_detector_stub.dart'
    if (dart.library.html) 'on_device_detector_web.dart'
    if (dart.library.ffi) 'on_device_detector_mobile.dart';

abstract class OnDeviceDetector {
  static OnDeviceDetector get instance => getDetectorInstance();

  Future<List<String>> detectIngredientsFromFile(String filePath);
  Future<List<String>> detectIngredientsFromBase64(String base64Image);
}
