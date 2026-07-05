import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/entities/user.dart';
import '../auth/auth_bloc.dart';
import 'app_setting_cubit.dart';
import 'edit_profile_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_security_screen.dart';
import 'help_center_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final authBloc = context.watch<AuthBloc>();
    final authState = authBloc.state;
    final settingsCubit = context.watch<AppSettingCubit>();
    final settingsState = settingsCubit.state;

    String name = 'Hoàng Minh Anh';
    String email = 'minhanh.h@smartbite.ai';
    String role = 'user';

    if (authState is AuthenticatedUser) {
      name = authState.user.profile.name;
      email = authState.user.email;
      role = authState.user.role;
    } else if (authState is AuthenticatedAdmin) {
      name = authState.user.profile.name;
      email = authState.user.email;
      role = authState.user.role;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('settingsTitle'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // --- Profile Card ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'H',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: role == 'admin'
                                ? Colors.purple.withValues(alpha: 0.1)
                                : Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            role == 'admin'
                                ? (settingsState.locale == 'vi' ? 'Quản Trị Viên' : 'Administrator')
                                : (settingsState.locale == 'vi' ? 'Thành Viên' : 'Member'),
                            style: TextStyle(
                              color: role == 'admin' ? Colors.purple : Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.grey[600]),
                    onPressed: () {
                      UserProfileEntity? currentProfile;
                      if (authState is AuthenticatedUser) {
                        currentProfile = authState.user.profile;
                      } else if (authState is AuthenticatedAdmin) {
                        currentProfile = authState.user.profile;
                      }

                      if (currentProfile != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              currentProfile: currentProfile!,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(settingsState.locale == 'vi' ? 'Không thể tải thông tin hồ sơ hiện tại' : 'Unable to load current profile information')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // --- Section: App Settings ---
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                settingsState.locale == 'vi' ? 'CÀI ĐẶT ỨNG DỤNG' : 'APP SETTINGS',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            
            Material(
              color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                    // Dark Mode Switch
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.surface,
                        child: Icon(
                          settingsState.themeMode == 'dark'
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: Colors.grey[600],
                        ),
                      ),
                      title: Text(context.translate('darkMode'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Switch(
                        value: settingsState.themeMode == 'dark',
                        activeThumbColor: theme.colorScheme.primary,
                        onChanged: (val) {
                          settingsCubit.toggleTheme();
                        },
                      ),
                    ),
                    const Divider(height: 1),

                    // Language dropdown
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.surface,
                        child: Icon(Icons.language, color: Colors.grey[600]),
                      ),
                      title: Text(context.translate('displayLanguage'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: DropdownButton<String>(
                        value: settingsState.locale,
                        dropdownColor: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt 🇻🇳')),
                          DropdownMenuItem(value: 'en', child: Text('English 🇬🇧')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            settingsCubit.changeLocale(val);
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1),

                    // Notifications
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.surface,
                        child: Icon(Icons.notifications_outlined, color: Colors.grey[600]),
                      ),
                      title: Text(context.translate('notifications'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),

                    // Privacy
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.surface,
                        child: Icon(Icons.security_outlined, color: Colors.grey[600]),
                      ),
                      title: Text(context.translate('privacy'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacySecurityScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

            // --- Section: Help ---
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                settingsState.locale == 'vi' ? 'HỖ TRỢ' : 'SUPPORT',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            Material(
              color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.surface,
                  child: Icon(Icons.help_outline, color: Colors.grey[600]),
                ),
                title: Text(context.translate('helpCenter'), style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Icon(Icons.open_in_new, color: Colors.grey[400], size: 20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpCenterScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Row(
                      children: [
                        const Icon(Icons.logout_rounded, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(settingsState.locale == 'vi' ? 'Đăng xuất?' : 'Logout?'),
                      ],
                    ),
                    content: Text(context.translate('logoutConfirm')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(context.translate('cancel'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext); // Close dialog
                          authBloc.add(LogoutRequested());
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                        child: Text(context.translate('logout'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: Text(context.translate('logout').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: Colors.redAccent, width: 2),
                foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'SmartBite AI v2.4.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
