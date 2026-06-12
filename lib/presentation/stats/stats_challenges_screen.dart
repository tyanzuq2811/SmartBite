import 'package:flutter/material.dart';

class StatsChallengesScreen extends StatelessWidget {
  const StatsChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thách thức & Thành tích', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // --- Streak Card Section ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                  '7 Ngày Ăn Sạch 🔥',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bạn đang có phong độ tuyệt vời! Tiếp tục duy trì nhé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Weekly streak dot tracker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStreakDot('T2', true),
                    _buildStreakDot('T3', true),
                    _buildStreakDot('T4', true),
                    _buildStreakDot('T5', true),
                    _buildStreakDot('T6', true),
                    _buildStreakDot('T7', true),
                    _buildStreakDot('CN', true, isCurrent: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Level & XP Section ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIẾN TRÌNH',
                  style: TextStyle(
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
                    Text(
                      'Level 3 - Tập sự ăn sạch',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '450/600 XP',
                      style: TextStyle(
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
                    value: 450 / 600,
                    minHeight: 12,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primaryContainer),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: theme.colorScheme.secondary, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Chỉ còn 150 XP nữa để đạt danh hiệu Chuyên gia dinh dưỡng!',
                          style: TextStyle(fontSize: 12, height: 1.3),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Huy hiệu của bạn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Xem tất cả',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              _buildBadgeCard(context, 'Kẻ hủy diệt mỡ thừa', 'Đã mở khóa', Icons.fitness_center, Colors.amber, isLocked: false),
              _buildBadgeCard(context, 'Chiến thần ăn chay', 'Đã mở khóa', Icons.eco, Colors.green, isLocked: false),
              _buildBadgeCard(context, 'Vua đầu bếp AI', 'Chưa mở', Icons.emoji_events, Colors.grey, isLocked: true),
              _buildBadgeCard(context, 'Thủy thần cấp cao', 'Chưa mở', Icons.water_drop, Colors.grey, isLocked: true),
            ],
          ),
          const SizedBox(height: 28),

          // --- Thách thức tuần này (Weekly Challenges) ---
          const Text(
            'Thách thức tuần này',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildChallengeCard(
            context,
            title: 'Chiến thần ăn rau',
            desc: 'Ăn ít nhất 300g rau xanh mỗi ngày trong 5 ngày liên tục.',
            progress: 0.6,
            progressText: '3/5 ngày',
          ),
          _buildChallengeCard(
            context,
            title: 'Cắt giảm đường tinh luyện',
            desc: 'Không sử dụng đường ngọt nhân tạo hoặc đồ uống có ga trong 3 ngày.',
            progress: 1.0,
            progressText: 'Đã hoàn thành 🎉',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStreakDot(String day, bool completed, {bool isCurrent = false}) {
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey[200] : color.withValues(alpha: 0.1),
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
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
            style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
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
