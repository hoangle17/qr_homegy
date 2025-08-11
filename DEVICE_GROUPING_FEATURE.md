# 📱 Tính năng Nhóm Thiết bị theo Loại - Màn hình Chi tiết Đơn hàng

## 📋 Tổng quan

Màn hình chi tiết đơn hàng đã được cập nhật để hiển thị các thiết bị theo nhóm dựa trên `skuCatalog.name` từ response API. Tính năng này giúp người dùng dễ dàng phân biệt và quản lý các loại thiết bị khác nhau trong cùng một đơn hàng.

## 🔄 Thay đổi chính

### **1. Cập nhật Model Device**

#### **Thêm class SkuCatalog:**
```dart
class SkuCatalog {
  final String skuCode;
  final String name;
  final String? description;
  final String? manufacturer;
  final String? category;

  SkuCatalog({
    required this.skuCode,
    required this.name,
    this.description,
    this.manufacturer,
    this.category,
  });

  factory SkuCatalog.fromJson(Map<String, dynamic> json) {
    return SkuCatalog(
      skuCode: json['skuCode'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      manufacturer: json['manufacturer'],
      category: json['category'],
    );
  }
}
```

#### **Cập nhật class Device:**
```dart
class Device {
  // ... existing fields
  final SkuCatalog? skuCatalog;

  Device({
    // ... existing parameters
    this.skuCatalog,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      // ... existing fields
      skuCatalog: json['skuCatalog'] != null ? SkuCatalog.fromJson(json['skuCatalog']) : null,
    );
  }
}
```

### **2. Logic Nhóm Thiết bị**

#### **Hàm `_buildGroupedDevices()`:**
```dart
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
    // Header cho nhóm
    widgets.add(_buildGroupHeader(groupName, devices.length));
    
    // Danh sách thiết bị trong nhóm
    for (final device in devices) {
      widgets.add(_buildDeviceCard(device));
    }
  });
  
  return widgets;
}
```

## 🎨 Giao diện mới

### **Cấu trúc hiển thị:**
```
┌─────────────────────────────────────┐
│ 📱 Công tắc wifi tuya (2 thiết bị)  │ ← Group Header
├─────────────────────────────────────┤
│ ☑️ DE:FM:D0:15:40:00               │
│    Mã sản phẩm: TUYA_WIFI_SW_01    │
│    Mô tả: Công tắc wifi tuya       │
│    [Kích hoạt] [Miễn phí]          │
│                                     │
│ ☑️ DE:FM:DC:B6:40:00               │
│    Mã sản phẩm: TUYA_WIFI_SW_01    │
│    Mô tả: Công tắc wifi tuya       │
│    [Chưa kích hoạt] [Miễn phí]     │
├─────────────────────────────────────┤
│ 📱 Cảm biến nhiệt độ (1 thiết bị)  │ ← Group Header
├─────────────────────────────────────┤
│ ☑️ DE:FM:DC:B6:40:01               │
│    Mã sản phẩm: TEMP_SENSOR_01     │
│    Mô tả: Cảm biến nhiệt độ        │
│    [Kích hoạt] [Đã thanh toán]     │
└─────────────────────────────────────┘
```

### **Group Header:**
- **Icon:** 📱 (category icon)
- **Tên nhóm:** Tên từ `skuCatalog.name`
- **Số lượng:** Số thiết bị trong nhóm
- **Styling:** Background màu tím nhạt với border

### **Device Card:**
- **Checkbox:** Chọn thiết bị để chia sẻ QR
- **MAC Address:** Copyable text
- **SKU Code:** Copyable text
- **Mô tả:** Từ `skuCatalog.description` (nếu có)
- **Status badges:** Kích hoạt/Chưa kích hoạt + Trạng thái thanh toán
- **QR Icon:** Mở màn hình QR code

## 🌐 Response API Structure

