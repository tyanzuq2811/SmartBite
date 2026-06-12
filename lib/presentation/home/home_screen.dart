import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animations/animations.dart';
import '../auth/auth_bloc.dart';
import '../recipe_detail/recipe_detail_screen.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../shared/widgets.dart';
import '../main_shell.dart';
import '../stats/stats_challenges_screen.dart';
import 'calorie_tracker_cubit.dart';
import 'sync_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Recipe> _dbSavedRecipes = [];
  bool _isLoadingSaved = true;

  static const Recipe smoothieRecipe = Recipe(
    recipeName: 'Smoothie Việt Quất',
    prepTime: 10,
    calories: 210,
    difficulty: 'Dễ',
    ingredients: [
      {'name': 'Việt quất', 'amount': '100g'},
      {'name': 'Sữa tươi không đường', 'amount': '150ml'},
      {'name': 'Sữa chua', 'amount': '1 hộp'},
      {'name': 'Hạt chia', 'amount': '1 muỗng cà phê'}
    ],
    instructions: [
      'Rửa sạch quả việt quất.',
      'Cho tất cả nguyên liệu vào máy xay sinh tố.',
      'Xay mịn hỗn hợp trong khoảng 1-2 phút.',
      'Đổ ra ly và thưởng thức.'
    ],
  );

  static const Recipe codRecipe = Recipe(
    recipeName: 'Cá Tuyết Hấp Tàu Xì',
    prepTime: 25,
    calories: 340,
    difficulty: 'Trung bình',
    ingredients: [
      {'name': 'Cá tuyết phi lê', 'amount': '200g'},
      {'name': 'Sốt tàu xì', 'amount': '2 muỗng canh'},
      {'name': 'Gừng', 'amount': '1 củ nhỏ'},
      {'name': 'Hành lá', 'amount': '2 nhánh'},
      {'name': 'Ớt sừng', 'amount': '1 quả'}
    ],
    instructions: [
      'Sơ chế sạch cá tuyết phi lê và thấm khô nước.',
      'Thái sợi gừng, hành lá và ớt sừng.',
      'Rưới sốt tàu xì lên cá và xếp gừng thái sợi lên trên.',
      'Hấp cách thủy trong 15 phút cho cá chín.',
      'Trang trí với hành lá, ớt sừng và rưới dầu nóng lên trên rồi dùng nóng.'
    ],
  );

  @override
  void initState() {
    super.initState();
    loadSavedRecipes();
  }

  Future<void> loadSavedRecipes() async {
    try {
      final repo = context.read<RecipeRepository>();
      final list = await repo.getSavedRecipes();
      if (mounted) {
        setState(() {
          _dbSavedRecipes = list;
          _isLoadingSaved = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSaved = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Chào buổi sáng! ☀️';
    if (hour >= 11 && hour < 18) return 'Chào buổi chiều! 🌤️';
    if (hour >= 18 && hour < 22) return 'Chào buổi tối! 🌙';
    return 'Chúc bạn ngủ ngon! 💤';
  }

  List<Recipe> _getRecommendations(String dietType) {
    if (dietType == 'Chay') {
      return const [
        Recipe(
          recipeName: 'Salad Bơ & Hạt Diêm Mạch Chay',
          prepTime: 15,
          calories: 310,
          difficulty: 'Dễ',
          ingredients: [
            {'name': 'Bơ chín', 'amount': '1/2 quả'},
            {'name': 'Hạt diêm mạch chín', 'amount': '100g'},
            {'name': 'Xà lách son', 'amount': '50g'},
            {'name': 'Sốt chanh dây', 'amount': '2 muỗng canh'},
          ],
          instructions: [
            'Bơ lột vỏ thái lát mỏng vừa ăn.',
            'Xà lách rửa sạch để ráo.',
            'Trộn đều diêm mạch, xà lách, sốt chanh dây và bày bơ lên trên đĩa.'
          ],
        ),
        Recipe(
          recipeName: 'Đậu Hũ Sốt Cà Rốt & Bông Cải',
          prepTime: 20,
          calories: 280,
          difficulty: 'Dễ',
          ingredients: [
            {'name': 'Đậu hũ non', 'amount': '2 miếng'},
            {'name': 'Bông cải xanh', 'amount': '150g'},
            {'name': 'Cà rốt', 'amount': '1 củ'},
            {'name': 'Hành tím, nước tương', 'amount': 'vừa đủ'},
          ],
          instructions: [
            'Rửa sạch bông cải cắt nhỏ, cà rốt gọt vỏ thái mỏng.',
            'Áp chảo đậu hũ chín vàng đều hai mặt rồi thái khối vuông.',
            'Phi thơm hành, cho cà rốt và bông cải vào xào sơ.',
            'Cho đậu hũ vào cùng nước tương, đậy nắp rim nhỏ lửa 5 phút.',
          ],
        ),
      ];
    } else if (dietType == 'Keto') {
      return const [
        Recipe(
          recipeName: 'Salad Ức Gà Địa Trung Hải',
          prepTime: 15,
          calories: 380,
          difficulty: 'Dễ',
          ingredients: [
            {'name': 'Ức gà chín xé phay', 'amount': '150g'},
            {'name': 'Cà chua bi', 'amount': '100g'},
            {'name': 'Dưa leo', 'amount': '1 quả'},
            {'name': 'Dầu ô liu, nước cốt chanh', 'amount': '2 muỗng canh'},
          ],
          instructions: [
            'Rửa sạch và cắt nhỏ cà chua bi, dưa leo.',
            'Cho xà lách, dưa leo, cà chua vào tô lớn cùng ức gà.',
            'Rưới dầu ô liu, chanh, muối tiêu và trộn đều rồi dùng.'
          ],
        ),
        Recipe(
          recipeName: 'Cá Hồi Nướng Măng Tây',
          prepTime: 25,
          calories: 450,
          difficulty: 'Trung bình',
          ingredients: [
            {'name': 'Cá hồi tươi', 'amount': '150g'},
            {'name': 'Măng tây tươi', 'amount': '100g'},
            {'name': 'Tỏi băm, muối, bơ lạt', 'amount': 'vừa đủ'},
          ],
          instructions: [
            'Rửa sạch cá hồi và măng tây, để ráo.',
            'Xếp măng tây và cá hồi vào khay nướng, quét bơ tỏi lên trên.',
            'Nướng ở 180 độ C trong 15 phút đến khi chín thơm.'
          ],
        ),
      ];
    } else {
      return const [
        Recipe(
          recipeName: 'Salad Ức Gà Địa Trung Hải',
          prepTime: 15,
          calories: 380,
          difficulty: 'Dễ',
          ingredients: [
            {'name': 'Ức gà chín xé phay', 'amount': '150g'},
            {'name': 'Cà chua bi', 'amount': '100g'},
            {'name': 'Dưa leo', 'amount': '1 quả'},
            {'name': 'Dầu ô liu, nước cốt chanh', 'amount': '2 muỗng canh'},
          ],
          instructions: [
            'Rửa sạch và cắt nhỏ cà chua bi, dưa leo.',
            'Cho xà lách, dưa leo, cà chua vào tô lớn cùng ức gà.',
            'Rưới dầu ô liu, chanh, muối tiêu và trộn đều rồi dùng.'
          ],
        ),
        Recipe(
          recipeName: 'Cá Hồi Nướng Măng Tây',
          prepTime: 25,
          calories: 450,
          difficulty: 'Trung bình',
          ingredients: [
            {'name': 'Cá hồi tươi', 'amount': '150g'},
            {'name': 'Măng tây tươi', 'amount': '100g'},
            {'name': 'Tỏi băm, muối, bơ lạt', 'amount': 'vừa đủ'},
          ],
          instructions: [
            'Rửa sạch cá hồi và măng tây, để ráo.',
            'Xếp măng tây và cá hồi vào khay nướng, quét bơ tỏi lên trên.',
            'Nướng ở 180 độ C trong 15 phút đến khi chín thơm.'
          ],
        ),
        Recipe(
          recipeName: 'Bò Cuộn Lá Lốt Không Mỡ',
          prepTime: 20,
          calories: 320,
          difficulty: 'Dễ',
          ingredients: [
            {'name': 'Thịt nạc bò băm', 'amount': '150g'},
            {'name': 'Lá lốt tươi', 'amount': '15 lá'},
            {'name': 'Hành tím, tiêu, sả', 'amount': 'vừa đủ'},
          ],
          instructions: [
            'Ướp thịt bò băm với hành tím, sả băm, muối tiêu trong 10 phút.',
            'Đặt một thìa thịt bò lên lá lốt, cuộn tròn chặt tay.',
            'Áp chảo không dầu trên lửa nhỏ hoặc nướng bằng nồi chiên không dầu.'
          ],
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartBite AI', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is AuthenticatedAdmin) {
                return IconButton(
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  onPressed: () {
                    // Navigate to admin if requested, or show admin snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chuyển tới bảng Quản trị viên')),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          BlocBuilder<SyncCubit, SyncState>(
            builder: (context, syncState) {
              switch (syncState.status) {
                case SyncStatus.syncing:
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                        ),
                      ),
                    ),
                  );
                case SyncStatus.noInternet:
                  return Tooltip(
                    message: 'Đang ngoại tuyến',
                    child: IconButton(
                      icon: const Icon(Icons.cloud_off, color: Colors.grey),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bạn đang ngoại tuyến. Dữ liệu mới sẽ được lưu cục bộ và đồng bộ sau.'),
                          ),
                        );
                      },
                    ),
                  );
                case SyncStatus.idle:
                  return Tooltip(
                    message: 'Đồng bộ đám mây thành công',
                    child: IconButton(
                      icon: const Icon(Icons.cloud_done, color: Colors.teal),
                      onPressed: () {
                        context.read<SyncCubit>().forceSync();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã đồng bộ thành công với đám mây! Nhấn để kiểm tra đồng bộ lại.'),
                          ),
                        );
                      },
                    ),
                  );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Switch to Settings tab
              context.findAncestorStateOfType<MainShellState>()?.onTabSelected(3);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_fab',
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('SÁNG TẠO MÓN ĂN AI'),
        onPressed: () {
          // Switch to Scanner tab
          context.findAncestorStateOfType<MainShellState>()?.onTabSelected(1);
        },
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          String userName = 'Khách';
          String dietType = 'Eat Clean';
          if (authState is AuthenticatedUser) {
            userName = authState.user.profile.name;
            dietType = authState.user.profile.dietType;
          } else if (authState is AuthenticatedAdmin) {
            userName = authState.user.profile.name;
            dietType = authState.user.profile.dietType;
          }

          final recommendations = _getRecommendations(dietType);

          return BlocBuilder<CalorieTrackerCubit, CalorieTrackerState>(
            builder: (context, calorieState) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<CalorieTrackerCubit>().reset();
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // --- Greeting Section ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              userName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Diet: $dietType',
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Streak Banner Card ---
                    InkWell(
                      onTap: () {
                        // Navigate to Gamification / Stats screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StatsChallengesScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF005236), const Color(0xFF004395)]
                                : [const Color(0xFF10B981), const Color(0xFF3B82F6)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.local_fire_department, color: Colors.white, size: 36),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '7 Ngày Ăn Sạch 🔥',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Phong độ tuyệt vời! Nhấn để xem huy hiệu.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Calorie Dashboard Card ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          CaloriesRing(
                            currentCalories: calorieState.consumedCalories,
                            targetCalories: calorieState.targetCalories,
                            eatenRecipes: calorieState.eatenRecipes,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calo đã nạp',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${calorieState.consumedCalories} / ${calorieState.targetCalories} kcal',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: (calorieState.consumedCalories / calorieState.targetCalories).clamp(0.0, 1.0),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primaryContainer),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // --- Section: Smart Recommendations ---
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Gợi ý hôm nay',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.auto_awesome, color: Colors.teal, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recommendations.length,
                        itemBuilder: (context, index) {
                          final recipe = recommendations[index];
                          // Use a linear gradient for the primary featured recommendation
                          final isFirst = index == 0;
                          
                           return Container(
                             width: 280,
                             margin: const EdgeInsets.only(right: 16, bottom: 8),
                             child: OpenContainer(
                               closedElevation: 0,
                               closedColor: Colors.transparent,
                               openElevation: 4,
                               openColor: theme.colorScheme.surface,
                               middleColor: theme.colorScheme.surface,
                               transitionDuration: const Duration(milliseconds: 500),
                               closedShape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(24),
                               ),
                               openBuilder: (context, action) => RecipeDetailScreen(recipe: recipe),
                               closedBuilder: (context, action) {
                                 return Container(
                                   decoration: BoxDecoration(
                                     gradient: isFirst && !isDark
                                         ? const LinearGradient(
                                             colors: [Color(0xFF10B981), Color(0xFF0058BE)],
                                             begin: Alignment.topLeft,
                                             end: Alignment.bottomRight,
                                           )
                                         : null,
                                     color: isFirst && !isDark
                                         ? null
                                         : (isDark ? theme.colorScheme.surfaceContainer : Colors.white),
                                     borderRadius: BorderRadius.circular(24),
                                     border: isFirst && !isDark
                                         ? null
                                         : Border.all(
                                             color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                           ),
                                     boxShadow: [
                                       BoxShadow(
                                         color: Colors.black.withValues(alpha: 0.03),
                                         blurRadius: 10,
                                         offset: const Offset(0, 4),
                                       )
                                     ],
                                   ),
                                   child: InkWell(
                                     onTap: action,
                                     borderRadius: BorderRadius.circular(24),
                                     child: Padding(
                                       padding: const EdgeInsets.all(20.0),
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Row(
                                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                             children: [
                                               Container(
                                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                 decoration: BoxDecoration(
                                                   color: isFirst && !isDark
                                                       ? Colors.white.withValues(alpha: 0.2)
                                                       : theme.colorScheme.primary.withValues(alpha: 0.1),
                                                   borderRadius: BorderRadius.circular(20),
                                                 ),
                                                 child: Text(
                                                   recipe.difficulty,
                                                   style: TextStyle(
                                                     color: isFirst && !isDark
                                                         ? Colors.white
                                                         : theme.colorScheme.primary,
                                                     fontWeight: FontWeight.bold,
                                                     fontSize: 10,
                                                   ),
                                                 ),
                                               ),
                                               Text(
                                                 '${recipe.prepTime} phút',
                                                 style: TextStyle(
                                                   color: isFirst && !isDark ? Colors.white : Colors.grey[600],
                                                   fontWeight: FontWeight.bold,
                                                   fontSize: 12,
                                                 ),
                                               )
                                             ],
                                           ),
                                           const Spacer(),
                                           Text(
                                             recipe.recipeName,
                                             maxLines: 2,
                                             overflow: TextOverflow.ellipsis,
                                             style: theme.textTheme.titleMedium?.copyWith(
                                               fontWeight: FontWeight.bold,
                                               color: isFirst && !isDark ? Colors.white : null,
                                               height: 1.2,
                                             ),
                                           ),
                                           const SizedBox(height: 4),
                                           Text(
                                             '${recipe.calories} kcal • ${recipe.ingredients.length} nguyên liệu',
                                             style: TextStyle(
                                               color: isFirst && !isDark ? Colors.white70 : Colors.grey[600],
                                               fontSize: 13,
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                   ),
                                 );
                               },
                             ),
                           );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // --- Section: Saved Recipes ---
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'Món ăn đã lưu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Smoothie Việt Quất Card
                    _buildSavedRecipeCard(
                      context,
                      title: 'Smoothie Việt Quất',
                      sub: '210 kcal • Bữa phụ',
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDjMkk0JDqdMeLbvCeuHlvbZOE5LQoLbVF0_9JTZMSELaU1VOTucKjr9W6Q4OzevndSwdw2KNrjEWZaQQdi9IOgguLqCFmfjUTcX698fWt9ZFOvwdiCgTChESeUDgLd9WqsN5V6x0-M4kTpb0ksVFazSicTqnf6yXqndssW4JZ5Skjkd99wUuZ8xgN2u-y5k2DE6JyVhNs-WGZRHljuvMwqD4WJUK0s5GVkMcOno4_13zodAdcp7s574Lsg_HlLGTdTZUUGnGw82i_O',
                      calories: 210,
                      isEaten: calorieState.eatenRecipes['Smoothie Việt Quất'] ?? false,
                      onEatenToggle: (val) {
                        context.read<CalorieTrackerCubit>().toggleEaten('Smoothie Việt Quất', 210);
                      },
                      recipe: smoothieRecipe,
                    ),
                    const SizedBox(height: 12),

                    // Cá Tuyết Hấp Tàu Xì Card
                    _buildSavedRecipeCard(
                      context,
                      title: 'Cá Tuyết Hấp Tàu Xì',
                      sub: '340 kcal • Bữa trưa',
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBQbkrCL1b-kYmHUQwEoXS7-0OVjGa0EUsk7bTYH5SC_NEjDYHtbYR1TFrq8UpvEDzoggt5tQvvGIaSTjYMiDBmTZkW5eKobtHiN1_jM1vYC7PTYphsTfaC4bBgKGuRhunkV-gNpG3sdRh1tcDwXlgOfAryWjoCR5LlBFgfuSUlEDbbrlx-LgNUp7t-CT7jdaX4tF8Gei1w3q7xen2Ro3PmcgGV-a02-dtPHEb_LpUo5utymUXilHruepaN0GLR34TD0A-iq6YfOOoY',
                      calories: 340,
                      isEaten: calorieState.eatenRecipes['Cá Tuyết Hấp Tàu Xì'] ?? false,
                      onEatenToggle: (val) {
                        context.read<CalorieTrackerCubit>().toggleEaten('Cá Tuyết Hấp Tàu Xì', 340);
                      },
                      recipe: codRecipe,
                    ),
                    const SizedBox(height: 12),

                    // SQLite Dynamically Loaded Saved Recipes
                    if (!_isLoadingSaved && _dbSavedRecipes.isNotEmpty)
                      ..._dbSavedRecipes.map((recipe) {
                        // Avoid duplicating mock items if they were saved in DB
                        if (recipe.recipeName == 'Smoothie Việt Quất' || recipe.recipeName == 'Cá Tuyết Hấp Tàu Xì') {
                          return const SizedBox.shrink();
                        }
                        final isEaten = calorieState.eatenRecipes[recipe.recipeName] ?? false;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildSavedRecipeCard(
                            context,
                            title: recipe.recipeName,
                            sub: '${recipe.calories} kcal • ${recipe.prepTime} phút • Độ khó: ${recipe.difficulty}',
                            imageUrl: '', // fallback to default icon
                            calories: recipe.calories,
                            isEaten: isEaten,
                            onEatenToggle: (val) {
                              context.read<CalorieTrackerCubit>().toggleEaten(recipe.recipeName, recipe.calories);
                            },
                            recipe: recipe,
                          ),
                        );
                      }),
                    const SizedBox(height: 80), // Padding to avoid overlap with bottom bar & FAB
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSavedRecipeCard(
    BuildContext context, {
    required String title,
    required String sub,
    required String imageUrl,
    required int calories,
    required bool isEaten,
    required ValueChanged<bool> onEatenToggle,
    required Recipe recipe,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: OpenContainer(
          closedElevation: 0,
          closedColor: Colors.transparent,
          openElevation: 4,
          openColor: theme.colorScheme.surface,
          middleColor: theme.colorScheme.surface,
          transitionDuration: const Duration(milliseconds: 500),
          closedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          openBuilder: (context, action) => RecipeDetailScreen(recipe: recipe),
          closedBuilder: (context, action) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: action,
                      borderRadius: BorderRadius.circular(14),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: (imageUrl.isNotEmpty)
                                ? Image.network(
                                    imageUrl,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      width: 64,
                                      height: 64,
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      child: const Icon(Icons.restaurant),
                                    ),
                                  )
                                : Container(
                                    width: 64,
                                    height: 64,
                                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                                    child: Icon(Icons.restaurant, color: theme.colorScheme.primary),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sub,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEaten
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      foregroundColor: isEaten
                          ? Colors.white
                          : theme.colorScheme.primary,
                      elevation: 0,
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      onEatenToggle(!isEaten);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEaten
                              ? 'Đã huỷ đánh dấu ăn "$title"'
                              : 'Đã đánh dấu đã ăn "$title" (+$calories kcal)'),
                          backgroundColor: isEaten ? Colors.amber[800] : Colors.teal,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Text(
                      isEaten ? 'Đã ăn ✓' : 'Đã ăn',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
