import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'ai_recipe_cubit.dart';
import '../auth/auth_bloc.dart';
import '../recipe_detail/recipe_detail_screen.dart';
import '../shared/widgets.dart';
import '../../data/datasources/on_device_detector.dart';
import '../../data/datasources/firebase_datasource.dart';
import '../../core/di/injection.dart';
import '../../core/localization/app_localizations.dart';

class InputHubScreen extends StatefulWidget {
  const InputHubScreen({super.key});

  @override
  State<InputHubScreen> createState() => _InputHubScreenState();
}

class _InputHubScreenState extends State<InputHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _textController = TextEditingController();
  final List<String> _ingredients = [];
  bool _isFlashOn = false;

  // Autocomplete mock suggestions
  List<String> get _suggestions {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    return isVi ? [
      'Thịt bò', 'Thịt heo', 'Ức gà', 'Cá hồi', 'Tôm tươi',
      'Cà chua', 'Khoai tây', 'Cà rốt', 'Bông cải xanh', 'Hành tây',
      'Nấm hương', 'Rau bina', 'Trứng gà', 'Phô mai', 'Đậu hũ'
    ] : [
      'Beef', 'Pork', 'Chicken Breast', 'Salmon', 'Fresh Shrimp',
      'Tomato', 'Potato', 'Carrot', 'Broccoli', 'Onion',
      'Shiitake Mushroom', 'Spinach', 'Chicken Eggs', 'Cheese', 'Tofu'
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _addIngredient(String val) {
    final clean = val.trim();
    if (clean.isEmpty) return;
    
    // Client-side Validation (Regex to strip special symbols, limit to 30 chars)
    final sanitized = clean.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '');
    if (sanitized.length > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Tên nguyên liệu không quá 30 ký tự.' : 'Ingredient name cannot exceed 30 characters.'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (sanitized.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Tên nguyên liệu không hợp lệ.' : 'Invalid ingredient name.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      if (!_ingredients.contains(sanitized)) {
        _ingredients.add(sanitized);
      }
      _textController.clear();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        if (!mounted) return;
        _triggerImageAnalysis(base64String);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Không thể chọn ảnh: $e' : 'Cannot pick image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _triggerImageAnalysis(String base64Image) async {
    final theme = Theme.of(context);

    // Show local processing loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: PremiumLoader(text: Localizations.localeOf(context).languageCode == 'vi' ? 'AI cục bộ đang quét thực phẩm...' : 'Local AI is scanning food...'),
      ),
    );

    try {
      final detected = await OnDeviceDetector.instance.detectIngredientsFromBase64(base64Image);

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      if (detected.isEmpty) {
        _showNotFoodDialog();
        return;
      }

      setState(() {
        for (var item in detected) {
          if (!_ingredients.contains(item)) {
            _ingredients.add(item);
          }
        }
      });

      // Animate tab controller to "Nhập thủ công" (tab index 1)
      _tabController.animateTo(1);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'vi' ? '🤖 Đã phát hiện: ${detected.join(", ")}. Bạn có thể chỉnh sửa rổ nguyên liệu!' : '🤖 Detected: ${detected.join(", ")}. You can edit your ingredient basket!'),
          backgroundColor: theme.colorScheme.primary,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: Localizations.localeOf(context).languageCode == 'vi' ? 'TẠO NGAY' : 'CREATE NOW',
            textColor: Colors.white,
            onPressed: _submitIngredients,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi nhận dạng: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _submitIngredients() {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Vui lòng thêm ít nhất một nguyên liệu!' : 'Please add at least one ingredient!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    dynamic profile;
    if (authState is AuthenticatedUser) {
      profile = authState.user.profile;
    } else if (authState is AuthenticatedAdmin) {
      profile = authState.user.profile;
    }

    if (profile != null) {
      context.read<AiRecipeCubit>().generateFromIngredients(_ingredients, profile);
    }
  }

  void _showNotFoodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Hình ảnh không hợp lệ' : 'Invalid Image'),
          ],
        ),
        content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Tôi không thấy nguyên liệu hay thực phẩm nào ở đây, bạn vui lòng chụp lại nhé!' : 'I did not see any ingredients or food here, please take another photo!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Đồng ý' : 'Agree', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<AiRecipeCubit, AiRecipeState>(
      listener: (context, state) {
        if (state is AiRecipeSuccess) {
          final authState = context.read<AuthBloc>().state;
          String? userId;
          if (authState is AuthenticatedUser) userId = authState.user.userId;
          if (authState is AuthenticatedAdmin) userId = authState.user.userId;
          if (userId != null) {
            getIt<FirebaseDataSource>().updateGamificationAfterAction(
              userId,
              aiRecipeCreated: true,
            );
          }

          // Open detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: state.recipe),
            ),
          );
          context.read<AiRecipeCubit>().reset();
        }
        if (state is AiRecipeFailure) {
          if (state.message.contains('Không tìm thấy thực phẩm') || state.message.toLowerCase().contains('notfood') || state.message.toLowerCase().contains('not_food')) {
            _showNotFoodDialog();
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'AI thông báo' : 'AI Notification'),
                content: Text(state.message),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<AiRecipeCubit>().reset();
                    },
                    child: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Thử lại' : 'Try Again', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        }
      },
      builder: (context, state) {
        if (state is AiRecipeImageAnalyzing) {
          return Scaffold(
            body: PremiumLoader(text: Localizations.localeOf(context).languageCode == 'vi' ? 'Đang phân tích hình ảnh bằng AI cục bộ (Offline)...' : 'Analyzing image with local AI (Offline)...'),
          );
        }
        if (state is AiRecipeGenerating) {
          return Scaffold(
            body: PremiumLoader(text: Localizations.localeOf(context).languageCode == 'vi' ? 'Đang chế biến công thức từ cơ sở dữ liệu...' : 'Preparing recipe from database...'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Nhập liệu nguyên liệu' : 'Input Ingredients', style: const TextStyle(fontWeight: FontWeight.bold)),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
              tabs: [
                Tab(icon: const Icon(Icons.camera_alt), text: Localizations.localeOf(context).languageCode == 'vi' ? 'Quét nguyên liệu' : 'Scan Ingredients'),
                Tab(icon: const Icon(Icons.edit_note), text: Localizations.localeOf(context).languageCode == 'vi' ? 'Nhập thủ công' : 'Manual Entry'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // --- CAMERA TAB ---
              _buildCameraTab(theme, isDark),

              // --- TEXT TAB ---
              _buildTextTab(theme, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraTab(ThemeData theme, bool isDark) {
    return Stack(
      children: [
        // Simulated Camera Viewfinder
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black87,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant, color: Colors.white.withValues(alpha: 0.1), size: 120),
              const SizedBox(height: 16),
              Text(
                Localizations.localeOf(context).languageCode == 'vi' ? 'Hướng camera về phía thực phẩm' : 'Point camera at the food',
                style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                Localizations.localeOf(context).languageCode == 'vi' ? 'AI Cục Bộ (Offline 100%) tự động nhận diện nguyên liệu.' : 'Local AI (100% Offline) automatically detects ingredients.',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),

        // Grid Guide overlay
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                VerticalDivider(color: Colors.white.withValues(alpha: 0.15), width: 1),
                VerticalDivider(color: Colors.white.withValues(alpha: 0.15), width: 1),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
              ],
            ),
          ),
        ),

        // Flash and Settings bar
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
                icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isFlashOn = !_isFlashOn;
                  });
                },
              ),
              Text(
                Localizations.localeOf(context).languageCode == 'vi' ? 'GÓC CANH CHUẨN' : 'PERFECT ANGLE',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
                icon: const Icon(Icons.photo_library, color: Colors.white),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ),

        // Floating Simulated Capture bar
        Positioned(
          bottom: 40,
          left: 40,
          right: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  // Simulate image base64
                  _triggerImageAnalysis('SIMULATED_BASE64_IMAGE_DATA');
                },
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                Localizations.localeOf(context).languageCode == 'vi' ? 'Bấm nút đỏ để quét mô phỏng, hoặc dùng icon Thư viện' : 'Tap the red button to simulate scanning, or use the Gallery icon',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTextTab(ThemeData theme, bool isDark) {
    final suggestions = _suggestions.where((s) {
      final input = _textController.text.trim().toLowerCase();
      return input.isNotEmpty && s.toLowerCase().contains(input) && !_ingredients.contains(s);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Localizations.localeOf(context).languageCode == 'vi' ? 'Nhập các nguyên liệu bạn đang có' : 'Enter ingredients you have',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Search input field
          TextField(
            controller: _textController,
            onChanged: (_) => setState(() {}),
            onSubmitted: _addIngredient,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: Localizations.localeOf(context).languageCode == 'vi' ? 'Ví dụ: Thịt bò, Cà chua...' : 'E.g., Beef, Tomato...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _textController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),

          // Autocomplete suggestion list
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
               child: Material(
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(12),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final item = suggestions[index];
                    return ListTile(
                      title: Text(item),
                      trailing: const Icon(Icons.add, size: 16),
                      onTap: () => _addIngredient(item),
                    );
                  },
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Ingredient list label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Localizations.localeOf(context).languageCode == 'vi' ? 'Rổ nguyên liệu của bạn (${_ingredients.length})' : 'Your ingredient basket (${_ingredients.length})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (_ingredients.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _ingredients.clear()),
                  child: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Xoá tất cả' : 'Clear All', style: const TextStyle(color: Colors.red)),
                )
            ],
          ),
          const SizedBox(height: 8),

          // Empty Basket State
          if (_ingredients.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_basket_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(
                      Localizations.localeOf(context).languageCode == 'vi' ? 'Rổ trống. Hãy thêm nguyên liệu!' : 'Basket is empty. Please add ingredients!',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            // Chip Grid list
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ingredients.map((ing) {
                    return Chip(
                      label: Text(ing),
                      deleteIcon: const Icon(Icons.cancel, size: 16),
                      onDeleted: () {
                        setState(() {
                          _ingredients.remove(ing);
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

          // Action Submit Button
          if (_ingredients.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'SÁNG TẠO CÔNG THỨC NGAY' : 'GENERATE RECIPE NOW', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                onPressed: _submitIngredients,
              ),
            ),
        ],
      ),
    );
  }
}
