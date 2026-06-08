import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:io';
import 'package:record/record.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:permission_handler/permission_handler.dart'; 
// Media Attachment Imports
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  
  // Voice Recording Variables
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  // Attachment Variables
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  void _sendMessage() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUserModel;
    if (user == null || _messageController.text.trim().isEmpty) return;
    String message = _messageController.text.trim();
    _messageController.clear(); 
    try {
      await _chatService.sendMessage(user.uid, user.name, widget.otherUserId, widget.otherUserName, message, senderPhone: user.phone, senderLocation: user.location, senderRole: user.role);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // =================== VOICE RECORDING LOGIC ===================
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) _uploadAndSendMedia(File(path), "[Voice Message]", "voice_messages");
    } else {
      if (await Permission.microphone.request().isGranted) {
        String path;
        if (kIsWeb) {
          path = "voice_msg.m4a"; 
        } else {
          final dir = await getApplicationDocumentsDirectory();
          path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }
        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
        setState(() => _isRecording = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Microphone permission denied")));
      }
    }
  }

  // =================== ATTACHMENT LOGIC (IMAGES, VIDEOS, FILES) ===================
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(Icons.image, "Photo", Colors.purple, () => _pickMedia(ImageSource.gallery, isVideo: false)),
                _buildAttachmentOption(Icons.videocam, "Video", Colors.pink, () => _pickMedia(ImageSource.gallery, isVideo: true)),
                _buildAttachmentOption(Icons.insert_drive_file, "Document", Colors.indigo, _pickDocument),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 28)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, {required bool isVideo}) async {
    final XFile? pickedFile = isVideo ? await _picker.pickVideo(source: source) : await _picker.pickImage(source: source);
    if (pickedFile != null) {
      _uploadAndSendMedia(File(pickedFile.path), isVideo ? "[Video]" : "[Image]", isVideo ? "chat_videos" : "chat_images");
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      _uploadAndSendMedia(File(result.files.single.path!), "[Document: ${result.files.single.name}]", "chat_documents");
    }
  }

  Future<void> _uploadAndSendMedia(File file, String messagePrefix, String storageFolder) async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUserModel;
    if (user == null) return;
    
    setState(() => _isUploading = true);
    try {
      String fileName = '$storageFolder/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      UploadTask task = FirebaseStorage.instance.ref().child(fileName).putFile(file);
      TaskSnapshot snapshot = await task;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      await _chatService.sendMessage(user.uid, user.name, widget.otherUserId, widget.otherUserName, "$messagePrefix $downloadUrl", senderPhone: user.phone, senderLocation: user.location, senderRole: user.role);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUserModel;
    if (user == null) return const Scaffold(body: Center(child: Text('User not logged in')));

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
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
              if (_isUploading) const LinearProgressIndicator(color: Color(0xFF7D444C)),
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _chatService.getMessages(user.uid, widget.otherUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: themeColor));
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
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black87), onPressed: () => Navigator.pop(context)),
          title: Row(
            children: [
              CircleAvatar(backgroundColor: themeColor.withOpacity(0.1), radius: 18, child: Text(widget.otherUserName[0].toUpperCase(), style: TextStyle(color: themeColor, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.otherUserName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    bool isMedia = message.message.startsWith("[Image]") || message.message.startsWith("[Video]") || message.message.startsWith("[Document]") || message.message.startsWith("[Voice Message]");
    
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMedia ? message.message.split(' ')[0] : message.message,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
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
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: themeColor, size: 26),
            onPressed: _showAttachmentOptions,
          ),
          IconButton(
            icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic, color: _isRecording ? Colors.red : themeColor, size: 28),
            onPressed: _toggleRecording,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: _isRecording ? "Recording..." : 'Type your message...',
                filled: true,
                fillColor: _isRecording ? Colors.red.shade50 : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
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