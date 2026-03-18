import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage(File? imageFile, Uint8List? webImage) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      Reference ref =
          _storage.ref().child("listing_images/$fileName.jpg");

      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = ref.putData(webImage!);
      } else {
        uploadTask = ref.putFile(imageFile!);
      }

      TaskSnapshot snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }
}