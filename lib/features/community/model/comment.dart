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
}
