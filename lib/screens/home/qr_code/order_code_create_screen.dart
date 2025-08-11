import 'package:flutter/material.dart';
import '../../../models/device.dart';
import '../../../models/user.dart';
import '../../../services/api_service.dart';

class OrderCodeCreateScreen extends StatefulWidget {
  const OrderCodeCreateScreen({super.key});

  @override
  State<OrderCodeCreateScreen> createState() => _OrderCodeCreateScreenState();
}

class _OrderCodeCreateScreenState extends State<OrderCodeCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoading = true;

  // Danh sách devices để tạo
  final List<DeviceRequest> _devices = [];

  // Danh sách sản phẩm từ API
  List<Map<String, dynamic>> _products = [];

  // Danh sách agents từ API
  List<User> _agents = [];

  // Thông tin người tạo (lấy từ user login)
  String? _currentUserEmail;
  String? _currentUserName;

  // Email khách hàng/đại lý được chọn
  String? _selectedCustomerEmail;

  // Danh sách payment status
  final List<Map<String, String>> _paymentStatuses = [
    {'value': 'free', 'name': 'Miễn phí'},
    {'value': 'paid', 'name': 'Đã thanh toán'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy thông tin user hiện tại
      _currentUserEmail = await ApiService.getCurrentUserEmail();
      final currentUser = await ApiService.getCurrentUser();
      _currentUserName = currentUser?['name'];
      
      // Lấy danh sách agents từ API với role=AGENT và chỉ lấy trạng thái ACTIVE
      final agents = await ApiService.getAllUsers(role: 'AGENT');
      final activeAgents = agents.where((a) => a.status.toUpperCase() == 'ACTIVE').toList();
      
      // Lấy danh sách device types từ API
      final deviceTypes = await ApiService.getDeviceTypes();
      
      setState(() {
        _agents = activeAgents;
        _products = deviceTypes;
        // Không thêm sản phẩm mặc định, người dùng phải tự thêm
      });
    } catch (e) {
      if (mounted) {
        print('Lỗi khi tải dữ liệu: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addDevice() {
    if (_products.isEmpty) return;
    
    setState(() {
      _devices.add(DeviceRequest(
        skuCode: _products.first['skuCode'] ?? '',
        quantity: 1,
        paymentStatus: 'free',
      ));
    });
  }

  void _removeDevice(int index) {
      setState(() {
        _devices.removeAt(index);
      });
  }

  void _updateDevice(int index, String? skuCode, int? quantity, String? paymentStatus) {
    setState(() {
      if (skuCode != null) _devices[index] = _devices[index].copyWith(skuCode: skuCode);
      if (quantity != null) _devices[index] = _devices[index].copyWith(quantity: quantity);
      if (paymentStatus != null) _devices[index] = _devices[index].copyWith(paymentStatus: paymentStatus);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_currentUserEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin người dùng!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedCustomerEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn email khách hàng/đại lý!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất một sản phẩm!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Gọi API tạo order
      final order = await ApiService.createOrder(
        customerId: _selectedCustomerEmail!,
        createdBy: _currentUserEmail!,
        note: _noteController.text.trim(),
        devices: _devices,
      );

      if (order != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo đơn hàng thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, order);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi tạo đơn hàng!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tạo đơn hàng mới'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo đơn hàng mới'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Thông tin cơ bản
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin đơn hàng',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCustomerEmail,
                        items: _agents.map((agent) {
                          return DropdownMenuItem<String>(
                            value: agent.email,
                            child: Text(agent.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCustomerEmail = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Đại lý',
                          hintText: 'Chọn đại lý',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Chọn email khách hàng' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú đơn hàng',
                          hintText: 'Đơn hàng cho đại lý A',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Người tạo:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _currentUserName ?? _currentUserEmail ?? 'Không xác định',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Danh sách devices
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sản phẩm:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addDevice,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Thêm', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_products.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Không có sản phẩm nào khả dụng',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else if (_devices.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Chưa có sản phẩm nào',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Nhấn "Thêm" để bắt đầu',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...List.generate(_devices.length, (index) {
                          final device = _devices[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Sản phẩm ${index + 1}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                        IconButton(
                                          onPressed: () => _removeDevice(index),
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Xóa sản phẩm',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: device.skuCode,
                                    items: _products.map((product) {
                                      return DropdownMenuItem<String>(
                                        value: product['skuCode'] as String? ?? '',
                                        child: Text(product['name'] ?? 'Không có tên'),
                                      );
                                    }).toList(),
                                    onChanged: (value) => _updateDevice(index, value, null, null),
                                    decoration: const InputDecoration(
                                      labelText: 'Chọn sản phẩm',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Flexible(
                                        flex: 1,
                                        child: TextFormField(
                                          initialValue: device.quantity.toString(),
                                          decoration: const InputDecoration(
                                            labelText: 'Số lượng',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (v) {
                                            final quantity = int.tryParse(v ?? '');
                                            if (quantity == null || quantity <= 0) {
                                              return 'Nhập số lượng > 0';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            final quantity = int.tryParse(value);
                                            if (quantity != null) {
                                              _updateDevice(index, null, quantity, null);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        flex: 2,
                                        child: DropdownButtonFormField<String>(
                                          value: device.paymentStatus,
                                          items: _paymentStatuses.map((status) {
                                            return DropdownMenuItem(
                                              value: status['value'],
                                              child: Text(status['name']!),
                                            );
                                          }).toList(),
                                          onChanged: (value) => _updateDevice(index, null, null, value),
                                          decoration: const InputDecoration(
                                            labelText: 'Trạng thái thanh toán',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Nút tạo đơn hàng
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Đang tạo...'),
                        ],
                      )
                    : const Text('Tạo đơn hàng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 