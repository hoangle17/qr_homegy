import 'package:flutter/material.dart';
import '../../services/mock_data_service.dart';
import '../../models/user.dart';
import 'distributor_form_screen.dart';

class DistributorListScreen extends StatefulWidget {
  const DistributorListScreen({super.key});

  @override
  State<DistributorListScreen> createState() => _DistributorListScreenState();
}

class _DistributorListScreenState extends State<DistributorListScreen> {
  String _search = '';

  List<User> get _filteredUsers {
    return MockDataService.users.where((u) {
      final query = _search.toLowerCase();
      return u.name.toLowerCase().contains(query) ||
          u.phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhà phân phối/Đại lý/Khách lẻ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm mới',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DistributorFormScreen()),
              );
              setState(() {}); // Refresh list after add
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm theo tên hoặc số điện thoại',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text('${user.address}\n${user.phone}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DistributorFormScreen(user: user),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            MockDataService.deleteUser(user.id);
                          });
                        },
                      ),
                    ],
                  ),
                  leading: Icon(_iconForType(user.type)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(UserType type) {
    switch (type) {
      case UserType.distributor:
        return Icons.local_shipping;
      case UserType.agent:
        return Icons.store;
      case UserType.retail:
        return Icons.person;
    }
  }
} 