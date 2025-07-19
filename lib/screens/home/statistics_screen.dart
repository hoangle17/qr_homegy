import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê QR Code')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          ListTile(
            title: Text('Số lượng QRCode đã kích hoạt'),
            subtitle: Text('Theo đơn hàng, khách hàng...'),
          ),
          ListTile(
            title: Text('Số lượng QRCode chưa kích hoạt'),
            subtitle: Text('Theo đơn hàng, khách hàng...'),
          ),
          ListTile(
            title: Text('Tra cứu QR đã tạo'),
            subtitle: Text('Đơn hàng, khách hàng, sản phẩm, trạng thái...'),
          ),
        ],
      ),
    );
  }
} 