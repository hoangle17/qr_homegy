import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class UserAddScreen extends StatefulWidget {
  final VoidCallback? onUserAdded;
  
  const UserAddScreen({super.key, this.onUserAdded});

  @override
  State<UserAddScreen> createState() => _UserAddScreenState();
}

class _UserAddScreenState extends State<UserAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        region: 'VN',
      );

      if (mounted) {
        if (result['success'] == true) {
          // Hiển thị thông báo thành công
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Đăng ký tài khoản thành công!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Gọi callback để refresh danh sách
          widget.onUserAdded?.call();
          
          // Quay lại màn hình trước
          Navigator.pop(context);
        } else {
          // Hiển thị lỗi
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Đăng ký tài khoản thất bại!'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
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
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm tài khoản mới'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_add,
                      size: 48,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Thêm tài khoản mới',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Điền thông tin để tạo tài khoản mới',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'Nhập email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu *',
                  hintText: 'Nhập mật khẩu',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên *',
                  hintText: 'Nhập họ và tên',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  if (value.trim().length < 2) {
                    return 'Họ và tên phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Đang tạo tài khoản...'),
                          ],
                        )
                      : const Text(
                          'Tạo tài khoản',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tài khoản mới sẽ được tạo với vai trò USER. Người dùng cần xác thực email để kích hoạt tài khoản.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 