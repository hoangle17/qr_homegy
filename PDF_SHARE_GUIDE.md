# 📄 Hướng dẫn Tạo và Chia sẻ PDF - Màn hình Chi tiết Đơn hàng

## 📋 Tổng quan

Màn hình chi tiết đơn hàng (`order_code_detail_screen.dart`) có tính năng tạo và chia sẻ file PDF chứa thông tin chi tiết của đơn hàng. Tính năng này hoạt động trên cả web và mobile.

**Cập nhật mới:** PDF hiện tại hiển thị thiết bị theo nhóm loại, bỏ trạng thái thanh toán để gọn gàng hơn, thêm QR code cho từng thiết bị với thiết kế đơn giản không có border và label, và sử dụng màu đen trắng đơn giản cho text.

## 🎯 Vị trí và Cách sử dụng

### **Vị trí nút chia sẻ:**
- **AppBar:** Icon share (📤) ở góc phải trên cùng
- **Tooltip:** "Chia sẻ PDF"
- **Chức năng:** Tạo PDF và mở dialog chia sẻ

### **Cách sử dụng:**
1. Vào màn hình "Chi tiết đơn hàng"
2. Click icon share (📤) trên AppBar
3. Chờ loading "Đang tạo file PDF..."
4. Chọn cách chia sẻ từ dialog

## 🏗️ Kiến trúc Code

### **1. Hàm chính `_shareOrderPDF()`**

```dart
Future<void> _shareOrderPDF() async {
  if (_order == null) return;

  try {
    // 1. Hiển thị loading dialog
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

    // 2. Tạo PDF bytes
    final pdfBytes = await _generateOrderPDFBytes(_order!);
    
    // 3. Đóng loading dialog
    Navigator.pop(context);

    // 4. Chia sẻ file PDF
    if (kIsWeb) {
      // Web: sử dụng XFile.fromData
      await Share.shareXFiles(
        [XFile.fromData(pdfBytes, name: 'chi_tiet_don_hang_${_order!.id}.pdf')],
        text: 'Chi tiết đơn hàng ${_order!.id}',
      );
    } else {
      // Mobile: lưu file tạm rồi chia sẻ
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/chi_tiet_don_hang_${_order!.id}.pdf');
      await file.writeAsBytes(pdfBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Chi tiết đơn hàng ${_order!.id}',
      );
    }
  } catch (e) {
    // Xử lý lỗi
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
```

### **2. Hàm tạo PDF `_generateOrderPDFBytes()`**

```dart
Future<Uint8List> _generateOrderPDFBytes(Order order) async {
  // 1. Load font Unicode để hỗ trợ tiếng Việt
  final fontData = await rootBundle.load('assets/fonts/Roboto/Roboto-VariableFont_wdth,wght.ttf');
  final ttf = pw.Font.ttf(fontData);
  
  // 2. Tạo QR codes cho tất cả thiết bị
  final Map<String, Uint8List> qrCodes = {};
  for (final device in order.devices) {
    final qrBytes = await _generateQRCodeBytes(device.macAddress);
    qrCodes[device.macAddress] = qrBytes;
  }
  
  // 3. Tạo document PDF
  final pdf = pw.Document();

  // 4. Thêm trang với theme và font
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

  // 5. Trả về bytes
  return await pdf.save();
}
```

### **3. Hàm tạo QR code `_generateQRCodeBytes()`**

```dart
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
```

### **3. Hàm xây dựng nội dung PDF `_buildOrderPDFWidgets()`**

```dart
List<pw.Widget> _buildOrderPDFWidgets(Order order) {
  final widgets = <pw.Widget>[];
  
  // 1. Header với tiêu đề và ngày tạo
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
  
  // 2. Thông tin đơn hàng
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

  // 3. Danh sách devices theo nhóm
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
        widgets.add(_buildDevicePDFWidget(device, i + 1));
        if (i < devices.length - 1) {
          widgets.add(pw.SizedBox(height: 8));
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
```

### **4. Hàm tạo widget cho từng device `_buildDevicePDFWidget()`**

```dart
pw.Widget _buildDevicePDFWidget(Device device, int index, Uint8List? qrBytes) {
  return pw.Container(
    padding: pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
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
```

