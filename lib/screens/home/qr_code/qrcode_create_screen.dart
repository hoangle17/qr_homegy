import 'package:flutter/material.dart';

class QRCodeCreateScreen extends StatelessWidget {
  const QRCodeCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo mã QR')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(labelText: 'Số lượng mã cần tạo'),
              keyboardType: TextInputType.number,
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Tên khách hàng'),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Thông tin đơn hàng'),
            ),
            DropdownButtonFormField<String>(
              items: const [
                DropdownMenuItem(value: 'paid', child: Text('Đã thanh toán')),
                DropdownMenuItem(value: 'unpaid', child: Text('Chưa thanh toán')),
                DropdownMenuItem(value: 'free', child: Text('Free')),
              ],
              onChanged: (value) {},
              decoration: const InputDecoration(labelText: 'Trạng thái đơn hàng'),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'ProductID (Mã sản phẩm)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Tạo mã'),
            ),
          ],
        ),
      ),
    );
  }
} 