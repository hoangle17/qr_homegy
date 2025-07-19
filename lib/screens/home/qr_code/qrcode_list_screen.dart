import 'package:flutter/material.dart';
import 'qrcode_all_screen.dart';
import 'qrcode_create_screen.dart';

class QRCodeScreen extends StatelessWidget {
  const QRCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mã QR')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.list),
                label: const Text('Xem tất cả', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QRCodeAllScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              height: 56,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Tạo mã QR', style: TextStyle(fontSize: 18)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: Colors.deepPurple, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QRCodeCreateScreen()),
                  );
                }, // Chưa có action
              ),
            ),
          ],
        ),
      ),
    );
  }
} 