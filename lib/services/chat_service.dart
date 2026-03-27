import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/chat_preview_model.dart';
import '../models/notification_model.dart'; 

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  Future<void> sendMessage(String senderId, String senderName, String receiverId, String receiverName, String message, {String? senderPhone, String? senderLocation, String? senderRole}) async {
    try {
      String chatRoomId = getChatRoomId(senderId, receiverId);

      MessageModel newMessage = MessageModel(
        messageId: '', 
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
        read: false,
      );

      // 1. Add the actual message to the chat room
      await _firestore.collection('chats').doc(chatRoomId).collection('messages').add(newMessage.toMap());

      // 2. Update the Sender's Inbox
      await _firestore.collection('users').doc(senderId).collection('chat_previews').doc(chatRoomId).set({
        'participantId': receiverId,
        'participantName': receiverName,
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'hasUnread': false,
      }, SetOptions(merge: true));

      // 3. Update the Receiver's Inbox
      await _firestore.collection('users').doc(receiverId).collection('chat_previews').doc(chatRoomId).set({
        'participantId': senderId,
        'participantName': senderName,
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'hasUnread': true, 
      }, SetOptions(merge: true));

      // --- 4. THE CUSTOMIZED NOTIFICATION ALERT ---
      String notifTitle;
      String notifMessage;
      
      if (senderRole == 'ngo') {
        notifTitle = 'Message from NGO';
        notifMessage = 'The NGO you donated to ($senderName) wants to send you a message regarding your donation. Tap to view details.';
      } 
      // --- FIX: Added logic for Travel Agency ---
      else if (senderRole == 'travel_agency') {
        notifTitle = 'Message from Travel Agency';
        notifMessage = 'The Travel Agency ($senderName) assigned to your donation has sent a message. Tap to view details.';
      } 
      else {
        notifTitle = 'Message from $senderName (Donor)';
        notifMessage = 'Tap to view details and reply.';
      }

      NotificationModel alert = NotificationModel(
        id: _firestore.collection('notifications').doc().id,
        receiverId: receiverId, 
        senderId: senderId,               
        senderName: senderName,
        type: 'new_message', 
        title: notifTitle,
        message: notifMessage, 
        relatedItemId: chatRoomId, 
        createdAt: DateTime.now(),
      );

      Map<String, dynamic> alertData = alert.toMap();
      if (senderPhone != null) alertData['senderPhone'] = senderPhone;
      if (senderLocation != null) alertData['senderLocation'] = senderLocation;
      if (senderRole != null) alertData['senderRole'] = senderRole; 

      await _firestore.collection('notifications').doc(alert.id).set(alertData);

    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  Stream<List<MessageModel>> getMessages(String userId1, String userId2) {
    String chatRoomId = getChatRoomId(userId1, userId2);

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

  Stream<List<ChatPreviewModel>> getChatInbox(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_previews')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatPreviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}