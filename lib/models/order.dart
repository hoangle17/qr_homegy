import 'device.dart';

class Order {
  final String id;
  final String customerId; // Email
  final String customerName;
  final String createdBy; // Email
  final DateTime createdAt;
  final String status; // "pending", "completed", "deactivated"
  final String? note; // Thay thế orderInfo
  final List<Device> devices; // Thay thế qrCodes
  final int deviceCount; // Thay thế quantity

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.createdBy,
    required this.createdAt,
    required this.status,
    this.note,
    required this.devices,
    required this.deviceCount,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Xử lý cả response từ getOrders và getOrderDetail
    List<Device> devices = [];
    
    // Nếu có deviceInventories (từ getOrderDetail)
    if (json['deviceInventories'] != null) {
      devices = (json['deviceInventories'] as List<dynamic>)
          .map((e) => Device.fromJson(e))
          .toList();
    }
    // Nếu có devices (từ getOrders hoặc response khác)
    else if (json['devices'] != null) {
      devices = (json['devices'] as List<dynamic>)
          .map((e) => Device.fromJson(e))
          .toList();
    }

    return Order(
      id: json['id'] ?? '',
      customerId: json['customer_id'] ?? json['customerId'] ?? '',
      customerName: json['customerName'] ?? json['customer_id'] ?? '', // Fallback to customer_id if customerName not available
      createdBy: json['created_by'] ?? json['createdBy'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'pending',
      note: json['note'] ?? json['orderInfo'],
      devices: devices,
      deviceCount: json['device_count'] ?? json['quantity'] ?? devices.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customerName': customerName,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'note': note,
      'devices': devices.map((e) => e.toJson()).toList(),
      'device_count': deviceCount,
    };
  }

  // Helper method để tương thích với code cũ
  bool get orderStatus => status == 'pending' || status == 'completed';
  int get quantity => deviceCount;
  String get productId => devices.isNotEmpty ? (devices.first.thingID ?? '') : '';
  List<Device> get qrCodes => devices; // Tương thích ngược
  String? get orderInfo => note;

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? createdBy,
    DateTime? createdAt,
    String? status,
    String? note,
    List<Device>? devices,
    int? deviceCount,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      note: note ?? this.note,
      devices: devices ?? this.devices,
      deviceCount: deviceCount ?? this.deviceCount,
    );
  }
}

 