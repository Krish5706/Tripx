class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? bio;
  final String? profilePicture;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.bio,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      bio: json['bio'],
      profilePicture: json['profilePicture'],
    );
  }
}