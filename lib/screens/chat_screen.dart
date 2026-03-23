import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

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
  final Color themeColor = const Color(0xFFB56F76);
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
        senderRole: user.role, // <--- ADD THIS LINE!
      );
      
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 50,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUserModel;
    if (user == null) {
       return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: themeColor.withValues(alpha: 0.15),
              radius: 18,
              child: Text(
                widget.otherUserName[0].toUpperCase(), 
                style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.otherUserName,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // --- MESSAGES LIST ---
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(user.uid, widget.otherUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: themeColor));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages', style: TextStyle(color: Colors.grey)));
                }

                List<MessageModel> messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Start the conversation!', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                // Auto-scroll to bottom logic
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    bool isMe = message.senderId == user.uid;

                    // Format time (e.g., 10:45 AM)
                    String formattedTime = DateFormat('h:mm a').format(message.timestamp);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isMe ? themeColor : Colors.white,
                                borderRadius: BorderRadius.circular(20).copyWith(
                                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                                ),
                                border: isMe ? null : Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  if (!isMe)
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5, offset: const Offset(0, 2))
                                ],
                              ),
                              child: Text(
                                message.message,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87, 
                                  fontSize: 15,
                                  height: 1.3
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedTime,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // --- MESSAGE INPUT AREA ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFF0F2F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}