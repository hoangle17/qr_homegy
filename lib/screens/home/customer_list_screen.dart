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
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  bool _isLoadingList = false; // Thêm biến loading riêng cho list
  String? _error;
  
  // Filter variables
  String? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    // No default filter selected - show all customers without highlighting any stat card
    _selectedStatusFilter = 'all';
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
      _applyFilters(); // Apply current filters after loading
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải danh sách khách hàng: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Customer> filtered = _customers;

    // Filter by status
    if (_selectedStatusFilter != null && _selectedStatusFilter != 'all') {
      switch (_selectedStatusFilter) {
        case 'active':
          filtered = filtered.where((customer) => customer.isActive).toList();
          break;
        case 'inactive':
          filtered = filtered.where((customer) => !customer.isActive).toList();
          break;
      }
    }

    // Filter by search query
    if (_search.isNotEmpty) {
      final query = _search.toLowerCase();
      filtered = filtered.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
            customer.email.toLowerCase().contains(query) ||
            (customer.phone?.toLowerCase().contains(query) ?? false) ||
            (customer.region?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    setState(() {
      _filteredCustomers = filtered;
    });
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

  // Method to handle filter by status
  void _filterByStatus(String? status) {
    setState(() {
      _selectedStatusFilter = status;
      _isLoadingList = true; // Chỉ loading phần list
    });
    
    // Simulate loading delay for better UX (since this is local filtering)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _applyFilters();
        setState(() {
          _isLoadingList = false;
        });
      }
    });
  }

  // Method to clear all filters
  void _clearFilters() {
    setState(() {
      _selectedStatusFilter = null;
      _isLoadingList = true; // Chỉ loading phần list
    });
    
    // Simulate loading delay for better UX (since this is local filtering)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _applyFilters();
        setState(() {
          _isLoadingList = false;
        });
      }
    });
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'Tổng số',
                    _customers.length.toString(),
                    Icons.people,
                    Colors.blue,
                    'all', // Filter for all (show all customers)
                  ),
                  _buildStatCard(
                    'Hoạt động',
                    _customers.where((c) => c.isActive).length.toString(),
                    Icons.check_circle,
                    Colors.green,
                    'active',
                  ),
                  _buildStatCard(
                    'Không hoạt động',
                    _customers.where((c) => !c.isActive).length.toString(),
                    Icons.cancel,
                    Colors.red,
                    'inactive',
                  ),
                ],
              ),
              // Filter status display
              if (_getFilterStatusText().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.deepPurple, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getFilterStatusText(),
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.deepPurple, size: 16),
                        onPressed: _clearFilters,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
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
              _applyFilters();
            },
          ),
        ),
        if (_isLoadingList)
          Expanded(
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_filteredCustomers.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _search.isEmpty && _getFilterStatusText().isEmpty
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

  String _getFilterStatusText() {
    switch (_selectedStatusFilter) {
      case 'active':
        return 'Đang lọc: Hoạt động';
      case 'inactive':
        return 'Đang lọc: Không hoạt động';
      default:
        return ''; // Don't show filter status for 'all' or null
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String? filterStatus,
  ) {
    // Don't show selected state for 'all' filter by default
    final isSelected = _selectedStatusFilter == filterStatus && filterStatus != 'all';
    
    return GestureDetector(
      onTap: filterStatus != null ? () => _filterByStatus(filterStatus) : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Column(
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
        ),
      ),
    );
  }
}
