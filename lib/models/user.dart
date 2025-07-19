enum UserType { distributor, agent, retail }

class User {
  final int id;
  final String name;
  final UserType type;
  final String address;
  final String phone;
  final String password;

  User({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.password,
  });
} 