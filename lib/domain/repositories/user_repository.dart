import '../entities/user.dart';

abstract class UserRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> register({
    required String email,
    required String password,
    required UserProfileEntity profile,
  });
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<void> resetPassword(String email);
  Future<void> updateUserProfile(String userId, UserProfileEntity profile);
  
  // Admin-specific operations
  Future<List<UserEntity>> getAllUsers();
  Future<void> updateUserStatus(String userId, String status); // 'active' | 'banned'
}
