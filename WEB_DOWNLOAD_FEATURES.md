# Web Download Features - QR Homegy

## Tổng quan
Ứng dụng QR Homegy đã được cập nhật để hỗ trợ tải về file trên web thay vì chỉ chia sẻ như trên mobile.

## Các tính năng mới

### 1. Tải QR Code trên Web
- **Trước đây**: Trên web chỉ hiển thị text "Mã QR: [data]"
- **Bây giờ**: Tự động tải ảnh QR code về máy khi nhấn nút "Chia sẻ"

#### Các màn hình hỗ trợ:
- `DeviceQrScreen`: QR code của device (MAC address)
- `OrderIdQrScreen`: QR code của đơn hàng (Order ID)
- `OrderCodeDetailScreen`: Chia sẻ nhiều QR codes cùng lúc

### 2. Tải PDF trên Web
- **Trước đây**: Chỉ chia sẻ file PDF trên mobile
- **Bây giờ**: Tự động tải PDF về máy khi sử dụng trên web

#### Các màn hình hỗ trợ:
- `OrderCodeAllScreen`: Tải PDF danh sách đơn hàng được chọn

### 3. Tải nhiều QR Codes
- **Trước đây**: Chia sẻ nhiều file QR codes trên mobile
- **Bây giờ**: Tải từng QR code về máy khi sử dụng trên web

## Cách hoạt động

### Platform Detection
```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  // Web: Tải về máy
  saveQrWeb(qrImageBytes);
} else {
  // Mobile: Chia sẻ
  await Share.shareXFiles([XFile(file.path)]);
}
```

### Web Download Functions
```dart
// Tải QR code đơn lẻ
void saveQrWeb(Uint8List bytes)

// Chia sẻ QR code (tải về trên web)
void shareQrWeb(Uint8List bytes)

// Tải nhiều QR codes
void shareMultipleQrWeb(List<Uint8List> qrImages, List<String> fileNames)

// Tải PDF
void savePdfWeb(Uint8List pdfBytes, String fileName)
```

## File Structure

### Core Files
- `lib/screens/home/qr_code/qr_save_web.dart`: Web download functions
- `lib/screens/home/qr_code/qr_save_mobile.dart`: Mobile stub functions

### Updated Screens
- `lib/screens/home/qr_code/device_qr_screen.dart`
- `lib/screens/home/qr_code/order_id_qr_screen.dart`
- `lib/screens/home/qr_code/order_code_detail_screen.dart`
- `lib/screens/home/qr_code/order_code_all_screen.dart`

## Import Strategy
```dart
import 'qr_save_web.dart'
    if (dart.library.io) 'qr_save_mobile.dart';
```

- **Web**: Sử dụng `qr_save_web.dart` với HTML download API
- **Mobile**: Sử dụng `qr_save_mobile.dart` với stub functions

## User Experience

### Web Users
- ✅ Tải QR code về máy khi nhấn "Chia sẻ"
- ✅ Tải PDF về máy khi nhấn "Chia sẻ PDF"
- ✅ Tải nhiều QR codes về máy cùng lúc
- ✅ Thông báo rõ ràng: "Đã tải [file] về máy!"

### Mobile Users
- ✅ Chia sẻ QR code qua các app khác
- ✅ Chia sẻ PDF qua các app khác
- ✅ Chia sẻ nhiều QR codes cùng lúc
- ✅ Thông báo: "Đã chia sẻ [file]"

## Technical Details

### Web Download Implementation
```dart
void saveQrWeb(Uint8List bytes) {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', 'qr_code.png')
    ..click();
  html.Url.revokeObjectUrl(url);
}
```

### Error Handling
- Kiểm tra platform trước khi thực hiện
- Try-catch cho các lỗi download
- Thông báo lỗi rõ ràng cho user

## Testing

### Web Testing
1. Mở ứng dụng trên web browser
2. Vào màn hình QR code bất kỳ
3. Nhấn nút "Chia sẻ"
4. Kiểm tra file được tải về

### Mobile Testing
1. Mở ứng dụng trên mobile
2. Vào màn hình QR code bất kỳ
3. Nhấn nút "Chia sẻ"
4. Kiểm tra dialog chia sẻ xuất hiện

## Benefits

### For Users
- **Web**: Tải file về máy dễ dàng
- **Mobile**: Chia sẻ qua các app khác
- **Consistent**: Trải nghiệm nhất quán trên mọi platform

### For Developers
- **Maintainable**: Code tách biệt rõ ràng
- **Extensible**: Dễ thêm tính năng mới
- **Platform-aware**: Tự động detect và xử lý phù hợp 