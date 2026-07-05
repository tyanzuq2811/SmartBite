import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../shared/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  void _validateForm() {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Email check
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty) {
      _emailError = context.translate('enterEmail');
    } else if (!emailRegex.hasMatch(email)) {
      _emailError = context.translate('invalidEmail');
    } else {
      _emailError = null;
    }

    // Password check
    if (password.isEmpty) {
      _passwordError = context.translate('enterPassword');
    } else if (password.length < 6) {
      _passwordError = context.translate('passwordTooShort');
    } else {
      _passwordError = null;
    }

    // Confirm password check
    if (confirmPassword.isEmpty) {
      _confirmPasswordError = Localizations.localeOf(context).languageCode == 'vi' ? 'Vui lòng xác nhận mật khẩu' : 'Please confirm your password';
    } else if (confirmPassword != password) {
      _confirmPasswordError = context.translate('passwordsDoNotMatch');
    } else {
      _confirmPasswordError = null;
    }

    setState(() {
      _isFormValid = _emailError == null &&
          _passwordError == null &&
          _confirmPasswordError == null &&
          email.isNotEmpty &&
          password.isNotEmpty &&
          confirmPassword.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.translate('createAccount'),
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                context.translate('registerSubtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 36),
              CustomTextField(
                controller: _emailController,
                labelText: context.translate('email'),
                hintText: 'abc@gmail.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailController.text.isNotEmpty ? _emailError : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                labelText: context.translate('password'),
                hintText: Localizations.localeOf(context).languageCode == 'vi' ? 'Nhập ít nhất 6 ký tự' : 'Enter at least 6 characters',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                errorText: _passwordController.text.isNotEmpty ? _passwordError : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _confirmPasswordController,
                labelText: context.translate('confirmPassword'),
                hintText: Localizations.localeOf(context).languageCode == 'vi' ? 'Nhập lại mật khẩu phía trên' : 'Re-enter your password',
                prefixIcon: Icons.lock_clock_outlined,
                obscureText: true,
                errorText: _confirmPasswordController.text.isNotEmpty ? _confirmPasswordError : null,
              ),
              const SizedBox(height: 36),
              GradientButton(
                text: Localizations.localeOf(context).languageCode == 'vi' ? 'TIẾP TỤC THIẾT LẬP PROFILE' : 'CONTINUE PROFILE SETUP',
                onPressed: _isFormValid
                    ? () {
                        // Navigate to onboarding screen, passing email & password as arguments
                        Navigator.pushNamed(
                          context,
                          '/onboarding',
                          arguments: {
                            'email': _emailController.text,
                            'password': _passwordController.text,
                          },
                        );
                      }
                    : null,
                isLoading: false,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Localizations.localeOf(context).languageCode == 'vi' ? 'Đã có tài khoản? ' : 'Already have an account? ',
                    style: theme.textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Go back to login
                    },
                    child: Text(
                      context.translate('login'),
                      style: TextStyle(
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
