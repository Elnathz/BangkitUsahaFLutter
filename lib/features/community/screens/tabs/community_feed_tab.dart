import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahan untuk cek admin/hapus
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
  bool _isAdmin = false; // Status Admin

  final List<String> categories = [
    'Semua',
    'Tips Bisnis',
    'Tanya Jawab',
    'Sharing Pengalaman',
    'Promosi',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus(); // Cek admin saat init
  }

  // --- LOGIC ADMIN ---

  Future<void> _checkAdminStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()?['role'] == 'admin') {
        if (mounted) {
          setState(() => _isAdmin = true);
        }
      }
    } catch (e) {
      debugPrint("Gagal cek admin: $e");
    }
  }

  Future<void> _deletePost(String postId, String? groupId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Postingan?"),
        content: const Text("Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog
              try {
                // Gunakan service function untuk delete post
                await widget.firebaseService.deletePost(postId, groupId);

                if (mounted) {
                  toastification.show(
                    context: context,
                    type: ToastificationType.success,
                    title: const Text("Postingan dihapus."),
                    autoCloseDuration: const Duration(seconds: 2),
                  );
                }
              } catch (e) {
                toastification.show(
                  context: context,
                  type: ToastificationType.error,
                  title: Text("Gagal hapus: $e"),
                );
              }
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

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
                  const Text(
                    'Apa yang Anda pikirkan?',
                    style: TextStyle(color: Colors.grey),
                  ),
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
                    onSelected: (val) =>
                        setState(() => selectedCategory = category),
                    backgroundColor: Colors.white,
                    selectedColor: Colors.black,
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
                final matchesSearch =
                    widget.searchQuery.isEmpty ||
                    post.content.toLowerCase().contains(
                      widget.searchQuery.toLowerCase(),
                    ) ||
                    post.author.name.toLowerCase().contains(
                      widget.searchQuery.toLowerCase(),
                    );

                // Filter by Category
                final matchesCategory =
                    selectedCategory == 'Semua' ||
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
                      Text(
                        "Tidak ada postingan ditemukan",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  final post = filteredPosts[index];

                  // CEK HAK HAPUS
                  // (Asumsi di Model Post ada field authorId atau userId)
                  // Jika di model Anda namanya 'author.id', sesuaikan ya.
                  // Defaultnya kita cek Admin atau Pemilik Post.
                  final currentUid = _auth.currentUser?.uid;
                  bool isMyPost =
                      (currentUid != null && post.author.id == currentUid);
                  bool canDelete = _isAdmin || isMyPost;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    // GUNAKAN STACK UNTUK OVERLAY TOMBOL HAPUS
                    child: Stack(
                      children: [
                        PostCard(
                          post: post,
                          onLike: () => _handleLike(post),
                          onComment: () => _handleComment(post),
                          onShare: () => _handleShare(post.author.name),
                          onBookmark: () => _handleBookmark(post.id),
                        ),

                        // TOMBOL HAPUS (POJOK KANAN ATAS)
                        if (canDelete)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  LucideIcons.trash2,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                tooltip: _isAdmin ? "Hapus (Admin)" : "Hapus",
                                onPressed: () =>
                                    _deletePost(post.id, post.groupId),
                              ),
                            ),
                          ),
                      ],
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
