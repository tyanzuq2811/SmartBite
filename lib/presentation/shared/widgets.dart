import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final String? errorText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: errorText != null 
                ? theme.colorScheme.error 
                : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: errorText != null 
                  ? theme.colorScheme.error 
                  : (isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final gradient = LinearGradient(
      colors: isDark 
          ? [AppColors.primaryDark, AppColors.secondaryDark] 
          : [AppColors.primary, AppColors.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    final disabled = onPressed == null || isLoading;

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: disabled ? null : gradient,
        color: disabled ? Colors.grey.withValues(alpha: 0.3) : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: disabled 
            ? null 
            : [
                BoxShadow(
                  color: (isDark ? AppColors.primaryDark : AppColors.primary).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

class PremiumLoader extends StatelessWidget {
  final String text;

  const PremiumLoader({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(isDark ? AppColors.primaryDark : AppColors.primary),
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.surfaceContainerDark : AppColors.surface,
                ),
                child: Icon(
                  Icons.restaurant_rounded,
                  size: 26,
                  color: isDark ? AppColors.primaryDark : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đang phân tích và chuẩn bị thực đơn dinh dưỡng...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Macro {
  final int p;
  final int c;
  final int f;
  const _Macro({required this.p, required this.c, required this.f});
}

const Map<String, _Macro> _recipeMacros = {
  'Smoothie Việt Quất': _Macro(p: 6, c: 32, f: 5),
  'Cá Tuyết Hấp Tàu Xì': _Macro(p: 28, c: 12, f: 8),
  'Salad Ức Gà Sốt Sữa Chua': _Macro(p: 32, c: 10, f: 6),
  'Cá Hồi Áp Chảo Sốt Chanh Dây': _Macro(p: 26, c: 8, f: 18),
  'Bò Né Cà Chua': _Macro(p: 30, c: 12, f: 20),
  'Trứng Cuộn Hành Tây & Nấm': _Macro(p: 12, c: 4, f: 11),
  'Canh Cà Chua Trứng': _Macro(p: 6, c: 8, f: 7),
  'Thịt Heo Luộc Sốt Tỏi Ớt': _Macro(p: 24, c: 2, f: 22),
  'Súp Bí Đỏ Thịt Băm': _Macro(p: 14, c: 22, f: 8),
  'Tôm Rim Tỏi Gừng': _Macro(p: 22, c: 4, f: 6),
  'Cải Bó Xôi Xào Thịt Bò': _Macro(p: 18, c: 6, f: 14),
  'Bắp Cải Cuộn Thịt Hấp': _Macro(p: 18, c: 12, f: 10),
  'Dưa Leo Trộn Chua Ngọt': _Macro(p: 1, c: 14, f: 0),
  'Cơm Chiên Dương Châu Sức Khỏe': _Macro(p: 12, c: 55, f: 10),
  'Canh Bí Đỏ Thịt Heo': _Macro(p: 12, c: 18, f: 7),
  'Nấm Hương Kho Đậu Hũ': _Macro(p: 10, c: 15, f: 9),
  'Sữa Đậu Nành Tự Nhiên': _Macro(p: 7, c: 12, f: 4),
};

class CaloriesRing extends StatefulWidget {
  final int currentCalories;
  final int targetCalories;
  final Map<String, bool> eatenRecipes;

  const CaloriesRing({
    super.key,
    required this.currentCalories,
    required this.targetCalories,
    required this.eatenRecipes,
  });

  @override
  State<CaloriesRing> createState() => _CaloriesRingState();
}

class _CaloriesRingState extends State<CaloriesRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Macros calculation values
  late double _carbsProgress;
  late double _proteinProgress;
  late double _fatProgress;

  // Real macros values for display
  late int _carbsConsumed;
  late int _proteinConsumed;
  late int _fatConsumed;

  late int _carbsTarget;
  late int _proteinTarget;
  late int _fatTarget;

  @override
  void initState() {
    super.initState();
    _calculateMacros();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  void _calculateMacros() {
    // Target macro calculation based on 40/30/30 ratio
    _carbsTarget = (widget.targetCalories * 0.4 / 4).round();
    _proteinTarget = (widget.targetCalories * 0.3 / 4).round();
    _fatTarget = (widget.targetCalories * 0.3 / 9).round();

    int pSum = 0;
    int cSum = 0;
    int fSum = 0;
    int recipeCaloriesSum = 0;

    widget.eatenRecipes.forEach((recipeName, isEaten) {
      if (isEaten) {
        final macro = _recipeMacros[recipeName];
        if (macro != null) {
          pSum += macro.p;
          cSum += macro.c;
          fSum += macro.f;
          recipeCaloriesSum += (macro.p * 4 + macro.c * 4 + macro.f * 9);
        } else {
          // Estimate macros if recipe details are not in static map
          const avgCal = 300;
          pSum += (avgCal * 0.3 / 4).round();
          cSum += (avgCal * 0.4 / 4).round();
          fSum += (avgCal * 0.3 / 9).round();
          recipeCaloriesSum += avgCal;
        }
      }
    });

    final remainingCalories = widget.currentCalories - recipeCaloriesSum;
    if (remainingCalories > 0) {
      cSum += (remainingCalories * 0.4 / 4).round();
      pSum += (remainingCalories * 0.3 / 4).round();
      fSum += (remainingCalories * 0.3 / 9).round();
    }

    _carbsConsumed = cSum;
    _proteinConsumed = pSum;
    _fatConsumed = fSum;

    _carbsProgress = _carbsTarget > 0 ? _carbsConsumed / _carbsTarget : 0.0;
    _proteinProgress = _proteinTarget > 0 ? _proteinConsumed / _proteinTarget : 0.0;
    _fatProgress = _fatTarget > 0 ? _fatConsumed / _fatTarget : 0.0;
  }

  @override
  void didUpdateWidget(covariant CaloriesRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentCalories != widget.currentCalories ||
        oldWidget.targetCalories != widget.targetCalories ||
        oldWidget.eatenRecipes != widget.eatenRecipes) {
      setState(() {
        _calculateMacros();
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _CaloriesRingPainter(
            progressCarbs: _carbsProgress * _animation.value,
            progressProtein: _proteinProgress * _animation.value,
            progressFat: _fatProgress * _animation.value,
            backgroundColor: isDark ? AppColors.surfaceContainerDark : const Color(0xFFE5E7EB),
            isDark: isDark,
          ),
          child: SizedBox(
            width: 140,
            height: 140,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.currentCalories}',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'kcal nạp',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CaloriesRingPainter extends CustomPainter {
  final double progressCarbs;
  final double progressProtein;
  final double progressFat;
  final Color backgroundColor;
  final bool isDark;

  _CaloriesRingPainter({
    required this.progressCarbs,
    required this.progressProtein,
    required this.progressFat,
    required this.backgroundColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 8.0;

    // Define harmonious colors (Carbs: Amber/Orange, Protein: Pink/Red, Fat: Blue/Teal)
    final carbsColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
    final proteinColor = isDark ? const Color(0xFFEC4899) : const Color(0xFFDB2777);
    final fatColor = isDark ? const Color(0xFF06B6D4) : const Color(0xFF0891B2);

    // 1. Carbs Ring (Outer)
    final radius1 = size.width / 2 - 8;
    _drawRing(canvas, center, radius1, strokeWidth, progressCarbs, carbsColor);

    // 2. Protein Ring (Middle)
    final radius2 = size.width / 2 - 22;
    _drawRing(canvas, center, radius2, strokeWidth, progressProtein, proteinColor);

    // 3. Fat Ring (Inner)
    final radius3 = size.width / 2 - 36;
    _drawRing(canvas, center, radius3, strokeWidth, progressFat, fatColor);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double strokeWidth, double progress, Color color) {
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw background track
    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress arc
    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CaloriesRingPainter oldDelegate) {
    return oldDelegate.progressCarbs != progressCarbs ||
        oldDelegate.progressProtein != progressProtein ||
        oldDelegate.progressFat != progressFat ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.isDark != isDark;
  }
}
