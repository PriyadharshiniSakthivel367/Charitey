import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message
  Future<void> sendMessage(String senderId, String receiverId, String message) async {
    try {
      // 1. Determine chat room ID (alphabetical order of UIDs to ensure consistency)
      List<String> ids = [senderId, receiverId];
      ids.sort();
      String chatRoomId = ids.join('_');

      // 2. Create message model
      MessageModel newMessage = MessageModel(
        messageId: '', // Firebase will generate
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
        read: false,
      );

      // 3. Add message to the subcollection of the chat room
      await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage.toMap());

      // Optionally, update a 'recentChats' kind of collection for the 'chats' tab view
      // ...
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get message stream
  Stream<List<MessageModel>> getMessages(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}
