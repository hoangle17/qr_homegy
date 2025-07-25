import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:media_store_plus/media_store_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../../../models/device.dart';
import '../../../services/api_service.dart';
import 'qr_save_mobile.dart'
    if (dart.library.html) 'qr_save_web.dart';

class DeviceQrScreen extends StatefulWidget {
  final Device device;
  final String macAddress;
  final VoidCallback? onDeviceUpdated;
  
  const DeviceQrScreen({
    super.key, 
    required this.device,
    required this.macAddress,
    this.onDeviceUpdated,
  });

  @override
  State<DeviceQrScreen> createState() => _DeviceQrScreenState();
}

class _DeviceQrScreenState extends State<DeviceQrScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isLoading = false;
  bool _isDeactivating = false;
  static const platform = MethodChannel('qr_homegy.share_channel');

  Future<void> shareImageNative(String filePath) async {
    try {
      await platform.invokeMethod('shareImage', {'filePath': filePath});
    } on PlatformException catch (e) {
      print("Failed to share image: ' {e.message}'.");
    }
  }

  Future<void> _shareQRCode() async {
    if (kIsWeb) {
      // Trên web: tạo QR và tải về
      try {
        final Uint8List? qrImageBytes = await _captureQRCode();
        if (qrImageBytes == null) {
          _showSnackBar('Lỗi khi tạo ảnh QR');
          return;
        }
        // ignore: undefined_function
        shareQrWeb(qrImageBytes);
        _showSnackBar('Đã tải ảnh QR về máy!');
      } catch (e) {
        _showSnackBar('Lỗi khi tải ảnh QR: $e');
      }
      return;
    }
    try {
      // Sử dụng method _captureQRCode() hiện có để lấy ảnh QR
      final Uint8List? qrImageBytes = await _captureQRCode();
      if (qrImageBytes == null) {
        _showSnackBar('Lỗi khi tạo ảnh QR');
        return;
      }

      // Tạo ảnh với padding trắng
      final decodedImage = img.decodeImage(qrImageBytes);
      if (decodedImage == null) {
        _showSnackBar('Lỗi khi xử lý ảnh QR');
        return;
      }

      // Tạo ảnh mới với padding
      final padding = 50;
      final newWidth = decodedImage.width + (padding * 2);
      final newHeight = decodedImage.height + (padding * 2);
      
      // Tạo ảnh trắng mới
      final newImage = img.Image(width: newWidth, height: newHeight);
      
      // Fill background trắng
      for (int y = 0; y < newHeight; y++) {
        for (int x = 0; x < newWidth; x++) {
          newImage.setPixel(x, y, img.ColorRgb8(255, 255, 255));
        }
      }
      
      // Copy QR code vào giữa
      for (int y = 0; y < decodedImage.height; y++) {
        for (int x = 0; x < decodedImage.width; x++) {
          final pixel = decodedImage.getPixel(x, y);
          newImage.setPixel(x + padding, y + padding, pixel);
        }
      }
      
      // Encode thành PNG
      final pngBytes = img.encodePng(newImage);
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/qr_code_share.png');
      await tempFile.writeAsBytes(pngBytes);
      await shareImageNative(tempFile.path);
    } catch (e) {
      _showSnackBar('Lỗi khi chia sẻ: $e');
      print('Lỗi khi chia sẻ: $e');
    }
  }

  Future<void> _saveQRCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Uint8List? qrImageBytes = await _captureQRCode();
      if (qrImageBytes == null) {
        setState(() { _isLoading = false; });
        return;
      }

      if (kIsWeb) {
        // ignore: undefined_function
        saveQrWeb(qrImageBytes);
        _showSnackBar('Đã tải ảnh QR về máy!');
        setState(() { _isLoading = false; });
        return;
      }

      await MediaStore.ensureInitialized();
      final storageStatus = await Permission.storage.request();
      final photosStatus = await Permission.photos.request();
      if (!storageStatus.isGranted && !photosStatus.isGranted) {
        _showSnackBar('Cần quyền truy cập bộ nhớ/ảnh để lưu ảnh');
        setState(() { _isLoading = false; });
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);

      final decodedImage = img.decodeImage(qrImageBytes);
      if (decodedImage == null) {
        _showSnackBar('Lỗi: Không decode được ảnh PNG sang JPG');
        setState(() { _isLoading = false; });
        return;
      }
      final jpgBytes = img.encodeJpg(decodedImage, quality: 95);
      await file.writeAsBytes(jpgBytes);

      MediaStore.appFolder = "QR_Generator";

      final result = await MediaStore().saveFile(
        tempFilePath: filePath,
        dirType: DirType.photo,
        dirName: DirName.pictures,
      );
      if (result != null) {
        _showSnackBar('Đã lưu ảnh QR vào Ảnh/Gallery!');
      } else {
        _showSnackBar('Lỗi khi lưu ảnh!');
      }
      await file.delete();
    } catch (e) {
      // _showSnackBar('Lỗi khi lưu ảnh: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Uint8List?> _captureQRCode() async {
    try {
      if (_qrKey.currentContext == null) {
        _showSnackBar('Lỗi: Không tìm thấy context của QR code');
        return null;
      }
      final renderObject = _qrKey.currentContext!.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        _showSnackBar('Lỗi: Không tìm thấy render object');
        return null;
      }
      final RenderRepaintBoundary boundary = renderObject;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showSnackBar('Lỗi: Không thể chuyển đổi ảnh thành bytes');
        return null;
      }
      return byteData.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _deactivateDevice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Deactivate Device'),
        content: Text(
          'Bạn có chắc chắn muốn vô hiệu hóa device này?\n\n'

          'Hành động này không thể hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeactivating = true;
    });

    try {
      final success = await ApiService.deactivateDevice(widget.macAddress);
      
      if (success) {
        // Cập nhật trạng thái local
        final updatedDevice = Device(
          id: widget.device.id,
          macAddress: widget.device.macAddress,
          serialNumber: widget.device.serialNumber,
          thingID: widget.device.thingID,
          paymentStatus: 'cancelled', // Cập nhật payment status thành cancelled
          isActive: false, // Chuyển về trạng thái không hoạt động
          createdAt: widget.device.createdAt,
          manufacturer: widget.device.manufacturer,
          model: widget.device.model,
          firmwareVersion: widget.device.firmwareVersion,
          activatedAt: widget.device.activatedAt,
          activatedBy: widget.device.activatedBy,
          orderId: widget.device.orderId,
          price: widget.device.price,
          createdBy: widget.device.createdBy,
          customerId: widget.device.customerId,
          skuCode: widget.device.skuCode,
        );
        
        // Trigger rebuild để hiển thị trạng thái mới
        setState(() {});
        
        // Gọi callback để reload danh sách
        widget.onDeviceUpdated?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã vô hiệu hóa device thành công!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi vô hiệu hóa device!'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi vô hiệu hóa: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isDeactivating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Device'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: widget.macAddress,
                      version: QrVersions.auto,
                      size: 250.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _shareQRCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.share),
                          label: const Text('Chia sẻ', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveQRCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isLoading ? 'Đang lưu...' : 'Lưu ảnh', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Thông tin Device
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Thông tin Device',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('MAC Address:', widget.macAddress),
                      _buildInfoRow('SKU Code:', widget.device.skuCode),
                      _buildInfoRow('ThingID:', widget.device.thingID != null && widget.device.thingID!.isNotEmpty 
                        ? widget.device.thingID! 
                        : 'Chờ cập nhật'),
                      _buildInfoRow('Payment Status:', widget.device.paymentStatus),
                      if (widget.device.serialNumber != null)
                        _buildInfoRow('Serial Number:', widget.device.serialNumber!),
                      if (widget.device.manufacturer != null)
                        _buildInfoRow('Manufacturer:', widget.device.manufacturer!),
                      if (widget.device.model != null)
                        _buildInfoRow('Model:', widget.device.model!),
                      if (widget.device.firmwareVersion != null)
                        _buildInfoRow('Firmware:', widget.device.firmwareVersion!),
                      if (widget.device.price != null)
                        _buildInfoRow('Price:', '\$${widget.device.price}'),
                      _buildInfoRow('Created Date:', widget.device.createdAt.toString().substring(0, 16)),
                      if (widget.device.activatedAt != null)
                        _buildInfoRow('Activated Date:', widget.device.activatedAt.toString().substring(0, 16)),
                      if (widget.device.activatedBy != null)
                        _buildInfoRow('Activated By:', widget.device.activatedBy!),
                      if (widget.device.createdBy != null)
                        _buildInfoRow('Created By:', widget.device.createdBy!),
                      if (widget.device.customerId != null)
                        _buildInfoRow('Customer ID:', widget.device.customerId!),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Trạng thái: '),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.device.isActive ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.device.isActive ? 'kích hoạt' : 'chưa kích hoạt',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Nút Deactivate Device - chỉ hiển thị khi device đang active
                      // if (widget.device.isActive)
                      //   SizedBox(
                      //     width: double.infinity,
                      //     child: ElevatedButton.icon(
                      //       onPressed: _isDeactivating ? null : _deactivateDevice,
                      //       style: ElevatedButton.styleFrom(
                      //         backgroundColor: Colors.red,
                      //         foregroundColor: Colors.white,
                      //         padding: const EdgeInsets.symmetric(vertical: 12),
                      //         shape: RoundedRectangleBorder(
                      //           borderRadius: BorderRadius.circular(8),
                      //         ),
                      //       ),
                      //       icon: _isDeactivating
                      //           ? const SizedBox(
                      //               width: 16,
                      //               height: 16,
                      //               child: CircularProgressIndicator(
                      //                 strokeWidth: 2,
                      //                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      //               ),
                      //             )
                      //           : const Icon(Icons.block),
                      //       label: Text(
                      //         _isDeactivating ? 'Đang deactivate...' : 'Deactivate Device',
                      //         style: const TextStyle(fontWeight: FontWeight.bold),
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 