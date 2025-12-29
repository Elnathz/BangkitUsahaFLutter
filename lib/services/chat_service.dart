import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- KIRIM PESAN (TEXT, GAMBAR, VIDEO) ---
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String text,
    XFile? imageFile, // Parameter ini menampung file Gambar ATAU Video
    String type = 'text', // 'text', 'image', atau 'video'
  }) async {
    String content = text;
    String finalType = type;

    // 1. PROSES UPLOAD FILE (Jika ada)
    if (imageFile != null) {
      try {
        Uint8List fileBytes = await imageFile.readAsBytes();

        // Tentukan path dan metadata berdasarkan tipe
        String extension = finalType == 'video' ? 'mp4' : 'jpg';
        String contentType = finalType == 'video' ? 'video/mp4' : 'image/jpeg';
        String folder = finalType == 'video' ? 'videos' : 'images';

        String fileName = "${DateTime.now().millisecondsSinceEpoch}.$extension";

        // Path: chats/{roomId}/images/filename.jpg atau chats/{roomId}/videos/filename.mp4
        Reference ref = _storage.ref().child(
          'chats/$chatRoomId/$folder/$fileName',
        );

        // Upload Data
        UploadTask uploadTask = ref.putData(
          fileBytes,
          SettableMetadata(contentType: contentType),
        );

        TaskSnapshot snapshot = await uploadTask;
        content = await snapshot.ref.getDownloadURL();
      } catch (e) {
        print("Gagal upload file: $e");
        return; // Hentikan jika upload gagal
      }
    }

    DocumentReference roomRef = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId);

    // 2. SIMPAN PESAN KE FIRESTORE
    await roomRef.collection('messages').add({
      'senderId': senderId,
      'text': content, // Isi pesan (Teks biasa atau URL File)
      'type': finalType,
      'isEdited': false, // Penanda untuk fitur edit
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 3. UPDATE DATA RUANGAN CHAT (Untuk List Chat)
    String previewMsg = content;
    if (finalType == 'image') previewMsg = '📷 Mengirim gambar';
    if (finalType == 'video') previewMsg = '🎥 Mengirim video';

    await roomRef.set({
      'participants': [senderId, receiverId],
      'last_message': previewMsg,
      'last_message_time': FieldValue.serverTimestamp(),
      'unread_count_$receiverId': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // --- HAPUS PESAN ---
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    try {
      // 1. Hapus Dokumen dari Firestore
      DocumentSnapshot doc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // (Opsional) Hapus file dari Storage jika tipe bukan text
        // Jika ingin hemat storage, aktifkan kode di bawah ini:
        /*
        if (data['type'] == 'image' || data['type'] == 'video') {
          try {
            await _storage.refFromURL(data['text']).delete();
          } catch (e) {
            print("Gagal hapus file storage: $e");
          }
        }
        */

        await doc.reference.delete();

        // Update last message jika pesan terakhir dihapus (Opsional, agak kompleks logikanya)
        // Untuk simpelnya, kita biarkan last_message tetap yang lama tidak masalah.
      }
    } catch (e) {
      print("Error delete message: $e");
    }
  }

  // --- EDIT PESAN ---
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
        .update({
          'text': newText,
          'isEdited': true, // Tandai pesan telah diedit
        });
  }
}
