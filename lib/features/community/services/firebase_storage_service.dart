import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

/// 🔥 Firebase Storage Service untuk Community Posts
/// Support: Web, Android, iOS
/// Features: Upload, Delete, Progress Tracking, Auto Rollback
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload image ke Firebase Storage
  /// Returns: Download URL dari gambar yang diupload
  Future<String?> uploadImage({
    required XFile imageFile,
    required String userId,
    String folder = 'community_posts',
    Function(double)? onProgress,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_${timestamp}_${imageFile.name}';
      final ref = _storage.ref().child('$folder/$fileName');

      UploadTask uploadTask;

      if (kIsWeb) {
        // WEB: Upload dari bytes
        debugPrint('🔥 [WEB] Uploading to: $folder/$fileName');
        final bytes = await imageFile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(
            contentType: 'image/${_getImageExtension(imageFile.name)}',
          ),
        );
      } else {
        // MOBILE: Upload dari file path
        debugPrint('🔥 [MOBILE] Uploading to: $folder/$fileName');
        final file = File(imageFile.path);
        uploadTask = ref.putFile(
          file,
          SettableMetadata(
            contentType: 'image/${_getImageExtension(imageFile.name)}',
          ),
        );
      }

      // Monitor progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('📊 Upload: ${(progress * 100).toStringAsFixed(1)}%');
        if (onProgress != null) {
          onProgress(progress);
        }
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        debugPrint('✅ Upload success! URL: $downloadUrl');
        return downloadUrl;
      } else {
        debugPrint('❌ Upload failed: ${snapshot.state}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading image: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }

  /// Delete image dari Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('✅ Image deleted: $imageUrl');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting image: $e');
      return false;
    }
  }

  /// Get image extension dari filename
  String _getImageExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (extension == 'jpg' || extension == 'jpeg') return 'jpeg';
    if (extension == 'png') return 'png';
    if (extension == 'gif') return 'gif';
    if (extension == 'webp') return 'webp';
    return 'jpeg'; // Default
  }

  /// Save post dengan image URL ke Firestore
  Future<String?> savePost({
    required String userId,
    required String userName,
    required String userAvatar,
    required String businessName,
    required String content,
    String? imageUrl,
    required String category,
    required String groupId,
    required String groupName,
  }) async {
    try {
      final postData = {
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'businessName': businessName,
        'content': content,
        'imageUrl': imageUrl,
        'category': category,
        'groupId': groupId,
        'groupName': groupName,
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'likedBy': [],
        'bookmarkedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('community_posts').add(postData);
      debugPrint('✅ Post saved: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving post: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }

  /// Upload image + save post (atomic operation)
  Future<String?> uploadImageAndSavePost({
    required XFile imageFile,
    required String userId,
    required String userName,
    required String userAvatar,
    required String businessName,
    required String content,
    required String category,
    required String groupId,
    required String groupName,
    Function(double)? onProgress,
  }) async {
    try {
      // Step 1: Upload image
      debugPrint('📤 Step 1/2: Uploading image...');
      final imageUrl = await uploadImage(
        imageFile: imageFile,
        userId: userId,
        folder: 'community_posts',
        onProgress: onProgress,
      );

      if (imageUrl == null) {
        debugPrint('❌ Image upload failed');
        return null;
      }

      // Step 2: Save post dengan image URL
      debugPrint('💾 Step 2/2: Saving post...');
      final postId = await savePost(
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        businessName: businessName,
        content: content,
        imageUrl: imageUrl,
        category: category,
        groupId: groupId,
        groupName: groupName,
      );

      if (postId == null) {
        // Rollback: Delete uploaded image
        debugPrint('⚠️ Post save failed, rolling back...');
        await deleteImage(imageUrl);
        return null;
      }

      debugPrint('✅ Complete! Post ID: $postId');
      return postId;
    } catch (e, stackTrace) {
      debugPrint('❌ Error in uploadImageAndSavePost: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }

  /// Get posts dari Firestore (real-time)
  Stream<List<Map<String, dynamic>>> getPostsStream(String groupId) {
    return _firestore
        .collection('community_posts')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get single post
  Future<Map<String, dynamic>?> getPost(String postId) async {
    try {
      final doc = await _firestore.collection('community_posts').doc(postId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting post: $e');
      return null;
    }
  }

  /// Like post
  Future<bool> likePost(String postId, String userId) async {
    try {
      await _firestore.collection('community_posts').doc(postId).update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error liking post: $e');
      return false;
    }
  }

  /// Unlike post
  Future<bool> unlikePost(String postId, String userId) async {
    try {
      await _firestore.collection('community_posts').doc(postId).update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userId]),
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error unliking post: $e');
      return false;
    }
  }

  /// Bookmark post
  Future<bool> bookmarkPost(String postId, String userId) async {
    try {
      await _firestore.collection('community_posts').doc(postId).update({
        'bookmarkedBy': FieldValue.arrayUnion([userId]),
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error bookmarking post: $e');
      return false;
    }
  }

  /// Unbookmark post
  Future<bool> unbookmarkPost(String postId, String userId) async {
    try {
      await _firestore.collection('community_posts').doc(postId).update({
        'bookmarkedBy': FieldValue.arrayRemove([userId]),
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error unbookmarking post: $e');
      return false;
    }
  }

  /// Delete post (with image)
  Future<bool> deletePost(String postId, String? imageUrl) async {
    try {
      // Delete image first if exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await deleteImage(imageUrl);
      }

      // Delete post document
      await _firestore.collection('community_posts').doc(postId).delete();
      debugPrint('✅ Post deleted: $postId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting post: $e');
      return false;
    }
  }
}