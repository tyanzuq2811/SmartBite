import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'ai_recipe_cubit.dart';
import '../auth/auth_bloc.dart';
import '../recipe_detail/recipe_detail_screen.dart';
import '../shared/widgets.dart';
import '../../data/datasources/on_device_detector.dart';

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
  final List<String> _suggestions = [
    'Thịt bò', 'Thịt heo', 'Ức gà', 'Cá hồi', 'Tôm tươi',
    'Cà chua', 'Khoai tây', 'Cà rốt', 'Bông cải xanh', 'Hành tây',
    'Nấm hương', 'Rau bina', 'Trứng gà', 'Phô mai', 'Đậu hũ'
  ];

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
        const SnackBar(content: Text('Tên nguyên liệu không quá 30 ký tự.'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (sanitized.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên nguyên liệu không hợp lệ.'), backgroundColor: Colors.red),
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
        SnackBar(content: Text('Không thể chọn ảnh: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _triggerImageAnalysis(String base64Image) async {
    final theme = Theme.of(context);

    // Show local processing loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: PremiumLoader(text: 'AI cục bộ đang quét thực phẩm...'),
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
          content: Text('🤖 Đã phát hiện: ${detected.join(", ")}. Bạn có thể chỉnh sửa rổ nguyên liệu!'),
          backgroundColor: theme.colorScheme.primary,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'TẠO NGAY',
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
        const SnackBar(content: Text('Vui lòng thêm ít nhất một nguyên liệu!'), backgroundColor: Colors.orange),
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
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Hình ảnh không hợp lệ'),
          ],
        ),
        content: const Text('Tôi không thấy nguyên liệu hay thực phẩm nào ở đây, bạn vui lòng chụp lại nhé!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đồng ý', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
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
                title: const Text('AI thông báo'),
                content: Text(state.message),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<AiRecipeCubit>().reset();
                    },
                    child: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        }
      },
      builder: (context, state) {
        if (state is AiRecipeImageAnalyzing) {
          return const Scaffold(
            body: PremiumLoader(text: 'Đang phân tích hình ảnh bằng AI cục bộ (Offline)...'),
          );
        }
        if (state is AiRecipeGenerating) {
          return const Scaffold(
            body: PremiumLoader(text: 'Đang chế biến công thức từ cơ sở dữ liệu...'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Nhập liệu nguyên liệu', style: TextStyle(fontWeight: FontWeight.bold)),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
              tabs: const [
                Tab(icon: Icon(Icons.camera_alt), text: 'Quét nguyên liệu'),
                Tab(icon: Icon(Icons.edit_note), text: 'Nhập thủ công'),
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
              const Text(
                'Hướng camera về phía thực phẩm',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'AI Cục Bộ (Offline 100%) tự động nhận diện nguyên liệu.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
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
              const Text(
                'GÓC CANH CHUẨN',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
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
              const Text(
                'Bấm nút đỏ để quét mô phỏng, hoặc dùng icon Thư viện',
                style: TextStyle(color: Colors.white70, fontSize: 12),
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
            'Nhập các nguyên liệu bạn đang có',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Search input field
          TextField(
            controller: _textController,
            onChanged: (_) => setState(() {}),
            onSubmitted: _addIngredient,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Thịt bò, Cà chua...',
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
          ],

          const SizedBox(height: 24),

          // Ingredient list label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rổ nguyên liệu của bạn (${_ingredients.length})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (_ingredients.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _ingredients.clear()),
                  child: const Text('Xoá tất cả', style: TextStyle(color: Colors.red)),
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
                      'Rổ trống. Hãy thêm nguyên liệu!',
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
                label: const Text('SÁNG TẠO CÔNG THỨC NGAY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                onPressed: _submitIngredients,
              ),
            ),
        ],
      ),
    );
  }
}
