import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../models/order.dart';
import '../../../models/device.dart';
import '../../../services/api_service.dart';
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
  Set<String> _selectedDevices = {};
  bool _selectAll = false;

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
          _selectedDevices.clear();
          _selectAll = false;
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

  void _toggleDeviceSelection(String macAddress) {
    setState(() {
      if (_selectedDevices.contains(macAddress)) {
        _selectedDevices.remove(macAddress);
      } else {
        _selectedDevices.add(macAddress);
      }
      _updateSelectAllState();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedDevices.clear();
        _selectAll = false;
      } else {
        _selectedDevices = _order!.devices.map((d) => d.macAddress).toSet();
        _selectAll = true;
      }
    });
  }

  void _updateSelectAllState() {
    if (_order != null) {
      final allSelected = _order!.devices.every((d) => _selectedDevices.contains(d.macAddress));
      if (_selectAll != allSelected) {
        setState(() {
          _selectAll = allSelected;
        });
      }
    }
  }

  Future<void> _shareSelectedQRCodes() async {
    if (_selectedDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một device để chia sẻ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final selectedDevices = _order!.devices.where((d) => _selectedDevices.contains(d.macAddress)).toList();
      
      // Hiển thị dialog để tạo và chia sẻ QR codes
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _QRCodeShareDialog(
          devices: selectedDevices,
          orderId: _order!.id,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chia sẻ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deactivateOrder() async {
    if (_order == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Deactive Đơn hàng'),
        content: Text(
          'Bạn có chắc chắn muốn vô hiệu hóa đơn hàng này?\n\n'
          'Hành động này sẽ:\n'
          '• Chuyển trạng thái đơn hàng thành "Đã hủy"\n'
          '• Chuyển tất cả ${_order!.devices.length} devices về trạng thái "chưa kích hoạt"\n\n'
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
            child: const Text('Deactive'),
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
        // Cập nhật trạng thái local - cả đơn hàng và tất cả devices
        final updatedDevices = _order!.devices.map((device) => Device(
          id: device.id,
          macAddress: device.macAddress,
          serialNumber: device.serialNumber,
          thingID: device.thingID,
          paymentStatus: device.paymentStatus,
          isActive: false, // Tất cả devices sẽ được chuyển về isActive: false
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
          status: 'deactivated', // Đơn hàng chuyển thành deactivated
          note: _order!.note,
          devices: updatedDevices, // Cập nhật devices với isActive: false
          deviceCount: _order!.deviceCount,
        );
        
        setState(() {
          _order = updatedOrder;
        });
        
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

  Future<void> _updateOrderStatus() async {
    if (_order == null) return;

    // Danh sách trạng thái có thể chọn
    final statuses = [
      {'value': 'pending', 'name': 'Chờ xử lý', 'color': Colors.orange},
      {'value': 'completed', 'name': 'Hoàn thành', 'color': Colors.green},
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
        // Cập nhật trạng thái local
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
                'Deactive',
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
                                    _buildInfoRow('ID đơn hàng:', _order!.id),
                                    _buildInfoRow('Khách hàng:', _order!.customerId),
                                    _buildInfoRow('Người tạo:', _order!.createdBy),
                                    _buildInfoRow('Ngày tạo:', _order!.createdAt.toString().substring(0, 16)),
                                    _buildInfoRow('Số lượng Device:', _order!.devices.length.toString()),
                                    _buildInfoRow('Ghi chú:', _order!.note ?? 'Không có'),
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
                                            _order!.status == 'pending' ? 'Chờ xử lý' :
                                            _order!.status == 'completed' ? 'Hoàn thành' : 'Đã hủy',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        if (!_isUpdatingStatus)
                                          ElevatedButton.icon(
                                            onPressed: _order!.status == 'deactivated' ? null : _updateOrderStatus,
                                            icon: const Icon(Icons.edit, size: 16),
                                            label: const Text('Cập nhật'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _order!.status == 'deactivated' ? Colors.grey : Colors.blue,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                          )
                                        else
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                            Text(
                                  'Devices: (${_order!.devices.length})',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Row(
                                  children: [
                                    if (_selectedDevices.isNotEmpty)
                                      ElevatedButton.icon(
                                        onPressed: _shareSelectedQRCodes,
                                        icon: const Icon(Icons.share, size: 16),
                                        label: Text('Chia sẻ (${_selectedDevices.length})'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: _toggleSelectAll,
                                      icon: Icon(_selectAll ? Icons.check_box : Icons.check_box_outline_blank),
                                      label: Text(_selectAll ? 'Bỏ chọn' : 'Tất cả'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._order!.devices.map((device) => Card(
                              child: ListTile(
                                leading: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Checkbox(
                                    value: _selectedDevices.contains(device.macAddress),
                                    onChanged: (bool? value) {
                                      _toggleDeviceSelection(device.macAddress);
                                    },
                                    activeColor: Colors.deepPurple,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                title: Text(device.macAddress, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('SKU: ${device.skuCode}'),
                                    Text('Payment: ${device.paymentStatus}'),
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
                                trailing: const Icon(Icons.qr_code),
                                onTap: () {
                                  // Navigate to QR screen showing QR code generated from MAC address
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
                                },
                              ),
                            )),
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
            child: Text(value),
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
            const Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                SizedBox(height: 16),
                Text('Đang chia sẻ...'),
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
              ? 'Đã tải ${widget.devices.length} QR code về máy!' 
              : 'Đã chia sẻ ${widget.devices.length} QR code'),
            backgroundColor: Colors.green,
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
      color: Colors.black,
      emptyColor: Colors.white,
      gapless: false,
    );

    final qrImage = await qrPainter.toImageData(200.0);
    return qrImage!.buffer.asUint8List();
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