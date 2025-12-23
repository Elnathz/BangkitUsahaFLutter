import 'dart:io';
import 'dart:typed_data'; // Tambahan untuk Uint8List
import 'package:flutter/foundation.dart'; // Tambahan untuk kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // Pastikan import ini ada
import '../models/post.dart';
import '../models/comment.dart';

class FirebaseStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- GET POSTS STREAM (REALTIME) ---
  Stream<List<Post>> getPosts() {
    final currentUserId = _auth.currentUser?.uid ?? '';
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Post.fromMap(doc.data(), doc.id, currentUserId);
      }).toList();
    });
  }

  // --- GET COMMENTS STREAM ---
  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Comment.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // --- ADD COMMENT ---
  Future<void> addComment(String postId, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'userId': user.uid,
        'authorName': user.displayName ?? 'Pengguna',
        'authorAvatar': user.photoURL ?? '',
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
      });

      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(1),
      });
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  // --- TOGGLE LIKE ---
  Future<void> toggleLike(String postId, bool isCurrentlyLiked) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final docRef = _firestore.collection('posts').doc(postId);

    if (isCurrentlyLiked) {
      await docRef.update({
        'likes': FieldValue.increment(-1),
        'likesId': FieldValue.arrayRemove([uid]),
      });
    } else {
      await docRef.update({
        'likes': FieldValue.increment(1),
        'likesId': FieldValue.arrayUnion([uid]),
      });
    }
  }

  // --- UPLOAD IMAGE & SAVE POST (SUPPORT WEB & MOBILE) ---
  Future<String?> uploadImageAndSavePost({
    required XFile? imageFile, // Ubah tipe jadi XFile? agar lebih aman
    required String userId,
    required String userName,
    required String userAvatar,
    required String businessName,
    required String content,
    required String category,
    String? groupId,
    String? groupName,
    required Function(double) onProgress,
  }) async {
    try {
      String? downloadUrl;

      // PROSES UPLOAD GAMBAR
      if (imageFile != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = _storage.ref().child('community_posts/$fileName');
        UploadTask uploadTask;

        if (kIsWeb) {
          // --- LOGIC UNTUK WEB (Upload Bytes) ---
          Uint8List bytes = await imageFile.readAsBytes();
          // Metadata penting agar browser tahu ini gambar
          final metadata = SettableMetadata(contentType: 'image/jpeg'); 
          uploadTask = ref.putData(bytes, metadata);
        } else {
          // --- LOGIC UNTUK MOBILE (Upload File Path) ---
          File fileToUpload = File(imageFile.path);
          uploadTask = ref.putFile(fileToUpload);
        }

        // Listen Progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress =
              snapshot.bytesTransferred / snapshot.totalBytes.toDouble();
          onProgress(progress);
        });

        // Tunggu selesai dan ambil URL
        TaskSnapshot snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      // SIMPAN DATA POST
      return await savePost(
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        businessName: businessName,
        content: content,
        category: category,
        groupId: groupId,
        groupName: groupName,
        imageUrl: downloadUrl,
      );
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // --- SAVE POST TO FIRESTORE ---
  Future<String?> savePost({
    required String userId,
    required String userName,
    required String userAvatar,
    required String businessName,
    required String content,
    required String category,
    String? groupId,
    String? groupName,
    String? imageUrl,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('posts').add({
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'businessName': businessName,
        'content': content,
        'category': category,
        'image': imageUrl ?? '',
        'groupId': groupId,
        'groupName': groupName,
        'likes': 0,
        'likesId': [],
        'comments': 0,
        'shares': 0,
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': false,
      });
      return docRef.id;
    } catch (e) {
      print("Error saving post: $e");
      return null;
    }
  }
}