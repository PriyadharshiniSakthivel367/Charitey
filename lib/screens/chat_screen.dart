import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; 

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserProfileImage;

  const ChatScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserProfileImage,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final Color themeColor = const Color(0xFF7D444C);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // --- NEW: Read receipts ---
    // Mark any messages the other user already sent us as "read" as soon as
    // this chat screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _markAsRead());
  }

  void _markAsRead() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUserModel;
    if (user == null) return;
    _chatService.markMessagesAsRead(user.uid, widget.otherUserId);
  }

  void sendMessage() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUserModel;
    if (user == null || _messageController.text.trim().isEmpty) return;
    
    String message = _messageController.text.trim();
    _messageController.clear();
    
    try {
      // 👇 FIXED: Added named arguments to match your ChatService definition
      await _chatService.sendMessage(
        user.uid,
        user.name,
        widget.otherUserId,
        widget.otherUserName,
        message,
        senderPhone: user.phone,
        senderLocation: user.location,
        senderRole: user.role,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _makePhoneCall() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        
        String? phoneNumber = data['phone'] ?? data['ngoPhone'];

        if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
          final Uri launchUri = Uri(
            scheme: 'tel',
            path: phoneNumber.trim(),
          );
          
          if (await canLaunchUrl(launchUri)) {
            await launchUrl(launchUri);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open the phone dialer.')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone number not available for this user.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching phone number: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUserModel;
    if (user == null) return const Scaffold(body: Center(child: Text('User not logged in')));
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                // 👇 FIXED: Changed 'O' to the number '0' in the hex code
                colors: [Color(0xFFFDF7F8), Color(0xFFEEDAE0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.1, 1.0],
              ),
            ),
          ),
          Column(
            children: [
              _buildGlassAppBar(),
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _chatService.getMessages(user.uid, widget.otherUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: themeColor));
                    }
                    
                    List<MessageModel> messages = snapshot.data ?? [];

                    // --- NEW: Read receipts ---
                    // If a new incoming message arrives while this screen is
                    // already open, mark it read too. Cheap no-op once caught up,
                    // since markMessagesAsRead only touches unread docs.
                    if (messages.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => _markAsRead());
                    }
                    
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        bool isMe = message.senderId == user.uid;
                        return _buildMessageBubble(message, isMe);
                      },
                    );
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AppBar(
          backgroundColor: Colors.white.withOpacity(0.7),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: themeColor.withOpacity(0.1),
                radius: 18,
                backgroundImage: (widget.otherUserProfileImage != null && widget.otherUserProfileImage!.isNotEmpty)
                    ? NetworkImage(widget.otherUserProfileImage!)
                    : null,
                child: (widget.otherUserProfileImage == null || widget.otherUserProfileImage!.isEmpty)
                    ? Text(
                        widget.otherUserName[0].toUpperCase(),
                        style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.otherUserName,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.call_rounded, color: themeColor, size: 24),
              onPressed: _makePhoneCall,
              tooltip: 'Call User',
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    bool isMedia = message.message.startsWith("[Image]") ||
        message.message.startsWith("[Video]") ||
        message.message.startsWith("[Document]") ||
        message.message.startsWith("[Voice Message]");
        
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isMe ? themeColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10, 
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMedia ? message.message.split(']')[0] + ']' : message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isMedia)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Icon(
                  message.message.startsWith("[Image]") ? Icons.image :
                  message.message.startsWith("[Video]") ? Icons.videocam :
                  message.message.startsWith("[Voice") ? Icons.mic :
                  Icons.insert_drive_file,
                  color: isMe ? Colors.white70 : themeColor.withOpacity(0.7),
                ),
              ),
            // --- NEW: WhatsApp-style read receipt tick, only on messages I sent ---
            // 1 grey tick   -> sent, not yet delivered to their device
            // 2 grey ticks  -> delivered, not yet opened/read
            // 2 blue ticks  -> they've opened the chat and seen it
            if (isMe)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      message.delivered ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 15,
                      color: message.read ? Colors.lightBlueAccent : Colors.white70,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 10, 
            offset: const Offset(0, -5)
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            backgroundColor: themeColor,
            elevation: 0,
            onPressed: sendMessage,
            child: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}