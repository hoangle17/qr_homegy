import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../models/qrcode.dart';
import 'qrcode_detail_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;
import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';

class QRCodeAllScreen extends StatefulWidget {
  const QRCodeAllScreen({super.key});

  @override
  State<QRCodeAllScreen> createState() => _QRCodeAllScreenState();
}

class _QRCodeAllScreenState extends State<QRCodeAllScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;
  String? _error;
  bool _selectionMode = false;
  Set<String> _selectedIds = {};

  static const platform = MethodChannel('qr_homegy.share_channel');

  Future<void> shareImageNative(String filePath) async {
    try {
      await platform.invokeMethod('shareImage', {'filePath': filePath});
    } on PlatformException catch (e) {
      print("Failed to share image: ' {e.message}'.");
    }
  }

  Future<void> shareImagesNative(List<String> filePaths) async {
    try {
      await platform.invokeMethod('shareImages', {'filePaths': filePaths});
    } on PlatformException catch (e) {
      print("Failed to share images: ' {e.message}'.");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchDevices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {}); // Hoặc có thể gọi _fetchDevices() nếu muốn reload dữ liệu
    }
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải danh sách thiết bị: $e';
        _isLoading = false;
      });
    }
  }

  Future<File> _generateQrImageFile(String data, String fileName) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception('QR data invalid');
    }
    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      color: const Color(0xFF000000), // Đen
      emptyColor: const Color(0xFFFFFFFF), // Trắng
      gapless: true,
    );
    final picData = await painter.toImageData(250, format: ui.ImageByteFormat.png); // Kích thước 250
    final bytes = picData!.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tất cả mã QR'),
        actions: _selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Chia sẻ mã đã chọn',
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () async {
                          final selectedMacs = _devices
                              .where((d) => _selectedIds.contains(d['id']?.toString() ?? d['macAddress']))
                              .map((d) => d['macAddress'] ?? '')
                              .where((mac) => mac.isNotEmpty)
                              .toList();
                          List<File> qrFiles = [];
                          for (var mac in selectedMacs) {
                            try {
                              final file = await _generateQrImageFile(mac, mac);
                              qrFiles.add(file);
                            } catch (e) {
                              // Có thể show lỗi nếu cần
                            }
                          }
                          if (qrFiles.isNotEmpty) {
                            await shareImagesNative(qrFiles.map((f) => f.path).toList());
                            if (!mounted) return;
                          }
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Hủy chọn',
                  onPressed: () {
                    setState(() {
                      _selectionMode = false;
                      _selectedIds.clear();
                    });
                  },
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final mac = device['macAddress'] ?? '';
                    final isActive = device['isActive'] == true;
                    final model = device['model'] ?? '';
                    final manufacturer = device['manufacturer'] ?? '';
                    final id = device['id']?.toString() ?? mac;
                    final isSelected = _selectedIds.contains(id);
                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          _selectionMode = true;
                          _selectedIds.add(id);
                        });
                      },
                      child: ListTile(
                        leading: _selectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedIds.add(id);
                                    } else {
                                      _selectedIds.remove(id);
                                      if (_selectedIds.isEmpty) {
                                        _selectionMode = false;
                                      }
                                    }
                                  });
                                },
                              )
                            : null,
                        title: Text('QR: $mac'),
                        subtitle: Text('Trạng thái:  ${isActive ? 'Kích hoạt' : 'Chưa kích hoạt'}\nModel: $model\nHãng: $manufacturer'),
                        isThreeLine: true,
                        trailing: !_selectionMode
                            ? IconButton(
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
                              )
                            : null,
                        onTap: _selectionMode
                            ? () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedIds.remove(id);
                                    if (_selectedIds.isEmpty) {
                                      _selectionMode = false;
                                    }
                                  } else {
                                    _selectedIds.add(id);
                                  }
                                });
                              }
                            : null,
                      ),
                    );
                  },
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