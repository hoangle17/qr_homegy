# APK Build Guide - QR Homegy

## 📱 Các file APK đã được tạo

### **1. APK Release (Khuyến nghị sử dụng)**
- **File:** `app-release.apk`
- **Kích thước:** 35.9 MB
- **Mô tả:** Phiên bản release hoàn chỉnh, phù hợp cho tất cả thiết bị Android
- **Sử dụng cho:** Phân phối chính thức, cài đặt trên mọi thiết bị

### **2. APK Split theo Architecture (Tối ưu kích thước)**
- **File:** `app-arm64-v8a-release.apk` (12.8 MB)
  - Dành cho thiết bị ARM64 (hầu hết thiết bị hiện đại)
  - Samsung Galaxy S series, Google Pixel, OnePlus, etc.

- **File:** `app-armeabi-v7a-release.apk` (12.8 MB)
  - Dành cho thiết bị ARM32 (thiết bị cũ hơn)
  - Một số thiết bị Android cũ, giá rẻ

- **File:** `app-x86_64-release.apk` (14.0 MB)
  - Dành cho thiết bị x86_64 (máy tính bảng, emulator)
  - Android emulator, một số máy tính bảng

### **3. APK Debug (Chỉ dành cho developer)**
- **File:** `app-debug.apk`
- **Kích thước:** 63.4 MB
- **Mô tả:** Phiên bản debug với thông tin debug, không nên sử dụng cho production

## 🚀 Cách cài đặt

### **Trên thiết bị Android:**
1. Tải file APK phù hợp về thiết bị
2. Bật "Cài đặt từ nguồn không xác định" trong Settings > Security
3. Mở file APK và làm theo hướng dẫn cài đặt

### **Khuyến nghị chọn file:**
- **Thiết bị mới (2018+):** Sử dụng `app-arm64-v8a-release.apk`
- **Thiết bị cũ (2015-2017):** Sử dụng `app-armeabi-v7a-release.apk`
- **Không chắc chắn:** Sử dụng `app-release.apk` (universal)

## 📋 Thông tin Build

### **Build Details:**
- **Flutter Version:** Latest stable
- **Build Date:** 25/07/2025
- **Build Type:** Release
- **Min SDK:** Android 5.0 (API 21)
- **Target SDK:** Android 14 (API 34)

### **Tính năng trong APK:**
- ✅ QR Code generation và scanning
- ✅ Device management
- ✅ Order management
- ✅ User management với role-based access
- ✅ PDF generation và sharing
- ✅ Web download support
- ✅ Multi-language support (Vietnamese/English)
- ✅ Offline capability
- ✅ Push notifications (nếu có)

## 🔧 Troubleshooting

### **Lỗi cài đặt:**
1. **"App not installed":** Kiểm tra xem đã bật "Install from unknown sources"
2. **"Parse error":** Tải lại file APK, có thể file bị hỏng
3. **"Incompatible":** Thử file APK khác phù hợp với architecture

### **Lỗi runtime:**
1. **App crash:** Kiểm tra quyền truy cập camera, storage
2. **QR scan không hoạt động:** Cấp quyền camera
3. **Không lưu được file:** Cấp quyền storage

## 📊 So sánh kích thước

| File APK | Kích thước | Mục đích |
|----------|------------|----------|
| app-release.apk | 35.9 MB | Universal, tất cả thiết bị |
| app-arm64-v8a-release.apk | 12.8 MB | Thiết bị ARM64 hiện đại |
| app-armeabi-v7a-release.apk | 12.8 MB | Thiết bị ARM32 cũ |
| app-x86_64-release.apk | 14.0 MB | Emulator, máy tính bảng |
| app-debug.apk | 63.4 MB | Development only |

## 🎯 Khuyến nghị

### **Cho Production:**
- Sử dụng `app-release.apk` cho phân phối chung
- Hoặc sử dụng split APKs cho Google Play Store

### **Cho Testing:**
- Sử dụng `app-debug.apk` cho development
- Sử dụng split APKs cho testing trên nhiều thiết bị

### **Cho Distribution:**
- Upload split APKs lên Google Play Store
- Sử dụng `app-release.apk` cho direct download

## 📞 Support

Nếu gặp vấn đề với APK, vui lòng:
1. Kiểm tra thiết bị có hỗ trợ Android 5.0+ không
2. Thử cài đặt lại app
3. Liên hệ support team với thông tin thiết bị và lỗi cụ thể 