## 📦 Dependencies cần thiết

### **pubspec.yaml:**
```yaml
dependencies:
  pdf: ^3.10.7
  share_plus: ^7.2.1
  path_provider: ^2.1.2
  flutter:
    sdk: flutter
```

### **Imports:**
```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:io';
```

## 🔄 Quy trình hoạt động

### **1. Khởi tạo:**
- User click icon share trên AppBar
- Kiểm tra `_order` có tồn tại không

### **2. Loading:**
- Hiển thị dialog loading với text "Đang tạo file PDF..."
- Dialog không thể đóng (barrierDismissible: false)

### **3. Tạo PDF:**
- Load font Roboto Unicode
- Tạo PDF document với format A4
- Xây dựng nội dung PDF từ dữ liệu đơn hàng
- Convert thành bytes

### **4. Chia sẻ:**
- **Web:** Sử dụng `Share.shareXFiles()` với `XFile.fromData()`
- **Mobile:** Lưu file tạm rồi chia sẻ với `XFile(file.path)`

### **5. Xử lý lỗi:**
- Đóng loading dialog
- Hiển thị SnackBar với thông báo lỗi

## 📊 Cấu trúc PDF mới

### **Header:**
```
┌─────────────────────────────────────┐
│ CHI TIẾT ĐƠN HÀNG    Ngày tạo: ... │
└─────────────────────────────────────┘
```

### **Thông tin đơn hàng:**
```
┌─────────────────────────────────────┐
│ THÔNG TIN ĐƠN HÀNG                 │
│                                     │
│ ID: ORD001    Trạng thái: Chờ xử lý │
│ Khách hàng: customer@email.com      │
│ Người tạo: admin@email.com          │
│ Ngày tạo: 14:30 04-08-2025          │
│ Số lượng device: 5                  │
│ Ghi chú: Đơn hàng test              │
└─────────────────────────────────────┘
```

