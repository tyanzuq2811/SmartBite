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
                    ? 'Được ghi nhận khi bạn nạp lượng calo đạt từ 80% - 105% lượng calo mục tiêu trong ngày. Quá 48h không ghi nhận hoạt động ăn uống, chuỗi Streak sẽ tự động reset về 0.'
                    : 'Recorded when you consume 80% - 105% of your target calories for the day. Streak resets to 0 if there is no activity for 48 hours.',
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
                            ? '🔥 Bạn đã duy trì chuỗi ${stats.streak} ngày ăn sạch! Hãy tiếp tục nạp calo đạt mục tiêu hôm nay để bảo vệ chuỗi Streak, tránh bị reset sau 48h.' 
                            : '🔥 You have kept a ${stats.streak}-day streak! Eat within 80%-105% of your target today to protect your streak from resetting after 48h.')
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
                Text(
                  Localizations.localeOf(context).languageCode == 'vi' ? 'Xem tất cả' : 'See all',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: _badges.map((badge) {
                      final color = _getColor(badge.color);
                      return GestureDetector(
                        onTap: () => _showBadgeDetail(context, badge),
                        child: _buildBadgeCard(
                          context,
                          _getBadgeTitle(badge.title),
                          badge.isLocked 
                              ? (Localizations.localeOf(context).languageCode == 'vi' ? 'Chưa mở' : 'Locked') 
                              : (Localizations.localeOf(context).languageCode == 'vi' ? 'Đã mở khóa' : 'Unlocked'),
                          _getIconData(badge.icon),
                          badge.isLocked ? Colors.grey : color,
                          isLocked: badge.isLocked,
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 28),

            // --- Thách thức tuần này ---
            Text(
              Localizations.localeOf(context).languageCode == 'vi' ? 'Thách thức tuần này' : 'Weekly Challenges',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _challenges.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Chưa có thách thức nào cho tuần này.' : 'No challenges for this week.',
                          style: const TextStyle(color: Colors.grey)),
                    ),
                  )
                : Column(
                    children: _challenges.map((challenge) {
                      return _buildChallengeCard(
                        context,
                        title: _getChallengeTitle(challenge.title),
                        desc: _getChallengeDesc(challenge.description),
                        progress: challenge.progress,
                        progressText: challenge.progressText,
                      );
                    }).toList(),
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

  String _getChallengeTitle(String key) {
    if (Localizations.localeOf(context).languageCode == 'vi') return key;
    final map = {
      'Ăn sạch mỗi ngày': 'Clean Eat Daily',
      'Đầu bếp tương lai': 'Future Chef',
      'Uống nước đầy đủ': 'Stay Hydrated',
      'Kỷ luật thép': 'Iron Discipline',
    };
    return map[key] ?? key;
  }

  String _getChallengeDesc(String key) {
    if (Localizations.localeOf(context).languageCode == 'vi') return key;
    final map = {
      'Đạt calo mục tiêu 5 ngày liên tiếp': 'Reach target calories for 5 days in a row',
      'Sáng tạo công thức AI đủ 3 lần': 'Create AI recipes 3 times',
      'Ghi nhận uống nước đủ 2L trong 3 ngày': 'Record drinking 2L of water for 3 days',
      'Hoàn thành tất cả bữa ăn trong ngày': 'Complete all meals of the day',
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

  Widget _buildBadgeCard(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
    Color color, {
    required bool isLocked,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLocked
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isLocked
                  ? Colors.grey[200]
                  : color.withValues(alpha: 0.15),
              child: Icon(
                isLocked ? Icons.lock_outline : icon,
                color: isLocked ? Colors.grey[600] : color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isLocked ? Colors.grey[600] : null,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.grey[200]
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                desc,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.grey[600] : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context, {
    required String title,
    required String desc,
    required double progress,
    required String progressText,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDone = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                progressText,
                style: TextStyle(
                  color: isDone ? Colors.green : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
                color: Colors.grey[600], fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor:
                  isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? Colors.green : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
