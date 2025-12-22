import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/group.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_dialog.dart';

class CommunityGroupDetailPage extends StatefulWidget {
  final CommunityGroup group;
  final List<Post> posts;
  final Function(String) onLikePost;
  final Function(String) onBookmarkPost;
  final Function(String, String) onSharePost;
  final Function(Post) onCommentClick;
  final bool isJoined;
  final Function(String, String)? onJoinGroup;
  final Function(Post)? onCreatePost;

  const CommunityGroupDetailPage({
    Key? key,
    required this.group,
    required this.posts,
    required this.onLikePost,
    required this.onBookmarkPost,
    required this.onSharePost,
    required this.onCommentClick,
    this.isJoined = false,
    this.onJoinGroup,
    this.onCreatePost,
  }) : super(key: key);

  @override
  State<CommunityGroupDetailPage> createState() =>
      _CommunityGroupDetailPageState();
}

class _CommunityGroupDetailPageState extends State<CommunityGroupDetailPage> {
  bool isCommentDialogOpen = false;
  bool isCreatePostDialogOpen = false;
  Post? selectedPost;
  String newComment = '';

  // Create Post State
  String newPostContent = '';
  String newPostCategory = 'Tips Bisnis';
  File? uploadedImage;
  final ImagePicker _picker = ImagePicker();

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

  // Filter posts yang relevan dengan grup
  List<Post> get groupPosts => widget.posts.take(3).toList();

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

  void handleJoinGroupClick() {
    if (widget.onJoinGroup != null) {
      widget.onJoinGroup!(widget.group.id, widget.group.name);
    }
  }

  void _showToast(String message, ToastificationType type) {
    toastification.show(
      context: context,
      type: type,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 2),
      alignment: Alignment.topCenter,
    );
  }

  // Handle Create Post
  void handleCreatePost() {
    if (newPostContent.trim().isEmpty) {
      _showToast('Konten post tidak boleh kosong!', ToastificationType.error);
      return;
    }

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: Author(
        name: 'Anda',
        avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Anda',
        businessName: 'Usaha Anda',
        verified: false,
      ),
      content: newPostContent,
      image: uploadedImage?.path, // Path to local image
      category: newPostCategory,
      likes: 0,
      comments: 0,
      shares: 0,
      timestamp: 'Baru saja',
      isLiked: false,
      isBookmarked: false,
    );

    if (widget.onCreatePost != null) {
      widget.onCreatePost!(newPost);
    }

    _showToast('Post berhasil dibuat! 📝', ToastificationType.success);

    setState(() {
      newPostContent = '';
      newPostCategory = 'Tips Bisnis';
      uploadedImage = null;
      isCreatePostDialogOpen = false;
    });
  }

  // Handle Image Upload
  Future<void> handleImageUpload() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        // Validasi ukuran file (max 5MB)
        if (fileSize > 5 * 1024 * 1024) {
          _showToast(
            'Ukuran file terlalu besar! Maksimal 5MB',
            ToastificationType.error,
          );
          return;
        }

        setState(() {
          uploadedImage = file;
        });
        _showToast('Gambar berhasil diupload! 📷', ToastificationType.success);
      }
    } catch (e) {
      _showToast('Gagal upload gambar!', ToastificationType.error);
    }
  }

  // Handle Remove Image
  void handleRemoveImage() {
    setState(() {
      uploadedImage = null;
    });
    _showToast('Gambar dihapus', ToastificationType.success);
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
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Group Info Card
                    _buildGroupInfoCard(),

                    const SizedBox(height: 16),

                    // Posts
                    if (groupPosts.isEmpty)
                      _buildEmptyState()
                    else
                      ...groupPosts.map((post) {
                        return PostCard(
                          post: post,
                          onLike: () => widget.onLikePost(post.id),
                          onComment: () => handleCommentClick(post),
                          onShare: () =>
                              widget.onSharePost(post.id, post.author.name),
                          onBookmark: () => widget.onBookmarkPost(post.id),
                        );
                      }),

                    const SizedBox(height: 100),
                  ],
                ),

                // Floating Action Button - CREATE POST
                if (widget.isJoined)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          isCreatePostDialogOpen = true;
                        });
                        _showCreatePostDialog();
                      },
                      backgroundColor: const Color(0xFF2563EB),
                      child: const Icon(LucideIcons.plus, color: Colors.white),
                    ),
                  ),
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
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
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
                  widget.group.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Grup Komunitas',
                  style: TextStyle(fontSize: 14, color: Color(0xFFDBEAFE)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.settings,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              _showToast('Pengaturan grup', ToastificationType.info);
            },
          ),
        ],
      ),
    );
  }

  // Group Info Card
  Widget _buildGroupInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Cover image
          Stack(
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Opacity(
                    opacity: 0.5,
                    child: Image.network(
                      widget.group.image,
                      width: double.infinity,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Group details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group avatar
                    Transform.translate(
                      offset: const Offset(0, -48),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.group.image,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.group.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '👥 ${widget.group.members.toStringAsFixed(0)} anggota',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '📝 ${widget.group.posts} post',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Action buttons
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Row(
                    children: [
                      if (widget.isJoined) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showToast(
                                'Notifikasi grup diaktifkan 🔔',
                                ToastificationType.success,
                              );
                            },
                            icon: const Icon(LucideIcons.bell, size: 16),
                            label: const Text('Notifikasi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _showToast(
                                'Membagikan grup...',
                                ToastificationType.info,
                              );
                            },
                            icon: const Icon(LucideIcons.share2, size: 16),
                            label: const Text('Undang'),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: handleJoinGroupClick,
                            icon: const Icon(LucideIcons.users, size: 16),
                            label: const Text('Gabung Grup'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _showToast(
                                'Membagikan grup...',
                                ToastificationType.info,
                              );
                            },
                            icon: const Icon(LucideIcons.share2, size: 16),
                            label: const Text('Undang'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
            Icon(LucideIcons.users, size: 64, color: Color(0xFFD1D5DB)),
            SizedBox(height: 16),
            Text(
              'Belum ada post di grup ini',
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

  // Create Post Dialog
  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Buat Post Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () {
                        setState(() {
                          newPostContent = '';
                          uploadedImage = null;
                          isCreatePostDialogOpen = false;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tulis Post
                      const Text(
                        'Tulis Post',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Tulis post Anda...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            newPostContent = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Kategori
                      const Text(
                        'Kategori',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: newPostCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Tips Bisnis',
                            child: Text('Tips Bisnis'),
                          ),
                          DropdownMenuItem(
                            value: 'Pengalaman',
                            child: Text('Pengalaman'),
                          ),
                          DropdownMenuItem(
                            value: 'Pertanyaan',
                            child: Text('Pertanyaan'),
                          ),
                          DropdownMenuItem(
                            value: 'Informasi',
                            child: Text('Informasi'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              newPostCategory = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Upload Gambar
                      const Text(
                        'Upload Gambar (Opsional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (uploadedImage != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                uploadedImage!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: handleRemoveImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.x,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: handleImageUpload,
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.image,
                                    size: 48,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Klik untuk upload gambar',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Maksimal 5MB',
                                    style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          newPostContent = '';
                          uploadedImage = null;
                          isCreatePostDialogOpen = false;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: newPostContent.trim().isEmpty
                          ? null
                          : () {
                              handleCreatePost();
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                      ),
                      child: const Text('Kirim Post'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
