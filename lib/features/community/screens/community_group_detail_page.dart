import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/group.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_dialog.dart';
import '../services/firebase_storage_service.dart';

/// Community Group Detail Page - PRODUCTION VERSION
/// - Clean UI without debug panels
/// - Firebase Storage integration for image upload
/// - Firestore integration for post storage
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
  XFile? pickedImageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _postController = TextEditingController();

  // Firebase Service
  final FirebaseStorageService _firebaseService = FirebaseStorageService();

  // Upload State
  bool isUploading = false;
  double uploadProgress = 0.0;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  // Mock existing comments
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
  ];

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

  void _showCommentsDialog() {
    if (selectedPost == null) return;
    showDialog(
      context: context,
      builder: (context) => CommentsDialog(
        post: selectedPost!,
        comments: mockComments,
        onAddComment: (comment) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text('Komentar berhasil ditambahkan! 💬'),
            autoCloseDuration: const Duration(seconds: 2),
            alignment: Alignment.topCenter,
          );
        },
      ),
    );
  }

  // Pick Image from Gallery
  Future<void> _handlePickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final sizeInMB = bytes.length / (1024 * 1024);

        if (sizeInMB > 5) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: Text(
              'Ukuran file terlalu besar! Maksimal 5MB (${sizeInMB.toStringAsFixed(2)} MB)',
            ),
            autoCloseDuration: const Duration(seconds: 3),
          );
          return;
        }

        setState(() {
          pickedImageFile = image;
        });

        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('Gambar berhasil dipilih! 📷'),
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text('Gagal memilih gambar: $e'),
        autoCloseDuration: const Duration(seconds: 3),
      );
    }
  }

  // Create Post and Upload to Firebase
  Future<void> _handleCreatePost() async {
    if (newPostContent.trim().isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('Konten post tidak boleh kosong!'),
        autoCloseDuration: const Duration(seconds: 2),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('Anda harus login terlebih dahulu!'),
        autoCloseDuration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    try {
      String? postId;

      if (pickedImageFile != null) {
        // Upload dengan gambar
        postId = await _firebaseService.uploadImageAndSavePost(
          imageFile: pickedImageFile!,
          userId: user.uid,
          userName: user.displayName ?? 'User',
          userAvatar:
              user.photoURL ??
              'https://api.dicebear.com/7.x/avataaars/svg?seed=${user.uid}',
          businessName: 'Toko Saya',
          content: newPostContent,
          category: newPostCategory,
          groupId: widget.group.id,
          groupName: widget.group.name,
          onProgress: (progress) {
            setState(() {
              uploadProgress = progress;
            });
          },
        );
      } else {
        // Upload tanpa gambar
        postId = await _firebaseService.savePost(
          userId: user.uid,
          userName: user.displayName ?? 'User',
          userAvatar:
              user.photoURL ??
              'https://api.dicebear.com/7.x/avataaars/svg?seed=${user.uid}',
          businessName: 'Toko Saya',
          content: newPostContent,
          category: newPostCategory,
          groupId: widget.group.id,
          groupName: widget.group.name,
        );
      }

      if (postId != null) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('Post berhasil dibuat! 🎉'),
          autoCloseDuration: const Duration(seconds: 2),
        );

        // Reset form
        setState(() {
          newPostContent = '';
          pickedImageFile = null;
          isCreatePostDialogOpen = false;
          isUploading = false;
          uploadProgress = 0.0;
        });
        _postController.clear();
      } else {
        throw Exception('Gagal menyimpan post');
      }
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text('Gagal membuat post: $e'),
        autoCloseDuration: const Duration(seconds: 3),
      );

      setState(() {
        isUploading = false;
        uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.group.name),
        actions: [
          IconButton(icon: const Icon(LucideIcons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(LucideIcons.moreVertical),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
            _buildGroupHeader(),

            const SizedBox(height: 16),

            // About Section
            _buildAboutSection(),

            const SizedBox(height: 16),

            // Posts Section
            _buildPostsSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            isCreatePostDialogOpen = true;
          });
        },
        backgroundColor: const Color(0xFF5D4037),
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      bottomSheet: isCreatePostDialogOpen ? _buildCreatePostDialog() : null,
    );
  }

  Widget _buildGroupHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Group Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.group.image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(LucideIcons.users, size: 32),
                    );
                  },
                ),
              ),

              const SizedBox(width: 16),

              // Group Info
              Expanded(
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
                        const Icon(
                          LucideIcons.users,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.group.members} anggota',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          LucideIcons.fileText,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.group.posts} post',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Join/Joined Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isJoined ? null : handleJoinGroupClick,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isJoined
                    ? const Color(0xFFE5E7EB)
                    : const Color(0xFF5D4037),
                foregroundColor: widget.isJoined
                    ? const Color(0xFF6B7280)
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isJoined ? LucideIcons.check : LucideIcons.plus,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(widget.isJoined ? 'Sudah Bergabung' : 'Bergabung'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tentang Grup',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Komunitas untuk pelaku UMKM di bidang ${widget.group.name}. Mari berbagi tips, pengalaman, dan saling mendukung untuk berkembang bersama! 🚀',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Postingan Terbaru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...groupPosts.map((post) {
            return PostCard(
              post: post,
              onLike: () => widget.onLikePost(post.id),
              onComment: () => handleCommentClick(post),
              onShare: () => widget.onSharePost(post.id, post.author.name),
              onBookmark: () => widget.onBookmarkPost(post.id),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCreatePostDialog() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: isUploading
                      ? null
                      : () {
                          setState(() {
                            isCreatePostDialogOpen = false;
                            pickedImageFile = null;
                            newPostContent = '';
                            _postController.clear();
                          });
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
                  // Text Field
                  TextField(
                    controller: _postController,
                    maxLines: 5,
                    enabled: !isUploading,
                    decoration: const InputDecoration(
                      hintText: 'Apa yang ingin Anda bagikan?',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        newPostContent = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: newPostCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Tips Bisnis',
                        child: Text('Tips Bisnis'),
                      ),
                      DropdownMenuItem(
                        value: 'Pertanyaan',
                        child: Text('Pertanyaan'),
                      ),
                      DropdownMenuItem(
                        value: 'Pengalaman',
                        child: Text('Pengalaman'),
                      ),
                      DropdownMenuItem(
                        value: 'Promosi',
                        child: Text('Promosi'),
                      ),
                    ],
                    onChanged: isUploading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                newPostCategory = value;
                              });
                            }
                          },
                  ),

                  const SizedBox(height: 16),

                  // Image Upload Section
                  if (pickedImageFile == null)
                    GestureDetector(
                      onTap: isUploading ? null : _handlePickImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFD1D5DB),
                            width: 2,
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
                                style: TextStyle(color: Color(0xFF6B7280)),
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
                    )
                  else
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(
                                  pickedImageFile!.path,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(pickedImageFile!.path),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        if (!isUploading)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  pickedImageFile = null;
                                });
                              },
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
                    ),

                  // Upload Progress
                  if (isUploading && uploadProgress > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Uploading: ${(uploadProgress * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: uploadProgress),
                        ],
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (newPostContent.trim().isEmpty || isUploading)
                    ? null
                    : _handleCreatePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D4037),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirim Post', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
