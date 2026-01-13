import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../models/trending_topic.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_dialog.dart';
import '../services/firebase_storage_service.dart';

class CommunityTopicDetailPage extends StatefulWidget {
  final TrendingTopic topic;

  const CommunityTopicDetailPage({Key? key, required this.topic})
    : super(key: key);

  @override
  State<CommunityTopicDetailPage> createState() =>
      _CommunityTopicDetailPageState();
}

class _CommunityTopicDetailPageState extends State<CommunityTopicDetailPage> {
  final FirebaseStorageService _firebaseService = FirebaseStorageService();
  final user = FirebaseAuth.instance.currentUser;

  // --- ACTIONS ---

  void _handleLike(Post post) {
    if (user == null) {
      _showLoginToast();
      return;
    }
    _firebaseService.toggleLike(post.id, post.isLiked);
  }

  void _handleComment(Post post) {
    if (user == null) {
      _showLoginToast();
      return;
    }

    // PERBAIKAN: Menggunakan showModalBottomSheet dan menghapus parameter dummy
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsDialog(post: post),
    );
  }

  void _handleShare(String postId, String authorName) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      title: Text('Tautan post dari $authorName berhasil disalin!'),
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _handleBookmark(String postId) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      title: const Text('Post disimpan ke koleksi!'),
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _showLoginToast() {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      title: const Text('Silakan login untuk berinteraksi'),
      autoCloseDuration: const Duration(seconds: 3),
    );
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
            child: StreamBuilder<List<Post>>(
              // Mengambil semua post lalu kita filter di client-side
              // (Untuk skala besar, sebaiknya filter dilakukan di query Firestore)
              stream: _firebaseService.getPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final allPosts = snapshot.data ?? [];

                // FILTER: Cari post yang mengandung kata dari Judul Topik
                // Contoh: Topik "Strategi Marketing" akan mencari post dengan kata "Strategi" atau "Marketing"
                final topicKeywords = widget.topic.title.toLowerCase().split(
                  ' ',
                );
                final relatedPosts = allPosts.where((post) {
                  final contentLower = post.content.toLowerCase();
                  final categoryLower = post.category.toLowerCase();

                  // Cek apakah ada keyword yang cocok di konten atau kategori
                  return topicKeywords.any(
                    (word) =>
                        contentLower.contains(word) ||
                        categoryLower.contains(word),
                  );
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Topic Info Card
                    _buildTopicInfoCard(relatedPosts.length),

                    const SizedBox(height: 16),

                    // Posts List
                    if (relatedPosts.isEmpty)
                      _buildEmptyState()
                    else
                      ...relatedPosts.map((post) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: PostCard(
                            post: post,
                            onLike: () => _handleLike(post),
                            onComment: () => _handleComment(post),
                            onShare: () =>
                                _handleShare(post.id, post.author.name),
                            onBookmark: () => _handleBookmark(post.id),
                          ),
                        );
                      }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Header Widget
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1976D2),
            Color(0xFF0D47A1),
          ], // Biru Terang ke Biru Gelap
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
                const Text(
                  'Topik Hangat 🔥',
                  style: TextStyle(fontSize: 14, color: Color(0xFFBBDEFB)),
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
  Widget _buildTopicInfoCard(int postCount) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF90CAF9), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFE1F5FE)],
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
                color: const Color(0xFFBBDEFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.hash,
                color: Color(0xFF1565C0),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.topic.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ditemukan $postCount diskusi terkait topik ini. Bergabunglah dalam percakapan!',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1565C0),
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

  // Empty State Widget
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(LucideIcons.searchX, size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            const Text(
              'Belum ada diskusi untuk topik ini',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Kembali ke Feed"),
            ),
          ],
        ),
      ),
    );
  }
}
