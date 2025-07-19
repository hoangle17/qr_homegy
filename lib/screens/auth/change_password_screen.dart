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
    final success = await ApiService.changePassword(
      _currentController.text,
      _newController.text,
    );
    setState(() { _isLoading = false; });
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công!')),
        );
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _error = 'Đổi mật khẩu thất bại. Kiểm tra lại mật khẩu cũ hoặc thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _currentController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
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
              TextFormField(
                controller: _newController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
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
                validator: (v) => v == null || v.isEmpty ? 'Nhập mật khẩu mới' : null,
              ),
              TextFormField(
                controller: _confirmController,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
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
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Xác nhận'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 