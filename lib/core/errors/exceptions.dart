class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'A server error occurred.']);

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'A cache error occurred.']);

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'No internet connection.']);

  @override
  String toString() => 'NetworkException: $message';
}

class GeminiTimeoutException implements Exception {
  final String message;
  GeminiTimeoutException([this.message = 'AI connection timed out.']);

  @override
  String toString() => 'GeminiTimeoutException: $message';
}

class GeminiFormatException implements Exception {
  final String message;
  GeminiFormatException([this.message = 'AI returned an invalid response.']);

  @override
  String toString() => 'GeminiFormatException: $message';
}

class NotFoodException implements Exception {
  final String message;
  NotFoodException([this.message = 'No food items detected in the image.']);

  @override
  String toString() => 'NotFoodException: $message';
}
