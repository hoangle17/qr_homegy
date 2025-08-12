# Phân tích tính năng Tìm kiếm đơn hàng theo ngày

## Tổng quan
Tính năng tìm kiếm đơn hàng theo ngày cho phép người dùng lọc và tìm kiếm đơn hàng dựa trên khoảng thời gian tạo đơn hàng. Tính năng này được tích hợp trong màn hình `OrderSearchScreen` với hai chế độ tìm kiếm: **Tìm kiếm chi tiết** và **Tìm kiếm tổng quát**.

## Cấu trúc tính năng

### 1. Giao diện người dùng (UI)

#### Chế độ tìm kiếm chi tiết
- **Trường tìm kiếm theo ngày**: 
  - `Từ ngày`: DatePicker cho phép chọn ngày bắt đầu
  - `Đến ngày`: DatePicker cho phép chọn ngày kết thúc
- **Các trường khác**:
  - Email khách hàng/đại lý
  - Email người tạo
  - Trạng thái đơn hàng

#### Chế độ tìm kiếm tổng quát
- **Trường tìm kiếm**: Một ô text duy nhất cho phép nhập từ khóa
- **Không hỗ trợ tìm kiếm theo ngày**: Chế độ này không có tùy chọn tìm kiếm theo ngày

### 2. Logic xử lý

#### State Management
```dart
DateTime? _fromDate;  // Ngày bắt đầu
DateTime? _toDate;    // Ngày kết thúc
bool _useGeneralSearch = false;  // Chế độ tìm kiếm
```

#### Chuyển đổi chế độ tìm kiếm
```dart
void _switchMode(bool general) {
  // Reset tất cả input khi chuyển chế độ
  _fromDate = null;
  _toDate = null;
  _useGeneralSearch = general;
  _searchResults.clear();
}
```

#### Xử lý tìm kiếm
```dart
Future<void> _searchOrders() async {
  if (_useGeneralSearch) {
    // Tìm kiếm tổng quát - không sử dụng ngày
    orders = await ApiService.searchOrders(_queryController.text.trim());
  } else {
    // Tìm kiếm chi tiết - có sử dụng ngày
    
    // Xử lý ngày "Đến" - thêm 1 ngày để bao gồm toàn bộ ngày được chọn
    // Lý do: API thường lọc theo timestamp, nên cần thêm 1 ngày để bao gồm tất cả dữ liệu trong ngày đó
    DateTime? adjustedToDate = _toDate;
    if (_toDate != null) {
      adjustedToDate = _toDate!.add(const Duration(days: 1));
    }
    
    orders = await ApiService.getOrders(
      status: _selectedStatus,
      customerId: _customerIdController.text.trim(),
      createdBy: _createdByController.text.trim(),
      fromDate: _fromDate,  // Ngày bắt đầu
      toDate: adjustedToDate, // Ngày kết thúc (đã được điều chỉnh)
    );
  }
}
```

### 3. API Integration

#### Endpoint
```
GET /api/orders
```

#### Query Parameters
```dart
final queryParams = <String, String>{};
if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String().split('T')[0];
if (toDate != null) queryParams['to_date'] = toDate.toIso8601String().split('T')[0];
```

#### Format ngày
- **Input**: DateTime object từ DatePicker
- **Output**: String format `YYYY-MM-DD` (ISO 8601 date only)
- **Ví dụ**: `2024-01-15`

### 4. DatePicker Implementation

#### Cấu hình DatePicker
```dart
final date = await showDatePicker(
  context: context,
  initialDate: _fromDate ?? DateTime.now(),
  firstDate: DateTime(2020),      // Ngày sớm nhất có thể chọn
  lastDate: DateTime.now(),       // Ngày muộn nhất có thể chọn (hôm nay)
);
```

#### Visual Feedback
```dart
ElevatedButton.icon(
  onPressed: () async { /* DatePicker logic */ },
  label: Text(
    _fromDate != null 
      ? 'Từ: ${_formatDateOnly(_fromDate!)}'  // Hiển thị ngày đã chọn
      : 'Từ ngày'                            // Placeholder
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: _fromDate != null ? Colors.green : Colors.grey,  // Màu xanh khi đã chọn
    foregroundColor: Colors.white,
  ),
)
```

### 5. Format ngày

#### Format hiển thị
```dart
String _formatDateOnly(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year.toString();
  return '$day-$month-$year';  // Format: DD-MM-YYYY
}
```

#### Format API
```dart
fromDate.toIso8601String().split('T')[0]  // Format: YYYY-MM-DD
```

#### Xử lý đặc biệt cho ngày "Đến"
```dart
// Thêm 1 ngày vào ngày "Đến" trước khi gọi API
DateTime? adjustedToDate = _toDate;
if (_toDate != null) {
  adjustedToDate = _toDate!.add(const Duration(days: 1));
}
```

