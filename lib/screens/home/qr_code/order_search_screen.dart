import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:intl/intl.dart';

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../models/order.dart';
import '../../../services/api_service.dart';
import '../../../widgets/copyable_text.dart';
import 'order_code_detail_screen.dart';
import 'qr_save_web.dart'
    if (dart.library.io) 'qr_save_mobile.dart';

class OrderSearchScreen extends StatefulWidget {
  const OrderSearchScreen({super.key});

  @override
  State<OrderSearchScreen> createState() => _OrderSearchScreenState();
}

class _OrderSearchScreenState extends State<OrderSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _customerIdController = TextEditingController();
  final TextEditingController _createdByController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedStatus;
  bool _isLoading = false;
  List<Order> _searchResults = [];
  bool _useGeneralSearch = false;

  // Helper function to format date in HH:mm dd/MM/yyyy format
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
  }

  // Helper function to format date only in dd-MM-yyyy format (for date picker)
  String _formatDateOnly(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    return '$day-$month-$year';
  }

  // Danh sách trạng thái đơn hàng
  final List<Map<String, String?>> _statuses = [
    {'value': null, 'name': 'Tất cả trạng thái'},
    {'value': 'pending', 'name': 'Chờ xử lý'},
    {'value': 'completed', 'name': 'Hoàn thành'},
    {'value': 'deactivated', 'name': 'Đã hủy'},
  ];

  Future<void> _searchOrders() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<Order> orders;
      
      if (_useGeneralSearch && _queryController.text.trim().isNotEmpty) {
        // Sử dụng tìm kiếm tổng quát
        orders = await ApiService.searchOrders(_queryController.text.trim());
      } else {
        // Sử dụng tìm kiếm chi tiết
        orders = await ApiService.getOrders(
          status: _selectedStatus,
          customerId: _customerIdController.text.trim().isEmpty ? null : _customerIdController.text.trim(),
          createdBy: _createdByController.text.trim().isEmpty ? null : _createdByController.text.trim(),
          fromDate: _fromDate,
          toDate: _toDate,
        );
      }

      setState(() {
        _searchResults = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tìm kiếm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearSearch() {
    _formKey.currentState?.reset();
    _queryController.clear();
    _customerIdController.clear();
    _createdByController.clear();
    _fromDate = null;
    _toDate = null;
    _selectedStatus = null;
    _useGeneralSearch = false;
    setState(() {
      _searchResults.clear();
    });
  }

  void _switchMode(bool general) {
    // Reset all inputs and results when switching modes
    _formKey.currentState?.reset();
    _queryController.clear();
    _customerIdController.clear();
    _createdByController.clear();
    _fromDate = null;
    _toDate = null;
    _selectedStatus = null;
    setState(() {
      _useGeneralSearch = general;
      _isLoading = false;
      _searchResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Tìm kiếm đơn hàng'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_searchResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Chia sẻ/Tải PDF',
              onPressed: _showPdfOptions,
            ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Xóa tìm kiếm',
            onPressed: _clearSearch,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Form
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Toggle cho loại tìm kiếm
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _switchMode(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_useGeneralSearch ? Colors.deepPurple : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Tìm kiếm chi tiết'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _switchMode(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _useGeneralSearch ? Colors.deepPurple : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Tìm kiếm tổng quát'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Tìm kiếm tổng quát
                    if (_useGeneralSearch) ...[
                      TextFormField(
                        controller: _queryController,
                        decoration: const InputDecoration(
                          labelText: 'Từ khóa tìm kiếm',
                          hintText: 'Nhập email, tên, mã MAC...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ] else ...[
                      // Tìm kiếm chi tiết
                      TextFormField(
                        controller: _customerIdController,
                        decoration: const InputDecoration(
                          labelText: 'Email khách hàng/đại lý',
                          hintText: 'agent@email.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _createdByController,
                        decoration: const InputDecoration(
                          labelText: 'Email người tạo',
                          hintText: 'admin@email.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_add),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        items: _statuses.map((status) {
                          return DropdownMenuItem(
                            value: status['value'],
                            child: Text(status['name']!),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedStatus = value),
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái đơn hàng',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.info),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _fromDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() => _fromDate = date);
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _fromDate != null 
                                  ? 'Từ: ${_formatDateOnly(_fromDate!)}'
                                  : 'Từ ngày'
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _fromDate != null ? Colors.green : Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _toDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() => _toDate = date);
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _toDate != null 
                                  ? 'Đến: ${_formatDateOnly(_toDate!)}'
                                  : 'Đến ngày'
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _toDate != null ? Colors.green : Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _searchOrders,
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.search),
                        label: Text(_isLoading ? 'Đang tìm...' : 'Tìm kiếm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Search Results
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_searchResults.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Không tìm thấy đơn hàng nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Hãy thử thay đổi điều kiện tìm kiếm',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kết quả tìm kiếm (${_searchResults.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                          label: const Text('Xóa tìm kiếm'),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final order = _searchResults[index];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: ListTile(
                          leading: const Icon(Icons.shopping_cart, color: Colors.deepPurple),
                          title: const SizedBox.shrink(),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CopyableText(
                                text: 'Khách hàng: ${order.customerName}',
                                style: const TextStyle(fontSize: 14),
                                copyMessage: 'Đã copy tên khách hàng',
                              ),
                              CopyableText(
                                text: 'Người tạo: ${order.createdBy}',
                                style: const TextStyle(fontSize: 14),
                                copyMessage: 'Đã copy người tạo',
                              ),
                              CopyableText(
                                text: 'Ngày tạo: ${_formatDateTime(order.createdAt)}',
                                style: const TextStyle(fontSize: 14),
                                copyMessage: 'Đã copy ngày tạo',
                              ),
                              CopyableText(
                                text: 'Số lượng device: ${order.deviceCount}',
                                style: const TextStyle(fontSize: 14),
                                copyMessage: 'Đã copy số lượng thiết bị',
                              ),
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
                                  onOrderUpdated: _searchOrders,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadOrderListPDF() async {
    if (_searchResults.isEmpty) return;

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

      final pdfBytes = await _generateOrderListPDFBytes(_searchResults);
      
      // Đóng loading dialog
      Navigator.pop(context);

      final fileName = 'danh_sach_don_hang_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (kIsWeb) {
        // ignore: undefined_function
        savePdfWeb(pdfBytes, fileName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tải PDF về máy!'), backgroundColor: Colors.green),
        );
        return;
      }

      // Mobile: lưu vào thư mục Tải xuống/Downloads
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
      await _shareOrderListPDF();
    } else if (action == 'download') {
      await _downloadOrderListPDF();
    }
  }

  Future<void> _shareOrderListPDF() async {
    if (_searchResults.isEmpty) return;

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

      final pdfBytes = await _generateOrderListPDFBytes(_searchResults);
      
      // Đóng loading dialog
      Navigator.pop(context);

      // Chia sẻ file PDF
      if (kIsWeb) {
        // Trên web: sử dụng XFile.fromData
        await Share.shareXFiles(
          [XFile.fromData(pdfBytes, name: 'danh_sach_don_hang_${DateTime.now().millisecondsSinceEpoch}.pdf')],
          text: 'Danh sách đơn hàng tìm kiếm (${_searchResults.length} đơn hàng)',
        );
      } else {
        // Trên mobile: lưu file tạm rồi chia sẻ
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/danh_sach_don_hang_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(pdfBytes);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Danh sách đơn hàng tìm kiếm (${_searchResults.length} đơn hàng)',
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

  Future<Uint8List> _generateOrderListPDFBytes(List<Order> orders) async {
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
        build: (context) => _buildOrderListPDFWidgets(orders),
      ),
    );

    return await pdf.save();
  }

  List<pw.Widget> _buildOrderListPDFWidgets(List<Order> orders) {
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
            'Ngày xuất: ${_formatDateOnly(DateTime.now())}',
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    ));

    // Thống kê
    widgets.add(pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text(
                orders.length.toString(),
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
              ),
              pw.Text('Tổng số đơn hàng', style: pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Column(
            children: [
              pw.Text(
                orders.where((o) => o.status == 'pending').length.toString(),
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.orange),
              ),
              pw.Text('Chờ xử lý', style: pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Column(
            children: [
              pw.Text(
                orders.where((o) => o.status == 'completed').length.toString(),
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
              ),
              pw.Text('Hoàn thành', style: pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Column(
            children: [
              pw.Text(
                orders.where((o) => o.status == 'deactivated').length.toString(),
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
              ),
              pw.Text('Đã hủy', style: pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    ));

    // Danh sách đơn hàng
    for (int i = 0; i < orders.length; i++) {
      final order = orders[i];
      
      widgets.add(pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 15),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Đơn hàng #${i + 1}',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Text(
                    _getStatusText(order.status),
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text('Khách hàng: ${order.customerName}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Người tạo: ${order.createdBy}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Ngày tạo: ${_formatDateTime(order.createdAt)}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Số lượng device: ${order.deviceCount}', style: pw.TextStyle(fontSize: 12)),
          ],
        ),
      ));
    }

    return widgets;
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'deactivated':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PdfColors.orange;
      case 'completed':
        return PdfColors.green;
      case 'deactivated':
        return PdfColors.red;
      default:
        return PdfColors.grey;
    }
  }
} 