import 'dart:io';
import 'dart:typed_data'; // Untuk Uint8List
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post.dart';
import '../models/comment.dart';

class FirebaseStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- GET POSTS STREAM ---
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

  Future<String?> createGroup({
    required XFile? imageFile,
    required String name,
    required String description,
    required String creatorId,
  }) async {
    try {
      String imageUrl =
          'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=500';

      if (imageFile != null) {
        String fileName = 'group_${DateTime.now().millisecondsSinceEpoch}';
        Reference ref = _storage.ref().child('community_groups/$fileName');
        UploadTask uploadTask;

        if (kIsWeb) {
          Uint8List bytes = await imageFile.readAsBytes();
          final metadata = SettableMetadata(contentType: 'image/jpeg');
          uploadTask = ref.putData(bytes, metadata);
        } else {
          File fileToUpload = File(imageFile.path);
          uploadTask = ref.putFile(fileToUpload);
        }

        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // 1. Buat Dokumen Grup
      DocumentReference docRef = await _firestore.collection('groups').add({
        'name': name,
        'description': description,
        'creatorId': creatorId,
        'image': imageUrl,
        'members': 1,
        'posts': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. OTOMATIS GABUNGKAN CREATOR KE SUB-COLLECTION MEMBERS
      await docRef.collection('members').doc(creatorId).set({
        'joinedAt': FieldValue.serverTimestamp(),
        'role': 'admin',
      });

      return docRef.id;
    } catch (e) {
      print("Error creating group: $e");
      return null;
    }
  }

  // --- CHECK IF JOINED ---
  Future<bool> hasJoinedGroup(String groupId, String userId) async {
    try {
      final doc = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // --- JOIN GROUP ---
  Future<void> joinGroup(String groupId, String userId) async {
    try {
      // Tambah ke sub-collection members
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .set({'joinedAt': FieldValue.serverTimestamp(), 'role': 'member'});

      // Increment counter anggota
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.increment(1),
      });
    } catch (e) {
      print("Error joining group: $e");
    }
  }

  // --- LEAVE GROUP ---
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      // Hapus dari sub-collection members
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .delete();

      // Decrement counter anggota
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.increment(-1),
      });
    } catch (e) {
      print("Error leaving group: $e");
    }
  }

  // --- UPLOAD IMAGE & SAVE POST ---
  Future<String?> uploadImageAndSavePost({
    required XFile? imageFile,
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

      if (imageFile != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = _storage.ref().child('community_posts/$fileName');
        UploadTask uploadTask;

        if (kIsWeb) {
          Uint8List bytes = await imageFile.readAsBytes();
          final metadata = SettableMetadata(contentType: 'image/jpeg');
          uploadTask = ref.putData(bytes, metadata);
        } else {
          File fileToUpload = File(imageFile.path);
          uploadTask = ref.putFile(fileToUpload);
        }

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress =
              snapshot.bytesTransferred / snapshot.totalBytes.toDouble();
          onProgress(progress);
        });

        TaskSnapshot snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

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

  // --- SAVE POST TO FIRESTORE (UPDATED) ---
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
      // 1. Simpan Postingan ke Collection 'posts'
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

      // 2. LOGIKA BARU: Update Jumlah Post di Grup (Increment)
      if (groupId != null && groupId.isNotEmpty) {
        await _firestore.collection('groups').doc(groupId).update({
          'posts': FieldValue.increment(1),
        });
      }

      return docRef.id;
    } catch (e) {
      print("Error saving post: $e");
      return null;
    }
  }

  Future<void> updatePost(String postId, String newContent) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'content': newContent,
        'isEdited': true, // Opsional: Penanda bahwa post telah diedit
      });
    } catch (e) {
      print("Error updating post: $e");
    }
  }

  // --- DELETE POST (HAPUS) ---
  Future<void> deletePost(String postId, String? groupId) async {
    try {
      // 1. Hapus Postingan
      await _firestore.collection('posts').doc(postId).delete();

      // 2. Jika ini postingan grup, kurangi jumlah post di grup tersebut
      if (groupId != null && groupId.isNotEmpty) {
        await _firestore.collection('groups').doc(groupId).update({
          'posts': FieldValue.increment(-1),
        });
      }

      // Opsional: Hapus sub-collection comments (Firestore tidak otomatis menghapus sub-collection)
      // Namun untuk skala kecil, ini bisa diabaikan atau ditangani cloud function.
    } catch (e) {
      print("Error deleting post: $e");
    }
  }

  // --- DELETE COMMENT ---
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      // 1. Hapus Komentar
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // 2. Kurangi counter komentar di post
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(-1),
      });
    } catch (e) {
      print("Error deleting comment: $e");
    }
  }
}
