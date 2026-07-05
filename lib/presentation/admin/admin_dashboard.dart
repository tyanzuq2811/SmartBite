import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_theme.dart';
import '../../core/di/injection.dart';
import '../../data/datasources/firebase_datasource.dart';
import '../../data/models/feedback_model.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../auth/auth_bloc.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<UserEntity> _users = [];
  List<FeedbackMessageModel> _feedbackMessages = [];
  bool _isLoading = true;
  bool _isLoadingFeedback = false;
  int _selectedTab = 0;
  String _searchQuery = '';
  String _selectedRoleFilter = 'Tất cả'; // Tất cả, user, admin
  String _selectedStatusFilter = 'Tất cả'; // Tất cả, active, banned

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadFeedbackMessages();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final repo = context.read<UserRepository>();
      final list = await repo.getAllUsers();
      if (!mounted) return;
      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFeedbackMessages() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFeedback = true;
    });

    try {
      final list = await getIt<FirebaseDataSource>().getFeedbackMessages();
      if (!mounted) return;
      setState(() {
        _feedbackMessages = list;
        _isLoadingFeedback = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingFeedback = false;
      });
    }
  }

  int get _unreadFeedbackCount => _feedbackMessages.where((feedback) => !feedback.isRead).length;

  Future<void> _toggleUserStatus(UserEntity user, bool isBanned) async {
    final action = isBanned ? 'KHOÁ' : 'MỞ KHOÁ';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$action tài khoản?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn $action tài khoản của "${user.profile.name}" (${user.email}) không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Đồng ý',
              style: TextStyle(
                color: isBanned ? Colors.redAccent : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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

  Future<void> _resetUserPassword(UserEntity user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Gửi email đặt lại mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Hệ thống sẽ gửi một email đặt lại mật khẩu bảo mật tự động đến địa chỉ "${user.email}". Bạn có chắc chắn muốn thực hiện?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gửi email', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final repo = context.read<UserRepository>();
        await repo.resetPassword(user.email);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gửi email khôi phục mật khẩu tới ${user.email} thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi email: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editUser(UserEntity user) async {
    final nameController = TextEditingController(text: user.profile.name);
    final emailController = TextEditingController(text: user.email);
    String selectedRole = user.role;
    String selectedStatus = user.status;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Chỉnh sửa tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Quyền hạn (Role)',
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('User (Thành viên)')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin (Quản trị)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRole = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái hoạt động',
                        prefixIcon: Icon(Icons.toggle_on_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active (Đang hoạt động)')),
                        DropdownMenuItem(value: 'banned', child: Text('Banned (Đã bị khóa)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedStatus = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Tiếp tục', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == true && mounted) {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      if (name.isEmpty || email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng điền đầy đủ các thông tin!'), backgroundColor: Colors.red),
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Xác nhận cập nhật?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Bạn có chắc chắn muốn lưu các thay đổi cho tài khoản của "${user.profile.name}" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cập nhật', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final repo = context.read<UserRepository>();
        await repo.adminUpdateUser(
          user.userId,
          name: name,
          email: email,
          role: selectedRole,
          status: selectedStatus,
        );
        
        if (mounted) Navigator.pop(context); // Close loading dialog

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật tài khoản thành công!'), backgroundColor: Colors.green),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) Navigator.pop(context); // Close loading dialog
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Quản trị không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleTabChanged(int index) {
    setState(() {
      _selectedTab = index;
    });
    if (index == 1 && _feedbackMessages.isEmpty && !_isLoadingFeedback) {
      _loadFeedbackMessages();
    }
  }

  Future<void> _markFeedbackRead(FeedbackMessageModel feedback) async {
    try {
      await getIt<FirebaseDataSource>().updateFeedbackStatus(
        feedback.id,
        isRead: true,
      );
      if (!mounted) return;
      setState(() {
        final index = _feedbackMessages.indexWhere((item) => item.id == feedback.id);
        if (index != -1) {
          _feedbackMessages[index] = _feedbackMessages[index].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đánh dấu đã đọc: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _markFeedbackProcessed(FeedbackMessageModel feedback) async {
    String? adminId;
    String? adminName;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedAdmin) {
      adminId = authState.user.userId;
      adminName = authState.user.profile.name;
    }

    try {
      await getIt<FirebaseDataSource>().updateFeedbackStatus(
        feedback.id,
        isRead: true,
        isProcessed: true,
        processedById: adminId,
        processedByName: adminName,
      );
      if (!mounted) return;
      setState(() {
        final index = _feedbackMessages.indexWhere((item) => item.id == feedback.id);
        if (index != -1) {
          _feedbackMessages[index] = _feedbackMessages[index].copyWith(
            isRead: true,
            isProcessed: true,
            readAt: DateTime.now(),
            processedAt: DateTime.now(),
            processedById: adminId,
            processedByName: adminName,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đánh dấu đã xử lý: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter users list based on query and filters
    final filteredUsers = _users.where((user) {
      final matchesQuery = user.profile.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesRole = _selectedRoleFilter == 'Tất cả' || 
          user.role.toLowerCase() == _selectedRoleFilter.toLowerCase();
          
      final matchesStatus = _selectedStatusFilter == 'Tất cả' ||
          user.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

      return matchesQuery && matchesRole && matchesStatus;
    }).toList();

    // Calculate stats
    final totalCount = _users.length;
    final activeCount = _users.where((u) => u.status == 'active').length;
    final bannedCount = _users.where((u) => u.status == 'banned').length;
    final adminCount = _users.where((u) => u.role == 'admin').length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'HỆ THỐNG QUẢN TRỊ',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới dữ liệu',
            onPressed: _loadUsers,
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildStatsGrid(totalCount, activeCount, bannedCount, adminCount, isDark),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: SegmentedButton<int>(
                        segments: [
                          const ButtonSegment(value: 0, label: Text('Người dùng'), icon: Icon(Icons.people_alt_outlined)),
                          ButtonSegment(
                            value: 1,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Phản hồi'),
                                if (_unreadFeedbackCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _unreadFeedbackCount.toString(),
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            icon: const Icon(Icons.feedback_outlined),
                          ),
                        ],
                        selected: {_selectedTab},
                        onSelectionChanged: (values) => _handleTabChanged(values.first),
                      ),
                    ),
                  ),
                  if (_selectedTab == 0) ...[
                    SliverToBoxAdapter(
                      child: _buildSearchAndFilters(isDark, theme),
                    ),
                    if (filteredUsers.isEmpty)
                      SliverToBoxAdapter(child: _buildEmptyState(isDark))
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final user = filteredUsers[index];
                              return _buildUserCard(user, isDark, theme);
                            },
                            childCount: filteredUsers.length,
                          ),
                        ),
                      ),
                  ] else ...[
                    if (_isLoadingFeedback)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_feedbackMessages.isEmpty)
                      SliverFillRemaining(
                        child: _buildFeedbackEmptyState(isDark),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildFeedbackCard(_feedbackMessages[index], isDark, theme);
                            },
                            childCount: _feedbackMessages.length,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildStatsGrid(int total, int active, int banned, int admin, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan hệ thống',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: [
              _buildStatCard('Tổng thành viên', total.toString(), Icons.people_rounded, 
                  [const Color(0xFF6366F1), const Color(0xFF4F46E5)]),
              _buildStatCard('Đang hoạt động', active.toString(), Icons.check_circle_rounded, 
                  [const Color(0xFF10B981), const Color(0xFF059669)]),
              _buildStatCard('Tài khoản bị khóa', banned.toString(), Icons.block_rounded, 
                  [const Color(0xFFEF4444), const Color(0xFFDC2626)]),
              _buildStatCard('Quản trị viên', admin.toString(), Icons.admin_panel_settings_rounded, 
                  [const Color(0xFFF59E0B), const Color(0xFFD97706)]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Input Bar
          TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên hoặc email...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.transparent : Colors.grey.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.primaryDark : AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Row of filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, size: 18),
                const SizedBox(width: 8),
                
                // Role filter dropdown button wrapper
                _buildFilterDropdown(
                  'Quyền: $_selectedRoleFilter',
                  ['Tất cả', 'user', 'admin'],
                  (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRoleFilter = val;
                      });
                    }
                  },
                  isDark,
                ),
                const SizedBox(width: 8),
                
                // Status filter dropdown button wrapper
                _buildFilterDropdown(
                  'Trạng thái: ${_selectedStatusFilter == 'Tất cả' ? 'Tất cả' : (_selectedStatusFilter == 'active' ? 'Hoạt động' : 'Đã khóa')}',
                  ['Tất cả', 'active', 'banned'],
                  (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatusFilter = val;
                      });
                    }
                  },
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    List<String> items,
    void Function(String?) onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.grey.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          hint: Text(label),
          items: items.map((String value) {
            String displayVal = value;
            if (value == 'user') displayVal = 'Thành viên (User)';
            if (value == 'admin') displayVal = 'Quản trị (Admin)';
            if (value == 'active') displayVal = 'Hoạt động';
            if (value == 'banned') displayVal = 'Đã khóa';
            if (value == 'Tất cả') displayVal = 'Tất cả';

            return DropdownMenuItem<String>(
              value: value,
              child: Text(displayVal),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUserCard(UserEntity user, bool isDark, ThemeData theme) {
    final isBanned = user.status == 'banned';
    final isAdmin = user.role == 'admin';
    final nameInitials = user.profile.name.isNotEmpty ? user.profile.name.trim().substring(0, 1).toUpperCase() : '?';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.transparent : Colors.grey.withOpacity(0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with circular initials
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isAdmin 
                      ? Colors.amber.withOpacity(0.2) 
                      : (isBanned ? Colors.red.withOpacity(0.2) : Colors.indigo.withOpacity(0.2)),
                  child: Text(
                    nameInitials,
                    style: TextStyle(
                      color: isAdmin 
                          ? Colors.amber[800] 
                          : (isBanned ? Colors.red[800] : Colors.indigo[800]),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                
                // Account Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.profile.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Badge for status
                          _buildBadge(
                            isBanned ? 'ĐÃ KHÓA' : 'HOẠT ĐỘNG',
                            isBanned ? Colors.red : Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Role display badge
                      _buildBadge(
                        isAdmin ? 'ADMIN' : 'MEMBER',
                        isAdmin ? Colors.amber[800]! : Colors.indigo,
                        filled: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, thickness: 0.5),
            ),
            
            // Action Control Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ban/Unban text button instead of pure raw switch
                TextButton.icon(
                  onPressed: () => _toggleUserStatus(user, !isBanned),
                  icon: Icon(
                    isBanned ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                    size: 16,
                    color: isBanned ? Colors.green : Colors.redAccent,
                  ),
                  label: Text(
                    isBanned ? 'Mở khóa' : 'Khóa tài khoản',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isBanned ? Colors.green : Colors.redAccent,
                    ),
                  ),
                ),
                
                // Edit and Key controls
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 20),
                      tooltip: 'Sửa thông tin',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withOpacity(0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _editUser(user),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.vpn_key_rounded, color: Colors.orangeAccent, size: 20),
                      tooltip: 'Khôi phục mật khẩu',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.orangeAccent.withOpacity(0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _resetUserPassword(user),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: filled ? null : Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : color,
          fontWeight: FontWeight.w900,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 72,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy kết quả',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Không có thành viên nào khớp với tìm kiếm hoặc bộ lọc hiện tại của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white30 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackMessageModel feedback, bool isDark, ThemeData theme) {
    final recipientLabel = feedback.recipientAdminNames.isNotEmpty
        ? 'Gửi tới: ${feedback.recipientAdminNames.join(', ')}'
        : 'Gửi tới: ${feedback.recipientAdminName} (${feedback.recipientAdminEmail})';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.transparent : Colors.grey.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  child: Text(
                    feedback.senderName.isNotEmpty ? feedback.senderName.trim().substring(0, 1).toUpperCase() : '?',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(feedback.senderName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('${feedback.senderEmail} · ${feedback.senderRole}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                    ],
                  ),
                ),
                _buildBadge(feedback.isRead ? 'ĐÃ ĐỌC' : 'MỚI', feedback.isRead ? Colors.green : Colors.orange, filled: true),
                const SizedBox(width: 8),
                _buildBadge(feedback.isProcessed ? 'ĐÃ XỬ LÝ' : 'CHƯA XỬ LÝ', feedback.isProcessed ? Colors.blue : Colors.grey, filled: true),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              feedback.message,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(recipientLabel, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!feedback.isRead)
                  TextButton.icon(
                    onPressed: () => _markFeedbackRead(feedback),
                    icon: const Icon(Icons.mark_email_read_outlined, size: 16),
                    label: const Text('Đánh dấu đã đọc'),
                  ),
                if (!feedback.isProcessed) ...[
                  ElevatedButton.icon(
                    onPressed: () => _markFeedbackProcessed(feedback),
                    icon: const Icon(Icons.task_alt_outlined, size: 16),
                    label: const Text('Đã xử lý'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                ],
              ],
            ),
            if (feedback.isProcessed && feedback.processedByName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Xử lý bởi: ${feedback.processedByName}',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feedback_outlined, size: 56, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 12),
            const Text('Chưa có phản hồi nào được gửi đến admin.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
