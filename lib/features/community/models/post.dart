import 'package:cloud_firestore/cloud_firestore.dart';

class PostAuthor {
  final String id;
  final String name;
  final String? avatar;
  final String businessName;
  final bool verified;

  PostAuthor({
    required this.id,
    required this.name,
    this.avatar,
    required this.businessName,
    required this.verified,
  });
}

class Post {
  final String id;
  final String userId; // INI YANG KITA TAMBAHKAN AGAR ERROR HILANG
  final PostAuthor author;
  final String content;
  final String? image;
  final String category;
  final String? groupId;
  final String? groupName;
  final int likes;
  final int comments;
  final int shares;
  final String timestamp;
  final bool isLiked;

  Post({
    required this.id,
    required this.userId,
    required this.author,
    required this.content,
    this.image,
    required this.category,
    this.groupId,
    this.groupName,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.timestamp,
    required this.isLiked,
  });

  factory Post.fromMap(Map<String, dynamic> map, String id, String currentUserId) {
    // Logic Format Waktu (Timestamp ke String)
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

    return Post(
      id: id,
      // Mapping userId dari database ke variable class
      userId: map['userId'] ?? '', 
      
      author: PostAuthor(
        id: map['userId'] ?? '',
        name: map['userName'] ?? 'Pengguna',
        avatar: map['userAvatar'],
        businessName: map['businessName'] ?? 'UMKM Member',
        verified: map['isVerified'] ?? false,
      ),
      content: map['content'] ?? '',
      image: map['image'],
      category: map['category'] ?? 'Umum',
      groupId: map['groupId'],
      groupName: map['groupName'],
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      shares: map['shares'] ?? 0,
      timestamp: timeAgo,
      
      // Cek apakah user yang sedang login ada di array likesId
      isLiked: (map['likesId'] as List?)?.contains(currentUserId) ?? false,
    );
  }
}