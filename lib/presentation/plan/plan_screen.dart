import 'package:flutter/material.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  // Shopping list item models
  final List<Map<String, dynamic>> _veggies = [
    {'name': 'Súp lơ xanh', 'qty': '500g', 'checked': true},
    {'name': 'Cà chua bi', 'qty': '1 hộp', 'checked': false},
    {'name': 'Quả bơ', 'qty': '2 quả', 'checked': false},
  ];

  final List<Map<String, dynamic>> _meats = [
    {'name': 'Cá hồi phi lê', 'qty': '300g', 'checked': true},
    {'name': 'Ức gà tươi', 'qty': '400g', 'checked': false},
  ];

  final List<Map<String, dynamic>> _spices = [
    {'name': 'Hạt Quinoa', 'qty': '1 túi', 'checked': false},
    {'name': 'Sữa chua không đường', 'qty': '4 hộp', 'checked': false},
  ];

  // Daily Meal Plans (mocking swap logic)
  final List<Map<String, dynamic>> _meals = [
    {
      'type': 'Bữa sáng',
      'name': 'Yogurt Ngũ Cốc & Dâu Tây',
      'calories': 320,
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAkzipEN3kijSUY-nDHK4unrmivQxZvy57nI9E_B8TNKt534Pa37gftli1FhHxpzTslfJSVqAOy5Z1OpZW1oNV2G2EU5DNNP8siZfZCj2rXV8L3JfXhMR2LndUUNFQ6Kt9btmUIUp63sy3vVi__FudPNWrL2A8mKo6mx6NJZCpkcv_-O6hc1g33Wmnaju77wofbaS0pDu-lkjPoIkbwKb-uEX4Ik3HDevAIyu_ZN3Mr4Vd7xzbdKo3aYAIkD_trywoFbnNA2jCT81wm',
      'swaps': ['Smoothie Bơ Chuối', 'Cháo Yến Mạch Táo Red', 'Trứng Cuộn Phô Mai'],
      'swapIdx': 0,
      'isSwapping': false,
    },
    {
      'type': 'Bữa trưa',
      'name': 'Salad Cá Hồi & Quinoa',
      'calories': 450,
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAmmNPERLqbON4YGo0biZL9HlBCir5lc6oBqL3AGybhkRl_oFrea6wxVzt-dN-nPJT8cz93eKK4e5cjPUIJ9Rvw4wc6duQN7vwKq1mmMMZTgP65Zt0DlMNKa_btpKkw6_iabjUyJlzJLIyyc84go7gcS7BAjGyWSIM_BA3u6s9zI4-fPtXONk357p02fWsKihFzxxH2pbVnPMTB248rEV4S-WHFs36mGrpCWBKi8f0onewAg6okrtRXXmIZtcW-KLRhwjMznufrdUVW',
      'swaps': ['Ức Gà Nướng Mật Ong', 'Bún Chả Đậu Hũ Chay', 'Cơm Gạo Lứt Thịt Bò'],
      'swapIdx': 0,
      'isSwapping': false,
    },
    {
      'type': 'Bữa tối',
      'name': 'Ức Gà Nướng Rau Củ',
      'calories': 380,
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDhoTMviIOaClnee2gR1QrQz_257Xd1tA20K0RRo23SG42egT98N8BCK4W-gCpfiOoJkqBG_-PpdDZcdQz1aXc01ZqlE6rRgFjVPhr6MnCyqvFzZ5jQHxK8n_9VIbVk8arVGFu6TqlWC7X9GOXVYBMpKNkRuQMk9EfWTaWJYYGWbnUgcOwsXD4eEthHE3msFomTnkoy0reAM6Tu-LjeZ6jLqqnwDfnAGCWyW4s0p1NSo-__q3UMpKeBm3OpF6XDPKTB9YBhsEF_Dygv',
      'swaps': ['Cá Tuyết Hấp Tàu Xì', 'Canh Chua Đậu Hũ', 'Súp Bí Đỏ Thịt Bằm'],
      'swapIdx': 0,
      'isSwapping': false,
    },
  ];

  int get _totalItems => _veggies.length + _meats.length + _spices.length;
  int get _checkedCount =>
      _veggies.where((item) => item['checked'] == true).length +
      _meats.where((item) => item['checked'] == true).length +
      _spices.where((item) => item['checked'] == true).length;

  Future<void> _handleSwap(int index) async {
    setState(() {
      _meals[index]['isSwapping'] = true;
    });
    // Simulate AI network swap response delay
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      final meal = _meals[index];
      final currentSwaps = meal['swaps'] as List<String>;
      final nextSwapIdx = (meal['swapIdx'] + 1) % currentSwaps.length;
      
      // Store current name to swap
      final prevName = meal['name'];
      meal['name'] = currentSwaps[meal['swapIdx']];
      currentSwaps[meal['swapIdx']] = prevName;

      meal['swapIdx'] = nextSwapIdx;
      meal['isSwapping'] = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã tìm món thay thế phù hợp nhất bằng AI! 🍲'),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showAiAssistantDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Trợ lý AI SmartBite'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tôi có thể giúp bạn tối ưu hoá thực đơn tuần này hoặc chuẩn bị danh sách mua sắm thông minh.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'Gợi ý hôm nay:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 4),
            Text('• "Nên đi chợ vào sáng sớm để mua cá hồi tươi ngon nhất."'),
            Text('• "Có thể dùng sữa hạt thay sữa chua nếu ăn chay thuần."'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ĐÓNG'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã cập nhật danh sách mua sắm tối ưu!')),
              );
            },
            child: const Text('TỐI ƯU HOÁ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lên kế hoạch & Đi chợ', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'plan_fab',
        onPressed: _showAiAssistantDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.bolt, size: 28),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // --- Lịch trình tuần này (Weekly Calendar Bar) ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lịch trình tuần này',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 84,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCalendarDay('Th 2', '12', false),
                    _buildCalendarDay('Th 3', '13', false),
                    _buildCalendarDay('Th 4', '14', true), // Today
                    _buildCalendarDay('Th 5', '15', false),
                    _buildCalendarDay('Th 6', '16', false),
                    _buildCalendarDay('Th 7', '17', false),
                    _buildCalendarDay('CN', '18', false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Bữa ăn hôm nay (Meal Cards Section) ---
          Text(
            'Bữa ăn hôm nay',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _meals.length,
            itemBuilder: (context, index) {
              final meal = _meals[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        meal['imageUrl'],
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 72,
                          height: 72,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.restaurant),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal['type'],
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            meal['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                '${meal['calories']} kcal',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: meal['isSwapping']
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        foregroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: meal['isSwapping'] ? null : () => _handleSwap(index),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // --- Danh sách đi chợ (Smart Grocery List Section) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Danh sách đi chợ',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Đã chọn $_checkedCount/$_totalItems',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildCategoryHeader('Rau củ quả 🥦'),
          _buildGroceryItemsBlock(_veggies),
          const SizedBox(height: 16),

          _buildCategoryHeader('Thịt & Hải sản 🥩'),
          _buildGroceryItemsBlock(_meats),
          const SizedBox(height: 16),

          _buildCategoryHeader('Gia vị & Khác 🧂'),
          _buildGroceryItemsBlock(_spices),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(String label, String number, bool isToday) {
    final theme = Theme.of(context);
    return Container(
      width: 52,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: isToday
            ? LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isToday ? null : (theme.brightness == Brightness.dark ? theme.colorScheme.surfaceContainer : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: isToday
            ? null
            : Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            number,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String name) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
      child: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildGroceryItemsBlock(List<Map<String, dynamic>> items) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final checked = item['checked'] as bool;
          return InkWell(
            onTap: () {
              setState(() {
                item['checked'] = !checked;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: index < items.length - 1
                    ? Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        checked ? Icons.check_box : Icons.check_box_outline_blank,
                        color: checked ? theme.colorScheme.primary : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: checked ? TextDecoration.lineThrough : null,
                          color: checked ? Colors.grey : null,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    item['qty'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
