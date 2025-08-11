# 👥 Tính năng Phân loại Khách hàng - QR Homegy

## 📋 Tổng quan

Đã thêm tính năng phân loại khách hàng vào màn hình thêm khách hàng, cho phép người dùng chọn loại khách hàng: Nhà phân phối, Khách hàng, hoặc Đại lý. Tính năng này tương ứng với các role trong API: DISTRIBUTOR, CUSTOMER, AGENT.

## 🎯 Tính năng chính

### **1. Phân loại khách hàng:**
- ✅ **Nhà phân phối** (Distributor) - Role: `DISTRIBUTOR`
- ✅ **Khách hàng** (Customer) - Role: `CUSTOMER`  
- ✅ **Đại lý** (Agent) - Role: `AGENT`

### **2. UI/UX:**
- ✅ Dropdown để chọn loại khách hàng
- ✅ Tự động cập nhật label và hint text theo loại
- ✅ Validation cho trường phân loại
- ✅ Màu sắc khác nhau cho từng loại

### **3. API Integration:**
- ✅ Gửi đúng role tương ứng với type
- ✅ Hỗ trợ lấy danh sách tất cả loại khách hàng
- ✅ Backward compatibility với code cũ

## 🏗️ Code Changes

### **1. CustomerAddScreen (`lib/screens/home/customer_add_screen.dart`):**

#### **Thêm state variable:**
```dart
String _selectedCustomerType = 'agent'; // Default value
```

#### **Cập nhật getter cho display name:**
```dart
String get _customerTypeDisplayName {
  switch (_selectedCustomerType) {
    case 'distributor':
      return 'Nhà phân phối';
    case 'customer':
      return 'Khách hàng';
    case 'agent':
      return 'Đại lý';
    default:
      return 'Đại lý';
  }
}
```

#### **Thêm Dropdown UI:**
```dart
DropdownButtonFormField<String>(
  value: _selectedCustomerType,
  decoration: InputDecoration(
    labelText: 'Phân loại khách hàng',
    border: const OutlineInputBorder(),
    prefixIcon: const Icon(Icons.category),
  ),
  items: const [
    DropdownMenuItem(
      value: 'distributor',
      child: Text('Nhà phân phối'),
    ),
    DropdownMenuItem(
      value: 'customer',
      child: Text('Khách hàng'),
    ),
    DropdownMenuItem(
      value: 'agent',
      child: Text('Đại lý'),
    ),
  ],
  onChanged: (String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedCustomerType = newValue;
      });
    }
  },
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng chọn phân loại khách hàng';
    }
    return null;
  },
),
```

#### **Cập nhật API call:**
```dart
final result = await CustomerService.addCustomer(
  name: _nameController.text.trim(),
  phone: _phoneController.text.trim(),
  email: _emailController.text.trim(),
  address: _addressController.text.trim(),
  type: _selectedCustomerType, // Sử dụng type được chọn
);
```

### **2. CustomerService (`lib/services/customer_service.dart`):**

#### **Cập nhật addCustomer method:**
```dart
// Map type to role
String role;
switch (type.toLowerCase()) {
  case 'distributor':
    role = 'DISTRIBUTOR';
    break;
  case 'customer':
    role = 'CUSTOMER';
    break;
  case 'agent':
  default:
    role = 'AGENT';
    break;
}

final result = await ApiService.registerUser(
  email: email,
  password: 'defaultPassword123',
  name: name,
  phone: phone,
  region: address,
  role: role, // Sử dụng role được map
);
```

#### **Cập nhật getCustomers method:**
```dart
// Lấy tất cả các loại khách hàng
final List<dynamic> allUsers = [];

// Lấy distributors
try {
  final distributors = await ApiService.getAllUsers(role: 'DISTRIBUTOR');
  allUsers.addAll(distributors);
} catch (e) {
  // Ignore if role doesn't exist
}

// Lấy customers
try {
  final customers = await ApiService.getAllUsers(role: 'CUSTOMER');
  allUsers.addAll(customers);
} catch (e) {
  // Ignore if role doesn't exist
}

// Lấy agents
try {
  final agents = await ApiService.getAllUsers(role: 'AGENT');
  allUsers.addAll(agents);
} catch (e) {
  // Ignore if role doesn't exist
}
```

### **3. Customer Model (`lib/models/customer.dart`):**

#### **Cập nhật typeDisplayName:**
```dart
String get typeDisplayName {
  switch (role.toUpperCase()) {
    case 'DISTRIBUTOR':
      return 'Nhà phân phối';
    case 'CUSTOMER':
      return 'Khách hàng';
    case 'AGENT':
    default:
      return 'Đại lý';
  }
}
```

#### **Cập nhật typeColor:**
```dart
Color get typeColor {
  switch (role.toUpperCase()) {
    case 'DISTRIBUTOR':
      return Colors.purple;
    case 'CUSTOMER':
      return Colors.green;
    case 'AGENT':
    default:
      return Colors.blue;
  }
}
```

#### **Cập nhật type getter:**
```dart
String get type {
  switch (role.toUpperCase()) {
    case 'DISTRIBUTOR':
      return 'distributor';
    case 'CUSTOMER':
      return 'customer';
    case 'AGENT':
    default:
      return 'agent';
  }
}
```

## 🎨 UI Changes

