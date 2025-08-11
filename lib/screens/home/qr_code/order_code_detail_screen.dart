import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:intl/intl.dart';

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../models/order.dart';
import '../../../models/device.dart';
import '../../../services/api_service.dart';
import '../../../widgets/copyable_text.dart';
import 'order_id_qr_screen.dart';
import 'device_qr_screen.dart';
import 'qr_save_web.dart'
    if (dart.library.io) 'qr_save_mobile.dart';

class OrderCodeDetailScreen extends StatefulWidget {
  final Order order;
  final VoidCallback? onOrderUpdated;
  const OrderCodeDetailScreen({
    super.key, 
    required this.order,
    this.onOrderUpdated,
  });

  @override
  State<OrderCodeDetailScreen> createState() => _OrderCodeDetailScreenState();
}

class _OrderCodeDetailScreenState extends State<OrderCodeDetailScreen> {
  Order? _order;
  bool _isLoading = true;
  bool _isDeactivating = false;
  bool _isUpdatingStatus = false;
  String? _error;
  // Lưu trạng thái mở/đóng cho từng nhóm sản phẩm
  final Map<String, bool> _groupExpanded = {};


  // Helper function to format date in HH:mm dd/MM/yyyy format
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
  }

  // Helper function to get status text
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
      case 'deactivated':
        return 'Đã hủy';
      default:
        return status;
    }
  }



  // Helper function to generate QR code bytes
  Future<Uint8List> _generateQRCodeBytes(String data) async {
    try {
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: true,
        embeddedImage: null,
        embeddedImageStyle: null,
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF000000),
        ),
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF000000),
        ),
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      final qrImage = await qrPainter.toImageData(200.0);
      return qrImage!.buffer.asUint8List();
    } catch (e) {
      print('Error generating QR code: $e');
      // Return empty bytes if QR generation fails
      return Uint8List(0);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orderDetail = await ApiService.getOrderDetail(widget.order.id);
      
      if (orderDetail != null) {
        setState(() {
          _order = orderDetail;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Không thể tải chi tiết đơn hàng';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải chi tiết đơn hàng: $e';
        _isLoading = false;
      });
    }
  }



  Future<void> _deactivateOrder() async {
    if (_order == null) return;

    // Kiểm tra xem có thiết bị nào đã kích hoạt chưa
    final activatedDevices = _order!.devices.where((device) => device.isActive).toList();
    
    if (activatedDevices.isNotEmpty) {
      // Có thiết bị đã kích hoạt, không cho phép hủy đơn hàng
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Thông báo'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đơn hàng này không thể hủy vì có thiết bị đã được kích hoạt.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'Số thiết bị đã kích hoạt: ${activatedDevices.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng hủy kích hoạt tất cả thiết bị trước khi hủy đơn hàng.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy Đơn hàng'),
        content: Text(
          'Bạn có chắc chắn muốn vô hiệu hóa đơn hàng này?\n\n'
          'Hành động này sẽ:\n'
          '• Chuyển trạng thái đơn hàng thành "Đã hủy"\n'
          '• Chuyển tất cả ${_order!.devices.length} thiết bị về trạng thái "chưa kích hoạt"\n\n'
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
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeactivating = true;
    });

    try {
      final success = await ApiService.deactivateOrder(_order!.id);
      
      if (success) {
        // Sau khi hủy thành công: gọi lại API chi tiết đơn hàng để refresh UI
        final refreshedOrder = await ApiService.getOrderDetail(_order!.id);
        
        if (refreshedOrder != null) {
          setState(() {
            _order = refreshedOrder;
          });
        } else {
          // Fallback: Cập nhật local nếu không lấy được dữ liệu mới
          final updatedDevices = _order!.devices.map((device) => Device(
            id: device.id,
            macAddress: device.macAddress,
            serialNumber: device.serialNumber,
            thingID: device.thingID,
            paymentStatus: device.paymentStatus,
            isActive: false,
            createdAt: device.createdAt,
            manufacturer: device.manufacturer,
            model: device.model,
            firmwareVersion: device.firmwareVersion,
            activatedAt: device.activatedAt,
            activatedBy: device.activatedBy,
            orderId: device.orderId,
            price: device.price,
            createdBy: device.createdBy,
            customerId: device.customerId,
            skuCode: device.skuCode,
          )).toList();

          final updatedOrder = Order(
            id: _order!.id,
            customerId: _order!.customerId,
            customerName: _order!.customerName,
            createdBy: _order!.createdBy,
            createdAt: _order!.createdAt,
            status: 'deactivated',
            note: _order!.note,
            devices: updatedDevices,
            deviceCount: _order!.deviceCount,
          );
          
          setState(() {
            _order = updatedOrder;
          });
        }

        // Gọi callback để reload danh sách đơn hàng
        widget.onOrderUpdated?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã vô hiệu hóa đơn hàng thành công! Tất cả devices đã được chuyển về trạng thái không hoạt động.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi vô hiệu hóa đơn hàng!'),
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

  Future<void> _shareOrderPDF() async {
    if (_order == null) return;

    try {
      // Hiển thị loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Đang tạo file PDF...'),
            ],
          ),
        ),
      );

      final pdfBytes = await _generateOrderPDFBytes(_order!);
      
      // Đóng loading dialog
      Navigator.pop(context);

      // Chia sẻ file PDF
      if (kIsWeb) {
        // Trên web: sử dụng XFile.fromData
        await Share.shareXFiles(
          [XFile.fromData(pdfBytes, name: 'chi_tiet_don_hang_${_order!.id}.pdf')],
          text: 'Chi tiết đơn hàng ${_order!.id}',
        );
      } else {
        // Trên mobile: lưu file tạm rồi chia sẻ
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/chi_tiet_don_hang_${_order!.id}.pdf');
        await file.writeAsBytes(pdfBytes);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Chi tiết đơn hàng ${_order!.id}',
        );
      }
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tạo PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadOrderPDF() async {
    if (_order == null) return;

    try {
      // Hiển thị loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Đang tạo file PDF...'),
            ],
          ),
        ),
      );

      final pdfBytes = await _generateOrderPDFBytes(_order!);

      // Đóng loading dialog
      Navigator.pop(context);

      final fileName = 'chi_tiet_don_hang_${_order!.id}.pdf';

      if (kIsWeb) {
        // ignore: undefined_function
        savePdfWeb(pdfBytes, fileName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tải PDF về máy!'), backgroundColor: Colors.green),
        );
        return;
      }

      // Mobile: lưu vào thư mục Tải xuống/Downloads (thư viện Ảnh trên iOS/Android)
      await MediaStore.ensureInitialized();
      final storageStatus = await Permission.storage.request();
      final photosStatus = await Permission.photos.request();
      if (!storageStatus.isGranted && !photosStatus.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần quyền bộ nhớ/ảnh để lưu PDF'), backgroundColor: Colors.red),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(pdfBytes);

      MediaStore.appFolder = 'QR_Generator';
      final result = await MediaStore().saveFile(
        tempFilePath: tempPath,
        dirType: DirType.download,
        dirName: DirName.download,
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu PDF vào Downloads!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi lưu PDF!'), backgroundColor: Colors.red),
        );
      }

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showPdfOptions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Chia sẻ PDF'),
                onTap: () => Navigator.pop(context, 'share'),
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Tải về máy'),
                onTap: () => Navigator.pop(context, 'download'),
              ),
            ],
          ),
        );
      },
    );

    if (action == 'share') {
      await _shareOrderPDF();
    } else if (action == 'download') {
      await _downloadOrderPDF();
    }
  }

  Future<Uint8List> _generateOrderPDFBytes(Order order) async {
    // Load font Unicode để hỗ trợ tiếng Việt
    final fontData = await rootBundle.load('assets/fonts/Roboto/Roboto-VariableFont_wdth,wght.ttf');
    final ttf = pw.Font.ttf(fontData);
    
    // Tạo QR codes cho tất cả thiết bị
    final Map<String, Uint8List> qrCodes = {};
    for (final device in order.devices) {
      final qrBytes = await _generateQRCodeBytes(device.macAddress);
      qrCodes[device.macAddress] = qrBytes;
    }
    
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttf,
          italic: ttf,
          boldItalic: ttf,
        ),
        build: (context) => _buildOrderPDFWidgets(order, qrCodes),
      ),
    );

    return await pdf.save();
  }

  List<pw.Widget> _buildOrderPDFWidgets(Order order, Map<String, Uint8List> qrCodes) {
    final widgets = <pw.Widget>[];
    
    // Header
    widgets.add(pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'CHI TIẾT ĐƠN HÀNG',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Ngày tạo: ${_formatDateTime(DateTime.now())}',
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    ));
    
    // Thông tin đơn hàng
    widgets.add(pw.Container(
      margin: pw.EdgeInsets.only(bottom: 20),
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'THÔNG TIN ĐƠN HÀNG',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ID: ${order.id}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Trạng thái: ${_getStatusText(order.status)}', style: pw.TextStyle(fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('Khách hàng: ${order.customerName}', style: pw.TextStyle(fontSize: 12)),
          pw.Text('Người tạo: ${order.createdBy}', style: pw.TextStyle(fontSize: 12)),
          pw.Text('Ngày tạo: ${_formatDateTime(order.createdAt)}', style: pw.TextStyle(fontSize: 12)),
          pw.Text('Số lượng device: ${order.deviceCount}', style: pw.TextStyle(fontSize: 12)),
          if (order.note != null && order.note!.isNotEmpty)
            pw.Text('Ghi chú: ${order.note}', style: pw.TextStyle(fontSize: 12)),
        ],
      ),
    ));

    // Danh sách devices theo nhóm
    if (order.devices.isNotEmpty) {
      widgets.add(pw.Text(
        'CHI TIẾT THIẾT BỊ',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ));
      widgets.add(pw.SizedBox(height: 10));
      
      // Nhóm thiết bị theo skuCatalog.name
      final Map<String, List<Device>> groupedDevices = {};
      
      for (final device in order.devices) {
        final groupName = device.skuCatalog?.name ?? 'Thiết bị khác';
        if (!groupedDevices.containsKey(groupName)) {
          groupedDevices[groupName] = [];
        }
        groupedDevices[groupName]!.add(device);
      }
      
      // Tạo widget cho từng nhóm
      groupedDevices.forEach((groupName, devices) {
        // Header cho nhóm
        widgets.add(pw.Container(
          margin: pw.EdgeInsets.only(bottom: 10),
          padding: pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Text(
            '$groupName (${devices.length} thiết bị)',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ));
        
        // Danh sách thiết bị trong nhóm
        for (int i = 0; i < devices.length; i++) {
          final device = devices[i];
          // Lấy QR code đã tạo sẵn
          final qrBytes = qrCodes[device.macAddress];
          widgets.add(_buildDevicePDFWidget(device, i + 1, qrBytes));
          if (i < devices.length - 1) {
            widgets.add(pw.SizedBox(height: 15)); // Khoảng cách giữa các thiết bị
            // Thêm separator line
            widgets.add(pw.Container(
              height: 1,
              color: PdfColors.grey300,
              margin: pw.EdgeInsets.symmetric(vertical: 5),
            ));
            widgets.add(pw.SizedBox(height: 15));
          }
        }
        
        // Khoảng cách giữa các nhóm
        if (groupedDevices.keys.last != groupName) {
          widgets.add(pw.SizedBox(height: 15));
        }
      });
    }

    return widgets;
  }

  pw.Widget _buildDevicePDFWidget(Device device, int index, Uint8List? qrBytes) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
        color: index % 2 == 0 ? PdfColors.grey50 : PdfColors.white, // Alternating background
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Thiết bị #$index',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Mã: ${device.macAddress}', style: pw.TextStyle(fontSize: 11)),
                    pw.Text('Mã sản phẩm: ${device.skuCode}', style: pw.TextStyle(fontSize: 11)),
                                      if (device.skuCatalog?.description != null && device.skuCatalog!.description!.isNotEmpty)
                    pw.Text('Mô tả: ${device.skuCatalog!.description}', style: pw.TextStyle(fontSize: 11)),
                    if (device.serialNumber != null && device.serialNumber!.isNotEmpty)
                      pw.Text('Serial Number: ${device.serialNumber}', style: pw.TextStyle(fontSize: 11)),
                    if (device.model != null && device.model!.isNotEmpty)
                      pw.Text('Model: ${device.model}', style: pw.TextStyle(fontSize: 11)),
                    if (device.manufacturer != null && device.manufacturer!.isNotEmpty)
                      pw.Text('Manufacturer: ${device.manufacturer}', style: pw.TextStyle(fontSize: 11)),
                    if (device.firmwareVersion != null && device.firmwareVersion!.isNotEmpty)
                      pw.Text('Firmware: ${device.firmwareVersion}', style: pw.TextStyle(fontSize: 11)),
                    if (device.price != null)
                      pw.Text('Price: \$${device.price!.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11)),
                    if (device.activatedAt != null)
                      pw.Text('Ngày kích hoạt: ${_formatDateTime(device.activatedAt!)}', style: pw.TextStyle(fontSize: 11)),
                    if (device.activatedBy != null && device.activatedBy!.isNotEmpty)
                      pw.Text('Người kích hoạt: ${device.activatedBy}', style: pw.TextStyle(fontSize: 11)),
                    pw.Text('Trạng thái: ${device.isActive ? "Kích hoạt" : "Chưa kích hoạt"}', style: pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
                          pw.SizedBox(width: 15),
            if (qrBytes != null && qrBytes.isNotEmpty)
              pw.Image(
                pw.MemoryImage(qrBytes),
                width: 80,
                height: 80,
              )
            else
              pw.Container(
                width: 80,
                height: 80,
                child: pw.Center(
                  child: pw.Text(
                    'QR',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus() async {
    if (_order == null) return;

    // Danh sách trạng thái có thể chọn
    final statuses = [
      {'value': 'pending', 'name': 'Chờ thanh toán', 'color': Colors.orange},
      {'value': 'completed', 'name': 'Thanh toán', 'color': Colors.green},
    ];

    // Hiển thị dialog chọn trạng thái
    final selectedStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật trạng thái đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            return ListTile(
              leading: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: status['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(status['name'] as String),
              onTap: () => Navigator.pop(context, status['value'] as String),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (selectedStatus == null || selectedStatus == _order!.status) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final success = await ApiService.updateOrderStatus(_order!.id, selectedStatus);
      
      if (success) {
        // Gọi lại API chi tiết đơn hàng để cập nhật dữ liệu mới nhất
        final updatedOrderDetail = await ApiService.getOrderDetail(_order!.id);
        
        if (updatedOrderDetail != null) {
          setState(() {
            _order = updatedOrderDetail;
          });
          
          // Gọi callback để reload danh sách đơn hàng
          widget.onOrderUpdated?.call();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã cập nhật trạng thái đơn hàng thành công!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          // Nếu không lấy được dữ liệu mới, cập nhật local
          final updatedOrder = Order(
            id: _order!.id,
            customerId: _order!.customerId,
            customerName: _order!.customerName,
            createdBy: _order!.createdBy,
            createdAt: _order!.createdAt,
            status: selectedStatus,
            note: _order!.note,
            devices: _order!.devices,
            deviceCount: _order!.deviceCount,
          );
          
          setState(() {
            _order = updatedOrder;
          });
          
          // Gọi callback để reload danh sách đơn hàng
          widget.onOrderUpdated?.call();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã cập nhật trạng thái đơn hàng thành công!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi cập nhật trạng thái đơn hàng!'),
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
            content: Text('Lỗi khi cập nhật trạng thái: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Icon chia sẻ/tải PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Chia sẻ/Tải PDF',
            onPressed: _showPdfOptions,
          ),
          // Icon QR để xem QR code của Order ID
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              if (_order != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderIdQrScreen(orderId: _order!.id),
                  ),
                );
              }
            },
            tooltip: 'Xem QR đơn hàng',
          ),

          if (_order?.orderStatus == true && !_isDeactivating)
            TextButton(
              onPressed: _deactivateOrder,
              child: const Text(
                'Hủy',
                style: TextStyle(color: Colors.white),
              ),
            ),
          if (_isDeactivating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrderDetail,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _order == null
                  ? const Center(child: Text('Không tìm thấy thông tin đơn hàng'))
                  : RefreshIndicator(
                      onRefresh: _loadOrderDetail,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Thông tin đơn hàng',
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('Khách hàng:', _order!.customerId),
                                    _buildInfoRow('Người tạo:', _order!.createdBy),
                                    _buildInfoRow('Ngày tạo:', _formatDateTime(_order!.createdAt)),
                                    _buildInfoRow('Số lượng thiết bị:', _order!.devices.length.toString()),
                                    if (_order!.note != null && _order!.note!.isNotEmpty)
                                      _buildInfoRow('Ghi chú:', _order!.note!),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        const Text('Trạng thái: '),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _order!.status == 'pending' ? Colors.orange : 
                                                   _order!.status == 'completed' ? Colors.green : Colors.red,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _order!.status == 'pending' ? 'Chờ thanh toán' :
                                            _order!.status == 'completed' ? 'Thanh toán' : 'Đã hủy',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  if (!_isUpdatingStatus)
                                      Center(
                                        child: ElevatedButton.icon(
                                          onPressed: _order!.status == 'deactivated' ? null : _updateOrderStatus,
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text('Cập nhật trạng thái'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _order!.status == 'deactivated' ? Colors.grey : Colors.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      )
                                    else
                                      const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Thiết bị: (${_order!.devices.length})',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),

                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._buildGroupedDevices(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  List<Widget> _buildGroupedDevices() {
    final widgets = <Widget>[];
    
    // Nhóm thiết bị theo skuCatalog.name
    final Map<String, List<Device>> groupedDevices = {};
    
    for (final device in _order!.devices) {
      final groupName = device.skuCatalog?.name ?? 'Thiết bị khác';
      if (!groupedDevices.containsKey(groupName)) {
        groupedDevices[groupName] = [];
      }
      groupedDevices[groupName]!.add(device);
    }
    
    // Tạo widget cho từng nhóm
    groupedDevices.forEach((groupName, devices) {
      // Khởi tạo trạng thái mở/đóng mặc định (mở để giữ trải nghiệm cũ)
      _groupExpanded.putIfAbsent(groupName, () => true);

      // Tính toán số lượng thiết bị đã kích hoạt và chưa kích hoạt
      final activatedCount = devices.where((device) => device.isActive).length;
      final notActivatedCount = devices.length - activatedCount;

      widgets.add(
        Card(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _groupExpanded[groupName] ?? true,
              onExpansionChanged: (expanded) {
                setState(() {
                  _groupExpanded[groupName] = expanded;
                });
              },
              leading: const Icon(Icons.category, color: Colors.deepPurple),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$groupName (${devices.length} thiết bị)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (notActivatedCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$notActivatedCount chưa kích hoạt',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (activatedCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$activatedCount đã kích hoạt',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              children: [
                ...devices.map((device) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: CopyableText(
                          text: device.macAddress,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _order!.status == 'completed' ? null : Colors.grey,
                          ),
                          copyMessage: 'Đã copy MAC Address',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CopyableText(
                              text: 'Mã sản phẩm: ${device.skuCode}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _order!.status == 'completed' ? null : Colors.grey,
                              ),
                              copyMessage: 'Đã copy SKU Code',
                            ),
                            if (device.skuCatalog?.description != null && device.skuCatalog!.description!.isNotEmpty)
                              Text(
                                'Mô tả: ${device.skuCatalog!.description}',
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: _order!.status == 'completed' ? Colors.grey : Colors.grey.withOpacity(0.5),
                                ),
                              ),
                            const SizedBox(height: 4),
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
                          ],
                        ),
                        trailing: Icon(
                          Icons.qr_code,
                          color: _order!.status == 'completed' ? null : Colors.grey,
                        ),
                        onTap: _order!.status == 'completed' ? () {
                          // Kiểm tra trạng thái đơn hàng và payment status
                          if (_order!.status == 'pending' && device.paymentStatus == 'pending') {
                            // Nếu đơn hàng đang chờ thanh toán và device cũng chờ thanh toán thì không cho phép click
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Không thể xem QR code khi đơn hàng đang chờ thanh toán'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeviceQrScreen(
                                device: device,
                                macAddress: device.macAddress,
                                onDeviceUpdated: _loadOrderDetail,
                              ),
                            ),
                          );
                        } : null,
                      ),
                    )),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    });
    
    return widgets;
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

class _QRCodeShareDialog extends StatefulWidget {
  final List<Device> devices;
  final String orderId;

  const _QRCodeShareDialog({
    required this.devices,
    required this.orderId,
  });

  @override
  State<_QRCodeShareDialog> createState() => _QRCodeShareDialogState();
}

class _QRCodeShareDialogState extends State<_QRCodeShareDialog> {
  bool _isGenerating = false;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.qr_code, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text('Chia sẻ ${widget.devices.length} QR Code'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isGenerating)
            const Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
                SizedBox(height: 16),
                Text('Đang tạo QR codes...'),
              ],
            )
          else if (_isSharing)
            Column(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 16),
                Text(kIsWeb 
                  ? widget.devices.length == 1 
                    ? 'Đang tạo QR code...' 
                    : 'Đang tạo file ZIP...'
                  : 'Đang chia sẻ...'),
                if (kIsWeb) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.devices.length == 1 
                      ? 'QR code sẽ được tải về máy'
                      : 'Tất cả QR codes sẽ được gom vào 1 file ZIP',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            )
          else
            Column(
              children: [
                const Text('Bạn có muốn chia sẻ QR codes của các devices sau:'),
                const SizedBox(height: 16),
                ...widget.devices.map((device) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.devices_other, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          device.macAddress,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
        ],
      ),
      actions: [
        if (!_isGenerating && !_isSharing) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: _generateAndShareQRCodes,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Chia sẻ'),
          ),
        ],
      ],
    );
  }

  Future<void> _generateAndShareQRCodes() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Tạo QR codes cho từng device
      final qrImages = <Uint8List>[];
      
      for (final device in widget.devices) {
        final qrImage = await _generateQRCodeImage(device.macAddress);
        qrImages.add(qrImage);
      }

      setState(() {
        _isGenerating = false;
        _isSharing = true;
      });

      // Chia sẻ tất cả QR codes
      await _shareQRCodes(qrImages);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb 
              ? widget.devices.length == 1 
                ? 'Đã tải QR code về máy!' 
                : 'Đã tải file ZIP chứa ${widget.devices.length} QR code về máy!'
              : 'Đã chia sẻ ${widget.devices.length} QR code'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _isSharing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo QR codes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List> _generateQRCodeImage(String data) async {
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: false,
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF000000),
      ),
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF000000),
      ),
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    final qrImage = await qrPainter.toImageData(200.0);
    final qrBytes = qrImage!.buffer.asUint8List();
    
    // Thêm padding cho ảnh QR (giống như trong device_qr_screen.dart)
    final decodedImage = img.decodeImage(qrBytes);
    if (decodedImage == null) {
      return qrBytes; // Trả về ảnh gốc nếu không decode được
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
    
    // Encode thành PNG với padding
    return img.encodePng(newImage);
  }

  Future<void> _shareQRCodes(List<Uint8List> qrImages) async {
    try {
      if (kIsWeb) {
        // Trên web: tải từng QR code về máy
        final fileNames = <String>[];
        for (final device in widget.devices) {
          fileNames.add('qr_${device.macAddress.replaceAll(':', '_')}.png');
        }
        // ignore: undefined_function
        shareMultipleQrWeb(qrImages, fileNames);
      } else {
        // Trên mobile: tạo thư mục tạm để lưu ảnh QR
        final tempDir = await getTemporaryDirectory();
        final qrFiles = <File>[];
        
        // Lưu từng QR code thành file
        for (int i = 0; i < qrImages.length; i++) {
          final device = widget.devices[i];
          final fileName = 'qr_${device.macAddress.replaceAll(':', '_')}.png';
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(qrImages[i]);
          qrFiles.add(file);
        }
        
        // Chia sẻ tất cả file QR codes
        await Share.shareXFiles(
          qrFiles.map((file) => XFile(file.path)).toList(),
          subject: 'QR Codes từ đơn hàng ${widget.orderId}',
          text: 'QR Codes của ${widget.devices.length} devices từ đơn hàng ${widget.orderId}',
        );
        
        // Xóa file tạm sau khi chia sẻ
        for (final file in qrFiles) {
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      throw Exception('Lỗi khi chia sẻ QR codes: $e');
    }
  }
} 