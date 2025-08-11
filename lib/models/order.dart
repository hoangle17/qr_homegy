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
    List<Device> devices = [];
    
    // Nếu có deviceInventories (từ getOrderDetail response mới)
    if (json['deviceInventories'] != null) {
      final deviceInventories = json['deviceInventories'] as List<dynamic>;
      devices = deviceInventories
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
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt'] ?? ''),
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

  // Helper method to parse DateTime with timezone support
  static DateTime _parseDateTime(String dateString) {
    try {
      // Handle ISO 8601 format with timezone offset (+07:00)
      if (dateString.contains('+') || (dateString.contains('-') && dateString.split('-').length > 3)) {
        // Extract timezone offset
        String timezoneOffset = '';
        if (dateString.contains('+')) {
          timezoneOffset = dateString.split('+')[1];
          dateString = dateString.split('+')[0];
        } else if (dateString.contains('-') && dateString.split('-').length > 3) {
          final parts = dateString.split('-');
          timezoneOffset = parts.last;
          dateString = parts.take(parts.length - 1).join('-');
        }
        
        // Parse the datetime without timezone - this gives us the local time as intended
        final parsed = DateTime.tryParse(dateString);
        if (parsed != null) {
          return parsed; // Return the local time as is
        }
      }
      
      // Handle UTC format (ending with Z)
      if (dateString.endsWith('Z')) {
        final utcString = dateString.substring(0, dateString.length - 1);
        final parsed = DateTime.tryParse(utcString);
        if (parsed != null) {
          // Convert UTC to local time (UTC+7 for Vietnam)
          final localTime = parsed.add(const Duration(hours: 7));
          return localTime;
        }
      }
      
      // Fallback: try to parse without timezone
      final parsed = DateTime.tryParse(dateString);
      if (parsed != null) {
        return parsed;
      }
      
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }
}

 