### **Expected API Response:**
```json
{
  "success": true,
  "data": {
    "order": {
      "id": "f19cb0c2-8c75-4b76-9bec-8c869f1f64a8",
      "status": "completed",
      "created_at": "2025-08-05T09:08:21.329Z",
      "created_by": "hoanglvhomegy@gmail.com",
      "customer_id": "vietnam9128@gmail.com",
      "note": "hoang tạo 1234"
    },
    "deviceInventories": [
      {
        "id": "bb9bfac0-b004-4390-9d50-47526e4b539d",
        "skuCode": "TUYA_WIFI_SW_01",
        "macAddress": "DE:FM:D0:15:40:00",
        "isActive": false,
        "payment_status": "free",
        "skuCatalog": {
          "skuCode": "TUYA_WIFI_SW_01",
          "name": "Công tắc wifi tuya",
          "description": "Công tắc wifi tuya",
          "manufacturer": null,
          "category": null
        }
      }
    ]
  }
}
```

## 🎯 Tính năng mới

### **1. Nhóm tự động:**
- Tự động nhóm thiết bị theo `skuCatalog.name`
- Thiết bị không có `skuCatalog` sẽ được nhóm vào "Thiết bị khác"

### **2. Hiển thị thông tin chi tiết:**
- **Tên nhóm:** Từ `skuCatalog.name`
- **Mô tả:** Từ `skuCatalog.description`
- **Số lượng:** Tổng số thiết bị trong nhóm

### **3. Status badges:**
- **Trạng thái kích hoạt:** Xanh (Kích hoạt) / Đỏ (Chưa kích hoạt)
- **Trạng thái thanh toán:** 
  - Xanh dương (Miễn phí)
  - Xanh lá (Đã thanh toán)
  - Cam (Chờ thanh toán)
  - Đỏ (Đã hủy)

### **4. Tương tác:**
- **Checkbox:** Chọn thiết bị để chia sẻ QR
- **Copyable text:** MAC Address và SKU Code
- **QR Icon:** Mở màn hình QR code
- **Group header:** Hiển thị tổng quan nhóm

## 🛠️ Cải thiện UX

### **1. Dễ phân biệt:**
- Thiết bị được nhóm theo loại
- Mỗi nhóm có header riêng biệt
- Màu sắc và icon phân biệt

### **2. Thông tin đầy đủ:**
- Hiển thị mô tả thiết bị
- Status badges rõ ràng
- Số lượng thiết bị trong nhóm

### **3. Tương tác tốt hơn:**
- Copyable text cho thông tin quan trọng
- Checkbox để chọn nhiều thiết bị
- QR code cho từng thiết bị

## 🔧 Helper Functions

### **1. `_getPaymentStatusColor()`:**
```dart
Color _getPaymentStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'free': return Colors.blue;
    case 'paid': return Colors.green;
    case 'pending': return Colors.orange;
    case 'cancelled': return Colors.red;
    default: return Colors.grey;
  }
}
```

### **2. `_getPaymentStatusText()`:**
```dart
String _getPaymentStatusText(String status) {
  switch (status.toLowerCase()) {
    case 'free': return 'Miễn phí';
    case 'paid': return 'Đã thanh toán';
    case 'pending': return 'Chờ thanh toán';
    case 'cancelled': return 'Đã hủy';
    default: return status;
  }
}
```

## 📊 Benefits

### **Cho người dùng:**
- ✅ **Dễ phân biệt** - thiết bị được nhóm theo loại
- ✅ **Thông tin đầy đủ** - hiển thị mô tả và trạng thái
- ✅ **Tương tác tốt** - copyable text và QR code
- ✅ **Quản lý dễ dàng** - chọn nhiều thiết bị cùng lúc

### **Cho developer:**
- ✅ **Code sạch** - tách biệt logic nhóm và hiển thị
- ✅ **Dễ mở rộng** - thêm loại thiết bị mới
- ✅ **Maintainable** - cấu trúc rõ ràng
- ✅ **Reusable** - có thể áp dụng cho màn hình khác

## 🚀 Tính năng tương lai

### **Có thể mở rộng:**
1. **Filter theo nhóm:** Lọc thiết bị theo loại
2. **Search trong nhóm:** Tìm kiếm thiết bị trong nhóm cụ thể
3. **Collapse/Expand:** Thu gọn/mở rộng nhóm
4. **Sort nhóm:** Sắp xếp nhóm theo tên hoặc số lượng
5. **Bulk actions:** Thao tác hàng loạt trên nhóm
6. **Statistics:** Thống kê theo nhóm thiết bị

---

*Document này được tạo ngày: 2025-08-04*
*Phiên bản: 1.0*
*Dự án: QR Homegy* 