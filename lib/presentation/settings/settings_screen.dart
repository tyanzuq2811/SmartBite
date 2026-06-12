import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_theme.dart';
import '../auth/auth_bloc.dart';
import 'app_setting_cubit.dart';

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
        title: const Text('Cài đặt', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            role == 'admin' ? 'Quản Trị Viên' : 'Thành Viên',
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng chỉnh sửa hồ sơ đang được phát triển')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // --- Section: App Settings ---
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'CÀI ĐẶT ỨNG DỤNG',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            
            Container(
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
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
                    title: const Text('Giao diện tối (Dark Mode)', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    title: const Text('Ngôn ngữ hiển thị', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                    onTap: () {},
                  ),
                  const Divider(height: 1),

                  // Privacy
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.surface,
                      child: Icon(Icons.security_outlined, color: Colors.grey[600]),
                    ),
                    title: const Text('Quyền riêng tư & Bảo mật', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Section: Help ---
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'HỖ TRỢ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.surface,
                  child: Icon(Icons.help_outline, color: Colors.grey[600]),
                ),
                title: const Text('Trung tâm trợ giúp', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Icon(Icons.open_in_new, color: Colors.grey[400], size: 20),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 32),

            // --- Logout Button ---
            OutlinedButton.icon(
              onPressed: () {
                authBloc.add(LogoutRequested());
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text('ĐĂNG XUẤT', style: TextStyle(fontWeight: FontWeight.bold)),
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
