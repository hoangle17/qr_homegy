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
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      macAddress: json['macAddress'] ?? '',
      serialNumber: json['serialNumber'],
      thingID: json['thingID'], // Không fallback nữa, giữ nguyên null nếu API trả về null
      paymentStatus: json['payment_status'] ?? 'pending',
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
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
    );
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