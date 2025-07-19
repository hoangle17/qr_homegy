import 'package:flutter/material.dart';
import 'distributor_list_screen.dart';
import 'qr_code/qrcode_list_screen.dart';
import 'statistics_screen.dart';
import 'qr_code/qrcode_lookup_screen.dart';
import '../auth/change_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final VoidCallback onLogout;
  const HomeScreen({super.key, required this.userId, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Trang chủ'),
      // ),
      body: _buildScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'NPP/ĐL/Khách lẻ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'Mã QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Tra cứu QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
          
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 0:
        return const DistributorListScreen();
      case 1:
        return const QRCodeScreen();
      case 2:
        return const QRCodeLookupScreen();
      case 3:
        return const StatisticsScreen();
      case 4:
        return AccountScreen(onLogout: widget.onLogout);
      default:
        return const SizedBox();
    }
  }
} 