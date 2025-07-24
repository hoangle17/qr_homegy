import 'package:flutter/material.dart';
import '../../../models/order.dart';
import '../../../services/api_service.dart';
import 'order_code_detail_screen.dart';

class OrderSearchScreen extends StatefulWidget {
  const OrderSearchScreen({super.key});

  @override
  State<OrderSearchScreen> createState() => _OrderSearchScreenState();
}

class _OrderSearchScreenState extends State<OrderSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _customerIdController = TextEditingController();
  final TextEditingController _createdByController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedStatus;
  bool _isLoading = false;
  List<Order> _searchResults = [];
  bool _useGeneralSearch = false;

  // Danh sách trạng thái đơn hàng
  final List<Map<String, String?>> _statuses = [
    {'value': null, 'name': 'Tất cả trạng thái'},
    {'value': 'pending', 'name': 'Chờ xử lý'},
    {'value': 'completed', 'name': 'Hoàn thành'},
    {'value': 'deactivated', 'name': 'Đã hủy'},
  ];

  Future<void> _searchOrders() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<Order> orders;
      
      if (_useGeneralSearch && _queryController.text.trim().isNotEmpty) {
        // Sử dụng tìm kiếm tổng quát
        orders = await ApiService.searchOrders(_queryController.text.trim());
      } else {
        // Sử dụng tìm kiếm chi tiết
        orders = await ApiService.getOrders(
          status: _selectedStatus,
          customerId: _customerIdController.text.trim().isEmpty ? null : _customerIdController.text.trim(),
          createdBy: _createdByController.text.trim().isEmpty ? null : _createdByController.text.trim(),
          fromDate: _fromDate,
          toDate: _toDate,
        );
      }

      setState(() {
        _searchResults = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tìm kiếm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearSearch() {
    _formKey.currentState?.reset();
    _queryController.clear();
    _customerIdController.clear();
    _createdByController.clear();
    _fromDate = null;
    _toDate = null;
    _selectedStatus = null;
    _useGeneralSearch = false;
    setState(() {
      _searchResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Tìm kiếm đơn hàng'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Xóa tìm kiếm',
            onPressed: _clearSearch,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Form
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Toggle cho loại tìm kiếm
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => setState(() => _useGeneralSearch = false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_useGeneralSearch ? Colors.deepPurple : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Tìm kiếm chi tiết'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => setState(() => _useGeneralSearch = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _useGeneralSearch ? Colors.deepPurple : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Tìm kiếm tổng quát'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Tìm kiếm tổng quát
                    if (_useGeneralSearch) ...[
                      TextFormField(
                        controller: _queryController,
                        decoration: const InputDecoration(
                          labelText: 'Từ khóa tìm kiếm',
                          hintText: 'Nhập email, tên, mã MAC...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ] else ...[
                      // Tìm kiếm chi tiết
                      TextFormField(
                        controller: _customerIdController,
                        decoration: const InputDecoration(
                          labelText: 'Email khách hàng/đại lý',
                          hintText: 'agent@email.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _createdByController,
                        decoration: const InputDecoration(
                          labelText: 'Email người tạo',
                          hintText: 'admin@email.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_add),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        items: _statuses.map((status) {
                          return DropdownMenuItem(
                            value: status['value'],
                            child: Text(status['name']!),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedStatus = value),
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái đơn hàng',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.info),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _fromDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() => _fromDate = date);
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _fromDate != null 
                                  ? 'Từ: ${_fromDate!.toString().substring(0, 10)}'
                                  : 'Từ ngày'
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _fromDate != null ? Colors.green : Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _toDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() => _toDate = date);
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _toDate != null 
                                  ? 'Đến: ${_toDate!.toString().substring(0, 10)}'
                                  : 'Đến ngày'
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _toDate != null ? Colors.green : Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _searchOrders,
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.search),
                        label: Text(_isLoading ? 'Đang tìm...' : 'Tìm kiếm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Search Results
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_searchResults.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Không tìm thấy đơn hàng nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Hãy thử thay đổi điều kiện tìm kiếm',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kết quả tìm kiếm (${_searchResults.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                          label: const Text('Xóa tìm kiếm'),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final order = _searchResults[index];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: ListTile(
                          leading: const Icon(Icons.shopping_cart, color: Colors.deepPurple),
                          title: const SizedBox.shrink(),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Khách hàng: ${order.customerName}'),
                              Text('Người tạo: ${order.createdBy}'),
                              Text('Ngày tạo: ${order.createdAt.toString().substring(0, 16)}'),
                              Text('Số lượng device: ${order.deviceCount}'),
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
                                  onOrderUpdated: _searchOrders,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
} 