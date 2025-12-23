import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';

class FirebaseStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- FUNGSI BARU: GET POSTS STREAM ---
  Stream<List<Post>> getPosts() {
    final currentUserId = _auth.currentUser?.uid ?? '';
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Menggunakan fromMap yang baru kita buat di models/post.dart
        return Post.fromMap(doc.data(), doc.id, currentUserId);
      }).toList();
    });
  }

  // --- FUNGSI BARU: TOGGLE LIKE ---
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

  // --- FUNGSI UPLOAD GAMBAR DAN SIMPAN POST ---
  Future<String?> uploadImageAndSavePost({
    required dynamic imageFile, // Bisa XFile atau File
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
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('community_posts/$fileName');
      
      // Handle tipe file (XFile dari image_picker atau File biasa)
      File fileToUpload;
      if (imageFile is File) {
        fileToUpload = imageFile;
      } else {
        fileToUpload = File(imageFile.path);
      }

      UploadTask uploadTask = ref.putFile(fileToUpload);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            snapshot.bytesTransferred / snapshot.totalBytes.toDouble();
        onProgress(progress);
      });

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

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

  // --- FUNGSI SIMPAN POST KE FIRESTORE ---
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