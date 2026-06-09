import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({Key? key, required this.otherUserId, required this.otherUserName}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final Color themeColor = const Color(0xFF7D444C);
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUserModel;
    if (user == null || _messageController.text.trim().isEmpty) return;
    
    String message = _messageController.text.trim();
    _messageController.clear(); 
    
    try {
      await _chatService.sendMessage(
        user.uid, 
        user.name, 
        widget.otherUserId, 
        widget.otherUserName, 
        message, 
        senderPhone: user.phone, 
        senderLocation: user.location, 
        senderRole: user.role
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            onPressed: () => Navigator.pop(context)
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: themeColor.withOpacity(0.1), 
                radius: 18, 
                child: Text(
                  widget.otherUserName[0].toUpperCase(), 
                  style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)
                )
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.otherUserName, 
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18), 
                  overflow: TextOverflow.ellipsis
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    // Kept the legacy check just in case old messages in the database still have media links, 
    // so it doesn't crash trying to render them.
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
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMedia ? message.message.split(' ')[0] : message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87, 
                fontSize: 15, 
                fontWeight: FontWeight.w500
              ),
            ),
            if (isMedia) 
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Icon(
                  message.message.startsWith("[Image]") ? Icons.image : 
                  message.message.startsWith("[Video]") ? Icons.videocam : 
                  message.message.startsWith("[Voice") ? Icons.mic : Icons.insert_drive_file, 
                  color: isMe ? Colors.white70 : themeColor.withOpacity(0.7)
                ),
              )
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -5))
        ]
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
                  borderSide: BorderSide.none
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            backgroundColor: themeColor,
            elevation: 0,
            onPressed: _sendMessage,
            child: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}