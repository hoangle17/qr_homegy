# 🔐 Tính năng "Ghi nhớ đăng nhập" - QR Homegy

## 📋 Tổng quan

Tính năng "Ghi nhớ đăng nhập" cho phép người dùng lưu email và mật khẩu để đăng nhập nhanh chóng trong lần tiếp theo. Tính năng này được bảo mật bằng mã hóa mật khẩu trước khi lưu trữ.

## 🎯 Tính năng chính

### **1. Lưu thông tin đăng nhập:**
- ✅ Lưu email và mật khẩu khi chọn "Ghi nhớ đăng nhập"
- ✅ Mã hóa mật khẩu trước khi lưu vào SharedPreferences
- ✅ Tự động điền thông tin khi mở lại ứng dụng

### **2. Bảo mật:**
- ✅ Mã hóa mật khẩu bằng Base64 + XOR encryption
- ✅ Key mã hóa: `QR_HOMEGY_2024`
- ✅ Xử lý lỗi khi giải mã thất bại

### **3. Quản lý dữ liệu:**
- ✅ Giữ lại thông tin remember me khi logout
- ✅ Xóa tự động khi bỏ chọn "Ghi nhớ đăng nhập"
- ✅ Lưu trữ an toàn trong SharedPreferences

## 🏗️ Kiến trúc Code

### **1. Mã hóa mật khẩu:**

```dart
String _encryptPassword(String password) {
  final bytes = utf8.encode(password);
  final encoded = base64.encode(bytes);
  // XOR với key đơn giản
  final key = 'QR_HOMEGY_2024';
  String encrypted = '';
  for (int i = 0; i < encoded.length; i++) {
    encrypted += String.fromCharCode(encoded.codeUnitAt(i) ^ key.codeUnitAt(i % key.length));
  }
  return base64.encode(utf8.encode(encrypted));
}
```

### **2. Giải mã mật khẩu:**

```dart
String _decryptPassword(String encryptedPassword) {
  try {
    final encryptedBytes = base64.decode(encryptedPassword);
    final encrypted = utf8.decode(encryptedBytes);
    final key = 'QR_HOMEGY_2024';
    String decrypted = '';
    for (int i = 0; i < encrypted.length; i++) {
      decrypted += String.fromCharCode(encrypted.codeUnitAt(i) ^ key.codeUnitAt(i % key.length));
    }
    final decodedBytes = base64.decode(decrypted);
    return utf8.decode(decodedBytes);
  } catch (e) {
    return '';
  }
}
```

### **3. Lưu thông tin đăng nhập:**

```dart
Future<void> _saveUserInfo(Map<String, dynamic> loginResponse) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', loginResponse['token']);
  await prefs.setString('user_email', loginResponse['user']['email']);
  await prefs.setString('user_info', jsonEncode(loginResponse['user']));
  
  // Lưu email và mật khẩu nếu chọn "Ghi nhớ đăng nhập"
  if (_rememberMe) {
    await prefs.setString('saved_email', loginResponse['user']['email']);
    // Mã hóa mật khẩu trước khi lưu
    final encryptedPassword = _encryptPassword(_passwordController.text);
    await prefs.setString('saved_password', encryptedPassword);
    await prefs.setBool('remember_me', true);
  } else {
    // Xóa email và mật khẩu đã lưu nếu không chọn "Ghi nhớ đăng nhập"
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
    await prefs.setBool('remember_me', false);
  }
}
```

### **4. Load thông tin đã lưu:**

```dart
Future<void> _loadSavedCredentials() async {
  final prefs = await SharedPreferences.getInstance();
  final rememberMe = prefs.getBool('remember_me') ?? false;
  
  if (rememberMe) {
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _phoneController.text = savedEmail;
        _rememberMe = true;
      });
      
      // Tự động điền mật khẩu nếu có (giải mã trước)
      if (savedPassword != null && savedPassword.isNotEmpty) {
        final decryptedPassword = _decryptPassword(savedPassword);
        if (decryptedPassword.isNotEmpty) {
          _passwordController.text = decryptedPassword;
        }
      }
    }
  }
}
```

## 🔄 Quy trình hoạt động

### **1. Đăng nhập lần đầu:**
1. User nhập email và mật khẩu
2. Chọn checkbox "Ghi nhớ đăng nhập"
3. Click "Đăng nhập"
4. Hệ thống mã hóa mật khẩu và lưu vào SharedPreferences
5. Lưu email và trạng thái remember_me

### **2. Mở lại ứng dụng:**
1. Kiểm tra trạng thái remember_me
2. Nếu true, load email và mật khẩu đã lưu
3. Giải mã mật khẩu
4. Tự động điền vào form đăng nhập
5. Checkbox "Ghi nhớ đăng nhập" được chọn

