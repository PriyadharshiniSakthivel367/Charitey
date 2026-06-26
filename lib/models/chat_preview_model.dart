//models/chat_preview_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPreviewModel {
  final String chatRoomId;
  final String participantId;
  final String participantName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool hasUnread;
  final String? participantProfileImage; // ADD

  ChatPreviewModel({
    required this.chatRoomId,
    required this.participantId,
    required this.participantName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.hasUnread = false,
    this.participantProfileImage, // ADD
  });

  factory ChatPreviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatPreviewModel(
      chatRoomId: id,
      participantId: map['participantId'] ?? '',
      participantName: map['participantName'] ?? 'Unknown User',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasUnread: map['hasUnread'] ?? false,
      participantProfileImage: map['participantProfileImage'] as String?, // ADD
    );
  }
}