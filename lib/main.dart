import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    setState(() {
      _isLoggedIn = token != null;
    });
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
