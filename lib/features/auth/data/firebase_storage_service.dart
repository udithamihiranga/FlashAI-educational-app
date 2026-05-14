import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase Storage Service for handling file uploads
class FirebaseStorageService {
  static final FirebaseStorageService _instance =
      FirebaseStorageService._();

  factory FirebaseStorageService() => _instance;

  FirebaseStorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

   /// Upload a profile picture
   /// [imageBytes] - the image data
   /// [userId] - the user's ID for naming the file
   /// [extension] - file extension (e.g., 'jpg', 'png')
   Future<String> uploadProfilePicture(
     Uint8List imageBytes,
     String userId,
     String extension,
   ) async {
     try {
       final ref = _storage
           .ref()
           .child('profile_pictures')
           .child('$userId.$extension');

       final metadata = SettableMetadata(
         contentType: _getContentType(extension),
         customMetadata: {'userId': userId},
       );

       // Upload with progress monitoring could be added here
       final uploadTask = ref.putData(imageBytes, metadata);
       await uploadTask;
       
       final downloadURL = await ref.getDownloadURL();
       print('Profile picture uploaded successfully: $downloadURL');
       return downloadURL;
     } catch (e, stack) {
       print('FirebaseStorage upload error: $e');
       print('Stack trace: $stack');
       rethrow;
     }
   }

  /// Delete a profile picture
  Future<void> deleteProfilePicture(String userId, String extension) async {
    try {
      final ref = _storage
          .ref()
          .child('profile_pictures')
          .child('$userId.$extension');
      await ref.delete();
    } catch (e) {
      // File may not exist; ignore
    }
  }

  /// Get MIME type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
