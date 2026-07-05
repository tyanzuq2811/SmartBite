import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../shared/widgets.dart';
import 'auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _emailError;
  String? _passwordError;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    final email = _emailController.text;
    final password = _passwordController.text;

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty) {
      _emailError = context.translate('enterEmail');
    } else if (!emailRegex.hasMatch(email)) {
      _emailError = context.translate('invalidEmail');
    } else {
      _emailError = null;
    }

    // Validate password length
    if (password.isEmpty) {
      _passwordError = context.translate('enterPassword');
    } else if (password.length < 6) {
      _passwordError = context.translate('passwordTooShort');
    } else {
      _passwordError = null;
    }

    setState(() {
      _isFormValid = _emailError == null && _passwordError == null && email.isNotEmpty && password.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _forgotPassword() {
    final email = _emailController.text;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Vui lòng nhập một email hợp lệ ở ô đăng nhập để khôi phục!' : 'Please enter a valid email to recover your password!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(ResetPasswordRequested(email: email));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final logoGradient = LinearGradient(
      colors: isDark 
          ? [AppColors.primaryDark, AppColors.secondaryDark] 
          : [AppColors.primary, AppColors.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is PasswordResetSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(Localizations.localeOf(context).languageCode == 'vi' ? 'Đã gửi link khôi phục mật khẩu vào hòm thư của bạn!' : 'Password reset link sent to your inbox!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is AuthenticatedUser) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          } else if (state is AuthenticatedAdmin) {
            Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // App Brand Logo/Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: logoGradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'SmartBite AI',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'vi' ? 'Dinh dưỡng cá nhân hóa & Gợi ý món ăn thông minh' : 'Personalized Nutrition & Smart Recipe Recommendations',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    context.translate('login'),
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 24),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : _forgotPassword,
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'vi' ? 'Quên mật khẩu?' : 'Forgot password?',
                        style: TextStyle(
                          color: isDark ? AppColors.primaryDark : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    text: context.translate('login').toUpperCase(),
                    isLoading: isLoading,
                    onPressed: _isFormValid
                        ? () {
                            context.read<AuthBloc>().add(
                                  LoginSubmitted(
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                  ),
                                );
                          }
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        Localizations.localeOf(context).languageCode == 'vi' ? 'Chưa có tài khoản? ' : "Don't have an account? ",
                        style: theme.textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'vi' ? 'Đăng ký ngay' : 'Register now',
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
          );
        },
      ),
    );
  }
}
