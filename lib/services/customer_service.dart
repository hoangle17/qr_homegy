import '../models/customer.dart';
import 'api_service.dart';

class CustomerService {
  // A. Lấy danh sách khách hàng
  static Future<List<Customer>> getCustomers() async {
    try {
      // Lấy tất cả các loại khách hàng
      final List<dynamic> allUsers = [];
      
      // Lấy distributors
      try {
        final distributors = await ApiService.getAllUsers(role: 'DISTRIBUTOR');
        allUsers.addAll(distributors);
      } catch (e) {
        // Ignore if role doesn't exist
      }
      
      // Lấy customers
      try {
        final customers = await ApiService.getAllUsers(role: 'CUSTOMER');
        allUsers.addAll(customers);
      } catch (e) {
        // Ignore if role doesn't exist
      }
      
      // Lấy agents
      try {
        final agents = await ApiService.getAllUsers(role: 'AGENT');
        allUsers.addAll(agents);
      } catch (e) {
        // Ignore if role doesn't exist
      }

      return allUsers
          .map(
            (user) => Customer.fromJson({
              ...user.toJson(),
              'region': user.region, // Đảm bảo trường region được truyền đúng
            }),
          )
          .toList();
    } catch (e) {
      throw Exception('Error loading customers: $e');
    }
  }

  // B. Thêm khách hàng mới (sử dụng API register)
  static Future<Map<String, dynamic>> addCustomer({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String type,
  }) async {
    try {
      // Map type to role
      String role;
      switch (type.toLowerCase()) {
        case 'distributor':
          role = 'DISTRIBUTOR';
          break;
        case 'customer':
          role = 'CUSTOMER';
          break;
        case 'agent':
        default:
          role = 'AGENT';
          break;
      }

      final result = await ApiService.registerUser(
        email: email,
        password: 'defaultPassword123', // Có thể cần thay đổi
        name: name,
        phone: phone,
        region: address,
        role: role,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi khi thêm khách hàng: $e'};
    }
  }

  // C. Cập nhật thông tin khách hàng
  static Future<Map<String, dynamic>> updateCustomer({
    required String id,
    required String currentName,
    required String name,
    required String phone,
    required String email,
    required String address,
    String? status,
  }) async {
    try {
      // Sử dụng API mới với format /api/users/agent/{currentName}
      final result = await ApiService.updateAgentProfile(
        currentName: currentName, // Tên hiện tại của khách hàng
        name: name,
        region: address,
        phone: phone,
        email: email,
        status: status,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi khi cập nhật khách hàng: $e'};
    }
  }

  // D. Xóa khách hàng
  static Future<Map<String, dynamic>> deleteCustomer(Customer customer) async {
    try {
      // Sử dụng API mới để xóa agent bằng tên khách hàng
      final result = await ApiService.deleteAgent(customer.name);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi khi xóa khách hàng: $e'};
    }
  }

  // E. Tìm kiếm khách hàng
  static Future<List<Customer>> searchCustomers(String query) async {
    try {
      final customers = await getCustomers();
      if (query.trim().isEmpty) {
        return customers;
      }

      final searchQuery = query.toLowerCase();
      return customers.where((customer) {
        return customer.name.toLowerCase().contains(searchQuery) ||
            customer.email.toLowerCase().contains(searchQuery) ||
            (customer.phone?.toLowerCase().contains(searchQuery) ?? false) ||
            (customer.region?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Error searching customers: $e');
    }
  }

  // Get customer by ID
  static Future<Customer?> getCustomerById(String id) async {
    try {
      final customers = await getCustomers();
      try {
        return customers.firstWhere((customer) => customer.id == id);
      } catch (e) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get customers by type
  static Future<List<Customer>> getCustomersByType(String type) async {
    try {
      final customers = await getCustomers();
      return customers.where((customer) => customer.type == type).toList();
    } catch (e) {
      throw Exception('Error getting customers by type: $e');
    }
  }
}
