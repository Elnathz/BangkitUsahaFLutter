import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/trending_topic.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_dialog.dart';

class CommunityTopicDetailPage extends StatefulWidget {
  final TrendingTopic topic;
  final List<Post> posts;
  final Function(String) onLikePost;
  final Function(String) onBookmarkPost;
  final Function(String, String) onSharePost;
  final Function(Post) onCommentClick;

  const CommunityTopicDetailPage({
    Key? key,
    required this.topic,
    required this.posts,
    required this.onLikePost,
    required this.onBookmarkPost,
    required this.onSharePost,
    required this.onCommentClick,
  }) : super(key: key);

  @override
  State<CommunityTopicDetailPage> createState() =>
      _CommunityTopicDetailPageState();
}

class _CommunityTopicDetailPageState extends State<CommunityTopicDetailPage> {
  bool isCommentDialogOpen = false;
  Post? selectedPost;
  String newComment = '';

  // Mock existing comments - GUNAKAN Comment dari model
  final List<Comment> mockComments = [
    Comment(
      id: '1',
      author: 'Budi Santoso',
      avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Budi',
      content:
          'Setuju banget! Strategi ini sangat membantu untuk UMKM seperti kita.',
      timestamp: '2 jam yang lalu',
      likes: 5,
    ),
    Comment(
      id: '2',
      author: 'Rina Wijaya',
      avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Rina',
      content:
          'Terima kasih sharingnya! Saya sudah coba terapkan dan hasilnya bagus 👍',
      timestamp: '5 jam yang lalu',
      likes: 3,
    ),
    Comment(
      id: '3',
      author: 'Dedi Prasetyo',
      avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Dedi',
      content:
          'Ada yang pernah coba untuk produk fashion juga? Share dong pengalamannya',
      timestamp: '1 hari yang lalu',
      likes: 8,
    ),
  ];

  // Filter posts yang relevan dengan topik (mock - di real app filter berdasarkan tags)
  List<Post> get topicRelatedPosts => widget.posts.take(3).toList();

  void handleCommentClick(Post post) {
    setState(() {
      selectedPost = post;
      isCommentDialogOpen = true;
    });
    _showCommentsDialog();
  }

  void handleSubmitComment() {
    if (newComment.trim().isNotEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Komentar berhasil ditambahkan! 💬'),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.topCenter,
      );
      setState(() {
        newComment = '';
        isCommentDialogOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Topic Info Card
                _buildTopicInfoCard(),

                const SizedBox(height: 16),

                // Posts
                if (topicRelatedPosts.isEmpty)
                  _buildEmptyState()
                else
                  ...topicRelatedPosts.map((post) {
                    return PostCard(
                      post: post,
                      onLike: () => widget.onLikePost(post.id),
                      onComment: () => handleCommentClick(post),
                      onShare: () =>
                          widget.onSharePost(post.id, post.author.name),
                      onBookmark: () => widget.onBookmarkPost(post.id),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEF4444)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topic.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.topic.posts} diskusi',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFEF3C7),
                  ),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.trendingUp, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  // Topic Info Card
  Widget _buildTopicInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFED7AA), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFEE2E2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFED7AA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.trendingUp,
                color: Color(0xFFEA580C),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Topik Trending',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C2D12),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Topik ini sedang banyak dibahas oleh komunitas UMKM. Ikuti diskusi untuk mendapat insight terbaru!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9A3412),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: const [
            Icon(LucideIcons.trendingUp, size: 64, color: Color(0xFFD1D5DB)),
            SizedBox(height: 16),
            Text(
              'Belum ada diskusi untuk topik ini',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  // Comments Dialog
  void _showCommentsDialog() {
    if (selectedPost == null) return;

    showDialog(
      context: context,
      builder: (context) => CommentsDialog(
        post: selectedPost!,
        comments: mockComments,
        onAddComment: (commentText) {
          setState(() {
            newComment = commentText;
          });
          handleSubmitComment();
        },
      ),
    );
  }
}
