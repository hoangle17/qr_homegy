import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../../models/device.dart';
import '../../services/api_service.dart';
import 'qr_code/qr_scan_screen.dart';
import 'qr_code/device_qr_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Device> _devices = [];
  List<Device> _filteredDevices = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _searchController.addListener(_filterDevices);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final devices = await ApiService.getAllDevices();
      setState(() {
        _devices = devices;
        _filteredDevices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải danh sách devices: $e';
        _isLoading = false;
      });
    }
  }

  void _filterDevices() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredDevices = _devices;
      });
    } else {
      setState(() {
        _filteredDevices = _devices.where((device) {
          return device.macAddress.toLowerCase().contains(query) ||
                 device.skuCode.toLowerCase().contains(query) ||
                 (device.customerId?.toLowerCase().contains(query) ?? false) ||
                 device.paymentStatus.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  void _showScanQR(BuildContext context) {
    // Kiểm tra platform trước khi mở scan
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _showPlatformNotSupportedDialog(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScanScreen()),
      );
    }
  }

  void _showPlatformNotSupportedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Không hỗ trợ'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tính năng Scan QR Code chỉ hỗ trợ trên ứng dụng mobile.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'Vui lòng sử dụng ứng dụng trên thiết bị Android hoặc iOS để scan mã QR.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê Devices'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadDevices,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR Code',
            onPressed: () => _showScanQR(context),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDevices,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }



    return Column(
      children: [
        // Thống kê tổng quan
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
                             _buildStatCard(
                 'Tổng số',
                 _filteredDevices.length.toString(),
                 Icons.devices_other,
                 Colors.blue,
               ),
               _buildStatCard(
                 'Đã kích hoạt',
                 _filteredDevices.where((d) => d.isActive).length.toString(),
                 Icons.check_circle,
                 Colors.green,
               ),
               _buildStatCard(
                 'Chưa kích hoạt',
                 _filteredDevices.where((d) => !d.isActive).length.toString(),
                 Icons.cancel,
                 Colors.red,
               ),
            ],
          ),
        ),
        // Tìm kiếm
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo MAC, SKU, Customer, Payment...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          ),
        const SizedBox(height: 16),
        // Danh sách devices
        Expanded(
          child: _filteredDevices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.devices_other, color: Colors.grey, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isNotEmpty 
                            ? 'Không tìm thấy device nào phù hợp'
                            : 'Không có device nào',
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredDevices.length,
                  itemBuilder: (context, index) {
                    final device = _filteredDevices[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          device.macAddress,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SKU: ${device.skuCode}'),
                            Text('Payment: ${device.paymentStatus}'),
                            if (device.customerId != null)
                              Text('Customer: ${device.customerId}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: device.isActive ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                device.isActive ? 'Kích hoạt' : 'Chưa kích hoạt',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.qr_code),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeviceQrScreen(
                                device: device,
                                macAddress: device.macAddress,
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
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