### **Trước khi thay đổi:**
```
┌─────────────────────────────────────┐
│ Thêm khách hàng                    │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Tên Đại lý                     │ │ ← Hardcoded
│ │ [_____________________________] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Số điện thoại                  │ │
│ │ [_____________________________] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Email                           │ │
│ │ [_____________________________] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Địa chỉ                         │ │
│ │ [_____________________________] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [        Thêm Đại lý        ]      │ ← Hardcoded
└─────────────────────────────────────┘
```

### **Sau khi thay đổi:**
```
┌─────────────────────────────────────┐
│ Thêm khách hàng                    │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Phân loại khách hàng            │ │ ← NEW DROPDOWN
│ │ [▼ Nhà phân phối ▼]            │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Tên Nhà phân phối              │ │ ← Dynamic
│ │ [_____________________________] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Số điện thoại                  │ │
│ │ [_____________________________] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Email                           │ │
│ │ [_____________________________] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Địa chỉ                         │ │
│ │ [_____________________________] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [    Thêm Nhà phân phối    ]       │ ← Dynamic
└─────────────────────────────────────┘
```

## 🔄 Quy trình hoạt động

### **1. Chọn loại khách hàng:**
1. User mở dropdown "Phân loại khách hàng"
2. Chọn một trong 3 loại: Nhà phân phối, Khách hàng, Đại lý
3. UI tự động cập nhật:
   - Label "Tên" thay đổi theo loại
   - Button "Thêm" thay đổi theo loại
   - Hint text thay đổi theo loại

### **2. Validation:**
1. Kiểm tra đã chọn phân loại chưa
2. Kiểm tra các trường bắt buộc khác
3. Hiển thị lỗi nếu chưa chọn phân loại

### **3. API Call:**
1. Map type sang role tương ứng:
   - `distributor` → `DISTRIBUTOR`
   - `customer` → `CUSTOMER`
   - `agent` → `AGENT`
2. Gọi API `/api/users/register` với role đúng
3. Hiển thị thông báo thành công/thất bại

## 📊 Mapping Table

| UI Display | Type Value | API Role | Color |
|------------|------------|----------|-------|
| Nhà phân phối | `distributor` | `DISTRIBUTOR` | Purple |
| Khách hàng | `customer` | `CUSTOMER` | Green |
| Đại lý | `agent` | `AGENT` | Blue |

## 🔧 API Integration

### **1. Register API:**
```json
POST /api/users/register
{
  "email": "user@example.com",
  "password": "defaultPassword123",
  "name": "Tên khách hàng",
  "phone": "0123456789",
  "region": "Địa chỉ",
  "role": "DISTRIBUTOR" // hoặc "CUSTOMER", "AGENT"
}
```

### **2. Get Users API:**
```json
GET /api/users?role=DISTRIBUTOR
GET /api/users?role=CUSTOMER
GET /api/users?role=AGENT
```

## 🎯 User Experience

### **1. Intuitive Selection:**
- ✅ Dropdown rõ ràng với 3 lựa chọn
- ✅ Icon category để dễ nhận biết
- ✅ Validation ngay lập tức

### **2. Dynamic UI:**
- ✅ Label thay đổi theo loại được chọn
- ✅ Button text thay đổi theo loại
- ✅ Hint text phù hợp với từng loại

### **3. Visual Feedback:**
- ✅ Màu sắc khác nhau cho từng loại
- ✅ Icon phù hợp với từng loại
- ✅ Thông báo rõ ràng khi thành công

## 🚀 Tính năng mở rộng

### **Có thể thêm:**
1. **Filter theo loại:** Lọc danh sách khách hàng theo loại
2. **Statistics:** Thống kê số lượng từng loại
3. **Permissions:** Phân quyền theo loại khách hàng
4. **Custom fields:** Trường tùy chỉnh cho từng loại
5. **Bulk operations:** Thao tác hàng loạt theo loại
6. **Export/Import:** Xuất/nhập theo loại khách hàng

## 🔒 Backward Compatibility

### **1. Existing Code:**
- ✅ Tất cả code cũ vẫn hoạt động
- ✅ Customer model có getter `type` tương thích
- ✅ Service methods không thay đổi signature

### **2. Default Values:**
- ✅ Default type là 'agent' (Đại lý)
- ✅ Default role là 'AGENT'
- ✅ Fallback cho các trường hợp không xác định

## 📋 Summary

### **Đã thêm:**
- ✅ Dropdown phân loại khách hàng
- ✅ 3 loại: Nhà phân phối, Khách hàng, Đại lý
- ✅ Dynamic UI theo loại được chọn
- ✅ API integration với role mapping
- ✅ Validation và error handling
- ✅ Color coding cho từng loại

### **Cải thiện:**
- ✅ UX tốt hơn với dropdown
- ✅ Flexibility trong quản lý khách hàng
- ✅ Scalability cho tương lai
- ✅ Maintainability với code clean

### **Kết quả:**
- ✅ Tính năng hoàn chỉnh và sẵn sàng sử dụng
- ✅ Tương thích với API hiện tại
- ✅ UI/UX intuitive và user-friendly
- ✅ Code maintainable và extensible

---

*Document này được cập nhật ngày: 2025-08-04*
*Phiên bản: 1.0*
*Dự án: QR Homegy*
