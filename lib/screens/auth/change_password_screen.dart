import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final result = await ApiService.changePassword(
      _currentController.text,
      _newController.text,
    );
      
    setState(() { _isLoading = false; });
      
      if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Đổi mật khẩu thành công!'),
              backgroundColor: Colors.green,
            ),
        );
        Navigator.pop(context);
      }
    } else {
      setState(() {
          _error = result['message'] ?? 'Đổi mật khẩu thất bại. Kiểm tra lại mật khẩu cũ hoặc thử lại.';
        });
      }
    } catch (e) {
      setState(() { 
        _isLoading = false;
        _error = 'Lỗi kết nối: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                      const SizedBox(height: 8),
                      Icon(Icons.lock_reset, size: 64, color: Colors.deepPurple),
                      const SizedBox(height: 8),
                      Text('Đổi mật khẩu',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      const SizedBox(height: 32),
              TextFormField(
                controller: _currentController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                          border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureCurrent = !_obscureCurrent;
                      });
                    },
                  ),
                ),
                obscureText: _obscureCurrent,
                validator: (v) => v == null || v.isEmpty ? 'Nhập mật khẩu hiện tại' : null,
              ),
                      const SizedBox(height: 16),
              TextFormField(
                controller: _newController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                          border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureNew = !_obscureNew;
                      });
                    },
                  ),
                ),
                obscureText: _obscureNew,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Nhập mật khẩu mới';
                          if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                          return null;
                        },
              ),
                      const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                          border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirm,
                validator: (v) => v != _newController.text ? 'Mật khẩu xác nhận không khớp' : null,
              ),
              if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
              ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
              ),
            ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 