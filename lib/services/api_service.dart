import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/device.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = "http://vps2025.homegy.com.vn:3000";

  static Future<http.Response> callApi({
    required String apiName,
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    print('---[API: $apiName]---');
    print('[$method] $url');
    if (headers != null) print('Headers: $headers');
    if (body != null) print('Request body: $body');
    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(Uri.parse(url), headers: headers, body: body);
          break;
        case 'PUT':
          response = await http.put(Uri.parse(url), headers: headers, body: body);
          break;
        case 'PATCH':
          response = await http.patch(Uri.parse(url), headers: headers, body: body);
          break;
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: headers, body: body);
          break;
        default:
          throw Exception('Unsupported HTTP method');
      }
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return response;
    } catch (e) {
      print('API ERROR: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = '$baseUrl/api/users/login';
    final response = await callApi(
      apiName: 'Login',
      method: 'POST',
      url: url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'token': data['token'] ?? data['accessToken'],
        'user': data['user'],
      };
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      return {'success': false, 'message': 'Không tìm thấy token xác thực'};
    }
    
    final url = '$baseUrl/api/users/change-password';
    final response = await callApi(
      apiName: 'ChangePassword',
      method: 'PATCH',
      url: url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': data['message'] ?? 'Đổi mật khẩu thành công'
      };
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Đổi mật khẩu thất bại'
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getMacDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return [];
    final url = '$baseUrl/api/inventory/devices';
    final response = await callApi(
      apiName: 'GetMacDevices',
      method: 'GET',
      url: url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
    }
    return [];
  }

  static Future<bool> forgotPassword(String email) async {
    final url = '$baseUrl/api/users/forgot-password';
    final response = await callApi(
      apiName: 'ForgotPassword',
      method: 'POST',
      url: url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  // Order APIs
  static Future<Order?> createOrder({
    required String customerId,
    required String createdBy,
    String? note,
    required List<DeviceRequest> devices,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;

    final url = '$baseUrl/api/orders';
    final response = await callApi(
      apiName: 'CreateOrder',
      method: 'POST',
      url: url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'customer_id': customerId,
        'created_by': createdBy,
        'note': note,
        'devices': devices.map((d) => d.toJson()).toList(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      // Tạo Order từ response data
      return Order(
        id: data['order_id'] ?? '',
        customerId: customerId,
        customerName: '', // Cần lấy từ customer service
        createdBy: createdBy,
        createdAt: DateTime.now(),
        status: 'pending',
        note: note,
        devices: (data['devices'] as List<dynamic>? ?? [])
            .map((d) => Device.fromJson(d))
            .toList(),
        deviceCount: (data['devices'] as List<dynamic>? ?? []).length,
      );
    }
    return null;
  }

  static Future<List<Order>> getOrders({
    String? status,
    String? customerId,
    String? createdBy,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return [];

    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (customerId != null) queryParams['customer_id'] = customerId;
    if (createdBy != null) queryParams['created_by'] = createdBy;
    if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String().split('T')[0];
    if (toDate != null) queryParams['to_date'] = toDate.toIso8601String().split('T')[0];

    final uri = Uri.parse('$baseUrl/api/orders').replace(queryParameters: queryParams);
    final response = await callApi(
      apiName: 'GetOrders',
      method: 'GET',
      url: uri.toString(),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['orders'] as List<dynamic>? ?? [])
          .map((o) => Order.fromJson(o))
          .toList();
    }
    return [];
  }

  static Future<Order?> getOrderDetail(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;

    final url = '$baseUrl/api/orders/$orderId';
    final response = await callApi(
      apiName: 'GetOrderDetail',
      method: 'GET',
      url: url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Order.fromJson(data);
    }
    return null;
  }

  static Future<List<Order>> searchOrders(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return [];

    final url = '$baseUrl/api/orders/search?query=$query';
    final response = await callApi(
      apiName: 'SearchOrders',
      method: 'GET',
      url: url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['orders'] as List<dynamic>? ?? [])
          .map((o) => Order.fromJson(o))
          .toList();
    }
    return [];
  }

  static Future<bool> updateOrderStatus(String orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final url = '$baseUrl/api/orders/$orderId';
    final response = await callApi(
      apiName: 'UpdateOrderStatus',
      method: 'PATCH',
      url: url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    return response.statusCode == 200;
  }

  static Future<bool> deactivateOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final url = '$baseUrl/api/orders/$orderId/deactivate';
    final response = await callApi(
      apiName: 'DeactivateOrder',
      method: 'POST',
      url: url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  static Future<bool> deactivateDevice(String macAddress) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final url = '$baseUrl/api/devices/$macAddress/deactivate';
    final response = await callApi(
      apiName: 'DeactivateDevice',
      method: 'POST',
      url: url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getDeviceTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return [];

    final url = '$baseUrl/api/device-types/skus';
    final response = await callApi(
      apiName: 'GetDeviceTypes',
      method: 'GET',
      url: url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_info');
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  static Future<String?> getCurrentUserRole() async {
    final user = await getCurrentUser();
    return user?['role'];
  }

  // Get current user profile from API
  static Future<User?> getCurrentUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;

    final response = await callApi(
      apiName: 'GetUserProfile',
      method: 'GET',
      url: '$baseUrl/api/users/profile',
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data);
      
      // Update user info in SharedPreferences
      await prefs.setString('user_info', jsonEncode(data));
      await prefs.setString('user_email', user.email);
      
      return user;
    }
    return null;
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? phone,
    String? address,
    String region = 'VN',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      return {'success': false, 'message': 'Không tìm thấy token xác thực'};
    }
    
    // Only include fields that are provided (not null)
    final Map<String, dynamic> requestBody = {};
    if (name != null) requestBody['name'] = name;
    if (phone != null) requestBody['phone'] = phone;
    if (address != null) requestBody['address'] = address;
    requestBody['region'] = region; // Always include region
    
    final url = '$baseUrl/api/users/profile';
    final response = await callApi(
      apiName: 'UpdateUserProfile',
      method: 'PATCH',
      url: url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': 'Cập nhật thông tin thành công',
        'data': data,
      };
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Cập nhật thông tin thất bại',
      };
    }
  }

  // Update user role (only for ADMIN)
  static Future<Map<String, dynamic>> updateUserRole({
    required String targetUserId,
    required String newRole,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      return {'success': false, 'message': 'Không tìm thấy token xác thực'};
    }
    
    final url = '$baseUrl/api/users/$targetUserId/role';
    final response = await callApi(
      apiName: 'UpdateUserRole',
      method: 'PUT',
      url: url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'role': newRole,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': 'Cập nhật vai trò thành công',
        'data': data,
      };
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Cập nhật vai trò thất bại',
      };
    }
  }

  // User APIs
  static Future<List<User>> getAllUsers({String? role, String? phone}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return [];

    final queryParams = <String, String>{};
    if (role != null) queryParams['role'] = role;
    if (phone != null) queryParams['phone'] = phone;

    final uri = Uri.parse('$baseUrl/api/users/all').replace(queryParameters: queryParams);
    final response = await callApi(
      apiName: 'GetAllUsers',
      method: 'GET',
      url: uri.toString(),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List<dynamic>? ?? [])
          .map((u) => User.fromJson(u))
          .toList();
    }
    return [];
  }

  // Register new user
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String name,
    String region = 'VN',
  }) async {
    final response = await callApi(
      apiName: 'RegisterUser',
      method: 'POST',
      url: '$baseUrl/api/users/register',
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'region': region,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': 'Đăng ký thành công! Vui lòng kiểm tra email để xác thực tài khoản.',
        'data': data,
      };
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Lỗi khi đăng ký',
      };
    }
  }

  static Future<Device?> getDeviceByMacAddress(String macAddress) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;

    final response = await callApi(
      apiName: 'GetDeviceByMac',
      method: 'GET',
      url: '$baseUrl/api/inventory/devices/by-mac/$macAddress',
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Device.fromJson(data['data']);
      }
    }
    return null;
  }

  static Future<List<Device>> getAllDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return [];

    final response = await callApi(
      apiName: 'GetAllDevices',
      method: 'GET',
      url: '$baseUrl/api/inventory/devices',
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List<dynamic>)
            .map((device) => Device.fromJson(device))
            .toList();
      }
    }
    return [];
  }

  static Future<bool> deleteUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final response = await callApi(
      apiName: 'DeleteUser',
      method: 'DELETE',
      url: '$baseUrl/api/users/$userId',
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 204;
  }
}
 