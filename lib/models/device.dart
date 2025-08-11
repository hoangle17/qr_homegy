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

  Map<String, dynamic> toJson() {
    return {
      'skuCode': skuCode,
      'name': name,
      'description': description,
      'manufacturer': manufacturer,
      'category': category,
    };
  }
}

class Device {
  final String? id; // ID của device inventory
  final String macAddress;
  final String? serialNumber;
  final String? thingID;
  final String paymentStatus; // "free", "paid", "pending", "cancelled"
  final bool isActive;
  final DateTime createdAt;
  final String? manufacturer;
  final String? model;
  final String? firmwareVersion;
  final DateTime? activatedAt;
  final String? activatedBy;
  final String? orderId;
  final double? price;
  final String? createdBy;
  final String? customerId;
  final String skuCode;
  final SkuCatalog? skuCatalog;

  Device({
    this.id,
    required this.macAddress,
    this.serialNumber,
    this.thingID,
    required this.paymentStatus,
    required this.isActive,
    required this.createdAt,
    this.manufacturer,
    this.model,
    this.firmwareVersion,
    this.activatedAt,
    this.activatedBy,
    this.orderId,
    this.price,
    this.createdBy,
    this.customerId,
    required this.skuCode,
    this.skuCatalog,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      macAddress: json['macAddress'] ?? '',
      serialNumber: json['serialNumber'],
      thingID: json['thingID'], // Không fallback nữa, giữ nguyên null nếu API trả về null
      paymentStatus: json['payment_status'] ?? 'pending',
      isActive: json['isActive'] ?? false,
      createdAt: _parseDateTime(json['createdAt'] ?? ''),
      manufacturer: json['manufacturer'],
      model: json['model'],
      firmwareVersion: json['firmwareVersion'],
      activatedAt: json['activatedAt'] != null ? DateTime.tryParse(json['activatedAt']) : null,
      activatedBy: json['activatedBy'],
      orderId: json['order_id'],
      price: json['price']?.toDouble(),
      createdBy: json['created_by'],
      customerId: json['customer_id'],
      skuCode: json['skuCode'] ?? '',
      skuCatalog: json['skuCatalog'] != null ? SkuCatalog.fromJson(json['skuCatalog']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'macAddress': macAddress,
      'serialNumber': serialNumber,
      'thingID': thingID,
      'payment_status': paymentStatus,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'manufacturer': manufacturer,
      'model': model,
      'firmwareVersion': firmwareVersion,
      'activatedAt': activatedAt?.toIso8601String(),
      'activatedBy': activatedBy,
      'order_id': orderId,
      'price': price,
      'created_by': createdBy,
      'customer_id': customerId,
      'skuCode': skuCode,
      'skuCatalog': skuCatalog?.toJson(),
    };
  }

  Device copyWith({
    String? id,
    String? macAddress,
    String? serialNumber,
    String? thingID,
    String? paymentStatus,
    bool? isActive,
    DateTime? createdAt,
    String? manufacturer,
    String? model,
    String? firmwareVersion,
    DateTime? activatedAt,
    String? activatedBy,
    String? orderId,
    double? price,
    String? createdBy,
    String? customerId,
    String? skuCode,
    SkuCatalog? skuCatalog,
  }) {
    return Device(
      id: id ?? this.id,
      macAddress: macAddress ?? this.macAddress,
      serialNumber: serialNumber ?? this.serialNumber,
      thingID: thingID ?? this.thingID,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      activatedAt: activatedAt ?? this.activatedAt,
      activatedBy: activatedBy ?? this.activatedBy,
      orderId: orderId ?? this.orderId,
      price: price ?? this.price,
      createdBy: createdBy ?? this.createdBy,
      customerId: customerId ?? this.customerId,
      skuCode: skuCode ?? this.skuCode,
      skuCatalog: skuCatalog ?? this.skuCatalog,
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

class DeviceRequest {
  final String skuCode;
  final int quantity;
  final String paymentStatus;

  DeviceRequest({
    required this.skuCode,
    required this.quantity,
    required this.paymentStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'skuCode': skuCode,
      'quantity': quantity,
      'payment_status': paymentStatus,
    };
  }

  DeviceRequest copyWith({
    String? skuCode,
    int? quantity,
    String? paymentStatus,
  }) {
    return DeviceRequest(
      skuCode: skuCode ?? this.skuCode,
      quantity: quantity ?? this.quantity,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
} 