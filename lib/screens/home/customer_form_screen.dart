import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../../services/api_service.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer customer;

  const CustomerFormScreen({super.key, required this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  bool _isLoading = false;
  String? _selectedStatus;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone ?? '');
    _emailController = TextEditingController(text: widget.customer.email);
    _addressController = TextEditingController(
      text: widget.customer.region ?? '',
    );
    _selectedStatus = widget.customer.status;
    _selectedRole = widget.customer.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await CustomerService.updateCustomer(
        id: widget.customer.id,
        currentName: widget.customer.name, // Tên hiện tại của khách hàng
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(), // Cho phép chỉnh sửa email
        address: _addressController.text.trim(),
        status: _selectedStatus,
      );

      bool roleUpdated = true;
      String roleUpdateMsg = '';

      // Update role if changed
      if (_selectedRole != null && _selectedRole != widget.customer.role) {
        final roleResp = await ApiService.updateUserRole(
          targetUserId: widget.customer.id,
          newRole: _selectedRole!,
        );
        roleUpdated = roleResp['success'] == true;
        roleUpdateMsg = roleResp['message'] ?? '';
      }

      if (result['success']) {
        if (mounted) {
          if (!roleUpdated && roleUpdateMsg.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cập nhật thông tin thành công nhưng phân loại thất bại: $roleUpdateMsg'),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.green,
              ),
            );
          }
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa khách hàng'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _updateCustomer,
              child: const Text(
                'Lưu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Customer Info Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: widget.customer.typeColor,
                                    child: Icon(
                                      _getCustomerIcon(widget.customer.type),
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.customer.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: widget.customer.typeColor
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: widget.customer.typeColor,
                                            ),
                                          ),
                                          child: Text(
                                            widget.customer.typeDisplayName,
                                            style: TextStyle(
                                              color: widget.customer.typeColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: widget.customer.statusColor
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  widget.customer.statusColor,
                                            ),
                                          ),
                                          child: Text(
                                            widget.customer.statusDisplayName,
                                            style: TextStyle(
                                              color:
                                                  widget.customer.statusColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Form Fields Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin chi tiết',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Tên khách hàng',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.business),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập tên khách hàng';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Số điện thoại',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập số điện thoại';
                                  }
                                  if (value.length < 10 || value.length > 11) {
                                    return 'Số điện thoại phải có 10-11 chữ số';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.email),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập email';
                                  }
                                  // Cải thiện regex email validation
                                  final emailRegex = RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                  );
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return 'Email không đúng định dạng (VD: example@email.com)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  labelText: 'Địa chỉ',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_on),
                                ),
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập địa chỉ';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Status Selection
                              const Text(
                                'Trạng thái tài khoản',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Status Options
                              Column(
                                children: [
                                  _buildStatusOption(
                                    'ACTIVE',
                                    'Kích hoạt',
                                    Icons.check_circle,
                                    Colors.green,
                                    _selectedStatus == 'ACTIVE',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildStatusOption(
                                    'DEACTIVE',
                                    'Hủy kích hoạt',
                                    Icons.cancel,
                                    Colors.red,
                                    _selectedStatus == 'DEACTIVE',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Role Selection
                              const Text(
                                'Phân loại khách hàng',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Column(
                                children: [
                                  _buildRoleOption(
                                    role: 'AGENT',
                                    label: 'Đại lý',
                                    icon: Icons.store,
                                    color: Colors.blue,
                                    isSelected: _selectedRole == 'AGENT',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildRoleOption(
                                    role: 'DISTRIBUTOR',
                                    label: 'Nhà phân phối',
                                    icon: Icons.local_shipping,
                                    color: Colors.purple,
                                    isSelected: _selectedRole == 'DISTRIBUTOR',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildRoleOption(
                                    role: 'CUSTOMER',
                                    label: 'Khách hàng',
                                    icon: Icons.person,
                                    color: Colors.green,
                                    isSelected: _selectedRole == 'CUSTOMER',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateCustomer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Đang lưu...'),
                                    ],
                                  )
                                  : const Text(
                                    'Lưu thay đổi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  IconData _getCustomerIcon(String type) {
    return Icons.store;
  }

  Widget _buildStatusOption(
    String status,
    String label,
    IconData icon,
    Color color,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required String role,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