**Lý do thêm 1 ngày:**
- API thường lọc theo timestamp (giờ:phút:giây)
- Khi user chọn "Đến ngày: 15/01/2024", họ muốn bao gồm tất cả dữ liệu trong ngày 15/01/2024
- Nếu không thêm 1 ngày, API sẽ chỉ lấy đến 00:00:00 của ngày 15/01/2024
- Thêm 1 ngày giúp bao gồm toàn bộ 24 giờ của ngày được chọn

**Ví dụ minh họa:**
```
User chọn: "Đến ngày: 15/01/2024"
- Ngày gốc: 2024-01-15 00:00:00
- Ngày sau khi thêm 1 ngày: 2024-01-16 00:00:00
- Kết quả: API sẽ lấy tất cả dữ liệu từ 00:00:00 đến 23:59:59 của ngày 15/01/2024
```

## Luồng hoạt động

### 1. Khởi tạo màn hình
1. Mặc định chế độ "Tìm kiếm chi tiết"
2. Tất cả trường input rỗng
3. Không có kết quả tìm kiếm

### 2. Chọn ngày tìm kiếm
1. User click vào button "Từ ngày" hoặc "Đến ngày"
2. DatePicker hiển thị với:
   - Ngày hiện tại làm ngày mặc định
   - Giới hạn từ 2020 đến hôm nay
3. User chọn ngày
4. Button cập nhật hiển thị ngày đã chọn
5. Button chuyển màu xanh để báo hiệu đã chọn

### 3. Thực hiện tìm kiếm
1. User click "Tìm kiếm"
2. Validate form
3. Gọi API với parameters:
   - `from_date`: Ngày bắt đầu (nếu có)
   - `to_date`: Ngày kết thúc (nếu có)
   - Các parameters khác
4. Hiển thị kết quả hoặc thông báo lỗi

### 4. Xóa tìm kiếm
1. User click "Xóa tìm kiếm"
2. Reset tất cả trường input
3. Xóa kết quả tìm kiếm

## Ưu điểm và hạn chế

### Ưu điểm
1. **Giao diện trực quan**: DatePicker dễ sử dụng
2. **Flexible**: Có thể chọn chỉ từ ngày, chỉ đến ngày, hoặc cả hai
3. **Validation**: Giới hạn ngày hợp lệ (2020 - hôm nay)
4. **Visual feedback**: Button đổi màu khi đã chọn ngày
5. **Tích hợp tốt**: Hoạt động cùng với các filter khác

### Hạn chế
1. **Chỉ hỗ trợ tìm kiếm chi tiết**: Không có trong chế độ tìm kiếm tổng quát
2. **Giới hạn thời gian**: Chỉ từ 2020 đến hôm nay
3. **Không có time picker**: Chỉ chọn ngày, không chọn giờ
4. **Không có preset**: Không có tùy chọn nhanh như "7 ngày qua", "30 ngày qua"

## Cải tiến đề xuất

### 1. Thêm preset ngày
```dart
// Thêm dropdown với các tùy chọn nhanh
final List<Map<String, dynamic>> _datePresets = [
  {'name': 'Hôm nay', 'from': DateTime.now(), 'to': DateTime.now()},
  {'name': '7 ngày qua', 'from': DateTime.now().subtract(Duration(days: 7)), 'to': DateTime.now()},
  {'name': '30 ngày qua', 'from': DateTime.now().subtract(Duration(days: 30)), 'to': DateTime.now()},
  {'name': 'Tháng này', 'from': DateTime(DateTime.now().year, DateTime.now().month, 1), 'to': DateTime.now()},
];
```

### 2. Hỗ trợ tìm kiếm tổng quát theo ngày
```dart
// Thêm từ khóa đặc biệt cho ngày
if (query.contains('ngày:') || query.contains('date:')) {
  // Parse ngày từ query string
  // Ví dụ: "ngày:2024-01-15" hoặc "date:2024-01-15"
}
```

### 3. Thêm time picker
```dart
// Cho phép chọn cả giờ phút
final DateTime? dateTime = await showDatePicker(
  // ... existing code
);
if (dateTime != null) {
  final TimeOfDay? time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );
  // Combine date and time
}
```

### 4. Cải thiện validation
```dart
// Kiểm tra fromDate <= toDate
if (_fromDate != null && _toDate != null && _fromDate!.isAfter(_toDate!)) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Ngày bắt đầu phải trước ngày kết thúc')),
  );
  return;
}
```

## Kết luận

Tính năng tìm kiếm đơn hàng theo ngày được thiết kế tốt với giao diện trực quan và logic xử lý rõ ràng. Tuy nhiên, vẫn có thể cải thiện thêm để tăng tính tiện dụng và linh hoạt cho người dùng.
