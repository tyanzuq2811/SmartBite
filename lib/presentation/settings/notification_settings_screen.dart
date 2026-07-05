import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _mealMorning = true;
  bool _mealAfternoon = true;
  bool _mealEvening = true;
  bool _waterReminder = true;
  bool _aiRecommendation = true;
  bool _streakReminder = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _mealMorning = prefs.getBool('notification_meal_morning') ?? true;
        _mealAfternoon = prefs.getBool('notification_meal_afternoon') ?? true;
        _mealEvening = prefs.getBool('notification_meal_evening') ?? true;
        _waterReminder = prefs.getBool('notification_water') ?? true;
        _aiRecommendation = prefs.getBool('notification_ai') ?? true;
        _streakReminder = prefs.getBool('notification_streak') ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(context.translate('notiUpdated')),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
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
        title: Text(context.translate('notiSettings'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                _buildSectionHeader(context.translate('mealReminders')),
                _buildContainer([
                  _buildSwitchTile(
                    title: context.translate('breakfastRemi'),
                    subtitle: context.translate('breakfastRemiSub'),
                    value: _mealMorning,
                    icon: Icons.wb_sunny_outlined,
                    onChanged: (val) {
                      setState(() => _mealMorning = val);
                      _saveSetting('notification_meal_morning', val);
                    },
                    theme: theme,
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: context.translate('lunchRemi'),
                    subtitle: context.translate('lunchRemiSub'),
                    value: _mealAfternoon,
                    icon: Icons.light_mode_outlined,
                    onChanged: (val) {
                      setState(() => _mealAfternoon = val);
                      _saveSetting('notification_meal_afternoon', val);
                    },
                    theme: theme,
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: context.translate('dinnerRemi'),
                    subtitle: context.translate('dinnerRemiSub'),
                    value: _mealEvening,
                    icon: Icons.nights_stay_outlined,
                    onChanged: (val) {
                      setState(() => _mealEvening = val);
                      _saveSetting('notification_meal_evening', val);
                    },
                    theme: theme,
                  ),
                ], theme, isDark),
                const SizedBox(height: 24),
                
                _buildSectionHeader(context.translate('healthAi')),
                _buildContainer([
                  _buildSwitchTile(
                    title: context.translate('waterRemi'),
                    subtitle: context.translate('waterRemiSub'),
                    value: _waterReminder,
                    icon: Icons.water_drop_outlined,
                    onChanged: (val) {
                      setState(() => _waterReminder = val);
                      _saveSetting('notification_water', val);
                    },
                    theme: theme,
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: context.translate('aiChef'),
                    subtitle: context.translate('aiChefSub'),
                    value: _aiRecommendation,
                    icon: Icons.auto_awesome_outlined,
                    onChanged: (val) {
                      setState(() => _aiRecommendation = val);
                      _saveSetting('notification_ai', val);
                    },
                    theme: theme,
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: context.translate('streakRemi'),
                    subtitle: context.translate('streakRemiSub'),
                    value: _streakReminder,
                    icon: Icons.local_fire_department_outlined,
                    onChanged: (val) {
                      setState(() => _streakReminder = val);
                      _saveSetting('notification_streak', val);
                    },
                    theme: theme,
                  ),
                ], theme, isDark),
                const SizedBox(height: 32),
                
                // Mẹo nhỏ
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.translate('notiTip'),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildContainer(List<Widget> children, ThemeData theme, bool isDark) {
    return Material(
      color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: CircleAvatar(
        backgroundColor: theme.colorScheme.surface,
        child: Icon(icon, color: Colors.grey[600], size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      activeColor: theme.colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
