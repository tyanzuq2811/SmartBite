import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_theme.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<UserEntity> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final repo = context.read<UserRepository>();
      final list = await repo.getAllUsers();
      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserStatus(UserEntity user, bool isBanned) async {
    final newStatus = isBanned ? 'banned' : 'active';
    
    // Optimistic UI update
    setState(() {
      final index = _users.indexWhere((u) => u.userId == user.userId);
      if (index != -1) {
        _users[index] = user.copyWith(status: newStatus);
      }
    });

    try {
      final repo = context.read<UserRepository>();
      await repo.updateUserStatus(user.userId, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật trạng thái ${user.profile.name} thành $newStatus!'),
          backgroundColor: isBanned ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      // Revert UI on failure
      _loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật trạng thái: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadUsers();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý danh sách người dùng',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Xem danh sách tài khoản thành viên và bật công tắc để Ban/Unban tài khoản lập tức.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // DataTable for Desktop/Tablet or beautiful responsive card lists
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              isDark ? AppColors.surfaceContainerDark : const Color(0xFFE5E7EB),
                            ),
                            columns: const [
                              DataColumn(label: Text('Họ tên', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Quyền', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _users.map((user) {
                              final isBanned = user.status == 'banned';
                              return DataRow(
                                cells: [
                                  DataCell(Text(user.profile.name)),
                                  DataCell(Text(user.email)),
                                  DataCell(Text(user.role)),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isBanned
                                            ? Colors.red.withValues(alpha: 0.15)
                                            : Colors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isBanned ? 'Banned' : 'Active',
                                        style: TextStyle(
                                          color: isBanned ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    // Ban/Unban Toggle Switch
                                    Switch(
                                      value: isBanned,
                                      activeThumbColor: Colors.redAccent,
                                      onChanged: (val) {
                                        _toggleUserStatus(user, val);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
