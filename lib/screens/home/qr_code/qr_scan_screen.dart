import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../models/device.dart';
import '../../../models/order.dart';
import '../../../services/api_service.dart';
import 'device_qr_screen.dart';
import 'order_code_detail_screen.dart';

enum QRType {
  macAddress,
  orderId,
  invalid,
}

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;
  String _scannedData = '';
  Device? _foundDevice;
  Order? _foundOrder;

  @override
  void initState() {
    super.initState();
    // Kiểm tra platform khi khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPlatformSupport();
    });
  }

  void _checkPlatformSupport() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _showPlatformNotSupportedDialog();
    }
  }

  void _showPlatformNotSupportedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final data = barcodes.first.rawValue ?? '';
    if (data.isEmpty) return;

    setState(() {
      _isScanning = false;
      _scannedData = data;
    });

    // Kiểm tra loại chuỗi quét được
    final qrType = _getQRType(data);
    
    switch (qrType) {
      case QRType.macAddress:
        await _handleMacAddressQR(data);
        break;
      case QRType.orderId:
        await _handleOrderIdQR(data);
        break;
      case QRType.invalid:
        if (mounted) {
          _showInvalidQRDialog(data);
        }
        break;
    }
    
    // Reset scanning state
    setState(() {
      _isScanning = true;
      _scannedData = '';
      _foundOrder = null;
    });
  }

  QRType _getQRType(String data) {
    // Kiểm tra MAC address format (XX:XX:XX:XX:XX:XX) với X là bất kỳ ký tự
    final macRegex = RegExp(r'^([A-Za-z0-9]{2}[:-]){5}([A-Za-z0-9]{2})$');
    if (macRegex.hasMatch(data)) {
      return QRType.macAddress;
    }
    
    // Kiểm tra UUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx) với x là bất kỳ ký tự
    final uuidRegex = RegExp(r'^[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}$');
    if (uuidRegex.hasMatch(data)) {
      return QRType.orderId;
    }
    
    return QRType.invalid;
  }

    Future<void> _handleMacAddressQR(String macAddress) async {
    try {
      final device = await ApiService.getDeviceByMacAddress(macAddress);

      if (device != null) {
        setState(() {
          _foundDevice = device;
        });

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceQrScreen(
                device: device,
                macAddress: device.macAddress,
              ),
            ),
          );
          }
      } else {
        if (mounted) {
          _showDeviceNotFoundDialog(macAddress);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Lỗi khi tìm kiếm device: $e');
      }
    }
  }

  Future<void> _handleOrderIdQR(String orderId) async {
    try {
      final order = await ApiService.getOrderDetail(orderId);
      
      if (order != null) {
    setState(() {
          _foundOrder = order;
    });

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderCodeDetailScreen(
                order: order,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          _showOrderNotFoundDialog(orderId);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Lỗi khi lấy chi tiết đơn hàng: $e');
  }
    }
  }

  void _showOrderNotFoundDialog(String scannedData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.search_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Không tìm thấy đơn hàng'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Không tìm thấy đơn hàng với mã:'),
              const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                scannedData,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vui lòng kiểm tra lại mã QR hoặc thử lại.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeviceNotFoundDialog(String macAddress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.search_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Không tìm thấy device'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Không tìm thấy device với MAC address:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                macAddress,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vui lòng kiểm tra lại mã QR hoặc thử lại.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInvalidQRDialog(String scannedData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_2, color: Colors.red),
            SizedBox(width: 8),
            Text('QR Code không hợp lệ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QR Code này không đúng định dạng. Chỉ hỗ trợ:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              '• MAC Address: XX:XX:XX:XX:XX:XX (X = số hoặc chữ) - Tìm device',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Text(
              '• Order ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx (x = số hoặc chữ) - Tìm đơn hàng',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              'Chuỗi quét được:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                scannedData,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị thông báo không hỗ trợ cho web
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    Icons.warning,
                    size: 60,
                    color: Colors.orange,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Không hỗ trợ trên nền tảng này',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tính năng Scan QR Code chỉ khả dụng trên ứng dụng mobile (Android/iOS).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Vui lòng sử dụng nút Back hoặc chuyển tab để quay lại',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          // Overlay hướng dẫn
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Đặt mã QR vào khung để quét',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          // Khung quét đơn giản (bỏ khung phức tạp)
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.deepPurple,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 