class UserModel {
  final String uid;
  final String name;
  final String username;
  final String phone;
  final String email;
  final String role; 
  final String location;
  final String profileImage;
  final String license;
  final DateTime createdAt;
  final int donationsCount;
  final int postsCount;
  // NEW: Mapped from Firebase
  final String? fcmToken;
  final List<String> favorites;

  UserModel({
    required this.uid,
    required this.name,
    this.username = '',
    required this.phone,
    required this.email,
    required this.role,
    required this.location,
    required this.profileImage,
    this.license = '',
    required this.createdAt,
    this.donationsCount = 0,
    this.postsCount = 0,
    this.fcmToken,
    this.favorites = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'phone': phone,
      'email': email,
      'role': role,
      'location': location,
      'profileImage': profileImage,
      'license': license,
      'createdAt': createdAt.toIso8601String(),
      'donationsCount': donationsCount,
      'postsCount': postsCount,
      'fcmToken': fcmToken,
      'favorites': favorites,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      location: map['location'] ?? '',
      profileImage: map['profileImage'] ?? '',
      license: map['license'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      donationsCount: map['donationsCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
      fcmToken: map['fcmToken'],
      favorites: List<String>.from(map['favorites'] ?? []),
    );
  }
}