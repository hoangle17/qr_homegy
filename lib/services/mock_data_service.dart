import '../models/user.dart';
import '../models/order.dart';
import '../models/qrcode.dart';

class MockDataService {
  static List<User> users = [
    User(
      id: 1,
      name: 'Nhà phân phối A',
      type: UserType.distributor,
      address: '123 Đường A',
      phone: '123',
      password: '123',
    ),
    User(
      id: 2,
      name: 'Đại lý B',
      type: UserType.agent,
      address: '456 Đường B',
      phone: '0900000002',
      password: '123456',
    ),
    User(
      id: 3,
      name: 'Khách lẻ C',
      type: UserType.retail,
      address: '789 Đường C',
      phone: '0900000003',
      password: '123456',
    ),
  ];

  static List<Order> orders = [
    Order(
      id: 1,
      customerId: 1,
      status: OrderStatus.paid,
      productId: 'SP001',
      orderInfo: 'Đơn hàng 1',
    ),
    Order(
      id: 2,
      customerId: 2,
      status: OrderStatus.unpaid,
      productId: 'SP002',
      orderInfo: 'Đơn hàng 2',
    ),
  ];

  static List<QRCodeModel> qrcodes = [
    QRCodeModel(
      id: 'QR001',
      orderId: 1,
      customerId: 1,
      isActive: true,
      productId: 'SP001',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      genCode: 'QR001-2024-01',
    ),
    QRCodeModel(
      id: 'QR002',
      orderId: 2,
      customerId: 2,
      isActive: false,
      productId: 'SP002',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      genCode: 'QR002-2024-01',
    ),
  ];

  // Thêm các hàm CRUD cơ bản nếu cần
  static void addUser(User user) => users.add(user);
  static void updateUser(User user) {
    final idx = users.indexWhere((u) => u.id == user.id);
    if (idx != -1) users[idx] = user;
  }
  static void deleteUser(int id) => users.removeWhere((u) => u.id == id);

  static void addOrder(Order order) => orders.add(order);
  static void updateOrder(Order order) {
    final idx = orders.indexWhere((o) => o.id == order.id);
    if (idx != -1) orders[idx] = order;
  }
  static void deleteOrder(int id) => orders.removeWhere((o) => o.id == id);

  static void addQRCode(QRCodeModel qr) => qrcodes.add(qr);
  static void updateQRCode(QRCodeModel qr) {
    final idx = qrcodes.indexWhere((q) => q.id == qr.id);
    if (idx != -1) qrcodes[idx] = qr;
  }
  static void deleteQRCode(String id) => qrcodes.removeWhere((q) => q.id == id);
} 