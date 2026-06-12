import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';

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
        const SnackBar(
          content: Text('Đã lưu công thức nấu ăn thành công!'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu công thức: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công thức', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        '${widget.recipe.prepTime} phút',
                        'Chuẩn bị',
                      ),
                      _buildInfoItem(
                        context,
                        Icons.local_fire_department_outlined,
                        '${widget.recipe.calories} kcal',
                        'Dinh dưỡng',
                      ),
                      _buildInfoItem(
                        context,
                        Icons.trending_up,
                        widget.recipe.difficulty,
                        'Độ khó',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // --- Ingredients Checklist ---
            Text(
              'Nguyên liệu cần chuẩn bị',
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
              'Các bước chế biến',
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
                );
              },
            ),
          ],
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
}
