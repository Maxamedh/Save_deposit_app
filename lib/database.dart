

class UserData {
  final String name;
  final String tell;
  final String email;

  UserData({required this.name, required this.tell, required this.email});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tell': tell,
      'email': email,
    };
  }
}
