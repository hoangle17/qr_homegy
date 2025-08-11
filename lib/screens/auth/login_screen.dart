import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final void Function(int userId) onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  String? _error;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Hàm mã hóa mật khẩu đơn giản (Base64 + XOR)
  String _encryptPassword(String password) {
    final bytes = utf8.encode(password);
    final encoded = base64.encode(bytes);
    // XOR với key đơn giản
    final key = 'QR_HOMEGY_2024';
    String encrypted = '';
    for (int i = 0; i < encoded.length; i++) {
      encrypted += String.fromCharCode(encoded.codeUnitAt(i) ^ key.codeUnitAt(i % key.length));
    }
    return base64.encode(utf8.encode(encrypted));
  }

  // Hàm giải mã mật khẩu
  String _decryptPassword(String encryptedPassword) {
    try {
      final encryptedBytes = base64.decode(encryptedPassword);
      final encrypted = utf8.decode(encryptedBytes);
      final key = 'QR_HOMEGY_2024';
      String decrypted = '';
      for (int i = 0; i < encrypted.length; i++) {
        decrypted += String.fromCharCode(encrypted.codeUnitAt(i) ^ key.codeUnitAt(i % key.length));
      }
      final decodedBytes = base64.decode(decrypted);
      return utf8.decode(decodedBytes);
    } catch (e) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
    
    // Load saved credentials if remember me was enabled
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveUserInfo(Map<String, dynamic> loginResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', loginResponse['token']);
    await prefs.setString('user_email', loginResponse['user']['email']);
    await prefs.setString('user_info', jsonEncode(loginResponse['user']));
    
    // Lưu email và mật khẩu nếu chọn "Ghi nhớ đăng nhập"
    if (_rememberMe) {
      await prefs.setString('saved_email', loginResponse['user']['email']);
      // Mã hóa mật khẩu trước khi lưu
      final encryptedPassword = _encryptPassword(_passwordController.text);
      await prefs.setString('saved_password', encryptedPassword);
      await prefs.setBool('remember_me', true);
    } else {
      // Xóa email và mật khẩu đã lưu nếu không chọn "Ghi nhớ đăng nhập"
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    
    if (rememberMe) {
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');
      
      if (savedEmail != null && savedEmail.isNotEmpty) {
        setState(() {
          _phoneController.text = savedEmail;
          _rememberMe = true;
        });
        
        // Tự động điền mật khẩu nếu có (giải mã trước)
        if (savedPassword != null && savedPassword.isNotEmpty) {
          final decryptedPassword = _decryptPassword(savedPassword);
          if (decryptedPassword.isNotEmpty) {
            _passwordController.text = decryptedPassword;
          }
        }
      }
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    final email = _phoneController.text.trim();
    final pass = _passwordController.text;
    setState(() {
      _error = null;
      _isLoading = true;
    });
    
    try {
      final loginResponse = await ApiService.login(email, pass);
    setState(() { _isLoading = false; });
      
      if (loginResponse != null) {
        await _saveUserInfo(loginResponse);
        widget.onLoginSuccess(0);
    } else {
      setState(() {
        _error = 'Sai email hoặc mật khẩu, hoặc lỗi server!';
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
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade500,
              Colors.purple.shade400,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 450 : size.width * 0.95,
                  maxHeight: size.height * 0.95,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Card(
                    elevation: 20,
                    shadowColor: Colors.black.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isWide ? 32.0 : 24.0),
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                              // Logo and Title Section
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.deepPurple.shade400,
                                      Colors.purple.shade300,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.deepPurple.withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.qr_code_2,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'QR Homegy',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                    const SizedBox(height: 8),
                              Text(
                                'Đăng nhập để tiếp tục',
                        textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                    const SizedBox(height: 32),
                              
                              // Email Field
                              TextFormField(
                      controller: _phoneController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                focusNode: _emailFocusNode,
                                onFieldSubmitted: (value) {
                                  // Focus vào field password khi nhấn Enter
                                  _passwordFocusNode.requestFocus();
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Email không hợp lệ';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'example@email.com',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: Colors.deepPurple.shade400,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Password Field
                              TextFormField(
                      controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                focusNode: _passwordFocusNode,
                                onFieldSubmitted: (value) {
                                  // Khi nhấn Enter ở field password, thực hiện đăng nhập
                                  if (!_isLoading) {
                                    _login();
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập mật khẩu';
                                  }
                                  if (value.length < 6) {
                                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                                  }
                                  return null;
                                },
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                                  hintText: 'Nhập mật khẩu của bạn',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: Colors.deepPurple.shade400,
                                  ),
                        suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey.shade600,
                                    ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Remember Me & Forgot Password
                              if (isWide)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                          activeColor: Colors.deepPurple.shade400,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        Text(
                                          'Ghi nhớ đăng nhập',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Quên mật khẩu?',
                                        style: TextStyle(
                                          color: Colors.deepPurple.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                          activeColor: Colors.deepPurple.shade400,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        Text(
                                          'Ghi nhớ đăng nhập',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Quên mật khẩu?',
                                        style: TextStyle(
                                          color: Colors.deepPurple.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              
                              // Error Message
                    if (_error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                    ],
                                  ),
                                ),
                              ],
                              
                    const SizedBox(height: 24),
                              
                              // Login Button
                    SizedBox(
                                height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple.shade600,
                          foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: Colors.deepPurple.withValues(alpha: 0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                        ),
                        child: _isLoading
                                      ? Row(
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
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Đang đăng nhập...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          'Đăng nhập',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Footer
                              if (isWide)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Chưa có tài khoản? ',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // TODO: Navigate to register screen
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Tính năng đăng ký sẽ được phát triển sau'),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Đăng ký ngay',
                                        style: TextStyle(
                                          color: Colors.deepPurple.shade600,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    Text(
                                      'Chưa có tài khoản?',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextButton(
                                      onPressed: () {
                                        // TODO: Navigate to register screen
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Tính năng đăng ký sẽ được phát triển sau'),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Đăng ký ngay',
                                        style: TextStyle(
                                          color: Colors.deepPurple.shade600,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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