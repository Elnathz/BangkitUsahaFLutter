import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String author;
  final String? avatar;
  final String content;
  final String timestamp;
  final int likes;

  Comment({
    required this.id,
    required this.author,
    this.avatar,
    required this.content,
    required this.timestamp,
    required this.likes,
  });

  // Factory Method untuk mengubah data JSON/Firestore menjadi Objek Comment
  factory Comment.fromMap(Map<String, dynamic> map, String docId) {
    // 1. Konversi Timestamp Firestore ke String yang mudah dibaca (misal: "5 menit lalu")
    String timeAgo = 'Baru saja';
    if (map['timestamp'] != null) {
      try {
        Timestamp t = map['timestamp'];
        DateTime dt = t.toDate();
        Duration diff = DateTime.now().difference(dt);

        if (diff.inDays > 7) {
          timeAgo = "${dt.day}/${dt.month}/${dt.year}";
        } else if (diff.inDays >= 1) {
          timeAgo = "${diff.inDays} hari lalu";
        } else if (diff.inHours >= 1) {
          timeAgo = "${diff.inHours} jam lalu";
        } else if (diff.inMinutes >= 1) {
          timeAgo = "${diff.inMinutes} menit lalu";
        } else {
          timeAgo = "Baru saja";
        }
      } catch (e) {
        timeAgo = "Baru saja";
      }
    }

    // 2. Return Objek Comment
    return Comment(
      id: docId,
      author: map['authorName'] ?? 'Pengguna',
      avatar: map['authorAvatar'],
      content: map['content'] ?? '',
      timestamp: timeAgo,
      likes: map['likes'] ?? 0,
    );
  }
}