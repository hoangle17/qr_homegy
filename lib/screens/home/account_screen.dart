import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../auth/change_password_screen.dart';
import '../../services/api_service.dart';
import '../../widgets/copyable_text.dart';
import 'distributor_list_screen.dart';

class AccountScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const AccountScreen({super.key, required this.onLogout});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? email;
  String? name;
  String? role;
  String? phone;
  String? address;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      // Sử dụng API profile mới để lấy thông tin user
      final user = await ApiService.getCurrentUserProfile();
      if (user != null) {
        setState(() {
          email = user.email;
          name = user.name;
          role = user.role;
          phone = user.phone;
          address = user.address;
          _loading = false;
        });
      } else {
        // Fallback to old method if API fails
        final userData = await ApiService.getCurrentUser();
        if (userData != null) {
          setState(() {
            email = userData['email']?.toString();
            name = userData['name']?.toString();
            role = userData['role']?.toString();
            phone = userData['phone']?.toString();
            address = userData['address']?.toString();
            _loading = false;
          });
        } else {
          setState(() { _loading = false; });
        }
      }
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  void _openChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
  }

  void _openUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DistributorListScreen()),
    );
  }

  Future<void> _logout() async {
    // Lấy thông tin email đã lưu trước khi logout
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final rememberMe = prefs.getBool('remember_me') ?? false;
    
    String logoutMessage = 'Bạn có chắc chắn muốn đăng xuất?';
    
    if (rememberMe && savedEmail != null && savedEmail.isNotEmpty) {
      logoutMessage = 'Bạn có chắc chắn muốn đăng xuất?\n\n'
          'Email đã lưu: $savedEmail\n'
          'Bạn có thể đăng nhập lại nhanh chóng.';
    }
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: Text(logoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    
    // Xóa tất cả thông tin đăng nhập
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
    await prefs.remove('user_info');
    
    if (mounted) {
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Profile Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Avatar and Name
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.deepPurple.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name ?? 'Chưa có tên',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(role ?? '').withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _getRoleColor(role ?? '')),
                      ),
                      child: Text(
                        _getRoleDisplayName(role ?? ''),
                        style: TextStyle(
                          color: _getRoleColor(role ?? ''),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin chi tiết',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.email, 'Email', email ?? 'Chưa có'),
                    _buildInfoRow(Icons.phone, 'Số điện thoại', phone ?? 'Chưa có'),
                    _buildInfoRow(Icons.location_on, 'Địa chỉ', address ?? 'Chưa có'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Actions Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tùy chọn',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openChangePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.lock_reset, size: 18),
                        label: const Text(
                          'Đổi mật khẩu',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Chỉ hiển thị nút quản lý tài khoản cho ADMIN và SUB_ADMIN
                    if (role == 'ADMIN' || role == 'SUB_ADMIN') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openUserManagement,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.people, size: 18),
                          label: const Text(
                            'Quản lý tài khoản',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text(
                          'Đăng xuất',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.deepPurple,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                CopyableText(
                  text: value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  copyMessage: 'Đã copy $label',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return Colors.red;
      case 'SUB_ADMIN':
        return Colors.orange;
      case 'AGENT':
        return Colors.blue;
      case 'USER':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Quản trị viên';
      case 'SUB_ADMIN':
        return 'Phó quản trị';
      case 'AGENT':
        return 'Đại lý';
      case 'USER':
        return 'Người dùng';
      default:
        return role;
    }
  }
} 