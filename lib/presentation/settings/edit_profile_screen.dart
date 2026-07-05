import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_theme.dart';
import '../../domain/entities/user.dart';
import '../auth/auth_bloc.dart';
import '../shared/widgets.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfileEntity currentProfile;

  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late DateTime? _dob;
  late String _dietType;
  late List<String> _allergies;
  late List<String> _likes;
  late List<String> _dislikes;

  final _allergyController = TextEditingController();
  final _likeController = TextEditingController();
  final _dislikeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile.name);
    _dob = widget.currentProfile.dob;
    _dietType = widget.currentProfile.dietType;
    _allergies = List<String>.from(widget.currentProfile.allergies);
    _likes = List<String>.from(widget.currentProfile.likes);
    _dislikes = List<String>.from(widget.currentProfile.dislikes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allergyController.dispose();
    _likeController.dispose();
    _dislikeController.dispose();
    super.dispose();
  }

  Future<void> _selectDOB(BuildContext context) async {
    final maxDate = DateTime.now().subtract(const Duration(days: 365 * 5));
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? maxDate,
      firstDate: DateTime(1920),
      lastDate: maxDate,
      helpText: 'Chọn ngày sinh (Tối thiểu 5 tuổi)',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.primaryDark 
                  : AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dob = picked;
      });
    }
  }

  void _addTag(TextEditingController controller, List<String> tagList) {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final specialChars = RegExp(r'[!@#\$%^&*(),.?":{}|<>]');
    if (specialChars.hasMatch(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không được chứa ký tự đặc biệt!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (text.length > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Độ dài tối đa 30 ký tự!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!tagList.contains(text)) {
      setState(() {
        tagList.add(text);
      });
    }
    controller.clear();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày sinh!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final updatedProfile = UserProfileEntity(
      name: _nameController.text.trim(),
      dob: _dob,
      dietType: _dietType,
      allergies: _allergies,
      likes: _likes,
      dislikes: _dislikes,
    );

    context.read<AuthBloc>().add(UpdateProfileRequested(profile: updatedProfile));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedUser || state is AuthenticatedAdmin) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật hồ sơ thành công! 🎉'), backgroundColor: Colors.teal),
            );
            Navigator.pop(context);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${state.message}'), backgroundColor: Colors.redAccent),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // --- Tên & Ngày sinh ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('THÔNG TIN CÁ NHÂN', style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Vui lòng nhập họ tên';
                        if (value.trim().length < 2) return 'Tên quá ngắn';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDOB(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_month_outlined, color: theme.colorScheme.primary),
                                const SizedBox(width: 12),
                                Text(
                                  _dob == null ? 'Chọn ngày sinh' : DateFormat('dd/MM/yyyy').format(_dob!),
                                  style: TextStyle(fontSize: 16, color: _dob == null ? Colors.grey : null),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Chế độ ăn ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CHẾ ĐỘ ĂN', style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _dietType,
                      decoration: InputDecoration(
                        labelText: 'Chế độ ăn ưa thích',
                        prefixIcon: const Icon(Icons.restaurant),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      items: ['Bình thường', 'Chay', 'Keto', 'Eat Clean'].map((diet) {
                        return DropdownMenuItem(value: diet, child: Text(diet));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _dietType = val;
                            if (val == 'Chay') {
                              _allergies.remove('Thịt bò');
                              _allergies.remove('Thịt heo');
                            }
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Dị ứng ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BỊ DỊ ỨNG (NẾU CÓ)', style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _allergyController,
                            decoration: InputDecoration(
                              hintText: 'Nhập chất dị ứng...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onSubmitted: (_) => _addTag(_allergyController, _allergies),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.add),
                          onPressed: () => _addTag(_allergyController, _allergies),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allergies.map((tag) {
                        return Chip(
                          label: Text(tag, style: const TextStyle(fontWeight: FontWeight.w600)),
                          onDeleted: () => setState(() => _allergies.remove(tag)),
                          backgroundColor: Colors.red[50],
                          side: BorderSide(color: Colors.red[200]!),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Món thích & Ghét ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MÓN ĂN YÊU THÍCH / GHÉT', style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _likeController,
                            decoration: InputDecoration(
                              hintText: 'Thích: Phở, Salad, Cá hồi...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onSubmitted: (_) => _addTag(_likeController, _likes),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.add),
                          onPressed: () => _addTag(_likeController, _likes),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _likes.map((tag) {
                        return Chip(
                          label: Text(tag, style: const TextStyle(fontWeight: FontWeight.w600)),
                          onDeleted: () => setState(() => _likes.remove(tag)),
                          backgroundColor: Colors.teal[50],
                          side: BorderSide(color: Colors.teal[200]!),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dislikeController,
                            decoration: InputDecoration(
                              hintText: 'Không thích: Mướp đắng, Hành...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onSubmitted: (_) => _addTag(_dislikeController, _dislikes),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.add),
                          onPressed: () => _addTag(_dislikeController, _dislikes),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dislikes.map((tag) {
                        return Chip(
                          label: Text(tag, style: const TextStyle(fontWeight: FontWeight.w600)),
                          onDeleted: () => setState(() => _dislikes.remove(tag)),
                          backgroundColor: Colors.orange[50],
                          side: BorderSide(color: Colors.orange[200]!),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- Nút lưu ---
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return ElevatedButton(
                    onPressed: isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('LƯU THAY ĐỔI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
