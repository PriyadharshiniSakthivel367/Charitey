class UserModel {
  final String uid;
  final String name;
  final String username; // <-- NEW: Unique username field
  final String phone;
  final String email;
  final String role; // user / ngo / volunteer / travel_agency
  final String location;
  final String profileImage;
  final String license; 
  final DateTime createdAt;
  final int donationsCount;
  final int postsCount;

  UserModel({
    required this.uid,
    required this.name,
    this.username = '', // <-- NEW
    required this.phone,
    required this.email,
    required this.role,
    required this.location,
    required this.profileImage,
    this.license = '', 
    required this.createdAt,
    this.donationsCount = 0,
    this.postsCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username, // <-- NEW
      'phone': phone,
      'email': email,
      'role': role,
      'location': location,
      'profileImage': profileImage,
      'license': license, 
      'createdAt': createdAt.toIso8601String(),
      'donationsCount': donationsCount,
      'postsCount': postsCount,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      username: map['username'] ?? '', // <-- NEW
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
    );
  }
}