class TrendingTopic {
  final String title;

  TrendingTopic({required this.title});

  factory TrendingTopic.fromMap(Map<String, dynamic> map) {
    return TrendingTopic(title: map['title'] ?? '');
  }
}
