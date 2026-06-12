import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server failure occurred.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache failure occurred.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class GeminiTimeoutFailure extends Failure {
  const GeminiTimeoutFailure([super.message = 'AI connection timed out. Please try again.']);
}

class GeminiFormatFailure extends Failure {
  const GeminiFormatFailure([super.message = 'AI returned an invalid recipe structure.']);
}

class NotFoodFailure extends Failure {
  const NotFoodFailure([super.message = 'No food items were detected in the image.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
