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
import '../../../models/qrcode.dart';
import 'qr_save_mobile.dart'
    if (dart.library.html) 'qr_save_web.dart';

class QRCodeDetailScreen extends StatefulWidget {
  final QRCodeModel qr;
  const QRCodeDetailScreen({super.key, required this.qr});

  @override
  State<QRCodeDetailScreen> createState() => _QRCodeDetailScreenState();
}

class _QRCodeDetailScreenState extends State<QRCodeDetailScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isLoading = false;
  static const platform = MethodChannel('qr_homegy.share_channel');

  Future<void> shareImageNative(String filePath) async {
    try {
      await platform.invokeMethod('shareImage', {'filePath': filePath});
    } on PlatformException catch (e) {
      print("Failed to share image: ' {e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết mã QR', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
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
                    borderRadius: BorderRadius.circular(16),
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
                    data: widget.qr.genCode,
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
              Text('Mã QR (MAC): ${widget.qr.genCode}'),
              Text('Trạng thái: ${widget.qr.isActive ? 'Kích hoạt' : 'Chưa kích hoạt'}'),
              Text('Model: ${widget.qr.productId}'),
              if (widget.qr.id.isNotEmpty) Text('ID: ${widget.qr.id}'),
              // Các trường bổ sung nếu cần
              // Text('Hãng: ...'),
              // Text('Serial: ...'),
              // Text('Firmware: ...'),
              Text('Ngày tạo: ${widget.qr.createdAt}'),
            ],
          ),
        ),
      ),
    );
  }

  // ... existing code ...
  Future<void> _shareQRCode() async {
    // Tạo QR code PNG không border, không padding
    if (kIsWeb) {
      await Share.share('Mã QR: ${widget.qr.genCode}');
      return;
    }
    try {
      final qrValidationResult = QrValidator.validate(
        data: widget.qr.genCode,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      if (qrValidationResult.status != QrValidationStatus.valid) {
        _showSnackBar('QR data invalid');
        return;
      }
      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );
      final picData = await painter.toImageData(250, format: ui.ImageByteFormat.png);
      final bytes = picData!.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/qr_code_share.png');
      await tempFile.writeAsBytes(bytes);
      await shareImageNative(tempFile.path);
      // KHÔNG xóa file ngay sau khi chia sẻ
    } catch (e) {
      _showSnackBar('Lỗi khi chia sẻ: $e');
      print('Lỗi khi chia sẻ: $e');
    }
  }
// ... existing code ...

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

      // Xử lý cho Web
      if (kIsWeb) {
        // ignore: undefined_function
        saveQrWeb(qrImageBytes);
        _showSnackBar('Đã tải ảnh QR về máy!');
        setState(() { _isLoading = false; });
        return;
      }

      // Xử lý cho Android/iOS
      await MediaStore.ensureInitialized();
      // Xin quyền truy cập bộ nhớ/ảnh
      final storageStatus = await Permission.storage.request();
      final photosStatus = await Permission.photos.request();
      if (!storageStatus.isGranted && !photosStatus.isGranted) {
        _showSnackBar('Cần quyền truy cập bộ nhớ/ảnh để lưu ảnh');
        setState(() { _isLoading = false; });
        return;
      }

      // Lưu file tạm
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);

      // Đảm bảo file là ảnh JPG hợp lệ
      final decodedImage = img.decodeImage(qrImageBytes);
      if (decodedImage == null) {
        _showSnackBar('Lỗi: Không decode được ảnh PNG sang JPG');
        setState(() { _isLoading = false; });
        return;
      }
      final jpgBytes = img.encodeJpg(decodedImage, quality: 95);
      await file.writeAsBytes(jpgBytes);

      // Thiết lập appFolder cho MediaStore (Android)
      MediaStore.appFolder = "QR_Generator";

      // Lưu vào gallery bằng media_store_plus
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
      // Xóa file tạm
      await file.delete();
    } catch (e) {
      // _showSnackBar('Lỗi khi lưu ảnh: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showPermissionDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cần quyền truy cập'),
        content: const Text('Ứng dụng cần quyền truy cập bộ nhớ/ảnh để lưu ảnh QR. Vui lòng cấp quyền trong phần Cài đặt của thiết bị.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Mở cài đặt'),
          ),
        ],
      ),
    );
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
      // _showSnackBar('Lỗi khi tạo ảnh: $e');
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
} 