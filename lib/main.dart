import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      // Nếu có token, gọi API để lấy thông tin profile mới nhất
      try {
        final userProfile = await ApiService.getCurrentUserProfile();
        if (userProfile != null) {
          // Cập nhật thông tin user thành công
          setState(() {
            _isLoggedIn = true;
          });
        } else {
          // Token không hợp lệ hoặc API lỗi, xóa token
          await prefs.remove('auth_token');
          await prefs.remove('user_info');
          await prefs.remove('user_email');
          setState(() {
            _isLoggedIn = false;
          });
        }
      } catch (e) {
        // Lỗi kết nối, vẫn cho phép đăng nhập với thông tin cũ
        setState(() {
          _isLoggedIn = true;
        });
      }
    } else {
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  void _onLoginSuccess(int userId) {
    setState(() {
      _isLoggedIn = true;
      _userId = userId;
    });
  }

  void _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    setState(() {
      _isLoggedIn = false;
      _userId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Homegy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: _isLoggedIn
          ? HomeScreen(userId: _userId ?? 0, onLogout: _onLogout)
          : LoginScreen(onLoginSuccess: _onLoginSuccess),
    );
  }
}
