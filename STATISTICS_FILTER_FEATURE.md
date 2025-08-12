# Tính năng Lọc dữ liệu khi click vào Icon Thống kê

## Mô tả
Tính năng này cho phép người dùng lọc dữ liệu bằng cách click vào các icon thống kê ở banner phía trên của mỗi tab.

## Các tab được hỗ trợ

### 1. Tab "Mã QR" (OrderCodeAllScreen)
- **Icon "Tổng số"**: Lọc tất cả đơn hàng (hiển thị tất cả)
- **Icon "Chờ xử lý"**: Lọc các đơn hàng có trạng thái "pending"
- **Icon "Hoàn thành"**: Lọc các đơn hàng có trạng thái "completed"  
- **Icon "Đã hủy"**: Lọc các đơn hàng có trạng thái "deactivated"

### 2. Tab "Thống kê" (StatisticsScreen)
- **Icon "Tổng số"**: Lọc tất cả device (hiển thị tất cả)
- **Icon "Đã kích hoạt"**: Lọc các device có trạng thái đã kích hoạt
- **Icon "Chưa kích hoạt"**: Lọc các device có trạng thái chưa kích hoạt

### 3. Tab "Khách hàng" (CustomerListScreen)
- **Icon "Tổng số"**: Lọc tất cả khách hàng (hiển thị tất cả)
- **Icon "Hoạt động"**: Lọc các khách hàng có trạng thái hoạt động
- **Icon "Không hoạt động"**: Lọc các khách hàng có trạng thái không hoạt động

## Cách hoạt động

### Visual Feedback
- Khi click vào icon thống kê, icon sẽ được highlight với:
  - Background color mờ của màu tương ứng
  - Border màu của icon
  - Hiển thị thông báo filter status bên dưới banner
  - **Tất cả các số thống kê luôn hiển thị tổng số thực tế (không thay đổi khi filter)**
  - **Ví dụ**: Khi chọn "Chờ xử lý", tất cả số "Tổng số", "Hoàn thành", "Đã hủy" vẫn hiển thị tổng số thực tế

### Default Behavior
- **Khi vào màn hình**: Tự động hiển thị tất cả dữ liệu
- **Không có icon nào được selected mặc định**: Tất cả icon thống kê đều không được highlight khi vào màn hình
- **Filter status**: Chỉ hiển thị khi người dùng chọn một trạng thái cụ thể (không hiển thị "Đang lọc: Tất cả")

### Filter Status Display
- Hiển thị thông tin về filter đang được áp dụng
- Có nút "X" để xóa filter và hiển thị lại tất cả dữ liệu

### API Integration
- **Tab Mã QR**: Gọi API `getOrders()` với parameter `status` tương ứng
- **Tab Thống kê**: Gọi API `getInventoryDevices()` với parameter `isActive` tương ứng
- **Tab Khách hàng**: Lọc dữ liệu local với logic `isActive`

## Các thay đổi code

### OrderCodeAllScreen
- Thêm state `_selectedStatusFilter` và `_filteredOrders`
- Thêm method `_filterByStatus()` và `_clearFilters()`
- Cập nhật `_buildStatCard()` để hỗ trợ click và visual feedback
- Thêm filter status display

### StatisticsScreen  
- Thêm method `_filterByStatCard()` để xử lý click vào icon
- Cập nhật `_buildStatCard()` để hỗ trợ click và visual feedback
- Tích hợp với filter system hiện có

### CustomerListScreen
- Thêm state `_selectedStatusFilter` và `_filteredCustomers`
- Thêm method `_applyFilters()`, `_filterByStatus()`, `_clearFilters()`
- Cập nhật `_buildStatCard()` để hỗ trợ click và visual feedback
- Thêm filter status display

## Lợi ích
1. **UX tốt hơn**: Người dùng có thể nhanh chóng lọc dữ liệu bằng cách click trực tiếp
2. **Visual feedback rõ ràng**: Hiển thị trạng thái filter và dữ liệu được lọc
3. **Số thống kê cố định**: Tất cả các số thống kê luôn hiển thị tổng số thực tế, không thay đổi khi filter
4. **Tích hợp mượt mà**: Hoạt động cùng với các tính năng filter hiện có
5. **Consistent UI**: Giao diện thống nhất giữa các tab

## Tương lai
- Có thể mở rộng để hỗ trợ filter theo nhiều tiêu chí khác
- Thêm animation khi chuyển đổi filter
- Lưu trạng thái filter trong local storage
