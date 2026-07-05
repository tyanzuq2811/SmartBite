import 'package:injectable/injectable.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/connectivity_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/firebase_datasource.dart';
import '../models/user_model.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final FirebaseDataSource firebaseDataSource;
  final ConnectivityService connectivityService;

  UserRepositoryImpl(
    this.firebaseDataSource,
    this.connectivityService,
  );

  @override
  Future<UserEntity> login({required String email, required String password}) async {
    if (!await connectivityService.isConnected) {
      throw const NetworkFailure('Vui lòng kiểm tra kết nối mạng của bạn');
    }
    try {
      return await firebaseDataSource.login(email: email, password: password);
    } on ServerException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    required UserProfileEntity profile,
  }) async {
    if (!await connectivityService.isConnected) {
      throw const NetworkFailure('Vui lòng kiểm tra kết nối mạng của bạn');
    }
    try {
      final profileModel = UserProfileModel.fromEntity(profile);
      return await firebaseDataSource.register(
        email: email,
        password: password,
        profile: profileModel,
      );
    } on ServerException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await firebaseDataSource.logout();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      return await firebaseDataSource.getCurrentUser();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    if (!await connectivityService.isConnected) {
      throw const NetworkFailure('Vui lòng kiểm tra kết nối mạng của bạn');
    }
    try {
      await firebaseDataSource.resetPassword(email);
    } on ServerException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateUserProfile(String userId, UserProfileEntity profile) async {
    try {
      final profileModel = UserProfileModel.fromEntity(profile);
      await firebaseDataSource.updateUserProfile(userId, profileModel);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    try {
      return await firebaseDataSource.getAllUsers();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await firebaseDataSource.updateUserStatus(userId, status);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> adminUpdateUser(
    String userId, {
    required String name,
    required String email,
    required String role,
    required String status,
  }) async {
    try {
      await firebaseDataSource.adminUpdateUser(
        userId,
        name: name,
        email: email,
        role: role,
        status: status,
      );
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
