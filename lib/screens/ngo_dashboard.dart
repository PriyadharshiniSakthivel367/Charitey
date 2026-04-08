import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/post_model.dart';
import 'create_post_screen.dart';

class NgoDashboard extends StatefulWidget {
  const NgoDashboard({super.key});

  @override
  State<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends State<NgoDashboard> {
  final Color themeColor = const Color(0xFFB56F76);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUserModel;

    if (user == null) {
      return Center(child: CircularProgressIndicator(color: themeColor));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: themeColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(user.role); 
          }

          var posts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              var post = PostModel.fromMap(posts[index].data() as Map<String, dynamic>, posts[index].id);
              
              if (post.image.isEmpty || !post.image.startsWith('http')) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(post.ngoId).get(),
                builder: (context, userSnapshot) {
                  String ngoName = "NGO";
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    ngoName = (userSnapshot.data!.data() as Map<String, dynamic>)['name'] ?? "NGO";
                  }

                  return PostCardWidget(
                    post: post, 
                    ngoName: ngoName, 
                    currentUserId: user.uid,
                    themeColor: themeColor,
                  );
                }
              );
            },
          );
        },
      ),
      
      // --- FIX: Only show + button if the user is an NGO ---
      floatingActionButton: user.role == 'ngo' 
        ? FloatingActionButton(
            backgroundColor: themeColor,
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreatePostScreen(),
                ),
              );
            },
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          )
        : null, 
    );
  }

  Widget _buildEmptyState(String? role) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))]),
            child: Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text("Impact Gallery", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          Text(
            role == 'ngo' 
              ? "No posts yet.\nClick the + button to share an update!"
              : "No posts yet.\nCheck back later for updates!", 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 15, color: Colors.grey.shade500, height: 1.4)
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// POST CARD WIDGET
// =====================================================================
class PostCardWidget extends StatefulWidget {
  final PostModel post;
  final String ngoName;
  final String currentUserId;
  final Color themeColor;

  const PostCardWidget({
    Key? key,
    required this.post,
    required this.ngoName,
    required this.currentUserId,
    required this.themeColor,
  }) : super(key: key);

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  bool _isLiked = false;

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });

    FirebaseFirestore.instance.collection('posts').doc(widget.post.postId).update({
      'likes': FieldValue.increment(_isLiked ? 1 : -1),
    });
  }

  void _deletePost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); 
              await FirebaseFirestore.instance.collection('posts').doc(widget.post.postId).delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post deleted"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _editPost() {
    TextEditingController descController = TextEditingController(text: widget.post.description);
    TextEditingController tagController = TextEditingController(text: widget.post.donorId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Post"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tagController,
              decoration: const InputDecoration(labelText: "Tag Donor (Optional)", prefixIcon: Icon(Icons.person_add)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
            onPressed: () async {
              Navigator.pop(context); 
              await FirebaseFirestore.instance.collection('posts').doc(widget.post.postId).update({
                'description': descController.text.trim(),
                'donorId': tagController.text.trim(),
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post updated!"), backgroundColor: Colors.green));
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('MMM d, yyyy').format(widget.post.createdAt);
    bool isMyPost = widget.post.ngoId == widget.currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.themeColor.withValues(alpha: 0.2),
                  child: Text(widget.ngoName[0].toUpperCase(), style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.ngoName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(formattedDate, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                if (isMyPost)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    onSelected: (value) {
                      if (value == 'edit') _editPost();
                      if (value == 'delete') _deletePost();
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
              ],
            ),
          ),
          
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 400),
            color: Colors.grey.shade100,
            child: Image.network(
              widget.post.image, 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Padding(
                padding: EdgeInsets.all(40.0),
                child: Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Icon(
                    _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                    size: 28, 
                    color: _isLiked ? Colors.red : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${widget.post.likes} likes", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      TextSpan(text: "${widget.ngoName} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (widget.post.donorId.isNotEmpty) 
                        TextSpan(text: "${widget.post.donorId} ", style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold)),
                      TextSpan(text: widget.post.description),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}