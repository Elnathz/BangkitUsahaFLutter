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
  });

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
