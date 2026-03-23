class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String role; // user / ngo / volunteer / travel_agency
  final String location;
  final String profileImage;
  final String license; // <-- ADDED THIS FOR YOUR FRIEND'S CODE
  final DateTime createdAt;
  final int donationsCount;
  final int postsCount;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.location,
    required this.profileImage,
    this.license = '', // <-- DEFAULT VALUE
    required this.createdAt,
    this.donationsCount = 0,
    this.postsCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'location': location,
      'profileImage': profileImage,
      'license': license, // <-- SAVES TO FIREBASE
      'createdAt': createdAt.toIso8601String(),
      'donationsCount': donationsCount,
      'postsCount': postsCount,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      location: map['location'] ?? '',
      profileImage: map['profileImage'] ?? '',
      license: map['license'] ?? '', // <-- READS FROM FIREBASE
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      donationsCount: map['donationsCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
    );
  }
}