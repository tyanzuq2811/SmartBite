import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isUpdatingPassword = false;

  bool _shareHealthData = true;
  bool _cloudBackup = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadPrivacySettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _shareHealthData = prefs.getBool('privacy_share_health') ?? true;
        _cloudBackup = prefs.getBool('privacy_cloud_backup') ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePrivacySetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdatingPassword = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Không tìm thấy người dùng hiện tại. Vui lòng đăng nhập lại.');
      }

      // Reauthenticate user before updating password (required by Firebase)
      final email = user.email;
      if (email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: _currentPasswordController.text.trim(),
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text.trim());

        if (mounted) {
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(context.translate('passwordUpdated')),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Lỗi không xác định khi đổi mật khẩu.';
      if (e.code == 'wrong-password') {
        errorMessage = 'Mật khẩu hiện tại không chính xác.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Mật khẩu mới quá yếu. Vui lòng nhập tối thiểu 6 ký tự.';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'Hành động yêu cầu bạn đăng nhập lại gần đây.';
      } else if (e.code == 'user-token-expired' || e.code == 'network-request-failed') {
        errorMessage = 'Lỗi kết nối mạng, vui lòng thử lại sau.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingPassword = false);
      }
    }
  }

  void _confirmAccountDeletion() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(context.translate('deleteConfirmTitle')),
          ],
        ),
        content: Text(context.translate('deleteConfirmContent')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.translate('cancel'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              _deleteAccount();
            },
            child: Text(context.translate('deleteConfirmBtn'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.translate('accountDeleted')),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xóa tài khoản. Bạn cần đăng nhập lại trước khi thực hiện thao tác nhạy cảm này.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('privacyTitle'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // --- Section: Đổi Mật khẩu ---
                _buildSectionHeader(context.translate('changePassword')),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrent,
                          decoration: InputDecoration(
                            labelText: context.translate('currentPassword'),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return context.translate('currentPasswordReq');
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          decoration: InputDecoration(
                            labelText: context.translate('newPassword'),
                            prefixIcon: const Icon(Icons.vpn_key_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureNew = !_obscureNew),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return context.translate('newPasswordReq');
                            if (val.length < 6) return context.translate('passwordTooShort');
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: context.translate('confirmNewPassword'),
                            prefixIcon: const Icon(Icons.check_circle_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (val) {
                            if (val != _newPasswordController.text) return context.translate('passwordsDoNotMatch');
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isUpdatingPassword ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isUpdatingPassword
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(context.translate('updatePassword'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // --- Section: Quyền Dữ liệu ---
                _buildSectionHeader(context.translate('dataPermissions')),
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
                      SwitchListTile(
                        value: _shareHealthData,
                        onChanged: (val) {
                          setState(() => _shareHealthData = val);
                          _savePrivacySetting('privacy_share_health', val);
                        },
                        secondary: CircleAvatar(
                          backgroundColor: theme.colorScheme.surface,
                          child: Icon(Icons.analytics_outlined, color: Colors.grey[600], size: 20),
                        ),
                        title: Text(context.translate('shareHealth'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(context.translate('shareHealthSub'), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        activeColor: theme.colorScheme.primary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _cloudBackup,
                        onChanged: (val) {
                          setState(() => _cloudBackup = val);
                          _savePrivacySetting('privacy_cloud_backup', val);
                        },
                        secondary: CircleAvatar(
                          backgroundColor: theme.colorScheme.surface,
                          child: Icon(Icons.cloud_sync_outlined, color: Colors.grey[600], size: 20),
                        ),
                        title: Text(context.translate('cloudBackup'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(context.translate('cloudBackupSub'), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        activeColor: theme.colorScheme.primary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // --- Section: Vùng Nguy hiểm ---
                _buildSectionHeader(context.translate('dangerZone')),
                Material(
                  color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      context.translate('deleteAccount'),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14),
                    ),
                    subtitle: Text(context.translate('deleteAccountSub'), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
                    onTap: _confirmAccountDeletion,
                  ),
                ),
                const SizedBox(height: 24),
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
}
