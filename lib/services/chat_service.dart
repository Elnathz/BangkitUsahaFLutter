import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; // Tambahkan ini
import 'dart:typed_data';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Update Parameter: Tambahkan receiverId (Penerima)
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String text,
    XFile? imageFile, // <--- UBAH TIPE DATA JADI XFile
  }) async {
    String type = 'text';
    String content = text;

    // 1. Upload Gambar (Versi Aman Web & Android)
    if (imageFile != null) {
      try {
        String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
        Reference ref = _storage.ref().child('chats/$chatRoomId/$fileName');

        // UBAH CARA UPLOAD: Baca sebagai Bytes (Data), bukan File
        Uint8List fileBytes = await imageFile.readAsBytes();

        // Upload Data
        UploadTask uploadTask = ref.putData(
          fileBytes,
          SettableMetadata(
            contentType: 'image/jpeg',
          ), // Penting agar bisa dibuka di browser
        );

        TaskSnapshot snapshot = await uploadTask;
        content = await snapshot.ref.getDownloadURL();
        type = 'image';
      } catch (e) {
        print("Gagal upload: $e");
        return;
      }
    }

    DocumentReference roomRef = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId);

    // 2. Simpan Pesan
    await roomRef.collection('messages').add({
      'senderId': senderId,
      'text': content,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 3. Update Room Data
    await roomRef.set({
      'participants': [senderId, receiverId],
      'last_message': type == 'image' ? '📷 Mengirim gambar' : content,
      'last_message_time': FieldValue.serverTimestamp(),
      'unread_count_$receiverId': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // ... (Fungsi deleteMessage dan editMessage biarkan tetap sama) ...
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<void> editMessage(
    String chatRoomId,
    String messageId,
    String newText,
  ) async {
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({'text': newText, 'isEdited': true});
  }
}
