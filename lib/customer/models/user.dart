class User {
  final String id;
  final String fullName;
  final String email;

  User({
    required this.id,
    required this.fullName,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
    );
  }
}
