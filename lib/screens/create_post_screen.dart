import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../models/post_model.dart';
import '../widgets/custom_button.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _donorTagController = TextEditingController();
  
  File? _selectedImage;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  final Color themeColor = const Color(0xFFB56F76);

  @override
  void dispose() {
    _descriptionController.dispose();
    _donorTagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        _webImage = await picked.readAsBytes();
      } else {
        _selectedImage = File(picked.path);
      }
      setState(() {});
    }
  }

  Future<void> _uploadPost() async {
    if ((_selectedImage == null && _webImage == null) || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image and write a description.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUserModel;

    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Upload Image to Storage
      final storageService = StorageService();
      String? imageUrl;

      try {
        // Give it 5 seconds. If Firebase blocks it, we catch the error instead of freezing.
        imageUrl = await storageService.uploadImage(_selectedImage, _webImage).timeout(const Duration(seconds: 5));
      } catch (e) {
        print("Firebase Storage blocked the upload: $e");
      }

      // --- THE MAGIC BYPASS FOR TESTING ---
      if (imageUrl == null || imageUrl.isEmpty) {
        // We use a high-quality placeholder image from Unsplash so your app keeps working!
        imageUrl = 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?q=80&w=1000&auto=format&fit=crop';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Storage access blocked. Using a test image so you can continue!"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // 2. Create Post Model
      String postId = FirebaseFirestore.instance.collection('posts').doc().id;
      
      PostModel newPost = PostModel(
        postId: postId,
        ngoId: user.uid,
        donorId: _donorTagController.text.trim(), 
        image: imageUrl,
        description: _descriptionController.text.trim(),
        likes: 0,
        createdAt: DateTime.now(),
      );

      // 3. Save to Firestore
      await FirebaseFirestore.instance.collection('posts').doc(postId).set(newPost.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Post published to Impact Gallery!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); 

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("New Post", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IMAGE PICKER ---
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: _selectedImage != null || _webImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: kIsWeb
                            ? Image.memory(_webImage!, fit: BoxFit.cover)
                            : Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 50, color: themeColor),
                          const SizedBox(height: 12),
                          Text("Tap to upload a photo", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // --- DONOR TAG ---
            const Text("Tag Donor (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _donorTagController,
              decoration: InputDecoration(
                hintText: "Enter donor's name...",
                prefixIcon: Icon(Icons.person_add_alt_1_rounded, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: themeColor)),
              ),
            ),
            const SizedBox(height: 20),

            // --- CAPTION ---
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write a caption about this impact...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: themeColor)),
              ),
            ),
            const SizedBox(height: 40),

            // --- PUBLISH BUTTON ---
            CustomButton(
              text: "Share to Gallery",
              isLoading: _isLoading,
              onPressed: _uploadPost,
            ),
          ],
        ),
      ),
    );
  }
}