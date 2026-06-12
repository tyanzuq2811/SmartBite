// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:injectable/injectable.dart';
import '../../core/di/injection.dart';
import '../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class FirebaseDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String email,
    required String password,
    required UserProfileModel profile,
  });
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<void> resetPassword(String email);
  Future<void> updateUserProfile(String userId, UserProfileModel profile);
  
  // Admin functions
  Future<List<UserModel>> getAllUsers();
  Future<void> updateUserStatus(String userId, String status);
}

@LazySingleton(as: FirebaseDataSource)
class FirebaseDataSourceImpl implements FirebaseDataSource {
  FirebaseAuth? get _auth {
    try {
      if (_isFirebaseInitialized) {
        return getIt<FirebaseAuth>();
      }
    } catch (_) {}
    return null;
  }

  FirebaseFirestore? get _firestore {
    try {
      if (_isFirebaseInitialized) {
        return getIt<FirebaseFirestore>();
      }
    } catch (_) {}
    return null;
  }

  FirebaseDataSourceImpl();

  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // --- MOCK IN-MEMORY DATABASE FOR TESTING WITHOUT FIREBASE ---
  static final List<UserModel> _mockUsers = [
    UserModel(
      userId: 'admin_123',
      email: 'admin@on-tap.com',
      role: 'admin',
      status: 'active',
      profile: const UserProfileModel(
        name: 'Quản trị viên',
        dietType: 'Bình thường',
        allergies: [],
        likes: ['Học tập'],
        dislikes: [],
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    UserModel(
      userId: 'user_123',
      email: 'user@on-tap.com',
      role: 'user',
      status: 'active',
      profile: UserProfileModel(
        name: 'Nguyễn Văn A',
        dob: DateTime.now().subtract(const Duration(days: 365 * 25)),
        dietType: 'Bình thường',
        allergies: const [],
        likes: const ['Tiếng Anh', 'Lịch Sử'],
        dislikes: const [],
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  static UserModel? _currentUserSession;

  @override
  Future<UserModel> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!_isFirebaseInitialized) {
      // Mock Authentication
      final user = _mockUsers.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw ServerException('Sai tài khoản hoặc mật khẩu!'),
      );
      if (user.status == 'banned') {
        throw ServerException('Tài khoản của bạn đã bị khoá bởi Admin!');
      }
      _currentUserSession = user;
      return user;
    }

    try {
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final userDoc = await _firestore!.collection('users').doc(credential.user!.uid).get();
      if (!userDoc.exists) {
        throw ServerException('Không tìm thấy thông tin người dùng trong cơ sở dữ liệu.');
      }
      final userModel = UserModel.fromJson(userDoc.data()!, userDoc.id);
      if (userModel.status == 'banned') {
        await _auth!.signOut();
        throw ServerException('Tài khoản của bạn đã bị khoá bởi Admin!');
      }
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Đăng nhập thất bại.');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required UserProfileModel profile,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!_isFirebaseInitialized) {
      // Mock Register
      if (_mockUsers.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
        throw ServerException('Email này đã được sử dụng!');
      }
      final newUser = UserModel(
        userId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        role: 'user',
        status: 'active',
        profile: profile,
        createdAt: DateTime.now(),
      );
      _mockUsers.add(newUser);
      _currentUserSession = newUser;
      return newUser;
    }

    try {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newUser = UserModel(
        userId: credential.user!.uid,
        email: email,
        role: 'user',
        status: 'active',
        profile: profile,
        createdAt: DateTime.now(),
      );
      
      await _firestore!.collection('users').doc(credential.user!.uid).set(newUser.toJson());
      return newUser;
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Đăng ký tài khoản thất bại.');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    if (!_isFirebaseInitialized) {
      _currentUserSession = null;
      return;
    }
    await _auth!.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (!_isFirebaseInitialized) {
      return _currentUserSession;
    }
    final firebaseUser = _auth!.currentUser;
    if (firebaseUser == null) return null;
    final userDoc = await _firestore!.collection('users').doc(firebaseUser.uid).get();
    if (!userDoc.exists) return null;
    return UserModel.fromJson(userDoc.data()!, userDoc.id);
  }

  @override
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!_isFirebaseInitialized) {
      if (!_mockUsers.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
        throw ServerException('Email không tồn tại trong hệ thống!');
      }
      return; // Mock reset success
    }
    try {
      await _auth!.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Gửi liên kết khôi phục mật khẩu thất bại.');
    }
  }

  @override
  Future<void> updateUserProfile(String userId, UserProfileModel profile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_isFirebaseInitialized) {
      final index = _mockUsers.indexWhere((u) => u.userId == userId);
      if (index != -1) {
        final current = _mockUsers[index];
        _mockUsers[index] = current.copyWith(profile: profile);
        if (_currentUserSession?.userId == userId) {
          _currentUserSession = _mockUsers[index];
        }
      }
      return;
    }
    await _firestore!.collection('users').doc(userId).update({
      'profile': profile.toJson(),
    });
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!_isFirebaseInitialized) {
      return List.from(_mockUsers);
    }
    final snapshot = await _firestore!.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromJson(doc.data(), doc.id)).toList();
  }

  @override
  Future<void> updateUserStatus(String userId, String status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_isFirebaseInitialized) {
      final index = _mockUsers.indexWhere((u) => u.userId == userId);
      if (index != -1) {
        _mockUsers[index] = _mockUsers[index].copyWith(status: status);
      }
      return;
    }
    await _firestore!.collection('users').doc(userId).update({
      'status': status,
    });
  }
}
