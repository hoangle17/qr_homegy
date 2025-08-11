enum UserType { distributor, agent, retail }

class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String phone;
  final String? address;
  final String? region;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.phone,
    this.address,
    this.region,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'],
      region: json['region'],
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['createdAt'] != null ? _parseDateTime(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? _parseDateTime(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'address': address,
      'region': region,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Helper method to parse DateTime with timezone support
  static DateTime? _parseDateTime(String dateString) {
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
      
      return null;
    } catch (e) {
      return null;
    }
  }
} 