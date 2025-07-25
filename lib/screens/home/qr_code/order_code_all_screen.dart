import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../models/order.dart';
import '../../../models/device.dart';
import '../../../services/api_service.dart';
import 'order_code_detail_screen.dart';
import 'order_code_create_screen.dart';
import 'order_search_screen.dart';
import 'qr_save_web.dart'
    if (dart.library.io) 'qr_save_mobile.dart';

class OrderCodeAllScreen extends StatefulWidget {
  const OrderCodeAllScreen({super.key});

  @override
  State<OrderCodeAllScreen> createState() => _OrderCodeAllScreenState();
}

class _OrderCodeAllScreenState extends State<OrderCodeAllScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<String> _selectedOrders = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await ApiService.getOrders();
      setState(() {
        _orders = orders;
      _isLoading = false;
      });
    } catch (e) {
      setState(() {
      _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải danh sách đơn hàng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedOrders.clear();
      }
    });
  }

  void _toggleOrderSelection(String orderId) {
    setState(() {
      if (_selectedOrders.contains(orderId)) {
        _selectedOrders.remove(orderId);
      } else {
        _selectedOrders.add(orderId);
      }
    });
  }

  Future<void> _shareSelectedOrdersPDF() async {
    if (_selectedOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một đơn hàng để chia sẻ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
              Text('Đang tạo PDF...'),
            ],
          ),
        ),
      );

      // Lấy danh sách đơn hàng được chọn
      final selectedOrders = _orders.where((order) => _selectedOrders.contains(order.id)).toList();
      
      // Đóng loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (kIsWeb) {
        // Trên web: tạo PDF và tải về
        final pdfBytes = await _generateOrdersPDFBytes(selectedOrders);
        final fileName = 'orders_${DateTime.now().millisecondsSinceEpoch}.pdf';
        // ignore: undefined_function
        savePdfWeb(pdfBytes, fileName);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tải PDF với ${selectedOrders.length} đơn hàng về máy!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Trên mobile: tạo file và chia sẻ
        final textFile = await _generateOrdersPDF(selectedOrders);
        
        // Chia sẻ file PDF
        await Share.shareXFiles(
          [XFile(textFile.path)],
          subject: 'Danh sách đơn hàng (${selectedOrders.length} đơn)',
          text: 'Danh sách ${selectedOrders.length} đơn hàng được chọn',
        );

        // Xóa file tạm
        if (await textFile.exists()) {
          await textFile.delete();
        }
      }
    } catch (e) {
      print('Lỗi khi tạo PDF: $e');
      // Đóng loading dialog nếu có lỗi
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<File> _generateOrdersPDF(List<Order> orders) async {
    // Load font Unicode để hỗ trợ tiếng Việt
    final fontData = await rootBundle.load('assets/fonts/Roboto/Roboto-VariableFont_wdth,wght.ttf');
    final ttf = pw.Font.ttf(fontData);
    
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
        build: (context) => _buildPDFWidgets(orders),
      ),
    );

    // Lưu PDF vào file tạm
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/orders_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  Future<Uint8List> _generateOrdersPDFBytes(List<Order> orders) async {
    // Load font Unicode để hỗ trợ tiếng Việt
    final fontData = await rootBundle.load('assets/fonts/Roboto/Roboto-VariableFont_wdth,wght.ttf');
    final ttf = pw.Font.ttf(fontData);
    
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
        build: (context) => _buildPDFWidgets(orders),
      ),
    );

    // Trả về bytes thay vì lưu file
    return await pdf.save();
  }

  pw.Widget _buildOrderWidget(Order order) {
    final children = <pw.Widget>[];
    
    // ID và trạng thái
    children.add(pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'ID: ${order.id}',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'Trạng thái: ${_getStatusText(order.status)}',
          style: pw.TextStyle(fontSize: 12),
        ),
      ],
    ));
    
    children.add(pw.SizedBox(height: 8));
    
    // Thông tin đơn hàng
          children.add(pw.Text('Khách hàng: ${order.customerName}', style: pw.TextStyle(fontSize: 12)));
      children.add(pw.Text('Người tạo: ${order.createdBy}', style: pw.TextStyle(fontSize: 12)));
      children.add(pw.Text('Ngày tạo: ${order.createdAt.toString().substring(0, 16)}', style: pw.TextStyle(fontSize: 12)));
      children.add(pw.Text('Số lượng device: ${order.deviceCount}', style: pw.TextStyle(fontSize: 12)));

      if (order.note != null && order.note!.isNotEmpty) {
        children.add(pw.Text('Ghi chú: ${order.note}', style: pw.TextStyle(fontSize: 12)));
      }

    // Danh sách devices
    if (order.devices.isNotEmpty) {
      children.add(pw.SizedBox(height: 8));
      children.add(pw.Text(
        'CHI TIẾT DEVICES:',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ));
      for (int i = 0; i < order.devices.length; i++) {
        final device = order.devices[i];
        children.add(_buildDeviceWidget(device, i + 1));
        if (i < order.devices.length - 1) {
          children.add(pw.SizedBox(height: 8));
        }
      }
    }

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 15),
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  pw.Widget _buildDeviceWidget(Device device, int index) {
    final children = <pw.Widget>[];
    
    // Header với số thứ tự
    children.add(pw.Row(
      children: [
        pw.Text(
          'Device #$index',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          '(${device.paymentStatus})',
          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
        ),
      ],
    ));
    
    children.add(pw.SizedBox(height: 4));
    
    // Thông tin chi tiết device
    children.add(pw.Text('MAC Address: ${device.macAddress}', style: pw.TextStyle(fontSize: 11)));
    children.add(pw.Text('SKU Code: ${device.skuCode}', style: pw.TextStyle(fontSize: 11)));
    
    if (device.serialNumber != null && device.serialNumber!.isNotEmpty) {
      children.add(pw.Text('Serial Number: ${device.serialNumber}', style: pw.TextStyle(fontSize: 11)));
    }
    
    if (device.model != null && device.model!.isNotEmpty) {
      children.add(pw.Text('Model: ${device.model}', style: pw.TextStyle(fontSize: 11)));
    }
    
    if (device.manufacturer != null && device.manufacturer!.isNotEmpty) {
      children.add(pw.Text('Manufacturer: ${device.manufacturer}', style: pw.TextStyle(fontSize: 11)));
    }
    
    if (device.firmwareVersion != null && device.firmwareVersion!.isNotEmpty) {
      children.add(pw.Text('Firmware: ${device.firmwareVersion}', style: pw.TextStyle(fontSize: 11)));
    }
    
    if (device.price != null) {
      children.add(pw.Text('Price: \$${device.price!.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11)));
    }
    
    if (device.activatedAt != null) {
      children.add(pw.Text('Activated: ${device.activatedAt!.toString().substring(0, 16)}', style: pw.TextStyle(fontSize: 11)));
    }
    
    if (device.activatedBy != null && device.activatedBy!.isNotEmpty) {
      children.add(pw.Text('Activated By: ${device.activatedBy}', style: pw.TextStyle(fontSize: 11)));
    }
    
    children.add(pw.Text('Status: ${device.isActive ? "Active" : "Inactive"}', style: pw.TextStyle(fontSize: 11)));

    return pw.Container(
      margin: pw.EdgeInsets.only(left: 15),
      padding: pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey200),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  List<pw.Widget> _buildPDFWidgets(List<Order> orders) {
    final widgets = <pw.Widget>[];
    
    // Header
    widgets.add(pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'DANH SÁCH ĐƠN HÀNG',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Ngày tạo: ${DateTime.now().toString().substring(0, 16)}',
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    ));
    
    // Thông tin tổng quan
    final summaryChildren = <pw.Widget>[];
    summaryChildren.add(pw.Text(
      'Tổng số đơn hàng: ${orders.length}',
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    ));
    summaryChildren.add(pw.SizedBox(height: 5));
    summaryChildren.add(pw.Text(
      'Đơn hàng chờ xử lý: ${orders.where((o) => o.status == 'pending').length}',
      style: pw.TextStyle(fontSize: 12),
    ));
    summaryChildren.add(pw.Text(
      'Đơn hàng hoàn thành: ${orders.where((o) => o.status == 'completed').length}',
      style: pw.TextStyle(fontSize: 12),
    ));
    summaryChildren.add(pw.Text(
      'Đơn hàng đã hủy: ${orders.where((o) => o.status == 'cancelled').length}',
      style: pw.TextStyle(fontSize: 12),
    ));
    
    widgets.add(pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: summaryChildren,
      ),
    ));
    
    widgets.add(pw.SizedBox(height: 20));
    
    // Thêm danh sách đơn hàng
    for (final order in orders) {
      widgets.add(_buildOrderWidget(order));
    }
    
    return widgets;
  }



  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách đơn hàng'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_isSelectionMode && _selectedOrders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Chia sẻ PDF',
              onPressed: _shareSelectedOrdersPDF,
            ),
          if (!_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Tìm kiếm',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderSearchScreen()),
                );
                if (result != null) {
                  // Refresh list after search
                  _loadOrders();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Tạo đơn hàng mới',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderCodeCreateScreen()),
                );
                if (result != null) {
                  // Refresh list after creating new order
                  _loadOrders();
                }
              },
            ),
          ],
        ],
      ),
      body: _isLoading
              ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Không có đơn hàng nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                    final isSelected = _selectedOrders.contains(order.id);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      child: ListTile(
                        leading: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (value) => _toggleOrderSelection(order.id),
                              )
                            : const Icon(Icons.shopping_cart, color: Colors.deepPurple),
                        title: const SizedBox.shrink(),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Khách hàng: ${order.customerName}'),
                            Text('Người tạo: ${order.createdBy}'),
                            Text('Ngày tạo: ${order.createdAt.toString().substring(0, 16)}'),
                            Text('Số lượng device: ${order.deviceCount}'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: order.status == 'pending' ? Colors.orange : 
                                       order.status == 'completed' ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status == 'pending' ? 'Chờ xử lý' :
                                order.status == 'completed' ? 'Hoàn thành' : 'Đã hủy',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderCodeDetailScreen(
                                order: order,
                                onOrderUpdated: _loadOrders,
                              ),
                            ),
                  );
                },
              ),
                    );
                  },
                ),
      floatingActionButton: _orders.isNotEmpty
          ? FloatingActionButton(
              onPressed: _toggleSelectionMode,
              backgroundColor: _isSelectionMode ? Colors.red : Colors.deepPurple,
              child: Icon(_isSelectionMode ? Icons.close : Icons.select_all),
            )
          : null,
    );
  }
}
