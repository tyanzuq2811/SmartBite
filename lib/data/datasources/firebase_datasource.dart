import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import '../../core/di/injection.dart';
import '../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../models/meal_plan_model.dart';
import '../models/gamification_models.dart';

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

  // Meal Plan functions
  Future<MealPlanModel?> getMealPlan(String userId, String date);
  Future<void> saveMealPlan(String userId, MealPlanModel plan);
  Future<void> deleteMealPlan(String userId, String date);
  Future<void> updateGroceryChecked(
      String userId, String date, String category, int index, bool checked);

  // Gamification functions
  Future<UserStatsModel> getUserStats(String userId);
  Future<void> updateUserStats(String userId, UserStatsModel stats);
  Future<List<BadgeModel>> getBadges(String userId);
  Future<List<ChallengeModel>> getChallenges(String userId);
  Future<void> updateChallengeProgress(
      String userId, String challengeId, int completedDays);
  Future<void> updateGamificationAfterAction(String userId, {
    bool eatenIncrement = false,
    int? currentDailyCalories,
    int? targetCalories,
    bool aiRecipeCreated = false,
    String? mealName,
    int? mealCalories,
  });
}

@LazySingleton(as: FirebaseDataSource)
class FirebaseDataSourceImpl implements FirebaseDataSource {
  FirebaseAuth get _auth => getIt<FirebaseAuth>();
  FirebaseFirestore get _firestore => getIt<FirebaseFirestore>();

  FirebaseDataSourceImpl();

  // ──────────────────────────────────────────────
  // AUTH
  // ──────────────────────────────────────────────

