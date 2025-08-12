import 'package:flutter/material.dart';
import '../../../models/order.dart';
import '../../../services/api_service.dart';
import '../../../widgets/copyable_text.dart';
import 'order_code_detail_screen.dart';
import 'order_code_create_screen.dart';
import 'order_search_screen.dart';

class OrderCodeAllScreen extends StatefulWidget {
  const OrderCodeAllScreen({super.key});

  @override
  State<OrderCodeAllScreen> createState() => _OrderCodeAllScreenState();
}

class _OrderCodeAllScreenState extends State<OrderCodeAllScreen> {
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  bool _isLoadingList = false; // Thêm biến loading riêng cho list
  String? _selectedStatusFilter;

  // Helper function to format date in HH:mm dd-MM-yyyy format
  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    return '$hour:$minute:$second $day/$month/$year';
  }

  @override
  void initState() {
    super.initState();
    // No default filter selected - show all orders without highlighting any stat card
    _selectedStatusFilter = 'all';
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Always get all orders for statistics (without filter)
      final allOrders = await ApiService.getOrders();
      
      // Get filtered orders for display
      final orders = await ApiService.getOrders(status: _selectedStatusFilter == 'all' ? null : _selectedStatusFilter);
      setState(() {
        _orders = allOrders; // Use all orders for statistics
        _filteredOrders = orders; // Use filtered orders for display
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải danh sách đơn hàng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to handle filter by status
  void _filterByStatus(String? status) async {
    setState(() {
      _selectedStatusFilter = status;
      _isLoadingList = true; // Chỉ loading phần list
    });
    
    try {
      // Chỉ load filtered orders, không load lại all orders
      final orders = await ApiService.getOrders(status: status == 'all' ? null : status);
      setState(() {
        _filteredOrders = orders;
        _isLoadingList = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingList = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lọc đơn hàng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to clear all filters
  void _clearFilters() async {
    setState(() {
      _selectedStatusFilter = null;
      _isLoadingList = true; // Chỉ loading phần list
    });
    
    try {
      // Load tất cả orders
      final orders = await ApiService.getOrders();
      setState(() {
        _filteredOrders = orders;
        _isLoadingList = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingList = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa bộ lọc: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get counts for statistics - always show total counts from all data (not filtered)
  int get _totalCount => _orders.length;
  int get _pendingCount => _orders.where((o) => o.status == 'pending').length;
  int get _completedCount => _orders.where((o) => o.status == 'completed').length;
  int get _cancelledCount => _orders.where((o) => o.status == 'deactivated').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách đơn hàng'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Tìm kiếm',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderSearchScreen()),
                );
                if (result != null) {
                  // Refresh list after search
                  _loadOrders();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Tạo đơn hàng mới',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderCodeCreateScreen()),
                );
                if (result != null) {
                  // Refresh list after creating new order
                  _loadOrders();
                }
              },
            ),
        ],
      ),
      body: _isLoading
              ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Không có đơn hàng nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Thống kê tổng quan với click functionality
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
                                _totalCount.toString(),
                                Icons.shopping_cart,
                                Colors.blue,
                                'all', // Filter for all (show all orders)
                              ),
                              _buildStatCard(
                                'Chờ xử lý',
                                _pendingCount.toString(),
                                Icons.pending,
                                Colors.orange,
                                'pending',
                              ),
                              _buildStatCard(
                                'Hoàn thành',
                                _completedCount.toString(),
                                Icons.check_circle,
                                Colors.green,
                                'completed',
                              ),
                              _buildStatCard(
                                'Đã hủy',
                                _cancelledCount.toString(),
                                Icons.cancel,
                                Colors.red,
                                'deactivated',
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
                    Expanded(
                      child: _isLoadingList
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredOrders.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                                      const SizedBox(height: 16),
                                      Text(
                                        _getFilterStatusText().isNotEmpty
                                            ? 'Không tìm thấy đơn hàng nào phù hợp'
                                            : 'Không có đơn hàng nào',
                                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(8.0),
                                  itemCount: _filteredOrders.length,
                                  itemBuilder: (context, index) {
                                    final order = _filteredOrders[index];
                                      
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                      child: ListTile(
                                        leading: const Icon(Icons.shopping_cart, color: Colors.deepPurple),
                                        title: const SizedBox.shrink(),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CopyableText(
                                              text: 'Khách hàng: ${order.customerName}',
                                              style: const TextStyle(fontSize: 14),
                                              copyMessage: 'Đã copy tên khách hàng',
                                            ),
                                            CopyableText(
                                              text: 'Người tạo: ${order.createdBy}',
                                              style: const TextStyle(fontSize: 14),
                                              copyMessage: 'Đã copy người tạo',
                                            ),
                                            CopyableText(
                                              text: 'Ngày tạo: ${_formatDateTime(order.createdAt)}',
                                              style: const TextStyle(fontSize: 14),
                                              copyMessage: 'Đã copy ngày tạo',
                                            ),
                                            CopyableText(
                                              text: 'Số lượng device: ${order.deviceCount}',
                                              style: const TextStyle(fontSize: 14),
                                              copyMessage: 'Đã copy số lượng thiết bị',
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: order.status == 'pending' ? Colors.orange : 
                                                       order.status == 'completed' ? Colors.green : Colors.red,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                order.status == 'pending' ? 'Chờ xử lý' :
                                                order.status == 'completed' ? 'Hoàn thành' : 'Đã hủy',
                                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: const Icon(Icons.arrow_forward_ios),
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => OrderCodeDetailScreen(
                                                order: order,
                                                onOrderUpdated: _loadOrders,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),

    );
  }

  String _getFilterStatusText() {
    switch (_selectedStatusFilter) {
      case 'pending':
        return 'Đang lọc: Chờ xử lý';
      case 'completed':
        return 'Đang lọc: Hoàn thành';
      case 'deactivated':
        return 'Đang lọc: Đã hủy';
      default:
        return ''; // Don't show filter status for 'all' or null
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String? filterStatus) {
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