### **3. Đăng xuất:**
1. User click "Đăng xuất"
2. Hiển thị dialog xác nhận đăng xuất
3. Xóa thông tin đăng nhập hiện tại (auth_token, user_email, user_info)
4. Giữ lại thông tin remember me (nếu có)
5. Chuyển về màn hình đăng nhập

## 📊 Dữ liệu lưu trữ

### **SharedPreferences Keys:**

| Key | Type | Mô tả |
|-----|------|-------|
| `auth_token` | String | Token xác thực |
| `user_email` | String | Email người dùng hiện tại |
| `user_info` | String | Thông tin user (JSON) |
| `saved_email` | String | Email đã lưu cho remember me |
| `saved_password` | String | Mật khẩu đã mã hóa |
| `remember_me` | Bool | Trạng thái ghi nhớ đăng nhập |

### **Ví dụ dữ liệu:**

```json
{
  "auth_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_email": "user@example.com",
  "user_info": "{\"id\":1,\"email\":\"user@example.com\",\"name\":\"User Name\"}",
  "saved_email": "user@example.com",
  "saved_password": "U1RfSE9NRVlZXzIwMjQ=",
  "remember_me": true
}
```

## 🔒 Bảo mật

### **1. Mã hóa mật khẩu:**
- **Algorithm:** Base64 + XOR encryption
- **Key:** `QR_HOMEGY_2024`
- **Layers:** 2 lớp mã hóa (Base64 → XOR → Base64)

### **2. Xử lý lỗi:**
- Try-catch khi giải mã
- Trả về chuỗi rỗng nếu giải mã thất bại
- Không crash ứng dụng khi dữ liệu bị hỏng

### **3. Quản lý dữ liệu:**
- Xóa dữ liệu khi không cần thiết
- Giữ lại thông tin remember me khi logout
- Không lưu dữ liệu nhạy cảm không cần thiết

## 🎨 User Experience

### **1. Giao diện:**
- Checkbox "Ghi nhớ đăng nhập" rõ ràng
- Tự động điền thông tin khi mở app
- Dialog xác nhận khi logout

### **2. Tương tác:**
- Smooth experience khi đăng nhập
- Không cần nhập lại thông tin
- Giữ lại thông tin đã lưu khi logout

### **3. Feedback:**
- Hiển thị thông tin đã lưu khi logout
- Xác nhận đăng xuất đơn giản
- Thông báo rõ ràng về tính năng

## 🛠️ Customization

### **1. Thay đổi key mã hóa:**
```dart
final key = 'YOUR_CUSTOM_KEY_HERE';
```

### **2. Thay đổi algorithm mã hóa:**
```dart
// Có thể thay đổi sang AES, RSA, hoặc algorithm khác
String _encryptPassword(String password) {
  // Implement your encryption algorithm
}
```

### **3. Thêm validation:**
```dart
// Kiểm tra độ mạnh mật khẩu trước khi lưu
if (password.length < 6) {
  return false; // Không lưu mật khẩu yếu
}
```

## 🔧 Troubleshooting

### **Lỗi thường gặp:**

#### **1. Không tự động điền:**
- Kiểm tra trạng thái remember_me
- Kiểm tra dữ liệu trong SharedPreferences
- Kiểm tra lỗi giải mã mật khẩu

#### **2. Lỗi mã hóa/giải mã:**
- Kiểm tra key mã hóa
- Kiểm tra format dữ liệu
- Xử lý exception trong try-catch

#### **3. Dữ liệu bị mất:**
- Kiểm tra quyền truy cập SharedPreferences
- Kiểm tra storage space
- Backup dữ liệu quan trọng

### **Debug tips:**
```dart
// Thêm log để debug
print('Remember me: $_rememberMe');
print('Saved email: $savedEmail');
print('Encrypted password: $savedPassword');
```

## 🚀 Tính năng mở rộng

### **Có thể thêm:**
1. **Biometric authentication:** Sử dụng vân tay/face ID
2. **Auto-login:** Tự động đăng nhập khi mở app
3. **Multiple accounts:** Lưu nhiều tài khoản
4. **Sync across devices:** Đồng bộ dữ liệu
5. **Password strength check:** Kiểm tra độ mạnh mật khẩu
6. **Auto-logout:** Tự động đăng xuất sau thời gian
7. **Session management:** Quản lý phiên đăng nhập
8. **Security audit:** Ghi log bảo mật

---

*Document này được cập nhật ngày: 2025-08-04*
*Phiên bản: 1.0*
*Dự án: QR Homegy* 