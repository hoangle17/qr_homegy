import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';

class CustomerAddScreen extends StatefulWidget {
  const CustomerAddScreen({super.key});

  @override
  State<CustomerAddScreen> createState() => _CustomerAddScreenState();
}

class _CustomerAddScreenState extends State<CustomerAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  String _selectedCustomerType = 'agent'; // Default value

  String get _customerTypeDisplayName {
    switch (_selectedCustomerType) {
      case 'distributor':
        return 'Nhà phân phối';
      case 'customer':
        return 'Khách hàng';
      case 'agent':
        return 'Đại lý';
      default:
        return 'Đại lý';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _addCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await CustomerService.addCustomer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        type: _selectedCustomerType,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm $_customerTypeDisplayName thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
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
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text('Thêm khách hàng'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                            Text(
                              'Thông tin khách hàng',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Customer Type Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedCustomerType,
                              decoration: InputDecoration(
                                labelText: 'Phân loại khách hàng',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.category),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'distributor',
                                  child: Text('Nhà phân phối'),
                                ),
                                DropdownMenuItem(
                                  value: 'customer',
                                  child: Text('Khách lẻ'),
                                ),
                                DropdownMenuItem(
                                  value: 'agent',
                                  child: Text('Đại lý'),
                                ),
                              ],
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedCustomerType = newValue;
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng chọn phân loại khách hàng';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Tên $_customerTypeDisplayName',
                                hintText: _getHintText('name'),
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.business),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập tên $_customerTypeDisplayName';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            

                            
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Số điện thoại',
                                hintText: _getHintText('phone'),
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.phone),
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
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: _getHintText('email'),
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.email),
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
                              decoration: InputDecoration(
                                labelText: 'Địa chỉ',
                                hintText: _getHintText('address'),
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.location_on),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập địa chỉ';
                                }
                                return null;
                              },
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
                        onPressed: _isLoading ? null : _addCustomer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
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
                                  Text('Đang thêm...'),
                                ],
                              )
                            : Text(
                                'Thêm $_customerTypeDisplayName',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getHintText(String field) {
    switch (field) {
      case 'name':
        return 'VD: Đại lý ABC, Cửa hàng XYZ...';
      case 'phone':
        return 'VD: 0123456789, 0987654321...';
      case 'email':
        return 'VD: example@email.com';
      case 'address':
        return 'VD: 123 Đường ABC, Quận 1, TP.HCM';
      default:
        return '';
    }
  }
} 