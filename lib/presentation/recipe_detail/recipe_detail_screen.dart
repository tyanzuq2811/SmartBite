import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../home/calorie_tracker_cubit.dart';
import '../../core/di/injection.dart';
import '../../data/datasources/firebase_datasource.dart';
import '../../data/models/meal_plan_model.dart';
import '../auth/auth_bloc.dart';
import '../../core/localization/app_localizations.dart';
import '../shared/widgets.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late List<bool> _checkedIngredients;
  late List<bool> _completedSteps;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkedIngredients = List<bool>.filled(widget.recipe.ingredients.length, false);
    _completedSteps = List<bool>.filled(widget.recipe.instructions.length, false);
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    try {
      final repo = context.read<RecipeRepository>();
      final list = await repo.getSavedRecipes();
      final exists = list.any((r) => r.recipeName == widget.recipe.recipeName);
      if (mounted) {
        setState(() {
          _isSaved = exists;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveRecipe() async {
    try {
      final repo = context.read<RecipeRepository>();
      await repo.saveRecipe(widget.recipe);
      if (!mounted) return;
      setState(() {
        _isSaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Đã lưu công thức nấu ăn thành công!' : 'Recipe saved successfully!'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Lỗi khi lưu công thức: $e' : 'Error saving recipe: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateTodayMealPlan(bool isAdding) async {
    final authState = context.read<AuthBloc>().state;
    String? userId;
    if (authState is AuthenticatedUser) {
      userId = authState.user.userId;
    } else if (authState is AuthenticatedAdmin) {
      userId = authState.user.userId;
    }

    if (userId == null) return;

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final ds = getIt<FirebaseDataSource>();

    try {
      var plan = await ds.getMealPlan(userId, todayStr);

      if (isAdding) {
        String mealType = 'Bữa trưa';
        if (now.hour < 10) {
          mealType = 'Bữa sáng';
        } else if (now.hour >= 17) {
          mealType = 'Bữa tối';
        }

        final mealItem = MealItemModel(
          type: mealType,
          name: widget.recipe.recipeName,
          calories: widget.recipe.calories,
          imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200',
          swaps: const [],
          instructions: widget.recipe.instructions,
        );

        final List<GroceryItemModel> newGroceries = widget.recipe.ingredients.map((ing) {
          return GroceryItemModel(
            name: ing['name'] ?? '',
            qty: ing['amount'] ?? '',
            checked: true,
          );
        }).toList();

        if (plan == null) {
          plan = MealPlanModel(
            date: todayStr,
            meals: [mealItem],
            groceryList: {
              'Nguyên liệu': newGroceries,
            },
          );
        } else {
          final mealsList = List<MealItemModel>.from(plan.meals);
          if (!mealsList.any((m) => m.name == mealItem.name)) {
            mealsList.add(mealItem);
          }

          final groceryMap = Map<String, List<GroceryItemModel>>.from(plan.groceryList);
          final currentGroceries = List<GroceryItemModel>.from(groceryMap['Nguyên liệu'] ?? []);
          for (var newItem in newGroceries) {
            if (!currentGroceries.any((g) => g.name == newItem.name)) {
              currentGroceries.add(newItem);
            }
          }
          groceryMap['Nguyên liệu'] = currentGroceries;

          plan = MealPlanModel(
            date: todayStr,
            meals: mealsList,
            groceryList: groceryMap,
          );
        }
      } else {
        // Remove recipe
        if (plan != null) {
          final mealsList = List<MealItemModel>.from(plan.meals)
            ..removeWhere((m) => m.name == widget.recipe.recipeName);

          final groceryMap = Map<String, List<GroceryItemModel>>.from(plan.groceryList);
          final currentGroceries = List<GroceryItemModel>.from(groceryMap['Nguyên liệu'] ?? []);
          final recipeIngNames = widget.recipe.ingredients.map((ing) => ing['name'] ?? '').toSet();
          currentGroceries.removeWhere((g) => recipeIngNames.contains(g.name));
          groceryMap['Nguyên liệu'] = currentGroceries;

          plan = MealPlanModel(
            date: todayStr,
            meals: mealsList,
            groceryList: groceryMap,
          );
        }
      }

      if (plan != null) {
        await ds.saveMealPlan(userId, plan);
      }
    } catch (e) {
      print('Lỗi cập nhật thực đơn hôm nay: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Chi tiết công thức' : 'Recipe Details', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? theme.colorScheme.primary : null,
            ),
            onPressed: _isSaved ? null : _saveRecipe,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // --- Recipe Info Card ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipe.recipeName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                        context,
                        Icons.timer_outlined,
                        '${widget.recipe.prepTime} ${Localizations.localeOf(context).languageCode == 'vi' ? 'phút' : 'mins'}',
                        Localizations.localeOf(context).languageCode == 'vi' ? 'Chuẩn bị' : 'Prep',
                      ),
                      _buildInfoItem(
                        context,
                        Icons.local_fire_department_outlined,
                        '${widget.recipe.calories} calo',
                        Localizations.localeOf(context).languageCode == 'vi' ? 'Dinh dưỡng' : 'Nutrition',
                      ),
                      _buildInfoItem(
                        context,
                        Icons.trending_up,
                        Localizations.localeOf(context).languageCode == 'vi' ? widget.recipe.difficulty : (widget.recipe.difficulty == 'Dễ' ? 'Easy' : (widget.recipe.difficulty == 'Trung bình' ? 'Medium' : 'Hard')),
                        Localizations.localeOf(context).languageCode == 'vi' ? 'Độ khó' : 'Difficulty',
                      ),
                    ],
                  ),
                  if (_buildBadgeRelationTag(widget.recipe.recipeName, widget.recipe.calories, theme) != null) ...[
                    const SizedBox(height: 10),
                    _buildBadgeRelationTag(widget.recipe.recipeName, widget.recipe.calories, theme)!,
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // --- Ingredients Checklist ---
            Text(
              Localizations.localeOf(context).languageCode == 'vi' ? 'Nguyên liệu cần chuẩn bị' : 'Ingredients',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.recipe.ingredients.length,
              itemBuilder: (context, index) {
                final ing = widget.recipe.ingredients[index];
                final isChecked = _checkedIngredients[index];

                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isChecked,
                  title: Text(
                    ing['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text(ing['amount'] ?? ''),
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    setState(() {
                      _checkedIngredients[index] = val ?? false;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 28),

            // --- Instructions Steps ---
            Text(
              Localizations.localeOf(context).languageCode == 'vi' ? 'Các bước chế biến' : 'Instructions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.recipe.instructions.length,
              itemBuilder: (context, index) {
                final stepText = widget.recipe.instructions[index];
                final isCompleted = _completedSteps[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleted
                          ? theme.colorScheme.primary.withValues(alpha: 0.3)
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    clipBehavior: Clip.antiAlias,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                        child: isCompleted
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      title: Text(
                        stepText,
                        style: TextStyle(
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : null,
                          height: 1.4,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _completedSteps[index] = !_completedSteps[index];
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Nút lưu công thức
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaved ? null : _saveRecipe,
                  icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_add_outlined),
                  label: Text(_isSaved ? (Localizations.localeOf(context).languageCode == 'vi' ? 'Đã lưu' : 'Saved') : (Localizations.localeOf(context).languageCode == 'vi' ? 'Lưu công thức' : 'Save Recipe')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaved 
                        ? (isDark ? Colors.grey[800] : Colors.grey[200]) 
                        : theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                    foregroundColor: _isSaved 
                        ? Colors.grey[600] 
                        : theme.colorScheme.primary,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: _isSaved ? Colors.transparent : theme.colorScheme.primary,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nút cập nhật calo
              Expanded(
                child: BlocBuilder<CalorieTrackerCubit, CalorieTrackerState>(
                  builder: (context, calorieState) {
                    final now = DateTime.now();
                    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                    final isEaten = calorieState.getEatenRecipesForDate(todayStr)[widget.recipe.recipeName] ?? false;

                    return ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await Dialogs.showConfirmDialog(
                          context: context,
                          title: Localizations.localeOf(context).languageCode == 'vi' ? 'Xác nhận thay đổi' : 'Confirm Change',
                          content: Localizations.localeOf(context).languageCode == 'vi'
                              ? 'Bạn có chắc chắn muốn ${isEaten ? "xóa" : "thêm"} "${widget.recipe.recipeName}" ${isEaten ? "khỏi" : "vào"} danh sách món ăn đã ăn?'
                              : 'Are you sure you want to ${isEaten ? "remove" : "add"} "${widget.recipe.recipeName}" ${isEaten ? "from" : "to"} eaten list?',
                        );
                        if (!confirm || !context.mounted) return;

                        final mealItem = MealItemModel(
                          type: 'Món ăn tự chọn',
                          name: widget.recipe.recipeName,
                          calories: widget.recipe.calories,
                          imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200',
                          swaps: const [],
                          instructions: widget.recipe.instructions,
                        );

                        final authState = context.read<AuthBloc>().state;
                        String? userId;
                        if (authState is AuthenticatedUser) userId = authState.user.userId;
                        if (authState is AuthenticatedAdmin) userId = authState.user.userId;

                        context.read<CalorieTrackerCubit>().toggleEaten(
                          mealItem,
                          userId ?? "anonymous",
                          todayStr,
                        );
                        _updateTodayMealPlan(!isEaten);

                        if (userId != null) {
                           final ds = getIt<FirebaseDataSource>();
                           final trackerState = context.read<CalorieTrackerCubit>().state;
                           final nextConsumed = trackerState.getConsumedCaloriesForDate(todayStr);
                           final target = trackerState.targetCalories;

                           await ds.updateGamificationAfterAction(
                             userId,
                             eatenIncrement: !isEaten,
                             currentDailyCalories: nextConsumed,
                             targetCalories: target,
                             mealName: widget.recipe.recipeName,
                             mealCalories: widget.recipe.calories,
                           );
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEaten 
                                  ? (Localizations.localeOf(context).languageCode == 'vi' ? 'Đã bớt ${widget.recipe.calories} calo khỏi calo hôm nay' : 'Removed ${widget.recipe.calories} calo from today\'s intake') 
                                  : (Localizations.localeOf(context).languageCode == 'vi' ? 'Đã thêm ${widget.recipe.calories} calo vào calo hôm nay và đồng bộ thực đơn!' : 'Added ${widget.recipe.calories} calo to today\'s intake & synced menu!'),
                            ),
                            backgroundColor: isEaten ? Colors.orange : Colors.teal,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(isEaten ? Icons.check_circle : Icons.local_fire_department),
                      label: Text(isEaten ? (Localizations.localeOf(context).languageCode == 'vi' ? 'Đã ăn' : 'Eaten') : (Localizations.localeOf(context).languageCode == 'vi' ? 'Đã ăn món này' : 'Mark Eaten')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEaten 
                            ? Colors.teal 
                            : theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget? _buildBadgeRelationTag(String mealName, int calories, ThemeData theme) {
    final nameLower = mealName.toLowerCase();

    if (nameLower.contains('chay') || nameLower.contains('đậu hũ') || nameLower.contains('rau củ') || nameLower.contains('salad') || nameLower.contains('quinoa')) {
      return _badgeTag(
        label: Localizations.localeOf(context).languageCode == 'vi' ? 'Tích lũy: Ăn chay 🥬' : 'Badge: Veggie Champion 🥬',
        color: Colors.green,
      );
    }

    if (nameLower.contains('gạo lứt') || nameLower.contains('yến mạch') || nameLower.contains('khoai lang') || nameLower.contains('quinoa')) {
      return _badgeTag(
        label: Localizations.localeOf(context).languageCode == 'vi' ? 'Tích lũy: Tinh bột tốt 🌾' : 'Badge: Carb Cleaner 🌾',
        color: Colors.orange,
      );
    }

    if (calories <= 400 && (nameLower.contains('ức gà') || nameLower.contains('cá hồi') || nameLower.contains('salad') || nameLower.contains('súp lơ') || nameLower.contains('chay') || nameLower.contains('rau'))) {
      return _badgeTag(
        label: Localizations.localeOf(context).languageCode == 'vi' ? 'Tích lũy: Giảm mỡ ⚡' : 'Badge: Fat Destroyer ⚡',
        color: Colors.amber,
      );
    }

    if (calories >= 500 || nameLower.contains('bò') || nameLower.contains('ức gà') || nameLower.contains('cá hồi') || nameLower.contains('trứng') || nameLower.contains('đùi gà')) {
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
}