### **Chi tiết thiết bị theo nhóm với QR code:**
```
┌─────────────────────────────────────┐
│ CHI TIẾT THIẾT BỊ                  │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Công tắc wifi tuya (2 thiết bị) │ ← Group Header
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Thiết bị #1            [QR]    │ │
│ │ Mã: AA:BB:CC:DD:EE:FF          │ │
│ │ Mã sản phẩm: TUYA_WIFI_SW_01   │ │
│ │ Mô tả: Công tắc wifi tuya      │ │
│ │ Trạng thái: Kích hoạt          │ │
│ └─────────────────────────────────┘ │
│ ─────────────────────────────────── │ ← Separator
│ ┌─────────────────────────────────┐ │
│ │ Thiết bị #2            [QR]    │ │
│ │ Mã: AA:BB:CC:DD:EE:02          │ │
│ │ Mã sản phẩm: TUYA_WIFI_SW_01   │ │
│ │ Mô tả: Công tắc wifi tuya      │ │
│ │ Trạng thái: Chưa kích hoạt     │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Cảm biến nhiệt độ (1 thiết bị)  │ ← Group Header
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Thiết bị #1            [QR]    │ │
│ │ Mã: AA:BB:CC:DD:EE:01          │ │
│ │ Mã sản phẩm: TEMP_SENSOR_01    │ │
│ │ Mô tả: Cảm biến nhiệt độ       │ │
│ │ Trạng thái: Chưa kích hoạt     │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## 🌐 Platform Differences

### **Web Platform:**
- **File handling:** Sử dụng `XFile.fromData()` trực tiếp
- **Share method:** `Share.shareXFiles()` với blob data
- **File name:** `chi_tiet_don_hang_${orderId}.pdf`
- **User experience:** Mở dialog chia sẻ của trình duyệt

### **Mobile Platform:**
- **File handling:** Lưu file tạm vào `getTemporaryDirectory()`
- **Share method:** `Share.shareXFiles()` với file path
- **File name:** `chi_tiet_don_hang_${orderId}.pdf`
- **User experience:** Mở dialog chia sẻ của hệ điều hành

## 🆕 Tính năng mới

### **1. Nhóm thiết bị theo loại:**
- Tự động nhóm thiết bị theo `skuCatalog.name`
- Header cho mỗi nhóm với tên và số lượng
- Khoảng cách rõ ràng giữa các nhóm

### **2. Bỏ trạng thái thanh toán:**
- Không hiển thị trạng thái thanh toán trong PDF
- Chỉ giữ lại trạng thái kích hoạt
- Giao diện gọn gàng và dễ đọc hơn

### **3. Thêm mô tả thiết bị:**
- Hiển thị mô tả từ `skuCatalog.description`
- Thông tin chi tiết hơn về từng thiết bị

### **4. QR code cho từng thiết bị (thiết kế đơn giản):**
- Tự động tạo QR code chứa MAC Address của thiết bị
- Hiển thị QR code 80x80px đơn giản không có border
- Không có label để giao diện clean và minimal
- Khoảng cách phù hợp giữa các QR code
- Alternating background (xám trắng) để phân biệt thiết bị
- Separator line giữa các thiết bị để tách biệt rõ ràng
- Fallback hiển thị "QR" text nếu tạo QR code thất bại

### **5. Thiết kế đơn giản đen trắng:**
- Bỏ tất cả màu sắc cho text để dễ đọc
- Sử dụng màu đen trắng đơn giản
- Tối ưu cho việc in ấn và photocopy
- Professional và clean design

## 🛠️ Customization

### **Thay đổi font:**
```dart
// Thay đổi font file
final fontData = await rootBundle.load('assets/fonts/YourFont.ttf');
final ttf = pw.Font.ttf(fontData);
```

### **Thay đổi layout:**
```dart
// Thay đổi page format
pageFormat: PdfPageFormat.letter, // hoặc custom size
```

### **Thêm logo:**
```dart
// Thêm logo vào header
pw.Image(pw.MemoryImage(logoBytes), width: 100, height: 50),
```

### **Thay đổi màu sắc:**
```dart
// Sử dụng màu custom
color: PdfColors.blue,
backgroundColor: PdfColors.grey100,
```

## 🔧 Troubleshooting

### **Lỗi thường gặp:**

#### 1. **Font không hiển thị tiếng Việt:**
- Kiểm tra font file có hỗ trợ Unicode
- Sử dụng font Roboto hoặc font Unicode khác

#### 2. **PDF quá lớn:**
- Giảm số lượng thông tin
- Sử dụng compression
- Chia thành nhiều trang

#### 3. **Lỗi chia sẻ trên web:**
- Kiểm tra browser support
- Thử browser khác (Chrome, Firefox, Edge)

#### 4. **Lỗi chia sẻ trên mobile:**
- Kiểm tra quyền truy cập file
- Đảm bảo có đủ dung lượng lưu trữ

### **Debug tips:**
```dart
// Thêm log để debug
print('PDF size: ${pdfBytes.length} bytes');
print('Order ID: ${order.id}');
print('Device count: ${order.devices.length}');
print('Group count: ${groupedDevices.length}');
```

## 📈 Performance Optimization

### **1. Lazy loading:**
- Tạo PDF theo từng trang
- Sử dụng `pw.MultiPage()` cho nhiều trang

### **2. Memory management:**
- Giải phóng font data sau khi sử dụng
- Sử dụng `compute()` cho heavy operations

### **3. Caching:**
- Cache PDF đã tạo
- Reuse PDF cho cùng một đơn hàng

## 🚀 Tính năng mở rộng

### **Có thể thêm:**
1. **QR Code trong PDF:** Hiển thị QR code của đơn hàng
2. **Barcode:** Thêm barcode cho từng device
3. **Watermark:** Thêm watermark công ty
4. **Digital signature:** Ký số PDF
5. **Password protection:** Bảo vệ PDF bằng mật khẩu
6. **Multiple formats:** Export sang Excel, CSV
7. **Email integration:** Gửi PDF qua email
8. **Cloud storage:** Lưu PDF lên cloud
9. **Collapse/Expand groups:** Thu gọn/mở rộng nhóm trong PDF
10. **Custom templates:** Mẫu PDF khác nhau cho từng loại đơn hàng

---

*Document này được cập nhật ngày: 2025-08-04*
*Phiên bản: 6.0*
*Dự án: QR Homegy* 