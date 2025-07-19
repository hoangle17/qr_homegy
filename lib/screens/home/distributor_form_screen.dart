import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/mock_data_service.dart';

class DistributorFormScreen extends StatefulWidget {
  final User? user;
  const DistributorFormScreen({super.key, this.user});

  @override
  State<DistributorFormScreen> createState() => _DistributorFormScreenState();
}

class _DistributorFormScreenState extends State<DistributorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  UserType? _type;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _addressController = TextEditingController(text: widget.user?.address ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _type = widget.user?.type;
  }

  void _save() {
    if (_formKey.currentState!.validate() && _type != null) {
      if (widget.user == null) {
        // Thêm mới
        final newUser = User(
          id: DateTime.now().millisecondsSinceEpoch,
          name: _nameController.text,
          type: _type!,
          address: _addressController.text,
          phone: _phoneController.text,
          password: '123456', // default
        );
        MockDataService.addUser(newUser);
      } else {
        // Sửa
        final updatedUser = User(
          id: widget.user!.id,
          name: _nameController.text,
          type: _type!,
          address: _addressController.text,
          phone: _phoneController.text,
          password: widget.user!.password,
        );
        MockDataService.updateUser(updatedUser);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.user == null ? 'Thêm khách hàng' : 'Sửa khách hàng')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên'),
                validator: (v) => v == null || v.isEmpty ? 'Nhập tên' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
                validator: (v) => v == null || v.isEmpty ? 'Nhập địa chỉ' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                validator: (v) => v == null || v.isEmpty ? 'Nhập số điện thoại' : null,
              ),
              DropdownButtonFormField<UserType>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: UserType.distributor, child: Text('Nhà phân phối')),
                  DropdownMenuItem(value: UserType.agent, child: Text('Đại lý')),
                  DropdownMenuItem(value: UserType.retail, child: Text('Khách lẻ')),
                ],
                onChanged: (value) => setState(() => _type = value),
                decoration: const InputDecoration(labelText: 'Loại'),
                validator: (v) => v == null ? 'Chọn loại' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 