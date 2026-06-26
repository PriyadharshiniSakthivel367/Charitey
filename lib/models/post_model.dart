//post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String ngoId;
  final String donorId; 
  final String donorUid; 
  final String? ngoProfileImage; // ADD THIS
  final String image;
  final String description;
  final int likes;
  final DateTime createdAt;

  PostModel({
    required this.postId,
    required this.ngoId,
    required this.donorId,
    this.donorUid = '', 
    this.ngoProfileImage, // ADD THIS
    required this.image,
    required this.description,
    this.likes = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'ngoId': ngoId,
      'donorId': donorId,
      'donorUid': donorUid,
      'ngoProfileImage': ngoProfileImage, // ADD THIS
      'image': image,
      'description': description,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PostModel(
      postId: documentId,
      ngoId: map['ngoId'] ?? '',
      donorId: map['donorId'] ?? '',
      ngoProfileImage: map['ngoProfileImage'] as String?, // ADD THIS
      image: map['image'] ?? '',
      description: map['description'] ?? '',
      likes: map['likes'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}