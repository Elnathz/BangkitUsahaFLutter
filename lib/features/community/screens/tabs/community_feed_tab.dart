import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toastification/toastification.dart';

import '../../models/post.dart';
import '../../services/firebase_storage_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/comments_dialog.dart';

class CommunityFeedTab extends StatefulWidget {
  final FirebaseStorageService firebaseService;
  final String searchQuery;
  final VoidCallback onShowCreatePost;

  const CommunityFeedTab({
    super.key,
    required this.firebaseService,
    required this.searchQuery,
    required this.onShowCreatePost,
  });

  @override
  State<CommunityFeedTab> createState() => _CommunityFeedTabState();
}

class _CommunityFeedTabState extends State<CommunityFeedTab> {
  String selectedCategory = 'Semua';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> categories = [
    'Semua', 'Tips Bisnis', 'Tanya Jawab', 'Sharing Pengalaman', 'Promosi', 'Lainnya',
  ];

  // --- ACTIONS ---

  void _handleLike(Post post) {
    if (_auth.currentUser == null) {
      _showLoginToast();
      return;
    }
    widget.firebaseService.toggleLike(post.id, post.isLiked);
  }

  void _handleComment(Post post) {
    if (_auth.currentUser == null) {
      _showLoginToast();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsDialog(post: post),
    );
  }

  void _handleShare(String authorName) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      title: Text('Tautan post dari $authorName disalin!'),
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
    return Column(
      children: [
        // 1. Create Post Trigger (Box "Apa yang Anda pikirkan?")
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: InkWell(
            onTap: widget.onShowCreatePost,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.edit3, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Apa yang Anda pikirkan?', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),

        // 2. Categories Filter
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (val) => setState(() => selectedCategory = category),
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF5D4037),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    checkmarkColor: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 3. Post List (REALTIME STREAM)
        Expanded(
          child: StreamBuilder<List<Post>>(
            stream: widget.firebaseService.getPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final allPosts = snapshot.data ?? [];

              // FILTERING LOGIC
              final filteredPosts = allPosts.where((post) {
                // Filter by Search Query (passed from parent)
                final matchesSearch = widget.searchQuery.isEmpty ||
                    post.content.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
                    post.author.name.toLowerCase().contains(widget.searchQuery.toLowerCase());
                
                // Filter by Category
                final matchesCategory = selectedCategory == 'Semua' || 
                    post.category == selectedCategory;
                
                return matchesSearch && matchesCategory;
              }).toList();

              if (filteredPosts.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.searchX, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("Tidak ada postingan ditemukan", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  final post = filteredPosts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: PostCard(
                      post: post,
                      onLike: () => _handleLike(post),
                      onComment: () => _handleComment(post),
                      onShare: () => _handleShare(post.author.name),
                      onBookmark: () => _handleBookmark(post.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}