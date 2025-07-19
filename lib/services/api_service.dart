import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  static Future<String?> login(String email, String password) async {
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
      return data['token'] ?? data['accessToken'];
    } else {
      return null;
    }
  }

  static Future<bool> changePassword(String currentPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;
    final url = '$baseUrl/api/users/profile';
    final response = await callApi(
      apiName: 'ChangePassword',
      method: 'PUT',
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
    return response.statusCode == 200;
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
}
 