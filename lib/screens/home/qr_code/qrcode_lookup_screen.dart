import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../models/qrcode.dart';
import 'qrcode_detail_screen.dart';

class QRCodeLookupScreen extends StatefulWidget {
  const QRCodeLookupScreen({super.key});

  @override
  State<QRCodeLookupScreen> createState() => _QRCodeLookupScreenState();
}

class _QRCodeLookupScreenState extends State<QRCodeLookupScreen> {
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final devices = await ApiService.getMacDevices();
      setState(() {
        _devices = devices;
        _filtered = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải danh sách thiết bị: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearch(String value) {
    setState(() {
      _search = value.trim();
      String searchNoColon = _search.replaceAll(':', '').toLowerCase();
      if (_search.isEmpty) {
        _filtered = _devices;
      } else {
        _filtered = _devices.where((d) {
          final mac = (d['macAddress'] ?? '').toString();
          final macNoColon = mac.replaceAll(':', '').toLowerCase();
          return macNoColon.contains(searchNoColon);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tra cứu QR Code')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Nhập mã QR', prefixIcon: Icon(Icons.search)),
              onChanged: _onSearch,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _filtered.isEmpty
                          ? const Center(child: Text('Không tìm thấy mã QR nào!'))
                          : ListView.builder(
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final device = _filtered[index];
                                final mac = device['macAddress'] ?? '';
                                final isActive = device['isActive'] == true;
                                final model = device['model'] ?? '';
                                final manufacturer = device['manufacturer'] ?? '';
                                return ListTile(
                                  title: Text('QR: $mac'),
                                  subtitle: Text('Trạng thái: ${isActive ? 'Kích hoạt' : 'Chưa kích hoạt'}\nModel: $model\nHãng: $manufacturer'),
                                  isThreeLine: true,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.qr_code),
                                    tooltip: 'Xem chi tiết',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => QRCodeDetailScreen(
                                            qr: _toQRCodeModel(device),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  QRCodeModel _toQRCodeModel(Map<String, dynamic> device) {
    return QRCodeModel(
      id: device['id'] ?? '',
      orderId: 0,
      customerId: 0,
      isActive: device['isActive'] == true,
      productId: device['skuCode'] ?? '',
      createdAt: DateTime.tryParse(device['createdAt'] ?? '') ?? DateTime.now(),
      genCode: device['macAddress'] ?? '',
    );
  }
} 