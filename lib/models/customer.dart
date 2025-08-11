import 'package:flutter/material.dart';

class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? region;
  final String role;
  final bool isEmailVerified;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String email;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.region,
    required this.role,
    required this.isEmailVerified,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.email,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      region: json['region'],
      role: json['role'] ?? 'AGENT',
      isEmailVerified: json['isEmailVerified'] ?? false,
      status: json['status'] ?? 'ACTIVE',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'region': region,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'email': email,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? region,
    String? role,
    bool? isEmailVerified,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? email,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      region: region ?? this.region,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      email: email ?? this.email,
    );
  }

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

  // Helper getters for backward compatibility
  String get representative => name;
  String get address => region ?? '';
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

  // Status helper methods
  String get statusDisplayName {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Đang hoạt động';
      case 'DEACTIVE':
        return 'Không hoạt động';
      case 'PENDING':
        return 'Chờ xác thực';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'DEACTIVE':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  bool get isActive => status.toUpperCase() == 'ACTIVE';
} 