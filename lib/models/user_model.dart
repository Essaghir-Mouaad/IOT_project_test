class User {
  final String uid;
  final String name;
  final String email;
  final String role;
  final int age;

  const User({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.age,
  });

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      uid: data['id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      age: (data['age'] ?? 0) is int
          ? data['age'] as int
          : int.tryParse(data['age'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': uid, 'name': name, 'email': email, 'role': role, 'age': age};
  }
}
