import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../../widgets/copyable_text.dart';
import 'customer_form_screen.dart';
import 'customer_add_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _search = '';
  List<Customer> _customers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final customers = await CustomerService.getCustomers();
      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải danh sách khách hàng: $e';
        _isLoading = false;
      });
    }
  }

  List<Customer> get _filteredCustomers {
    List<Customer> filtered = _customers;

    // Filter by search query
    if (_search.isNotEmpty) {
      final query = _search.toLowerCase();
      filtered =
          filtered.where((customer) {
            return customer.name.toLowerCase().contains(query) ||
                customer.email.toLowerCase().contains(query) ||
                (customer.phone?.toLowerCase().contains(query) ?? false) ||
                (customer.region?.toLowerCase().contains(query) ?? false);
          }).toList();
    }

    return filtered;
  }

  void _navigateToAddScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerAddScreen()),
    );

    // Reload customers list if customer was added successfully
    if (result == true) {
      _loadCustomers();
    }
  }

  Future<void> _confirmDeleteCustomer(Customer customer) async {
    // Hiển thị dialog xác nhận xóa
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('Xác nhận xóa'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bạn có chắc chắn muốn xóa khách hàng này?',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tên: ${customer.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Email: ${customer.email}'),
                      if (customer.phone != null && customer.phone!.isNotEmpty)
                        Text('SĐT: ${customer.phone}'),
                      if (customer.region != null &&
                          customer.region!.isNotEmpty)
                        Text('Địa chỉ: ${customer.region}'),
                      Text('Loại: ${customer.typeDisplayName}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hành động này không thể hoàn tác!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );

    // Nếu user xác nhận xóa, thực hiện xóa
    if (confirmed == true) {
      await _deleteCustomer(customer);
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    try {
      final result = await CustomerService.deleteCustomer(customer);

      if (result['success']) {
        // Xóa customer khỏi danh sách local
        setState(() {
          _customers.removeWhere((c) => c.id == customer.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          // Kiểm tra nếu lỗi là do khách hàng có đơn hàng
          if (result['error'] != null &&
              result['error']['code'] == 'USER_HAS_ORDERS') {
            _showOrdersDialog(customer, result['error']['details']);
          } else {
            // Hiển thị thông báo lỗi chi tiết
            String errorMessage =
                result['message'] ?? 'Xóa khách hàng thất bại';
            if (result['error'] != null && result['error']['message'] != null) {
              errorMessage = result['error']['message'];
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa khách hàng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOrdersDialog(Customer customer, Map<String, dynamic> details) {
    final orderCount = details['orderCount'] ?? 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Thông báo'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Không thể xóa khách hàng "${customer.name}" vì đang có $orderCount đơn hàng.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách khách hàng'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm khách hàng mới',
            onPressed: () => _navigateToAddScreen(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCustomers,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Thống kê tổng quan
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Tổng số',
                _filteredCustomers.length.toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Hoạt động',
                _filteredCustomers.where((c) => c.isActive).length.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'Không hoạt động',
                _filteredCustomers.where((c) => !c.isActive).length.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText:
                  'Tìm kiếm theo tên, người đại diện, địa chỉ, email, SĐT',
              hintText: 'Nhập từ khóa tìm kiếm...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _search = value;
              });
            },
          ),
        ),
        if (_filteredCustomers.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _search.isEmpty
                        ? 'Không có khách hàng nào'
                        : 'Không tìm thấy kết quả',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCustomers.length,
              itemBuilder: (context, index) {
                final customer = _filteredCustomers[index];
                return Slidable(
                  key: Key(customer.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed:
                            (context) => _confirmDeleteCustomer(customer),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Xóa',
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: customer.typeColor,
                        child: Icon(
                          _getCustomerIcon(customer.type),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        customer.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CopyableText(
                            text: 'Email: ${customer.email}',
                            style: const TextStyle(fontSize: 14),
                            copyMessage: 'Đã copy email',
                          ),
                          if (customer.phone != null &&
                              customer.phone!.isNotEmpty)
                            CopyableText(
                              text: 'SĐT: ${customer.phone}',
                              style: const TextStyle(fontSize: 14),
                              copyMessage: 'Đã copy số điện thoại',
                            ),
                          if (customer.region != null &&
                              customer.region!.isNotEmpty)
                            CopyableText(
                              text: 'Địa chỉ: ${customer.region}',
                              style: const TextStyle(fontSize: 14),
                              copyMessage: 'Đã copy khu vực',
                            ),
                          CopyableText(
                            text:
                                'Ngày tạo: ${_formatDateTime(customer.createdAt)}',
                            style: const TextStyle(fontSize: 14),
                            copyMessage: 'Đã copy ngày tạo',
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: customer.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: customer.statusColor),
                            ),
                            child: Text(
                              customer.statusDisplayName,
                              style: TextStyle(
                                color: customer.statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: customer.typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: customer.typeColor),
                            ),
                            child: Text(
                              customer.typeDisplayName,
                              style: TextStyle(
                                color: customer.typeColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      CustomerFormScreen(customer: customer),
                            ),
                          );
                          _loadCustomers(); // Refresh list after edit
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _getCustomerIcon(String type) {
    return Icons.store;
  }

  // Helper function to format date in HH:mm dd-MM-yyyy format
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
