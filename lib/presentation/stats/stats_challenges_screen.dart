import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_bloc.dart';
import '../../data/datasources/firebase_datasource.dart';
import '../../data/models/gamification_models.dart';
import '../../core/di/injection.dart';

class StatsChallengesScreen extends StatefulWidget {
  const StatsChallengesScreen({super.key});

  @override
  State<StatsChallengesScreen> createState() => _StatsChallengesScreenState();
}

class _StatsChallengesScreenState extends State<StatsChallengesScreen> {
  UserStatsModel? _stats;
  List<BadgeModel> _badges = [];
  List<ChallengeModel> _challenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String? _getUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedUser) return authState.user.userId;
    if (authState is AuthenticatedAdmin) return authState.user.userId;
    return null;
  }

  Future<void> _loadData() async {
    final userId = _getUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final ds = getIt<FirebaseDataSource>();
    final results = await Future.wait([
      ds.getUserStats(userId),
      ds.getBadges(userId),
      ds.getChallenges(userId),
    ]);

    if (mounted) {
      setState(() {
        _stats = results[0] as UserStatsModel;
        _badges = results[1] as List<BadgeModel>;
        _challenges = results[2] as List<ChallengeModel>;
        _isLoading = false;
      });
    }
  }

  // Map icon string to IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'eco':
        return Icons.eco;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'water_drop':
        return Icons.water_drop;
      case 'bolt':
        return Icons.bolt;
      case 'grain':
        return Icons.grain;
      default:
        return Icons.emoji_events;
    }
  }

  // Map color string to Color
  Color _getColor(String colorName) {
    switch (colorName) {
      case 'amber':
        return Colors.amber;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }  void _showHelpBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 24, left: 24, right: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.help_outline, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    Localizations.localeOf(context).languageCode == 'vi' ? 'Hướng dẫn Cơ chế Thách thức' : 'Challenges & Achievements Guide',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildGuideItem(
                context,
                icon: Icons.local_fire_department,
                iconColor: Colors.orange,
                title: Localizations.localeOf(context).languageCode == 'vi' ? 'Chuỗi ăn sạch (Streak) 🔥' : 'Clean Eating Streak 🔥',
                desc: Localizations.localeOf(context).languageCode == 'vi' 
                    ? 'Được ghi nhận khi bạn nạp lượng calo đạt từ 80% - 105% lượng calo mục tiêu trong ngày. Quá 24h không ghi nhận hoạt động ăn uống đạt mục tiêu calo, chuỗi Streak sẽ tự động reset về 0.'
                    : 'Recorded when you consume 80% - 105% of your target calories for the day. Streak resets to 0 if there is no activity for 24 hours.',
              ),
              const SizedBox(height: 16),
              _buildGuideItem(
                context,
                icon: Icons.star_border,
                iconColor: Colors.purple,
                title: Localizations.localeOf(context).languageCode == 'vi' ? 'Hệ thống XP & Cấp độ ⭐' : 'XP & Levels System ⭐',
                desc: Localizations.localeOf(context).languageCode == 'vi'
                    ? '• Tick ăn món ăn: +50 XP / bữa.\n• Đạt mục tiêu calo ngày: +50 XP.\n• Sáng tạo công thức AI: +20 XP.\nTích lũy đủ XP để nâng cấp Level và nhận danh hiệu mới!'
                    : '• Mark meal eaten: +50 XP / meal.\n• Meet daily calorie target: +50 XP.\n• Generate AI recipe: +20 XP.\nAccumulate XP to level up and earn new titles!',
              ),
              const SizedBox(height: 16),
              _buildGuideItem(
                context,
                icon: Icons.emoji_events_outlined,
                iconColor: Colors.amber,
                title: Localizations.localeOf(context).languageCode == 'vi' ? 'Huy hiệu & Thử thách 🏆' : 'Badges & Challenges 🏆',
                desc: Localizations.localeOf(context).languageCode == 'vi'
                    ? 'Hoàn thành các cột mốc đặc biệt để nhận huy hiệu độc quyền. Ví dụ: Dùng AI sáng tạo món ăn đủ 5 lần để mở khóa huy hiệu "Vua đầu bếp AI".'
                    : 'Complete special milestones to receive exclusive badges. E.g., Use AI to create dishes 5 times to unlock the "AI Head Chef" badge.',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'ĐÃ HIỂU' : 'UNDERSTOOD', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuideItem(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withValues(alpha: 0.15),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Thách thức & Thành tích' : 'Challenges & Achievements',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHelpBottomSheet,
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final stats = _stats ?? UserStatsModel.initial();

    return Scaffold(
      appBar: AppBar(
        title: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Thách thức & Thành tích' : 'Challenges & Achievements',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpBottomSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // --- Streak Card Section ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainer
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Localizations.localeOf(context).languageCode == 'vi' ? '${stats.streak} Ngày Ăn Sạch 🔥' : '${stats.streak}-Day Clean Eating 🔥',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stats.streak > 0
                        ? (Localizations.localeOf(context).languageCode == 'vi' 
                            ? '🔥 Bạn đã duy trì chuỗi ${stats.streak} ngày ăn sạch! Hãy tiếp tục nạp calo đạt mục tiêu hôm nay để bảo vệ chuỗi Streak, tránh bị reset sau 24h.' 
                            : '🔥 You have kept a ${stats.streak}-day streak! Eat within 80%-105% of your target today to protect your streak from resetting after 24h.')
                        : (Localizations.localeOf(context).languageCode == 'vi' 
                            ? 'Hãy đạt lượng calo từ 80% - 105% mục tiêu ngày hôm nay để kích hoạt chuỗi Streak ăn sạch đầu tiên của bạn!' 
                            : 'Reach 80% - 105% of your target calories today to start your first clean eating streak!'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: stats.streak > 0 ? Colors.orange[800] : Colors.grey[600],
                      fontSize: 13,
                      fontWeight: stats.streak > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Weekly streak dot tracker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map((dayKey) {
                      final hasStreak = stats.streakDays[dayKey] ?? false;
                      final isVi = Localizations.localeOf(context).languageCode == 'vi';
                      var displayDay = dayKey;
                      if (!isVi) {
                        final mapping = {
                          'T2': 'Mon',
                          'T3': 'Tue',
                          'T4': 'Wed',
                          'T5': 'Thu',
                          'T6': 'Fri',
                          'T7': 'Sat',
                          'CN': 'Sun',
                        };
                        displayDay = mapping[dayKey] ?? dayKey;
                      }
                      final isCurrent = dayKey == _getCurrentDayLabelViOnly();
                      return _buildStreakDot(
                          displayDay, hasStreak, isCurrent: isCurrent);
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Level & XP Section ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainer
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Localizations.localeOf(context).languageCode == 'vi' ? 'TIẾN TRÌNH' : 'PROGRESS',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Level ${stats.level} - ${Localizations.localeOf(context).languageCode == 'vi' ? stats.levelTitle : (stats.levelTitle == 'Thành viên mới' ? 'New Member' : (stats.levelTitle == 'Người ăn sạch' ? 'Clean Eater' : (stats.levelTitle == 'Chuyên gia dinh dưỡng' ? 'Nutrition Expert' : stats.levelTitle)))}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${stats.xp}/${stats.xpToNextLevel} XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: stats.xpToNextLevel > 0
                          ? (stats.xp / stats.xpToNextLevel)
                              .clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 12,
                      backgroundColor:
                          isDark ? Colors.grey[800] : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primaryContainer),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info,
                            color: theme.colorScheme.secondary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            stats.xpToNextLevel - stats.xp > 0
                                ? (Localizations.localeOf(context).languageCode == 'vi' ? 'Chỉ còn ${stats.xpToNextLevel - stats.xp} XP nữa để lên level tiếp theo!' : 'Only ${stats.xpToNextLevel - stats.xp} XP left to level up!')
                                : (Localizations.localeOf(context).languageCode == 'vi' ? 'Bạn đã đạt level tối đa hiện tại! 🎉' : 'You have reached the maximum level! 🎉'),
                            style: const TextStyle(
                                fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // --- Badges Shelf ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Localizations.localeOf(context).languageCode == 'vi' ? 'Huy hiệu của bạn' : 'Your Badges',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: _showAllBadgesBottomSheet,
                  child: Text(
                    Localizations.localeOf(context).languageCode == 'vi' ? 'Xem tất cả' : 'See all',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _badges.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Chưa có huy hiệu nào.' : 'No badges yet.',
                          style: const TextStyle(color: Colors.grey)),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _badges.take(4).length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemBuilder: (ctx, idx) {
                      final badge = _badges[idx];
                      final prog = _getBadgeProgress(stats, badge);
                      final color = _getColor(badge.color);
                      return GestureDetector(
                        onTap: () => _showBadgeDetail(context, badge),
                        child: _buildBadgeCardExtended(
                          context,
                          _getBadgeTitle(badge.title),
                          badge.isLocked,
                          _getIconData(badge.icon),
                          color,
                          progress: prog['progress']!,
                          progressText: '${prog['current']!.toInt()}/${prog['target']!.toInt()}',
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getCurrentDayLabelViOnly() {
    final weekday = DateTime.now().weekday;
    const labels = {
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      7: 'CN',
    };
    return labels[weekday] ?? 'T2';
  }

  String _getBadgeTitle(String key) {
    if (Localizations.localeOf(context).languageCode == 'vi') return key;
    final map = {
      'Vua đầu bếp AI': 'AI Chef King',
      'Người ăn sạch': 'Clean Eater',
      'Chiến binh Streak': 'Streak Warrior',
      'Kẻ hủy diệt Calo': 'Calo Destroyer',
      'Sứ giả xanh': 'Green Messenger',
      'Kẻ hủy diệt mỡ thừa': 'Fat Destroyer',
      'Chiến thần ăn chay': 'Veggie Champion',
      'Thủy thần cấp cao': 'Hydration Master',
      'Chiến thần cơ bắp': 'Protein Beast',
      'Khắc tinh đường bột': 'Carb Cleaner',
    };
    return map[key] ?? key;
  }

  Widget _buildStreakDot(String day, bool completed,
      {bool isCurrent = false}) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 6,
          decoration: BoxDecoration(
            color: completed ? Colors.teal : Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
            border: isCurrent
                ? Border.all(color: Colors.orange, width: 1.5)
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? Colors.teal : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showBadgeDetail(BuildContext context, BadgeModel badge) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _getColor(badge.color);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: badge.isLocked ? Colors.grey[200] : color.withValues(alpha: 0.15),
              child: Icon(
                badge.isLocked ? Icons.lock : _getIconData(badge.icon),
                color: badge.isLocked ? Colors.grey[600] : color,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getBadgeTitle(badge.title),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: badge.isLocked ? Colors.grey[200] : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge.isLocked
                    ? (Localizations.localeOf(context).languageCode == 'vi' ? 'CHƯA MỞ KHÓA' : 'LOCKED')
                    : (Localizations.localeOf(context).languageCode == 'vi' ? 'ĐÃ MỞ KHÓA' : 'UNLOCKED'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badge.isLocked ? Colors.grey[600] : color,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.description.isNotEmpty 
                  ? badge.description 
                  : (Localizations.localeOf(context).languageCode == 'vi' 
                      ? 'Hoàn thành các cột mốc dinh dưỡng lành mạnh để mở khóa.' 
                      : 'Complete healthy nutrition milestones to unlock.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  Localizations.localeOf(context).languageCode == 'vi' ? 'Đóng' : 'Close',
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _getBadgeProgress(UserStatsModel stats, BadgeModel badge) {
    int current = 0;
    int target = 3;
    switch (badge.id) {
      case 'fat_destroyer':
        current = stats.fatDestroyerCount;
        target = 3;
        break;
      case 'veggie_champion':
        current = stats.veggieChampionCount;
        target = 3;
        break;
      case 'ai_chef_king':
        current = stats.aiRecipesCreatedCount;
        target = 5;
        break;
      case 'protein_beast':
        current = stats.proteinBeastCount;
        target = 3;
        break;
      case 'carb_cleaner':
        current = stats.carbCleanerCount;
        target = 3;
        break;
      case 'hydration_master':
        current = 0;
        target = 3;
        final hydrationChallenge = _challenges.firstWhere(
          (c) => c.id == 'hydration_master' || c.title.contains('nước') || c.title.contains('Hydrated'),
          orElse: () => const ChallengeModel(id: '', title: '', description: '', targetDays: 3, completedDays: 0, isCompleted: false, weekOf: ''),
        );
        current = hydrationChallenge.completedDays;
        target = hydrationChallenge.targetDays;
        break;
      default:
        current = 0;
        target = 3;
    }
    current = current.clamp(0, target);
    return {
      'current': current.toDouble(),
      'target': target.toDouble(),
      'progress': target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0,
    };
  }

  void _showAllBadgesBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stats = _stats ?? UserStatsModel.initial();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String activeFilter = 'all';

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final filteredBadges = _badges.where((badge) {
              final prog = _getBadgeProgress(stats, badge);
              final isUnlocked = !badge.isLocked;
              final isInProgress = badge.isLocked && prog['current']! > 0;
              final isNotStarted = badge.isLocked && prog['current']! == 0;

              if (activeFilter == 'unlocked') return isUnlocked;
              if (activeFilter == 'in_progress') return isInProgress;
              if (activeFilter == 'locked') return isNotStarted;
              return true;
            }).toList();

            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.only(top: 8, bottom: 24, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Localizations.localeOf(sheetContext).languageCode == 'vi'
                            ? 'Hệ thống Huy hiệu'
                            : 'All Badges System',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetContext),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: Localizations.localeOf(sheetContext).languageCode == 'vi' ? 'Tất cả' : 'All',
                          isActive: activeFilter == 'all',
                          count: _badges.length,
                          onTap: () => setSheetState(() => activeFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: Localizations.localeOf(sheetContext).languageCode == 'vi' ? 'Đã đạt' : 'Unlocked',
                          isActive: activeFilter == 'unlocked',
                          count: _badges.where((b) => !b.isLocked).length,
                          onTap: () => setSheetState(() => activeFilter == 'unlocked'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: Localizations.localeOf(sheetContext).languageCode == 'vi' ? 'Đang làm' : 'In Progress',
                          isActive: activeFilter == 'in_progress',
                          count: _badges.where((b) {
                            final prog = _getBadgeProgress(stats, b);
                            return b.isLocked && prog['current']! > 0;
                          }).length,
                          onTap: () => setSheetState(() => activeFilter == 'in_progress'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: Localizations.localeOf(sheetContext).languageCode == 'vi' ? 'Chưa đạt' : 'Locked',
                          isActive: activeFilter == 'locked',
                          count: _badges.where((b) {
                            final prog = _getBadgeProgress(stats, b);
                            return b.isLocked && prog['current']! == 0;
                          }).length,
                          onTap: () => setSheetState(() => activeFilter == 'locked'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: filteredBadges.isEmpty
                        ? Center(
                            child: Text(
                              Localizations.localeOf(sheetContext).languageCode == 'vi'
                                  ? 'Không có huy hiệu nào khớp bộ lọc.'
                                  : 'No badges match the filter.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : GridView.builder(
                            itemCount: filteredBadges.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.15,
                            ),
                            itemBuilder: (ctx, idx) {
                              final badge = filteredBadges[idx];
                              final prog = _getBadgeProgress(stats, badge);
                              final color = _getColor(badge.color);
                              
                              return GestureDetector(
                                onTap: () => _showBadgeDetail(sheetContext, badge),
                                child: _buildBadgeCardExtended(
                                  sheetContext,
                                  _getBadgeTitle(badge.title),
                                  badge.isLocked,
                                  _getIconData(badge.icon),
                                  color,
                                  progress: prog['progress']!,
                                  progressText: '${prog['current']!.toInt()}/${prog['target']!.toInt()}',
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required int count,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return FilterChip(
      selected: isActive,
      label: Text('$label ($count)'),
      labelStyle: TextStyle(
        color: isActive ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
      onSelected: (_) => onTap(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }

  Widget _buildBadgeCardExtended(
    BuildContext context,
    String title,
    bool isLocked,
    IconData icon,
    Color color, {
    required double progress,
    required String progressText,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasStarted = progress > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked
              ? (hasStarted
                  ? Colors.orange.withValues(alpha: 0.4)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.2))
              : color.withValues(alpha: 0.4),
          width: isLocked ? 1.0 : 1.5,
        ),
        boxShadow: isLocked
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isLocked
                    ? (hasStarted ? Colors.orange.withValues(alpha: 0.1) : Colors.grey[200])
                    : color.withValues(alpha: 0.15),
                child: Icon(
                  isLocked ? (hasStarted ? icon : Icons.lock_outline) : icon,
                  color: isLocked ? (hasStarted ? Colors.orange : Colors.grey[600]) : color,
                  size: 16,
                ),
              ),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasStarted ? Colors.orange.withValues(alpha: 0.15) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    progressText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: hasStarted ? Colors.orange[800] : Colors.grey[600],
                    ),
                  ),
                )
              else
                Icon(Icons.check_circle, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isLocked && !hasStarted ? Colors.grey[600] : null,
            ),
          ),
          const SizedBox(height: 8),
          if (isLocked)
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                valueColor: AlwaysStoppedAnimation<Color>(
                  hasStarted ? Colors.orange : Colors.grey[400]!,
                ),
              ),
            )
          else
            Text(
              Localizations.localeOf(context).languageCode == 'vi' ? 'Đã đạt được 🎉' : 'Unlocked 🎉',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}
