# Cải thiện Loading khi chọn trạng thái

## Mô tả
Cải thiện trải nghiệm người dùng bằng cách chỉ hiển thị loading ở phần danh sách khi chọn trạng thái, thay vì loading toàn màn hình như trước đây.

## Vấn đề trước đây
- Khi click vào icon trạng thái (Chờ xử lý, Hoàn thành, Đã hủy), toàn bộ màn hình hiển thị loading spinner
- Phần thống kê cũng bị ẩn đi trong quá trình loading
- Trải nghiệm người dùng không tốt, cảm giác chậm và không mượt mà

## Giải pháp
Thêm biến loading riêng cho phần danh sách (`_isLoadingList`) và cập nhật logic hiển thị:

### 1. **OrderCodeAllScreen** (Tab Mã QR)
```dart
// Thêm biến loading riêng
bool _isLoadingList = false;

// Cập nhật method filter
void _filterByStatus(String? status) async {
  setState(() {
    _selectedStatusFilter = status;
    _isLoadingList = true; // Chỉ loading phần list
  });
  
  try {
    // Chỉ load filtered orders, không load lại all orders
    final orders = await ApiService.getOrders(status: status == 'all' ? null : status);
    setState(() {
      _filteredOrders = orders;
      _isLoadingList = false;
    });
  } catch (e) {
    // Handle error
  }
}

// Cập nhật UI
Expanded(
  child: _isLoadingList
      ? const Center(child: CircularProgressIndicator())
      : _filteredOrders.isEmpty
          ? Center(child: ...) // Empty state
          : ListView.builder(...) // List content
)
```

### 2. **StatisticsScreen** (Tab Thống kê)
```dart
// Thêm biến loading riêng
bool _isLoadingList = false;

// Cập nhật method filter
void _filterByStatCard(String filterStatus) async {
  setState(() {
    _selectedFilter = filterStatus == 'all' ? null : filterStatus;
    _page = 1;
    _isLoadingList = true; // Chỉ loading phần list
  });
  
  try {
    // Get filtered data for display
    final result = await ApiService.getInventoryDevices(
      page: 1,
      limit: _limit,
      isActive: activeFilter,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    setState(() {
      _devices = devices;
      _isLoadingList = false;
    });
  } catch (e) {
    // Handle error
  }
}

// Cập nhật UI
Expanded(
  child: _isLoadingList
      ? const Center(child: CircularProgressIndicator())
      : _filteredDevices.isEmpty
          ? Center(child: ...) // Empty state
          : Scrollbar(...) // List content
)
```

### 3. **CustomerListScreen** (Tab Khách hàng)
```dart
// Thêm biến loading riêng
bool _isLoadingList = false;

// Cập nhật method filter (local filtering)
void _filterByStatus(String? status) {
  setState(() {
    _selectedStatusFilter = status;
    _isLoadingList = true; // Chỉ loading phần list
  });
  
  // Simulate loading delay for better UX (since this is local filtering)
  Future.delayed(const Duration(milliseconds: 300), () {
    if (mounted) {
      _applyFilters();
      setState(() {
        _isLoadingList = false;
      });
    }
  });
}

// Cập nhật UI
if (_isLoadingList)
  Expanded(child: const Center(child: CircularProgressIndicator()))
else if (_filteredCustomers.isEmpty)
  Expanded(child: Center(child: ...)) // Empty state
else
  Expanded(child: ListView.builder(...)) // List content
```

## Lợi ích

### 1. **Trải nghiệm người dùng tốt hơn**
- Phần thống kê luôn hiển thị, không bị ẩn khi loading
- Loading chỉ xuất hiện ở phần cần thiết (danh sách)
- Cảm giác ứng dụng nhanh và mượt mà hơn

### 2. **Visual Feedback rõ ràng**
- Người dùng biết chính xác phần nào đang được cập nhật
- Không bị mất context khi loading
- Dễ dàng theo dõi tiến trình

### 3. **Performance tối ưu**
- Không reload lại dữ liệu thống kê không cần thiết
- Giảm số lần gọi API
- Tối ưu memory usage

### 4. **Consistency**
- Áp dụng cùng pattern cho tất cả các tab
- Code dễ maintain và mở rộng
- Behavior nhất quán

## API Calls được tối ưu

### **OrderCodeAllScreen**
- **Trước**: Gọi 2 lần `getOrders()` (all + filtered)
- **Sau**: Chỉ gọi 1 lần `getOrders()` với filter parameter

### **StatisticsScreen**
- **Trước**: Gọi lại toàn bộ `getInventoryDevices()`
- **Sau**: Chỉ gọi `getInventoryDevices()` với filter parameter

### **CustomerListScreen**
- **Trước**: Không có loading feedback
- **Sau**: Có loading feedback với delay nhỏ cho UX tốt hơn

## Kết quả
- ✅ Loading chỉ hiển thị ở phần danh sách
- ✅ Phần thống kê luôn hiển thị
- ✅ Trải nghiệm người dùng mượt mà hơn
- ✅ Performance được cải thiện
- ✅ Code dễ maintain hơn