  @override
  Future<UserModel> login(
      {required String email, required String password}) async {
    print('[FirebaseDataSource] Bắt đầu đăng nhập cho email: $email');
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      print(
          '[FirebaseDataSource] Đăng nhập Auth thành công. UID: ${credential.user?.uid}');

      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      print(
          '[FirebaseDataSource] Đã truy vấn Firestore. Exists: ${userDoc.exists}');

      if (!userDoc.exists) {
        throw ServerException(
            'Không tìm thấy thông tin người dùng trong cơ sở dữ liệu.');
      }

      print('[FirebaseDataSource] Bắt đầu parse JSON người dùng...');
      final userModel = UserModel.fromJson(userDoc.data()!, userDoc.id);
      print(
          '[FirebaseDataSource] Parse JSON thành công. Vai trò: ${userModel.role}, Trạng thái: ${userModel.status}');

      if (userModel.status == 'banned') {
        await _auth.signOut();
        throw ServerException('Tài khoản của bạn đã bị khoá bởi Admin!');
      }
      return userModel;
    } on FirebaseAuthException catch (e, stack) {
      print(
          '[FirebaseDataSource] Lỗi FirebaseAuthException khi đăng nhập: [${e.code}] ${e.message}');
      print(stack);
      throw ServerException(
          '[${e.code}] ${e.message ?? 'Đăng nhập thất bại.'}');
    } on ServerException catch (e) {
      print(
          '[FirebaseDataSource] Lỗi ServerException khi đăng nhập: ${e.message}');
      rethrow;
    } catch (e, stack) {
      print('[FirebaseDataSource] Lỗi không xác định khi đăng nhập: $e');
      print(stack);
      throw ServerException('Lỗi hệ thống khi đăng nhập: $e');
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required UserProfileModel profile,
  }) async {
    print('[FirebaseDataSource] Bắt đầu đăng ký cho email: $email');
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      print(
          '[FirebaseDataSource] Đăng ký Auth thành công. UID: ${credential.user?.uid}');

      final newUser = UserModel(
        userId: credential.user!.uid,
        email: email.trim(),
        role: 'user',
        status: 'active',
        profile: profile,
        createdAt: DateTime.now(),
      );

      print('[FirebaseDataSource] Đang ghi dữ liệu user profile lên Firestore...');
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(newUser.toJson());
      print('[FirebaseDataSource] Ghi dữ liệu lên Firestore thành công!');

      // Seed default data for new user
      print('[FirebaseDataSource] Đang tạo dữ liệu mặc định cho người dùng mới...');
      await _seedDefaultData(credential.user!.uid);
      print('[FirebaseDataSource] Tạo dữ liệu mặc định thành công!');

      return newUser;
    } on FirebaseAuthException catch (e, stack) {
      print(
          '[FirebaseDataSource] Lỗi FirebaseAuthException khi đăng ký: [${e.code}] ${e.message}');
      print(stack);
      throw ServerException(
          '[${e.code}] ${e.message ?? 'Đăng ký tài khoản thất bại.'}');
    } catch (e, stack) {
      print('[FirebaseDataSource] Lỗi không xác định khi đăng ký: $e');
      print(stack);
      throw ServerException('Lỗi hệ thống khi đăng ký: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    final userDoc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (!userDoc.exists) return null;
    return UserModel.fromJson(userDoc.data()!, userDoc.id);
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw ServerException(
          e.message ?? 'Gửi liên kết khôi phục mật khẩu thất bại.');
    }
  }

  @override
  Future<void> updateUserProfile(
      String userId, UserProfileModel profile) async {
    await _firestore.collection('users').doc(userId).update({
      'profile': profile.toJson(),
    });
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> updateUserStatus(String userId, String status) async {
    await _firestore.collection('users').doc(userId).update({
      'status': status,
    });
  }

  // ──────────────────────────────────────────────
  // MEAL PLANS
  // ──────────────────────────────────────────────

  @override
  Future<MealPlanModel?> getMealPlan(String userId, String date) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meal_plans')
          .doc(date)
          .get();
      if (!doc.exists) return null;
      return MealPlanModel.fromJson(doc.data()!);
    } catch (e) {
      print('[FirebaseDataSource] Lỗi khi lấy meal plan: $e');
      return null;
    }
  }

  @override
  Future<void> saveMealPlan(String userId, MealPlanModel plan) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('meal_plans')
        .doc(plan.date)
        .set(plan.toJson());
  }

  @override
  Future<void> deleteMealPlan(String userId, String date) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('meal_plans')
        .doc(date)
        .delete();
  }

  @override
  Future<void> updateGroceryChecked(String userId, String date,
      String category, int index, bool checked) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('meal_plans')
        .doc(date)
        .get();
    if (!doc.exists) return;

    final plan = MealPlanModel.fromJson(doc.data()!);
    final updatedGrocery =
        Map<String, List<GroceryItemModel>>.from(plan.groceryList);

    if (updatedGrocery.containsKey(category) &&
        index < updatedGrocery[category]!.length) {
      final items = List<GroceryItemModel>.from(updatedGrocery[category]!);
      items[index] = items[index].copyWith(checked: checked);
      updatedGrocery[category] = items;

      final updatedPlan = MealPlanModel(
        date: plan.date,
        meals: plan.meals,
        groceryList: updatedGrocery,
      );
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('meal_plans')
          .doc(date)
          .set(updatedPlan.toJson());
    }
  }

  // ──────────────────────────────────────────────
  // GAMIFICATION
  // ──────────────────────────────────────────────

  @override
  Future<UserStatsModel> getUserStats(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_stats')
          .doc('current')
          .get();
      if (!doc.exists) {
        // Create default stats if not exist
        final defaultStats = UserStatsModel.initial();
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('user_stats')
            .doc('current')
            .set(defaultStats.toJson());
        return defaultStats;
      }
      return UserStatsModel.fromJson(doc.data()!);
    } catch (e) {
      print('[FirebaseDataSource] Lỗi khi lấy user stats: $e');
      return UserStatsModel.initial();
    }
  }

  @override
   Future<void> updateUserStats(String userId, UserStatsModel stats) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('user_stats')
        .doc('current')
        .set(stats.toJson());
  }

  String _getDayLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
      default:
        return 'CN';
    }
  }

  Future<void> _checkAndUnlockAiChefBadge(String userId, int count) async {
    if (count >= 5) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc('ai_chef_king')
          .update({
        'is_locked': false,
        'unlocked_at': Timestamp.now(),
      });
    }
  }

  Future<void> _unlockBadge(String userId, String badgeId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(badgeId);
      final doc = await docRef.get();
      if (doc.exists) {
        final isLocked = doc.data()?['is_locked'] as bool? ?? true;
        if (isLocked) {
          await docRef.update({
            'is_locked': false,
            'unlocked_at': Timestamp.now(),
          });
        }
      }
    } catch (e) {
      print('[FirebaseDataSource] Lỗi unlock badge $badgeId: $e');
    }
  }

  @override
  Future<void> updateGamificationAfterAction(String userId, {
    bool eatenIncrement = false,
    int? currentDailyCalories,
    int? targetCalories,
    bool aiRecipeCreated = false,
    String? mealName,
    int? mealCalories,
  }) async {
    try {
      var stats = await getUserStats(userId);
      int currentXp = stats.xp;
      int currentLevel = stats.level;
      int currentStreak = stats.streak;
      final Map<String, bool> currentStreakDays = Map<String, bool>.from(stats.streakDays);
      DateTime? lastActive = stats.lastActiveDate;
      int aiCount = stats.aiRecipesCreatedCount;
      int fatCount = stats.fatDestroyerCount;
      int veggieCount = stats.veggieChampionCount;
      int proteinCount = stats.proteinBeastCount;
      int carbCount = stats.carbCleanerCount;

      final now = DateTime.now();

      // Kiểm tra xem có cần reset streak không (chu kỳ 24 tiếng - hàng ngày)
      if (lastActive != null) {
        final lastActiveDateOnly = DateTime(lastActive.year, lastActive.month, lastActive.day);
        final todayDateOnly = DateTime(now.year, now.month, now.day);
        final diffDays = todayDateOnly.difference(lastActiveDateOnly).inDays;

        if (diffDays >= 1) {
          final yesterdayLabel = _getDayLabel(now.subtract(const Duration(days: 1)));
          final wasYesterdayReached = currentStreakDays[yesterdayLabel] ?? false;

          // Nếu bỏ lỡ từ 2 ngày trở lên hoặc hôm qua không đạt mục tiêu calo, reset streak về 0
          if (diffDays >= 2 || !wasYesterdayReached) {
            currentStreak = 0;
            currentStreakDays.forEach((key, value) {
              currentStreakDays[key] = false;
            });
          }
        }
      }

      // 1. Cộng XP khi bấm đã ăn và đếm thể loại món ăn
      if (eatenIncrement) {
        currentXp += 50;

        if (mealName != null) {
          final nameLower = mealName.toLowerCase();

          // Kẻ hủy diệt mỡ thừa (calo <= 400 và có gà/cá hồi/salad/rau)
          if ((mealCalories != null && mealCalories <= 400) &&
              (nameLower.contains('ức gà') || nameLower.contains('cá hồi') || nameLower.contains('salad') || nameLower.contains('súp lơ') || nameLower.contains('chay') || nameLower.contains('rau'))) {
            fatCount += 1;
            if (fatCount >= 3) {
              await _unlockBadge(userId, 'fat_destroyer');
            }
          }

          // Chiến thần ăn chay
          if (nameLower.contains('chay') || nameLower.contains('đậu hũ') || nameLower.contains('rau củ') || nameLower.contains('salad') || nameLower.contains('quinoa')) {
            veggieCount += 1;
            if (veggieCount >= 3) {
              await _unlockBadge(userId, 'veggie_champion');
            }
          }

          // Chiến thần cơ bắp
          if ((mealCalories != null && mealCalories >= 500) ||
              nameLower.contains('bò') || nameLower.contains('ức gà') || nameLower.contains('cá hồi') || nameLower.contains('trứng') || nameLower.contains('đùi gà')) {
            proteinCount += 1;
            if (proteinCount >= 3) {
              await _unlockBadge(userId, 'protein_beast');
            }
          }

          // Khắc tinh đường bột
          if (nameLower.contains('gạo lứt') || nameLower.contains('yến mạch') || nameLower.contains('khoai lang') || nameLower.contains('quinoa')) {
            carbCount += 1;
            if (carbCount >= 3) {
              await _unlockBadge(userId, 'carb_cleaner');
            }
          }
        }
      }

      // 2. Cộng XP và đếm số lần tạo công thức AI
      if (aiRecipeCreated) {
        currentXp += 20;
        aiCount += 1;
        await _checkAndUnlockAiChefBadge(userId, aiCount);
      }

      // 3. Kiểm tra calo nạp của ngày hôm nay
      final todayLabel = _getDayLabel(now);
      if (currentDailyCalories != null && targetCalories != null && targetCalories > 0) {
        final double percentage = currentDailyCalories / targetCalories;
        final bool reachedGoal = percentage >= 0.8 && percentage <= 1.05;
        final bool wasAlreadyReached = currentStreakDays[todayLabel] ?? false;

        if (reachedGoal && !wasAlreadyReached) {
          currentStreakDays[todayLabel] = true;
          currentStreak += 1;
          currentXp += 50; // Thưởng 50 XP
        } else if (!reachedGoal && wasAlreadyReached) {
          currentStreakDays[todayLabel] = false;
          currentStreak = (currentStreak - 1).clamp(0, 9999);
          currentXp = (currentXp - 50).clamp(0, 99999);
        }
      }

      // 4. Lên cấp
      int xpNeeded = 200 * currentLevel;
      while (currentXp >= xpNeeded) {
        currentXp -= xpNeeded;
        currentLevel += 1;
        xpNeeded = 200 * currentLevel;
      }

      String levelTitle = 'Tân binh dinh dưỡng';
      if (currentLevel >= 2 && currentLevel < 4) {
        levelTitle = 'Chiến binh ăn sạch';
      } else if (currentLevel >= 4 && currentLevel < 7) {
        levelTitle = 'Bậc thầy calo';
      } else if (currentLevel >= 7) {
        levelTitle = 'Huyền thoại dinh dưỡng';
      }

      final updatedStats = UserStatsModel(
        streak: currentStreak,
        streakDays: currentStreakDays,
        xp: currentXp,
        level: currentLevel,
        levelTitle: levelTitle,
        xpToNextLevel: xpNeeded,
        lastActiveDate: now,
        aiRecipesCreatedCount: aiCount,
        fatDestroyerCount: fatCount,
        veggieChampionCount: veggieCount,
        proteinBeastCount: proteinCount,
        carbCleanerCount: carbCount,
      );

      await updateUserStats(userId, updatedStats);
    } catch (e) {
      print('[FirebaseDataSource] Lỗi cập nhật gamification: $e');
    }
  }

  @override
  Future<List<BadgeModel>> getBadges(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .get();

      final currentBadges = snapshot.docs
          .map((doc) => BadgeModel.fromJson(doc.data(), doc.id))
          .toList();

      final defaultBadges = [
        const BadgeModel(
          id: 'fat_destroyer',
          title: 'Kẻ hủy diệt mỡ thừa',
          description: 'Đạt được khi ăn 3 món ít béo & ít calo (ức gà, cá hồi áp chảo, salad quinoa).',
          icon: 'fitness_center',
          color: 'amber',
          isLocked: true,
        ),
        const BadgeModel(
          id: 'veggie_champion',
          title: 'Chiến thần ăn chay',
          description: 'Đạt được khi ăn 3 món chay thuần thực vật lành mạnh (bún chả chay, đậu hũ).',
          icon: 'eco',
          color: 'green',
          isLocked: true,
        ),
        const BadgeModel(
          id: 'ai_chef_king',
          title: 'Vua đầu bếp AI',
          description: 'Đạt được khi sáng tạo thực đơn hoặc công thức bằng AI đủ 5 lần.',
          icon: 'emoji_events',
          color: 'amber',
          isLocked: true,
        ),
        const BadgeModel(
          id: 'hydration_master',
          title: 'Thủy thần cấp cao',
          description: 'Đạt được khi hoàn thành thử thách uống nước đủ 2L trong 3 ngày.',
          icon: 'water_drop',
          color: 'blue',
          isLocked: true,
        ),
        const BadgeModel(
          id: 'protein_beast',
          title: 'Chiến thần cơ bắp',
          description: 'Đạt được khi ăn 3 món ăn giàu đạm protein (thịt bò, cá hồi, trứng).',
          icon: 'bolt',
          color: 'red',
          isLocked: true,
        ),
        const BadgeModel(
          id: 'carb_cleaner',
          title: 'Khắc tinh đường bột',
          description: 'Đạt được khi ăn 3 món chứa tinh bột chậm tốt cho sức khỏe (gạo lứt, yến mạch).',
          icon: 'grain',
          color: 'orange',
          isLocked: true,
        ),
      ];

      final Map<String, BadgeModel> currentMap = {for (var b in currentBadges) b.id: b};
      final List<BadgeModel> mergedBadges = [];

      for (final defBadge in defaultBadges) {
        if (!currentMap.containsKey(defBadge.id)) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('badges')
              .doc(defBadge.id)
              .set(defBadge.toJson());
          mergedBadges.add(defBadge);
        } else {
          mergedBadges.add(currentMap[defBadge.id]!);
        }
      }

      return mergedBadges;
    } catch (e) {
      print('[FirebaseDataSource] Lỗi khi lấy badges: $e');
      return [];
    }
  }

  @override
  Future<List<ChallengeModel>> getChallenges(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .get();
      if (snapshot.docs.isEmpty) {
        // Seed default challenges
        await _seedDefaultChallenges(userId);
        final newSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('challenges')
            .get();
        return newSnapshot.docs
            .map((doc) => ChallengeModel.fromJson(doc.data(), doc.id))
            .toList();
      }
      return snapshot.docs
          .map((doc) => ChallengeModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('[FirebaseDataSource] Lỗi khi lấy challenges: $e');
      return [];
    }
  }

  @override
  Future<void> updateChallengeProgress(
      String userId, String challengeId, int completedDays) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .doc(challengeId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final challenge = ChallengeModel.fromJson(doc.data()!, doc.id);
    final isCompleted = completedDays >= challenge.targetDays;

    await docRef.update({
      'completed_days': completedDays,
      'is_completed': isCompleted,
    });
  }

  // ──────────────────────────────────────────────
  // SEED DEFAULT DATA (called on registration)
  // ──────────────────────────────────────────────

  Future<void> _seedDefaultData(String userId) async {
    await Future.wait([
      _seedDefaultStats(userId),
      _seedDefaultBadges(userId),
      _seedDefaultChallenges(userId),
      _seedDefaultMealPlan(userId),
    ]);
  }

  Future<void> _seedDefaultStats(String userId) async {
    final stats = UserStatsModel.initial();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('user_stats')
        .doc('current')
        .set(stats.toJson());
  }

  Future<void> _seedDefaultBadges(String userId) async {
    final badges = [
      const BadgeModel(
        id: 'fat_destroyer',
        title: 'Kẻ hủy diệt mỡ thừa',
        description: 'Đạt được khi ăn 3 món ít béo & ít calo (ức gà, cá hồi áp chảo, salad quinoa).',
        icon: 'fitness_center',
        color: 'amber',
        isLocked: true,
      ),
      const BadgeModel(
        id: 'veggie_champion',
        title: 'Chiến thần ăn chay',
        description: 'Đạt được khi ăn 3 món chay thuần thực vật lành mạnh (bún chả chay, đậu hũ).',
        icon: 'eco',
        color: 'green',
        isLocked: true,
      ),
      const BadgeModel(
        id: 'ai_chef_king',
        title: 'Vua đầu bếp AI',
        description: 'Đạt được khi sáng tạo thực đơn hoặc công thức bằng AI đủ 5 lần.',
        icon: 'emoji_events',
        color: 'amber',
        isLocked: true,
      ),
      const BadgeModel(
        id: 'hydration_master',
        title: 'Thủy thần cấp cao',
        description: 'Đạt được khi hoàn thành thử thách uống nước đủ 2L trong 3 ngày.',
        icon: 'water_drop',
        color: 'blue',
        isLocked: true,
      ),
      const BadgeModel(
        id: 'protein_beast',
        title: 'Chiến thần cơ bắp',
        description: 'Đạt được khi ăn 3 món ăn giàu đạm protein (thịt bò, cá hồi, trứng).',
        icon: 'bolt',
        color: 'red',
        isLocked: true,
      ),
      const BadgeModel(
        id: 'carb_cleaner',
        title: 'Khắc tinh đường bột',
        description: 'Đạt được khi ăn 3 món chứa tinh bột chậm tốt cho sức khỏe (gạo lứt, yến mạch).',
        icon: 'grain',
        color: 'orange',
        isLocked: true,
      ),
    ];

    for (final badge in badges) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(badge.id)
          .set(badge.toJson());
    }
  }

  Future<void> _seedDefaultChallenges(String userId) async {
    // Get Monday of current week
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekOf =
        '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';

    final challenges = [
      ChallengeModel(
        id: 'veggie_warrior',
        title: 'Chiến thần ăn rau',
        description:
            'Ăn ít nhất 300g rau xanh mỗi ngày trong 5 ngày liên tục.',
        targetDays: 5,
        completedDays: 0,
        isCompleted: false,
        weekOf: weekOf,
      ),
      ChallengeModel(
        id: 'sugar_cut',
        title: 'Cắt giảm đường tinh luyện',
        description:
            'Không sử dụng đường ngọt nhân tạo hoặc đồ uống có ga trong 3 ngày.',
        targetDays: 3,
        completedDays: 0,
        isCompleted: false,
        weekOf: weekOf,
      ),
    ];

    for (final challenge in challenges) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .doc(challenge.id)
          .set(challenge.toJson());
    }
  }

  Future<void> _seedDefaultMealPlan(String userId) async {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final plan = MealPlanModel(
      date: date,
      meals: const [
        MealItemModel(
          type: 'Bữa sáng',
          name: 'Yogurt Ngũ Cốc & Dâu Tây',
          calories: 320,
          imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAkzipEN3kijSUY-nDHK4unrmivQxZvy57nI9E_B8TNKt534Pa37gftli1FhHxpzTslfJSVqAOy5Z1OpZW1oNV2G2EU5DNNP8siZfZCj2rXV8L3JfXhMR2LndUUNFQ6Kt9btmUIUp63sy3vVi__FudPNWrL2A8mKo6mx6NJZCpkcv_-O6hc1g33Wmnaju77wofbaS0pDu-lkjPoIkbwKb-uEX4Ik3HDevAIyu_ZN3Mr4Vd7xzbdKo3aYAIkD_trywoFbnNA2jCT81wm',
          swaps: [
            'Smoothie Bơ Chuối',
            'Cháo Yến Mạch Táo Red',
            'Trứng Cuộn Phô Mai'
          ],
          instructions: [
            'Chuẩn bị sữa chua không đường ra bát',
            'Rắc ngũ cốc hạt granola lên trên',
            'Thêm dâu tây tươi cắt lát',
            'Trộn đều và thưởng thức'
          ],
        ),
        MealItemModel(
          type: 'Bữa trưa',
          name: 'Salad Cá Hồi & Quinoa',
          calories: 450,
          imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAmmNPERLqbON4YGo0biZL9HlBCir5lc6oBqL3AGybhkRl_oFrea6wxVzt-dN-nPJT8cz93eKK4e5cjPUIJ9Rvw4wc6duQN7vwKq1mmMMZTgP65Zt0DlMNKa_btpKkw6_iabjUyJlzJLIyyc84go7gcS7BAjGyWSIM_BA3u6s9zI4-fPtXONk357p02fWsKihFzxxH2pbVnPMTB248rEV4S-WHFs36mGrpCWBKi8f0onewAg6okrtRXXmIZtcW-KLRhwjMznufrdUVW',
          swaps: [
            'Ức Gà Nướng Mật Ong',
            'Bún Chả Đậu Hũ Chay',
            'Cơm Gạo Lứt Thịt Bò'
          ],
          instructions: [
            'Rửa sạch hạt quinoa và nấu chín',
            'Áp chảo cá hồi chín đều hai mặt',
            'Trộn quinoa, rau xanh và sốt dầu olive',
            'Đặt cá hồi lên trên và thưởng thức'
          ],
        ),
        MealItemModel(
          type: 'Bữa tối',
          name: 'Ức Gà Nướng Rau Củ',
          calories: 380,
          imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuDhoTMviIOaClnee2gR1QrQz_257Xd1tA20K0RRo23SG42egT98N8BCK4W-gCpfiOoJkqBG_-PpdDZcdQz1aXc01ZqlE6rRgFjVPhr6MnCyqvFzZ5jQHxK8n_9VIbVk8arVGFu6TqlWC7X9GOXVYBMpKNkRuQMk9EfWTaWJYYGWbnUgcOwsXD4eEthHE3msFomTnkoy0reAM6Tu-LjeZ6jLqqnwDfnAGCWyW4s0p1NSo-__q3UMpKeBm3OpF6XDPKTB9YBhsEF_Dygv',
          swaps: [
            'Cá Tuyết Hấp Tàu Xì',
            'Canh Chua Đậu Hũ',
            'Súp Bí Đỏ Thịt Bằm'
          ],
          instructions: [
            'Thái ức gà thành miếng vừa ăn, ướp gia vị',
            'Cắt nhỏ bông cải xanh, cà rốt, ớt chuông',
            'Nướng gà và rau củ ở 180 độ trong 15 phút',
            'Trình bày ra đĩa và dùng nóng'
          ],
        ),
      ],
      groceryList: const {
        'Rau củ quả 🥦': [
          GroceryItemModel(name: 'Súp lơ xanh', qty: '500g', checked: false),
          GroceryItemModel(name: 'Cà chua bi', qty: '1 hộp', checked: false),
          GroceryItemModel(name: 'Quả bơ', qty: '2 quả', checked: false),
        ],
        'Thịt & Hải sản 🥩': [
          GroceryItemModel(
              name: 'Cá hồi phi lê', qty: '300g', checked: false),
          GroceryItemModel(name: 'Ức gà tươi', qty: '400g', checked: false),
        ],
        'Gia vị & Khác 🧂': [
          GroceryItemModel(name: 'Hạt Quinoa', qty: '1 túi', checked: false),
          GroceryItemModel(
              name: 'Sữa chua không đường', qty: '4 hộp', checked: false),
        ],
      },
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('meal_plans')
        .doc(date)
        .set(plan.toJson());
  }
}
