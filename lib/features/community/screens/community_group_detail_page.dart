import 'dart:io';
import 'package:flutter/foundation.dart'; // Tambahan untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../models/group.dart';
import '../models/post.dart';
import '../services/firebase_storage_service.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_dialog.dart';

class CommunityGroupDetailPage extends StatefulWidget {
  final CommunityGroup group;

  const CommunityGroupDetailPage({
    super.key,
    required this.group,
  });

  @override
  State<CommunityGroupDetailPage> createState() =>
      _CommunityGroupDetailPageState();
}

class _CommunityGroupDetailPageState extends State<CommunityGroupDetailPage> {
  final FirebaseStorageService _firebaseService = FirebaseStorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool isJoined = false;

  @override
  void initState() {
    super.initState();
    isJoined = false; 
  }

  // --- ACTIONS ---

  void _handleJoinGroup() {
    setState(() {
      isJoined = !isJoined;
    });
    
    final msg = isJoined 
        ? 'Berhasil bergabung ke grup ${widget.group.name}'
        : 'Anda keluar dari grup ${widget.group.name}';
        
    toastification.show(
      context: context,
      type: isJoined ? ToastificationType.success : ToastificationType.info,
      title: Text(msg),
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _handleLike(Post post) {
    if (_auth.currentUser == null) {
      _showLoginError();
      return;
    }
    _firebaseService.toggleLike(post.id, post.isLiked);
  }

  void _handleComment(Post post) {
    if (_auth.currentUser == null) {
      _showLoginError();
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

  void _handleBookmark() {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      title: const Text('Post disimpan!'),
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _showLoginError() {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      title: const Text('Silakan login terlebih dahulu'),
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _showCreateGroupPostModal() {
    if (_auth.currentUser == null) {
      _showLoginError();
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupCreatePostSheet(
        firebaseService: _firebaseService,
        group: widget.group,
        currentUser: _auth.currentUser!,
        onSuccess: () {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text('Postingan grup berhasil dibuat!'),
            autoCloseDuration: const Duration(seconds: 2),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // 1. HEADER GRUP
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF5D4037),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.group.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                widget.group.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.share2, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          // 2. INFO GRUP & TOMBOL ACTIONS
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStatItem('Anggota', '${widget.group.members}'),
                      _buildDivider(),
                      _buildStatItem('Postingan', '${widget.group.posts}'),
                      _buildDivider(),
                      _buildStatItem('Kategori', 'Bisnis'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleJoinGroup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isJoined 
                                ? Colors.grey[200] 
                                : const Color(0xFF5D4037),
                            foregroundColor: isJoined 
                                ? Colors.black87 
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(isJoined ? 'Telah Bergabung' : 'Gabung Grup'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showCreateGroupPostModal,
                          icon: const Icon(LucideIcons.penTool, size: 16),
                          label: const Text('Buat Post'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5D4037),
                            side: const BorderSide(color: Color(0xFF5D4037)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. TITLE FEED
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Diskusi Grup",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // 4. LIST POSTINGAN (FILTERED BY GROUP ID)
          StreamBuilder<List<Post>>(
            stream: _firebaseService.getPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(child: Text("Error: ${snapshot.error}"));
              }

              final allPosts = snapshot.data ?? [];
              
              // Filter postingan hanya untuk grup ini
              final groupPosts = allPosts.where((p) => p.groupId == widget.group.id).toList();

              if (groupPosts.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.messagesSquare, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("Belum ada diskusi di grup ini.", style: TextStyle(color: Colors.grey)),
                        Text("Jadilah yang pertama memposting!", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = groupPosts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: PostCard(
                        post: post,
                        onLike: () => _handleLike(post),
                        onComment: () => _handleComment(post),
                        onShare: () => _handleShare(post.author.name),
                        onBookmark: _handleBookmark,
                      ),
                    );
                  },
                  childCount: groupPosts.length,
                ),
              );
            },
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey[300],
    );
  }
}

// =========================================================
// WIDGET KHUSUS UNTUK MEMBUAT POSTINGAN DI DALAM GRUP
// =========================================================

class GroupCreatePostSheet extends StatefulWidget {
  final FirebaseStorageService firebaseService;
  final CommunityGroup group;
  final User currentUser;
  final VoidCallback onSuccess;

  const GroupCreatePostSheet({
    super.key,
    required this.firebaseService,
    required this.group,
    required this.currentUser,
    required this.onSuccess,
  });

  @override
  State<GroupCreatePostSheet> createState() => _GroupCreatePostSheetState();
}

class _GroupCreatePostSheetState extends State<GroupCreatePostSheet> {
  final TextEditingController _contentController = TextEditingController();
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imageFile = image);
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) return;
    
    setState(() => _isUploading = true);

    // ERROR FIX HERE:
    // Kirim _imageFile langsung (XFile?), jangan dibungkus File().
    // Service kita sudah diupdate untuk menerima XFile? agar kompatibel Web & Mobile.
    await widget.firebaseService.uploadImageAndSavePost(
      imageFile: _imageFile, 
      userId: widget.currentUser.uid,
      userName: widget.currentUser.displayName ?? 'Pengguna',
      userAvatar: widget.currentUser.photoURL ?? '',
      businessName: 'UMKM Member',
      content: _contentController.text,
      category: 'Grup', 
      groupId: widget.group.id,   
      groupName: widget.group.name,
      onProgress: (val) {},
    );

    widget.onSuccess();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Post di ${widget.group.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _contentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Bagikan sesuatu ke grup ini...',
                      border: InputBorder.none,
                    ),
                  ),
                  
                  // PREVIEW IMAGE (WEB & MOBILE COMPATIBLE)
                  if (_imageFile != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(
                                  _imageFile!.path,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_imageFile!.path),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          right: 8, top: 8,
                          child: InkWell(
                            onTap: () => setState(() => _imageFile = null),
                            child: const CircleAvatar(
                              backgroundColor: Colors.red, radius: 12, 
                              child: Icon(LucideIcons.x, size: 14, color: Colors.white)
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton(onPressed: _pickImage, icon: const Icon(LucideIcons.image, color: Colors.green)),
              const Spacer(),
              ElevatedButton(
                onPressed: _isUploading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037)),
                child: _isUploading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
                  : const Text("Posting", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}