class User {
  final String? id;
  final String name;
  final String phone;
  final String? email;
  final DateTime? createdAt;

  User({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      name: json['name'] ?? json['nom'] ?? '',
      phone: json['phone'] ?? json['telephone'] ?? '',
      email: json['email'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'telephone':
          phone, // le backend attend "telephone" (même champ que register/login)
      'email': email,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
