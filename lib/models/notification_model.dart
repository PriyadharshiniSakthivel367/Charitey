import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String receiverId; // The NGO receiving the alert
  final String senderId;   // The Donor
  final String senderName; 
  final String type;       // e.g., 'donation_offer'
  final String title;
  final String message;
  final String relatedItemId; // The ID of the donation
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.receiverId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.title,
    required this.message,
    required this.relatedItemId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiverId': receiverId,
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'title': title,
      'message': message,
      'relatedItemId': relatedItemId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return NotificationModel(
      id: documentId,
      receiverId: map['receiverId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Someone',
      type: map['type'] ?? 'general',
      title: map['title'] ?? 'New Notification',
      message: map['message'] ?? '',
      relatedItemId: map['relatedItemId'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}