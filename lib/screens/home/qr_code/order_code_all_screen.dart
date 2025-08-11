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
  bool _isLoading = true;

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
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await ApiService.getOrders();
      setState(() {
        _orders = orders;
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
                            _orders.length.toString(),
                            Icons.shopping_cart,
                            Colors.blue,
                          ),
                          _buildStatCard(
                            'Chờ xử lý',
                            _orders.where((o) => o.status == 'pending').length.toString(),
                            Icons.pending,
                            Colors.orange,
                          ),
                          _buildStatCard(
                            'Hoàn thành',
                            _orders.where((o) => o.status == 'completed').length.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                          _buildStatCard(
                            'Đã hủy',
                            _orders.where((o) => o.status == 'deactivated').length.toString(),
                            Icons.cancel,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                            
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
