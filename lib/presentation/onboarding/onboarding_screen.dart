import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/entities/user.dart';
import '../auth/auth_bloc.dart';
import '../shared/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;

  // Step 1 Controllers & States
  final _nameController = TextEditingController();
  DateTime? _dob;
  String _gender = 'Nam'; // Nam, Nữ, Khác

  // Step 2 States
  String _dietType = 'Bình thường'; // Chay, Keto, Eat Clean, Bình thường
  final List<String> _allergies = [];

  // Step 3 States
  final List<String> _likes = [];
  final List<String> _dislikes = [];
  final _likeInputController = TextEditingController();
  final _dislikeInputController = TextEditingController();

  // Route Arguments
  String _email = '';
  String _password = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve email and password from arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    if (args != null) {
      _email = args['email'] ?? '';
      _password = args['password'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _likeInputController.dispose();
    _dislikeInputController.dispose();
    super.dispose();
  }

  // Check if current step inputs are valid to allow moving forward
  bool _isStepValid() {
    if (_currentStep == 0) {
      return _nameController.text.trim().isNotEmpty && _dob != null;
    }
    return true; // Steps 2 and 3 can have empty selections (e.g. no allergies)
  }

  // DOB datepicker with age restriction: age >= 5 years (maxDate = today - 5 years)
  Future<void> _selectDOB(BuildContext context) async {
    final maxDate = DateTime.now().subtract(const Duration(days: 365 * 5));
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? maxDate,
      firstDate: DateTime(1920),
      lastDate: maxDate,
      helpText: Localizations.localeOf(context).languageCode == 'vi' ? 'Chọn ngày sinh (Tối thiểu 5 tuổi)' : 'Select Date of Birth (At least 5 years old)',
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

  // Helper to add chip tags
  void _addTag(TextEditingController controller, List<String> tagList) {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    // Check validation constraints
    final specialChars = RegExp(r'[!@#\$%^&*(),.?":{}|<>]');
    if (specialChars.hasMatch(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Tên khẩu vị không được chứa ký tự đặc biệt!' : 'Taste name cannot contain special characters!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (text.length > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Tên khẩu vị không được vượt quá 30 ký tự!' : 'Taste name cannot exceed 30 characters!'),
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

  void _finishOnboarding() {
    final profile = UserProfileEntity(
      name: _nameController.text.trim(),
      dob: _dob,
      dietType: _dietType,
      allergies: _allergies,
      likes: _likes,
      dislikes: _dislikes,
    );

    context.read<AuthBloc>().add(
          RegisterSubmitted(
            email: _email,
            password: _password,
            profile: profile,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Thiết lập Profile' : 'Profile Setup', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: Localizations.localeOf(context).languageCode == 'vi' ? 'Hủy đăng ký' : 'Cancel Registration',
          onPressed: () {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Hủy đăng ký?' : 'Cancel Registration?'),
                  ],
                ),
                content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Bạn có chắc chắn muốn hủy đăng ký và quay lại màn hình đăng nhập không? Mọi thông tin bạn đã thiết lập sẽ bị mất.' : 'Are you sure you want to cancel registration and return to the login screen? All setup information will be lost.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(context.translate('cancel'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext); // Close dialog
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false); // Go back to login
                    },
                    child: Text(context.translate('confirm'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is AuthenticatedUser || state is AuthenticatedAdmin) {
            // Success registration -> go home
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              // Custom Step Indicator
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: List.generate(3, (index) {
                    final isActive = index == _currentStep;
                    final isCompleted = index < _currentStep;
                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isDark ? AppColors.primaryDark : AppColors.primary)
                              : (isCompleted
                                  ? (isDark ? AppColors.primaryDark : AppColors.primary).withValues(alpha: 0.5)
                                  : Colors.grey.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(),
                ),
              ),
              // Navigation Buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _currentStep--;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: BorderSide(
                              color: isDark ? AppColors.primaryDark : AppColors.primary,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'vi' ? 'QUAY LẠI' : 'BACK',
                            style: TextStyle(
                              color: isDark ? AppColors.primaryDark : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: GradientButton(
                        text: _currentStep == 2 
                            ? (Localizations.localeOf(context).languageCode == 'vi' ? 'HOÀN TẤT' : 'FINISH') 
                            : (Localizations.localeOf(context).languageCode == 'vi' ? 'TIẾP TỤC' : 'CONTINUE'),
                        onPressed: _isStepValid()
                            ? () {
                                if (_currentStep < 2) {
                                  setState(() {
                                    _currentStep++;
                                  });
                                } else {
                                  _finishOnboarding();
                                }
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Identity();
      case 1:
        return _buildStep2Nutrition();
      case 2:
        return _buildStep3Taste();
      default:
        return Container();
    }
  }

  // --- STEP 1: IDENTITY ---
  Widget _buildStep1Identity() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Bạn là ai?' : 'Who are you?', style: theme.textTheme.titleLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            Localizations.localeOf(context).languageCode == 'vi' ? 'Nhập các thông tin cơ bản để chúng tôi có thể cá nhân hóa chế độ dinh dưỡng cho bạn.' : 'Enter basic details so we can customize your nutrition program.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          CustomTextField(
            controller: _nameController,
            labelText: Localizations.localeOf(context).languageCode == 'vi' ? 'Tên hiển thị' : 'Display name',
            hintText: Localizations.localeOf(context).languageCode == 'vi' ? 'Nhập tên của bạn' : 'Enter your name',
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 24),
          // DOB Field
          Text(
            Localizations.localeOf(context).languageCode == 'vi' ? 'Ngày sinh' : 'Date of Birth',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDOB(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _dob == null 
                        ? (Localizations.localeOf(context).languageCode == 'vi' ? 'Chọn ngày sinh' : 'Select Date of Birth') 
                        : DateFormat('dd/MM/yyyy').format(_dob!),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _dob == null
                          ? (isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant)
                          : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Gender Field
          Text(
            Localizations.localeOf(context).languageCode == 'vi' ? 'Giới tính' : 'Gender',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            dropdownColor: isDark ? AppColors.surfaceContainerDark : AppColors.surface,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.transgender_rounded,
                color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
            items: ['Nam', 'Nữ', 'Khác'].map((String val) {
              String displayText = val;
              if (Localizations.localeOf(context).languageCode != 'vi') {
                if (val == 'Nam') displayText = 'Male';
                if (val == 'Nữ') displayText = 'Female';
                if (val == 'Khác') displayText = 'Other';
              }
              return DropdownMenuItem<String>(
                value: val,
                child: Text(displayText, style: theme.textTheme.bodyLarge),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _gender = val;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // --- STEP 2: NUTRITION ---
  Widget _buildStep2Nutrition() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Logic contradiction list: Vegetarians don't eat Beef/Meat
    final isVegetarian = _dietType == 'Chay';

    // Allergy checklist
    final allAllergies = ['Đậu phộng', 'Hải sản', 'Thịt bò', 'Sữa'];

    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Chế độ dinh dưỡng' : 'Nutrition Diet', style: theme.textTheme.titleLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            Localizations.localeOf(context).languageCode == 'vi' ? 'Lựa chọn chế độ ăn của bạn và khai báo dị ứng để AI lọc công thức nấu ăn.' : 'Select your diet and report allergies for AI to filter recipes.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            Localizations.localeOf(context).languageCode == 'vi' ? 'Chế độ ăn (Chọn 1)' : 'Diet Mode (Select 1)',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Column(
            children: ['Bình thường', 'Chay', 'Keto', 'Eat Clean'].map((diet) {
              String displayText = diet;
              if (Localizations.localeOf(context).languageCode != 'vi') {
                if (diet == 'Bình thường') displayText = 'Normal';
                if (diet == 'Chay') displayText = 'Vegetarian';
                if (diet == 'Keto') displayText = 'Keto';
                if (diet == 'Eat Clean') displayText = 'Eat Clean';
              }
              return Card(
                elevation: 0,
                color: _dietType == diet 
                    ? (isDark ? AppColors.primaryDark : AppColors.primary).withValues(alpha: 0.15)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _dietType == diet 
                        ? (isDark ? AppColors.primaryDark : AppColors.primary) 
                        : Colors.grey.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    title: Text(displayText, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Icon(
                      _dietType == diet ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: _dietType == diet 
                          ? (isDark ? AppColors.primaryDark : AppColors.primary) 
                          : Colors.grey,
                    ),
                    onTap: () {
                      setState(() {
                        _dietType = diet;
                        // If user switches to Vegetarian, auto-remove 'Thịt bò' from allergies to prevent logic conflict
                        if (diet == 'Chay') {
                          _allergies.remove('Thịt bò');
                        }
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            Localizations.localeOf(context).languageCode == 'vi' ? 'Bạn có bị dị ứng không? (Chọn nhiều)' : 'Do you have any allergies? (Select multiple)',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Column(
            children: allAllergies.map((allergy) {
              // Contradiction logic: disable "Thịt bò" if "Chay" (Vegetarian) is selected
              final isDisabled = isVegetarian && allergy == 'Thịt bò';
              
              String displayText = allergy;
              if (Localizations.localeOf(context).languageCode != 'vi') {
                if (allergy == 'Đậu phộng') displayText = 'Peanuts';
                if (allergy == 'Hải sản') displayText = 'Seafood';
                if (allergy == 'Thịt bò') displayText = 'Beef';
                if (allergy == 'Sữa') displayText = 'Milk / Dairy';
              }

              return CheckboxListTile(
                title: Text(
                  displayText,
                  style: TextStyle(
                    color: isDisabled 
                        ? Colors.grey 
                        : (isDark ? Colors.white : Colors.black),
                    decoration: isDisabled ? TextDecoration.lineThrough : null,
                  ),
                ),
                value: _allergies.contains(allergy),
                enabled: !isDisabled,
                activeColor: isDark ? AppColors.primaryDark : AppColors.primary,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _allergies.add(allergy);
                    } else {
                      _allergies.remove(allergy);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: TASTE ---
  Widget _buildStep3Taste() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Khẩu vị cá nhân' : 'Personal Taste', style: theme.textTheme.titleLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            Localizations.localeOf(context).languageCode == 'vi' ? 'Nhập các hương vị hoặc nguyên liệu yêu thích và ghét của bạn để đầu bếp AI gợi ý tối ưu nhất.' : 'Enter your favorite and disliked flavors or ingredients so AI Chef can suggest the best menu.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          // Yêu thích
          Text(
            Localizations.localeOf(context).languageCode == 'vi' ? 'Sở thích / Hương vị Yêu thích' : 'Favorite Flavors / Ingredients',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _likeInputController,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: Localizations.localeOf(context).languageCode == 'vi' ? 'VD: Cay, Hải sản, Bột béo...' : 'E.g., Spicy, Seafood, Fat...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _addTag(_likeInputController, _likes),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _addTag(_likeInputController, _likes),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
                ),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _likes.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () {
                  setState(() {
                    _likes.remove(tag);
                  });
                },
                backgroundColor: (isDark ? AppColors.primaryDark : AppColors.primary).withValues(alpha: 0.1),
                side: BorderSide(color: isDark ? AppColors.primaryDark : AppColors.primary),
                deleteIconColor: Colors.redAccent,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Không thích
          Text(
            Localizations.localeOf(context).languageCode == 'vi' ? 'Nguyên liệu / Hương vị Không thích' : 'Disliked Flavors / Ingredients',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dislikeInputController,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: Localizations.localeOf(context).languageCode == 'vi' ? 'VD: Hành lá, Cà rốt, Ngọt...' : 'E.g., Onions, Carrots, Sweet...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _addTag(_dislikeInputController, _dislikes),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _addTag(_dislikeInputController, _dislikes),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _dislikes.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () {
                  setState(() {
                    _dislikes.remove(tag);
                  });
                },
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                side: const BorderSide(color: Colors.redAccent),
                deleteIconColor: Colors.redAccent,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
