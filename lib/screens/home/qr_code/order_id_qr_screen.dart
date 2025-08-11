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
import '../../../widgets/copyable_text.dart';
import 'qr_save_web.dart'
    if (dart.library.io) 'qr_save_mobile.dart';

class OrderIdQrScreen extends StatefulWidget {
  final String orderId;
  
  const OrderIdQrScreen({super.key, required this.orderId});

  @override
  State<OrderIdQrScreen> createState() => _OrderIdQrScreenState();
}

class _OrderIdQrScreenState extends State<OrderIdQrScreen> {
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
      final qrValidationResult = QrValidator.validate(
        data: widget.orderId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Đơn hàng'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
                    data: widget.orderId,
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
              // Thông tin Order ID có thể copy
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Thông tin đơn hàng',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Mã đơn hàng:', widget.orderId),
                  ],
                ),
              ),
            ],
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
            child: CopyableText(
              text: value,
              copyMessage: 'Đã copy $label',
            ),
          ),
        ],
      ),
    );
  }
} 