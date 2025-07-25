import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

class DistributorFormScreen extends StatefulWidget {
  final User? user;
  const DistributorFormScreen({super.key, this.user});

  @override
  State<DistributorFormScreen> createState() => _DistributorFormScreenState();
}

class _DistributorFormScreenState extends State<DistributorFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  String? _role;
  bool _isLoading = false;
  String? _currentUserRole;
  bool _canChangeRole = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _addressController = TextEditingController(text: widget.user?.address ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _role = widget.user?.role;
    _checkUserPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkUserPermissions() async {
    try {
      final currentUserRole = await ApiService.getCurrentUserRole();
      setState(() {
        _currentUserRole = currentUserRole;
        _canChangeRole = currentUserRole == 'ADMIN';
      });
    } catch (e) {
      setState(() {
        _currentUserRole = null;
        _canChangeRole = false;
      });
    }
  }

  void _saveProfile() async {
    if (widget.user == null) return;
    
    // Check if user has permission to update profile
    if (_currentUserRole != 'ADMIN' && _currentUserRole != 'SUB_ADMIN') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chỉ ADMIN và SUB_ADMIN mới có quyền cập nhật thông tin'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare only changed fields
      final Map<String, String?> changedFields = {};
      
      if (_nameController.text.trim() != widget.user!.name) {
        changedFields['name'] = _nameController.text.trim();
      }
      if (_phoneController.text.trim() != widget.user!.phone) {
        changedFields['phone'] = _phoneController.text.trim();
      }
      if (_addressController.text.trim() != (widget.user!.address ?? '')) {
        changedFields['address'] = _addressController.text.trim();
      }
      
      // Update user profile with only changed fields
      final profileResult = await ApiService.updateUserProfile(
        name: changedFields['name'],
        phone: changedFields['phone'],
        address: changedFields['address'],
      );

      if (profileResult['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(profileResult['message']),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(profileResult['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveRole() async {
    if (widget.user == null || _role == null) return;
    
    // Check if user has permission to change role
    if (!_canChangeRole) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chỉ ADMIN mới có quyền thay đổi vai trò'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check if role actually changed
    if (_role == widget.user!.role) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vai trò không thay đổi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final roleResult = await ApiService.updateUserRole(
        targetUserId: widget.user!.id,
        newRole: _role!,
        );

      if (roleResult['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(roleResult['message']),
              backgroundColor: Colors.green,
            ),
          );
      Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(roleResult['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Thông tin'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Không thể chỉnh sửa thông tin người dùng không tồn tại'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.person),
              text: 'Thông tin cá nhân',
            ),
            Tab(
              icon: Icon(Icons.admin_panel_settings),
              text: 'Thay đổi vai trò',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Thông tin cá nhân
          _buildProfileTab(),
          // Tab 2: Thay đổi vai trò
          _buildRoleTab(),
        ],
      ),
    );
  }

  Color _getPermissionColor() {
    if (_currentUserRole == 'ADMIN') return Colors.green;
    if (_currentUserRole == 'SUB_ADMIN') return Colors.blue;
    return Colors.red;
  }

  IconData _getPermissionIcon() {
    if (_currentUserRole == 'ADMIN') return Icons.admin_panel_settings;
    if (_currentUserRole == 'SUB_ADMIN') return Icons.manage_accounts;
    return Icons.block;
  }

  String _getPermissionText() {
    if (_currentUserRole == 'ADMIN') {
      return 'Bạn có quyền cập nhật thông tin và thay đổi vai trò người dùng';
    }
    if (_currentUserRole == 'SUB_ADMIN') {
      return 'Bạn có quyền cập nhật thông tin người dùng';
    }
    return 'Bạn không có quyền cập nhật thông tin người dùng';
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
            // Permission info card
            if (_currentUserRole != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getPermissionColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getPermissionColor()),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getPermissionIcon(),
                          color: _getPermissionColor(),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quyền truy cập',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getPermissionColor(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPermissionText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getPermissionColor(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
              TextFormField(
                controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên',
                border: OutlineInputBorder(),
              ),
              // Bỏ validation check - cho phép để trống
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              enabled: false, // Email không được phép sửa
            ),
            const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                border: OutlineInputBorder(),
              ),
              // Bỏ validation check - cho phép để trống
            ),
            const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
              ),
              // Bỏ validation check - cho phép để trống
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Cập nhật thông tin'),
              ),
            ),
            // Add extra padding at bottom to prevent overflow
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Permission info card
          if (_currentUserRole != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getPermissionColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getPermissionColor()),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getPermissionIcon(),
                        color: _getPermissionColor(),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quyền truy cập',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getPermissionColor(),
                        ),
                      ),
                ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPermissionText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getPermissionColor(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Current role info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vai trò hiện tại:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
              ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRoleColor(widget.user?.role ?? ''),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getRoleDisplayName(widget.user?.role ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ),
            ],
          ),
        ),
          const SizedBox(height: 24),

          // Role selection
          DropdownButtonFormField<String>(
            value: _role,
            items: const [
              DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên')),
              DropdownMenuItem(value: 'SUB_ADMIN', child: Text('Phó quản trị')),
              DropdownMenuItem(value: 'AGENT', child: Text('Đại lý')),
              DropdownMenuItem(value: 'USER', child: Text('Người dùng')),
            ],
            onChanged: _canChangeRole ? (value) => setState(() => _role = value) : null,
            decoration: InputDecoration(
              labelText: 'Chọn vai trò mới',
              border: const OutlineInputBorder(),
              suffixIcon: !_canChangeRole 
                ? const Icon(Icons.lock, color: Colors.grey)
                : null,
            ),
          ),
          if (!_canChangeRole) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chỉ ADMIN mới có quyền thay đổi vai trò người dùng khác',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading || !_canChangeRole ? null : _saveRole,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Cập nhật vai trò'),
            ),
          ),
          // Add extra padding at bottom to prevent overflow
          const SizedBox(height: 32),
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