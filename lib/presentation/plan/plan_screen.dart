import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_bloc.dart';
import '../home/calorie_tracker_cubit.dart';
import '../../data/datasources/firebase_datasource.dart';
import '../../data/datasources/gemini_datasource.dart';
import '../../data/models/meal_plan_model.dart';
import '../../core/di/injection.dart';
import '../../core/localization/app_localizations.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  MealPlanModel? _mealPlan;
  bool _isLoading = true;
  String? _userId;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedWeekDay = DateTime.now();

  // Track swap animation state locally
  final Map<int, bool> _isSwapping = {};

  @override
  void initState() {
    super.initState();
    _loadMealPlan();
  }

  String _getFormattedDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _ensureUserId() {
    if (_userId == null) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedUser) {
        _userId = authState.user.userId;
      } else if (authState is AuthenticatedAdmin) {
        _userId = authState.user.userId;
      }
    }
  }

  String _getTodayDate() {
    return _getFormattedDate(DateTime.now());
  }

  Future<void> _loadMealPlan() async {
    final authState = context.read<AuthBloc>().state;
    String? userId;
    if (authState is AuthenticatedUser) {
      userId = authState.user.userId;
    } else if (authState is AuthenticatedAdmin) {
      userId = authState.user.userId;
    }

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    _userId = userId;
    final ds = getIt<FirebaseDataSource>();
    final plan = await ds.getMealPlan(userId, _getFormattedDate(_selectedDate));

    if (mounted) {
      setState(() {
        _mealPlan = plan;
        _isLoading = false;
      });
    }
  }

  Future<void> _generateMealPlanAI() async {
    _ensureUserId();
    if (_userId == null) return;
    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthBloc>().state;
      String diet = 'Bình thường';
      List<String> allergies = [];
      List<String> dislikes = [];
      List<String> likes = [];

      if (authState is AuthenticatedUser) {
        diet = authState.user.profile.dietType;
        allergies = authState.user.profile.allergies;
        dislikes = authState.user.profile.dislikes;
        likes = authState.user.profile.likes;
      } else if (authState is AuthenticatedAdmin) {
        diet = authState.user.profile.dietType;
        allergies = authState.user.profile.allergies;
        dislikes = authState.user.profile.dislikes;
        likes = authState.user.profile.likes;
      }

      int targetCalories = 2000;
      try {
        targetCalories = context.read<CalorieTrackerCubit>().state.targetCalories;
      } catch (_) {}

      final geminiDs = getIt<GeminiDataSource>();
      final result = await geminiDs.generateMealPlan(
        diet: diet,
        allergies: allergies,
        dislikes: dislikes,
        likes: likes,
        targetCalories: targetCalories,
      );

      final mealsJson = result['meals'] as List? ?? [];
      final mealsList = mealsJson.map<MealItemModel>((m) {
        final map = Map<String, dynamic>.from(m);
        final model = MealItemModel.fromJson(map);
        if (model.imageUrl.isEmpty) {
          return model.copyWith(
            imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200',
          );
        }
        return model;
      }).toList();

      final rawGrocery = result['grocery_list'] as Map? ?? {};
      final groceryMap = <String, List<GroceryItemModel>>{};
      for (final entry in rawGrocery.entries) {
        final key = entry.key.toString();
        final list = (entry.value as List?)?.map((i) {
          final item = Map<String, dynamic>.from(i);
          return GroceryItemModel(
            name: item['name']?.toString() ?? '',
            qty: item['qty']?.toString() ?? '',
            checked: item['checked'] as bool? ?? false,
          );
        }).toList() ?? [];
        groceryMap[key] = list;
      }

      final todayStr = _getFormattedDate(_selectedDate);
      final newPlan = MealPlanModel(
        date: todayStr,
        meals: mealsList,
        groceryList: groceryMap,
      );

      final ds = getIt<FirebaseDataSource>();
      await ds.saveMealPlan(_userId!, newPlan);
      await ds.updateGamificationAfterAction(_userId!, aiRecipeCreated: true);

      if (mounted) {
        setState(() {
          _mealPlan = newPlan;
          _isLoading = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Localizations.localeOf(context).languageCode == 'vi'
                ? '🎉 Đã khởi tạo thực đơn AI thành công cho ${_getFormattedDateString(_selectedDate)}!'
                : '🎉 AI menu successfully initialized ${_getFormattedDateString(_selectedDate)}!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Lỗi tạo thực đơn AI: $e' : 'Error generating AI menu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  int get _totalItems {
    if (_mealPlan == null) return 0;
    return _mealPlan!.groceryList.values
        .fold(0, (sum, items) => sum + items.length);
  }

  int get _checkedCount {
    if (_mealPlan == null) return 0;
    return _mealPlan!.groceryList.values.fold(
        0,
        (sum, items) =>
            sum + items.where((item) => item.checked).length);
  }

  Future<void> _deleteCurrentMealPlan() async {
    _ensureUserId();
    if (_userId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Xóa thực đơn?' : 'Delete menu?', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Bạn có chắc chắn muốn xóa thực đơn ngày ${_getFormattedDate(_selectedDate)} không?' : 'Are you sure you want to delete the menu for ${_getFormattedDate(_selectedDate)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.translate('cancel').toUpperCase(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.translate('delete').toUpperCase(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final ds = getIt<FirebaseDataSource>();
        await ds.deleteMealPlan(_userId!, _getFormattedDate(_selectedDate));
        if (mounted) {
          setState(() {
            _mealPlan = null;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSwap(int index) async {
    _ensureUserId();
    if (_mealPlan == null || _userId == null) return;

    setState(() => _isSwapping[index] = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final meal = _mealPlan!.meals[index];
    if (meal.swaps.isEmpty) {
      setState(() => _isSwapping[index] = false);
      return;
    }

    // Rotate name with first swap
    final newName = meal.swaps[0];
    final newSwaps = List<String>.from(meal.swaps)
      ..removeAt(0)
      ..add(meal.name);

    final updatedMeals = List<MealItemModel>.from(_mealPlan!.meals);
    updatedMeals[index] = meal.copyWith(name: newName, swaps: newSwaps);

    final updatedPlan = MealPlanModel(
      date: _mealPlan!.date,
      meals: updatedMeals,
      groceryList: _mealPlan!.groceryList,
    );

    // Save to Firestore
    final ds = getIt<FirebaseDataSource>();
    await ds.saveMealPlan(_userId!, updatedPlan);

    if (mounted) {
      setState(() {
        _mealPlan = updatedPlan;
        _isSwapping[index] = false;
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Đã tìm món thay thế phù hợp nhất bằng AI! 🍲' : 'Found the most suitable AI replacement dish! 🍲'),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _toggleMealEaten(MealItemModel meal) async {
    _ensureUserId();
    if (_userId == null) return;

    final dateStr = _getFormattedDate(_selectedDate);
    context.read<CalorieTrackerCubit>().toggleEaten(meal, dateStr);

    // Get updated states
    final trackerState = context.read<CalorieTrackerCubit>().state;
    final nextConsumed = trackerState.getConsumedCaloriesForDate(dateStr);
    final target = trackerState.targetCalories;
    final isNowEaten = trackerState.getEatenRecipesForDate(dateStr)[meal.name] ?? false;

    final ds = getIt<FirebaseDataSource>();
    await ds.updateGamificationAfterAction(
      _userId!,
      eatenIncrement: isNowEaten,
      currentDailyCalories: nextConsumed,
      targetCalories: target,
      mealName: meal.name,
      mealCalories: meal.calories,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'vi'
              ? (isNowEaten
                  ? '🎉 Đã nạp ${meal.calories} calo cho ngày hôm đó!'
                  : 'Đã bớt ${meal.calories} calo khỏi ngày hôm đó!')
              : (isNowEaten
                  ? '🎉 Added ${meal.calories} calo to that day!'
                  : 'Removed ${meal.calories} calo from that day!')),
          backgroundColor: isNowEaten ? Colors.teal : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget? _buildBadgeRelationTag(String mealName, int calories, ThemeData theme) {
    final nameLower = mealName.toLowerCase();
    
    // Check Veggie
    if (nameLower.contains('chay') || nameLower.contains('đậu hũ') || nameLower.contains('rau củ') || nameLower.contains('salad') || nameLower.contains('quinoa')) {
      return _badgeTag(
        label: Localizations.localeOf(context).languageCode == 'vi' ? 'Tích lũy: Ăn chay 🥬' : 'Badge: Veggie Champion 🥬',
        color: Colors.green,
      );
    }
    
    // Check Carb Cleaner
    if (nameLower.contains('gạo lứt') || nameLower.contains('yến mạch') || nameLower.contains('khoai lang') || nameLower.contains('quinoa')) {
      return _badgeTag(
        label: Localizations.localeOf(context).languageCode == 'vi' ? 'Tích lũy: Tinh bột tốt 🌾' : 'Badge: Carb Cleaner 🌾',
        color: Colors.orange,
      );
    }
    
    // Check Fat Destroyer
    if (calories <= 400 && 
        (nameLower.contains('ức gà') || nameLower.contains('cá hồi') || nameLower.contains('salad') || nameLower.contains('súp lơ') || nameLower.contains('chay') || nameLower.contains('rau'))) {
      return _badgeTag(
        label: Localizations.localeOf(context).languageCode == 'vi' ? 'Tích lũy: Giảm mỡ ⚡' : 'Badge: Fat Destroyer ⚡',
        color: Colors.amber,
      );
    }

    // Check Protein Beast
    if (calories >= 500 || 
        nameLower.contains('bò') || nameLower.contains('ức gà') || nameLower.contains('cá hồi') || nameLower.contains('trứng') || nameLower.contains('đùi gà')) {
      return _badgeTag(
        label: Localizations.localeOf(context).languageCode == 'vi' ? 'Tích lũy: Tăng cơ 💪' : 'Badge: Protein Beast 💪',
        color: Colors.redAccent,
      );
    }

    return null;
  }

  Widget _badgeTag({required String label, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<String> _getFallbackInstructions(String mealName) {
    return [
      'Chuẩn bị đầy đủ các nguyên liệu sạch cho món "$mealName".',
      'Sơ chế và rửa sạch nguyên liệu, thái miếng vừa ăn.',
      'Chế biến chín thực phẩm (luộc, hấp, áp chảo hoặc nướng tùy món) để giữ trọn dinh dưỡng.',
      'Trình bày món ăn ra đĩa, trang trí thêm rau thơm và thưởng thức khi còn nóng.'
    ];
  }

  void _showMealDetailSheet(MealItemModel meal) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final instructions = (meal.instructions != null && meal.instructions!.isNotEmpty)
        ? meal.instructions!
        : _getFallbackInstructions(meal.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      meal.imageUrl,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        height: 180,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.restaurant, size: 48, color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    Localizations.localeOf(context).languageCode == 'vi' 
                        ? meal.type.toUpperCase() 
                        : (meal.type == 'Bữa sáng' ? 'BREAKFAST' : (meal.type == 'Bữa trưa' ? 'LUNCH' : 'DINNER')),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meal.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${meal.calories} calo',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_buildBadgeRelationTag(meal.name, meal.calories, theme) != null) ...[
                        const SizedBox(width: 8),
                        _buildBadgeRelationTag(meal.name, meal.calories, theme)!,
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    Localizations.localeOf(context).languageCode == 'vi' ? 'Cách nấu chi tiết' : 'Detailed Recipe Instructions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(instructions.length, (stepIndex) {
                    final step = instructions[stepIndex];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${stepIndex + 1}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleGroceryItem(
      String category, int index, bool newValue) async {
    _ensureUserId();
    if (_mealPlan == null || _userId == null) return;

    // Update local state immediately
    final updatedGrocery =
        Map<String, List<GroceryItemModel>>.from(_mealPlan!.groceryList);
    final items = List<GroceryItemModel>.from(updatedGrocery[category]!);
    items[index] = items[index].copyWith(checked: newValue);
    updatedGrocery[category] = items;

    final updatedPlan = MealPlanModel(
      date: _mealPlan!.date,
      meals: _mealPlan!.meals,
      groceryList: updatedGrocery,
    );

    setState(() => _mealPlan = updatedPlan);

    // Save to Firestore in background
    final ds = getIt<FirebaseDataSource>();
    await ds.saveMealPlan(_userId!, updatedPlan);
  }

  void _showAiAssistantDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Trợ lý AI SmartBite' : 'SmartBite AI Assistant'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Localizations.localeOf(context).languageCode == 'vi' ? 'Tôi có thể giúp bạn tối ưu hoá thực đơn tuần này hoặc chuẩn bị danh sách mua sắm thông minh.' : 'I can help you optimize this week\'s menu or prepare a smart shopping list.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              Localizations.localeOf(context).languageCode == 'vi' ? 'Gợi ý hôm nay:' : 'Today\'s suggestion:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(Localizations.localeOf(context).languageCode == 'vi' ? '• "Nên đi chợ vào sáng sớm để mua cá hồi tươi ngon nhất."' : '• "Go shopping early in the morning to buy the freshest salmon."'),
            Text(Localizations.localeOf(context).languageCode == 'vi' ? '• "Có thể dùng sữa hạt thay sữa chua nếu ăn chay thuần."' : '• "You can use nut milk instead of yogurt if eating vegan."'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'ĐÓNG' : 'CLOSE'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _generateMealPlanAI();
            },
            child: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'TỐI ƯU HOÁ' : 'OPTIMIZE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthenticatedUser || state is AuthenticatedAdmin) {
          _loadMealPlan();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Lên kế hoạch & Đi chợ' : 'Plan & Grocery',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            if (_mealPlan != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: Localizations.localeOf(context).languageCode == 'vi' ? 'Xóa thực đơn ngày này' : 'Delete menu for this day',
                onPressed: _deleteCurrentMealPlan,
              ),
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
        body: _isLoading
            ? const AiLoadingWidget()
            : Column(
                children: [
                  // Lịch trình tuần này luôn hiển thị ở trên cùng
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _getWeekRangeLabel(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  icon: const Icon(Icons.chevron_left, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _focusedWeekDay = _focusedWeekDay.subtract(const Duration(days: 7));
                                      final newMonday = _focusedWeekDay.subtract(Duration(days: _focusedWeekDay.weekday - 1));
                                      _selectedDate = newMonday;
                                      _isLoading = true;
                                    });
                                    _loadMealPlan();
                                  },
                                ),
                                if (!_isCurrentWeek(_focusedWeekDay)) ...[
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _focusedWeekDay = DateTime.now();
                                        _selectedDate = DateTime.now();
                                        _isLoading = true;
                                      });
                                      _loadMealPlan();
                                    },
                                    child: Text(
                                      Localizations.localeOf(context).languageCode == 'vi' ? 'Hiện tại' : 'Current',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  icon: const Icon(Icons.chevron_right, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _focusedWeekDay = _focusedWeekDay.add(const Duration(days: 7));
                                      final newMonday = _focusedWeekDay.subtract(Duration(days: _focusedWeekDay.weekday - 1));
                                      _selectedDate = newMonday;
                                      _isLoading = true;
                                    });
                                    _loadMealPlan();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 84,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _buildWeekDays(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Nội dung chính
                  Expanded(
                    child: _mealPlan == null
                        ? _buildEmptyState(theme)
                        : _buildContent(theme, isDark),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_outlined,
                size: 68, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text(
              Localizations.localeOf(context).languageCode == 'vi'
                  ? 'Chưa có kế hoạch ăn ${_getFormattedDateString(_selectedDate)}'
                  : 'No meal plan ${_getFormattedDateString(_selectedDate)}',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              Localizations.localeOf(context).languageCode == 'vi'
                  ? 'Hãy để AI thiết lập thực đơn ăn sạch ${_getFormattedDateString(_selectedDate)} phù hợp nhất với khẩu vị và chế độ ăn của bạn.'
                  : 'Let AI design ${_getFormattedDateString(_selectedDate)}\'s clean eating menu that best fits your tastes and diet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _generateMealPlanAI,
              icon: const Icon(Icons.bolt, color: Colors.white),
              label: Text(context.translate('generateMenu'), style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      children: [
        // --- Bữa ăn hôm nay ---
        Text(
          Localizations.localeOf(context).languageCode == 'vi'
              ? 'Bữa ăn ${_getFormattedDateString(_selectedDate)}'
              : '${_getFormattedDateStringCap(_selectedDate)}\'s Meals',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<CalorieTrackerCubit, CalorieTrackerState>(
          builder: (context, trackerState) {
            final dateStr = _getFormattedDate(_selectedDate);
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mealPlan!.meals.length,
              itemBuilder: (context, index) {
                final meal = _mealPlan!.meals[index];
                final isSwapping = _isSwapping[index] ?? false;
                final isEaten = trackerState.getEatenRecipesForDate(dateStr)[meal.name] ?? false;

                return GestureDetector(
                  onTap: () => _showMealDetailSheet(meal),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surfaceContainer
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.3),
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
                            meal.imageUrl,
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
                                Localizations.localeOf(context).languageCode == 'vi' ? meal.type : (meal.type == 'Bữa sáng' ? 'Breakfast' : (meal.type == 'Bữa trưa' ? 'Lunch' : 'Dinner')),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                meal.name,
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
                                  const Icon(Icons.local_fire_department,
                                      size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${meal.calories} calo',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (_buildBadgeRelationTag(meal.name, meal.calories, theme) != null)
                                _buildBadgeRelationTag(meal.name, meal.calories, theme)!,
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Eaten button
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            minimumSize: const Size(0, 0),
                            backgroundColor: isEaten
                                ? Colors.green.withValues(alpha: 0.1)
                                : theme.colorScheme.primary.withValues(alpha: 0.05),
                            foregroundColor: isEaten ? Colors.green : theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _toggleMealEaten(meal),
                          icon: Icon(isEaten ? Icons.check_circle : Icons.check_circle_outline, size: 14),
                          label: Text(
                            Localizations.localeOf(context).languageCode == 'vi'
                                ? (isEaten ? 'Đã ăn' : 'Ăn')
                                : (isEaten ? 'Eaten' : 'Eat'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: isSwapping
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            foregroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed:
                              isSwapping ? null : () => _handleSwap(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),

        // --- Danh sách đi chợ ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.translate('shoppingList'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                Localizations.localeOf(context).languageCode == 'vi' ? 'Đã chọn $_checkedCount/$_totalItems' : 'Checked $_checkedCount/$_totalItems',
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

        // Build grocery categories dynamically
        ..._mealPlan!.groceryList.entries.map((entry) {
          return Column(
            children: [
              _buildCategoryHeader(Localizations.localeOf(context).languageCode == 'vi' ? entry.key : (entry.key == 'Thịt & Hải sản' ? 'Meat & Seafood' : (entry.key == 'Rau củ & Trái cây' ? 'Vegetables & Fruits' : (entry.key == 'Gia vị & Khác' ? 'Spices & Others' : entry.key)))),
              _buildGroceryItemsBlock(entry.key, entry.value),
              const SizedBox(height: 16),
            ],
          );
        }),
        const SizedBox(height: 32),
      ],
    );
  }

  List<Widget> _buildWeekDays() {
    final monday = _focusedWeekDay.subtract(Duration(days: _focusedWeekDay.weekday - 1));
    final dayLabels = Localizations.localeOf(context).languageCode == 'vi' 
        ? ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'] 
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final isSelected = day.day == _selectedDate.day &&
          day.month == _selectedDate.month &&
          day.year == _selectedDate.year;
      return _buildCalendarDay(
          dayLabels[i], day.day.toString(), isSelected, day);
    });
  }

  String _getWeekRangeLabel() {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    if (_isCurrentWeek(_focusedWeekDay)) {
      return isVi ? 'Lịch trình tuần này' : 'This Week\'s Schedule';
    }
    final monday = _focusedWeekDay.subtract(Duration(days: _focusedWeekDay.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return isVi 
        ? 'Tuần: ${monday.day}/${monday.month} - ${sunday.day}/${sunday.month}' 
        : 'Week: ${monday.day}/${monday.month} - ${sunday.day}/${sunday.month}';
  }

  bool _isCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final mondayNow = now.subtract(Duration(days: now.weekday - 1));
    final sundayNow = mondayNow.add(const Duration(days: 6));
    
    final mondayStart = DateTime(mondayNow.year, mondayNow.month, mondayNow.day);
    final sundayEnd = DateTime(sundayNow.year, sundayNow.month, sundayNow.day, 23, 59, 59);
    return date.isAfter(mondayStart.subtract(const Duration(seconds: 1))) && 
           date.isBefore(sundayEnd.add(const Duration(seconds: 1)));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.day == now.day && date.month == now.month && date.year == now.year;
  }

  String _getFormattedDateString(DateTime date) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    if (_isToday(date)) {
      return isVi ? 'hôm nay' : 'today';
    }
    return isVi ? 'ngày ${date.day}/${date.month}/${date.year}' : 'on ${date.day}/${date.month}/${date.year}';
  }

  String _getFormattedDateStringCap(DateTime date) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    if (_isToday(date)) {
      return isVi ? 'Hôm nay' : 'Today';
    }
    return isVi ? 'Ngày ${date.day}/${date.month}/${date.year}' : '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCalendarDay(String label, String number, bool isSelected, DateTime date) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isRealToday = date.day == now.day && date.month == now.month && date.year == now.year;

    return GestureDetector(
      onTap: () {
        if (date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year) {
          return;
        }
        setState(() {
          _selectedDate = date;
          _isLoading = true;
        });
        _loadMealPlan();
      },
      child: Container(
        width: 52,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (theme.brightness == Brightness.dark
                  ? theme.colorScheme.surfaceContainer
                  : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isRealToday 
                    ? theme.colorScheme.primary.withValues(alpha: 0.6) 
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
            width: isRealToday ? 1.5 : 1,
          ),
          boxShadow: isSelected
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
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              number,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : (isRealToday ? theme.colorScheme.primary : null),
              ),
            ),
            if (isRealToday) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
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

  Widget _buildGroceryItemsBlock(
      String category, List<GroceryItemModel> items) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return InkWell(
            onTap: () => _toggleGroceryItem(category, index, !item.checked),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: index < items.length - 1
                    ? Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.2),
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    item.checked
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: item.checked
                        ? theme.colorScheme.primary
                        : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: item.checked
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.checked ? Colors.grey : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    item.qty,
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

class AiLoadingWidget extends StatefulWidget {
  const AiLoadingWidget({super.key});

  @override
  State<AiLoadingWidget> createState() => _AiLoadingWidgetState();
}

class _AiLoadingWidgetState extends State<AiLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _messageIndex = 0;
  List<String> get _loadingMessages {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    return isVi ? [
      'Đang kết nối với đầu bếp AI...',
      'Đang phân tích khẩu vị và calo mục tiêu...',
      'Đang chọn lọc thực phẩm sạch & dinh dưỡng...',
      'Đang thiết lập món ăn sáng, trưa, tối...',
      'Đang lập danh sách đi chợ thông minh...',
      'Chuẩn bị hoàn tất thực đơn của bạn...',
    ] : [
      'Connecting to AI Chef...',
      'Analyzing taste and target calories...',
      'Selecting clean and nutritious food...',
      'Setting up breakfast, lunch, dinner...',
      'Creating a smart shopping list...',
      'Getting ready to complete your menu...',
    ];
  }
  late final Stream<int> _timerStream;
  StreamSubscription<int>? _subscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _timerStream = Stream<int>.periodic(
      const Duration(milliseconds: 3200),
      (computationCount) => (computationCount + 1) % _loadingMessages.length,
    );
    _subscription = _timerStream.listen((index) {
      if (mounted) {
        setState(() {
          _messageIndex = index;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.bolt,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              Localizations.localeOf(context).languageCode == 'vi' ? 'Đang tạo thực đơn với AI' : 'Generating menu with AI',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _loadingMessages[_messageIndex],
                  key: ValueKey<int>(_messageIndex),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
