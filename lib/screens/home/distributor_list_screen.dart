import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import 'distributor_form_screen.dart';
import 'user_add_screen.dart';

class DistributorListScreen extends StatefulWidget {
  const DistributorListScreen({super.key});

  @override
  State<DistributorListScreen> createState() => _DistributorListScreenState();
}

class _DistributorListScreenState extends State<DistributorListScreen> {
  String _search = '';
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;
  String? _userRole;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _checkUserAccess();
  }

  Future<void> _checkUserAccess() async {
    try {
      final userRole = await ApiService.getCurrentUserRole();
      setState(() {
        _userRole = userRole;
        _hasAccess = userRole == 'ADMIN' || userRole == 'SUB_ADMIN';
      });
      
      if (_hasAccess) {
        _loadUsers();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi kiểm tra quyền truy cập: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await ApiService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải danh sách: $e';
        _isLoading = false;
      });
    }
  }

  List<User> get _filteredUsers {
    return _users.where((u) {
      final query = _search.toLowerCase();
      return u.name.toLowerCase().contains(query) ||
          u.phone.toLowerCase().contains(query) || 
          (u.address?.toLowerCase().contains(query) ?? false) ||
          u.email.toLowerCase().contains(query);
    }).toList();
  }

  void _showAddUserScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserAddScreen(
          onUserAdded: _loadUsers,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteUser(User user) async {
    // Kiểm tra quyền admin
    if (_userRole != 'ADMIN') {
      _showPermissionDeniedDialog();
      return;
    }

    // Hiển thị dialog xác nhận xóa
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn có chắc chắn muốn xóa người dùng này?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tên: ${user.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Email: ${user.email}'),
                  Text('Vai trò: ${_getRoleDisplayName(user.role)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hành động này không thể hoàn tác!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    // Nếu user xác nhận xóa, thực hiện xóa
    if (confirmed == true) {
      await _deleteUser(user);
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.orange),
            SizedBox(width: 8),
            Text('Không có quyền'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chỉ ADMIN mới có quyền xóa người dùng.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Vai trò hiện tại của bạn không đủ quyền để thực hiện hành động này.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(User user) async {
    try {
      final success = await ApiService.deleteUser(user.id);
      
      if (success) {
        // Xóa user khỏi danh sách local
        setState(() {
          _users.removeWhere((u) => u.id == user.id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa người dùng ${user.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi xóa người dùng'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa người dùng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách tài khoản'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_hasAccess) ...[
            // IconButton(
            //   icon: const Icon(Icons.add),
            //   tooltip: 'Thêm tài khoản mới',
            //   onPressed: _showAddUserScreen,
            // ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới',
              onPressed: _loadUsers,
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasAccess) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Quyền truy cập bị hạn chế',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chỉ ADMIN và SUB_ADMIN mới có quyền xem danh sách người dùng',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vai trò hiện tại: ${_getRoleDisplayName(_userRole ?? 'UNKNOWN')}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Thử lại'),
          ),
        ],
      ),
      );
    }

    return Column(
        children: [
          Padding(
          padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
              labelText: 'Tìm kiếm theo tên, email, số điện thoại, địa chỉ',
              hintText: 'Nhập từ khóa tìm kiếm...',
                prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
            ),
          ),
        if (_filteredUsers.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _search.isEmpty ? 'Không có người dùng nào' : 'Không tìm thấy kết quả',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return Slidable(
                  key: Key(user.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) => _confirmDeleteUser(user),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Xóa',
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRoleColor(user.role),
                        child: Icon(
                          _iconForType(user.role),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${user.email}'),
                          Text('SĐT: ${user.phone}'),
                          if (user.address != null && user.address!.isNotEmpty)
                            Text('Địa chỉ: ${user.address}'),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.role).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getRoleColor(user.role)),
                            ),
                            child: Text(
                              _getRoleDisplayName(user.role),
                              style: TextStyle(
                                color: _getRoleColor(user.role),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DistributorFormScreen(user: user),
                            ),
                          );
                          _loadUsers(); // Refresh list after edit
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
    );
  }

  IconData _iconForType(String role) {
    switch (role) {
      case 'ADMIN':
        return Icons.admin_panel_settings;
      case 'SUB_ADMIN':
        return Icons.manage_accounts;
      case 'AGENT':
        return Icons.store;
      case 'USER':
        return Icons.person;
      default:
        return Icons.person;
    }
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
        return 'Khách lẻ';
      default:
        return role;
    }
  }
}

 