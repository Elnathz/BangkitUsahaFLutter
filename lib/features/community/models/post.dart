import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final Author author;
  final String content;
  final String? image;
  final String category;
  final int likes;
  final int comments;
  final int shares;
  final String timestamp;
  final bool isLiked;
  final bool isBookmarked;

  // Field tambahan untuk referensi grup
  final String? groupId;
  final String? groupName;

  Post({
    required this.id,
    required this.author,
    required this.content,
    this.image,
    required this.category,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.timestamp,
    required this.isLiked,
    required this.isBookmarked,
    this.groupId,
    this.groupName,
  });

  // Factory WAJIB ADA untuk membaca data dari Firebase
  factory Post.fromMap(Map<String, dynamic> map, String docId, String currentUserId) {
    // Parsing Author
    final author = Author(
      name: map['userName'] ?? 'Pengguna',
      avatar: map['userAvatar'] ?? '',
      businessName: map['businessName'] ?? 'UMKM Member',
      verified: map['isVerified'] ?? false,
    );

    // Parsing Waktu (Timestamp Firestore -> String Ago)
    String timeAgo = '';
    if (map['timestamp'] != null) {
      Timestamp t = map['timestamp'];
      DateTime dt = t.toDate();
      Duration diff = DateTime.now().difference(dt);

      if (diff.inDays > 7) {
        timeAgo = "${dt.day}/${dt.month}/${dt.year}";
      } else if (diff.inDays >= 1) {
        timeAgo = "${diff.inDays} hari yang lalu";
      } else if (diff.inHours >= 1) {
        timeAgo = "${diff.inHours} jam yang lalu";
      } else if (diff.inMinutes >= 1) {
        timeAgo = "${diff.inMinutes} menit yang lalu";
      } else {
        timeAgo = "Baru saja";
      }
    }

    // Cek Like
    List<dynamic> likesList = map['likesId'] ?? [];
    bool liked = likesList.contains(currentUserId);

    return Post(
      id: docId,
      author: author,
      content: map['content'] ?? '',
      image: (map['image'] == "" || map['image'] == null) ? null : map['image'],
      category: map['category'] ?? 'Umum',
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      shares: map['shares'] ?? 0,
      timestamp: timeAgo,
      isLiked: liked,
      isBookmarked: false, // Belum diimplementasi
      groupId: map['groupId'],
      groupName: map['groupName'],
    );
  }

  Post copyWith({
    String? id,
    Author? author,
    String? content,
    String? image,
    String? category,
    int? likes,
    int? comments,
    int? shares,
    String? timestamp,
    bool? isLiked,
    bool? isBookmarked,
    String? groupId,
    String? groupName,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      image: image ?? this.image,
      category: category ?? this.category,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      timestamp: timestamp ?? this.timestamp,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
    );
  }
}

class Author {
  final String name;
  final String? avatar;
  final String businessName;
  final bool verified;

  Author({
    required this.name,
    this.avatar,
    required this.businessName,
    required this.verified,
  });
}