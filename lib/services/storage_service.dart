// lib/services/storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StorageService {
  // Configured directly from your Cloudinary Environment Settings
  static const String _cloudName = 'dn3crlxzz'; 
  
  // The official unsigned preset copied from your upload settings tab
  static const String _uploadPreset = 'yzl8jb6z'; 

  /// Uploads an image file or web byte array directly to Cloudinary bypassing the Firebase paywall
  Future<String?> uploadImage(File? imageFile, Uint8List? webImage) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      var request = http.MultipartRequest('POST', url);
      
      // Inject required unsigned form fields
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = 'charitey_uploads'; 

      if (kIsWeb) {
        if (webImage == null) {
          debugPrint("Cloudinary Web Upload Blocked: webImage data is null.");
          return null;
        }
        request.files.add(http.MultipartFile.fromBytes(
          'file', 
          webImage, 
          filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ));
      } else {
        if (imageFile == null) {
          debugPrint("Cloudinary Mobile Upload Blocked: imageFile local path is null.");
          return null;
        }
        request.files.add(await http.MultipartFile.fromPath(
          'file', 
          imageFile.path
        ));
      }

      // Send the request payload over to Cloudinary's asset ingestion server
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("CLOUDINARY STATUS: ${response.statusCode}");
      debugPrint("CLOUDINARY BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final secureUrl =
    data['secure_url'] as String?;
        
        debugPrint("🎉 Cloudinary Media Upload Successful: $secureUrl");
        return secureUrl; // Returns the clean string URL directly into your Firestore records
      } else {
        debugPrint("Cloudinary Server Core Rejection: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Fatal execution crash inside custom StorageService layer: $e");
      return null;
    }
  }
}