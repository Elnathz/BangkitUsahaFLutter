import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Untuk cek current user
import 'package:toastification/toastification.dart';
import '../models/post.dart';
import '../services/firebase_storage_service.dart'; // Import Service
import 'share_bottom_sheet.dart';
import 'full_screen_image_viewer.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onBookmark;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onBookmark,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final FirebaseStorageService _service = FirebaseStorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cek apakah user yang login adalah pemilik postingan
  bool get isOwner {
    final currentUser = _auth.currentUser;
    return currentUser != null && currentUser.uid == widget.post.userId;
  }

  // --- FUNGSI EDIT ---
  void _showEditDialog() {
    final TextEditingController editController = 
        TextEditingController(text: widget.post.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Postingan"),
        content: TextField(
          controller: editController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: "Ubah isi postingan...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.trim().isNotEmpty) {
                await _service.updatePost(widget.post.id, editController.text);
                if (mounted) {
                  Navigator.pop(context);
                  _showToast("Postingan berhasil diperbarui", ToastificationType.success);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI DELETE ---
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Postingan?"),
        content: const Text("Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              // Tutup Dialog Dulu
              Navigator.pop(context);
              
              // Eksekusi Hapus
              await _service.deletePost(widget.post.id, widget.post.groupId);
              
              if (mounted) {
                _showToast("Postingan dihapus", ToastificationType.info);
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showToast(String msg, ToastificationType type) {
    toastification.show(
      context: context,
      title: Text(msg),
      type: type,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ShareBottomSheet(postUrl: "https://bangkitbmkm.app/post/${widget.post.id}"),
    );
  }

  void _openImageViewer() {
    if (widget.post.image != null && widget.post.image!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenImageViewer(
            imageUrl: widget.post.image!,
            authorName: widget.post.author.name,
            likes: widget.post.likes,
            comments: widget.post.comments,
            shares: 0,
            isLiked: widget.post.isLiked,
            onLikeToggled: (bool isLiked) {
              // Trigger the post's like callback to update database
              widget.onLike();
            },
            onCommentTap: () {
              // Close viewer and open comment
              Navigator.pop(context);
              widget.onComment();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: User Info & Menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (widget.post.author.avatar != null && widget.post.author.avatar!.isNotEmpty)
                      ? NetworkImage(widget.post.author.avatar!)
                      : null,
                  child: (widget.post.author.avatar == null || widget.post.author.avatar!.isEmpty)
                      ? const Icon(LucideIcons.user, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // NAMA USER (Sesuai database)
                          Flexible(
                            child: Text(
                              widget.post.author.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.post.author.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                color: Colors.blue, size: 14),
                          ],
                        ],
                      ),
                      Text(
                        '${widget.post.author.businessName} • ${widget.post.timestamp}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // --- MENU TITIK TIGA (POPUP) ---
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreHorizontal, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'edit') _showEditDialog();
                    if (value == 'delete') _confirmDelete();
                    if (value == 'share') _showShareSheet();
                  },
                  itemBuilder: (context) {
                    return [
                      // Hanya tampilkan Edit/Hapus jika pemilik post
                      if (isOwner) 
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(LucideIcons.edit, size: 18, color: Colors.black87),
                              SizedBox(width: 8),
                              Text('Edit Postingan'),
                            ],
                          ),
                        ),
                      if (isOwner)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus Postingan', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      // Share selalu muncul
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(LucideIcons.share2, size: 18, color: Colors.black87),
                            SizedBox(width: 8),
                            Text('Bagikan'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),

          // Content Text
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                widget.post.content,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),

          // Content Image (Clickable)
          if (widget.post.image != null && widget.post.image!.isNotEmpty)
            GestureDetector(
              onTap: _openImageViewer,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 400),
                child: Image.network(
                  widget.post.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(LucideIcons.imageOff, color: Colors.grey)),
                  ),
                ),
              ),
            ),

          // Category Tag
          if (widget.post.category.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.post.category,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AnimatedLikeButton(
                  isLiked: widget.post.isLiked,
                  likeCount: widget.post.likes,
                  onTap: widget.onLike,
                ),
                _AnimatedIconButton(
                  icon: LucideIcons.messageCircle,
                  label: '${widget.post.comments} Komen',
                  onTap: widget.onComment,
                  activeColor: Colors.blue, // Comment active color
                ),
                _AnimatedIconButton(
                  icon: LucideIcons.share2,
                  label: 'Bagikan',
                  onTap: _showShareSheet,
                  activeColor: Colors.green, // Share active color
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap;

  const _AnimatedLikeButton({
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
  });

  @override
  State<_AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<_AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _AnimatedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked && !oldWidget.isLiked) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.onTap();
        // Always animate on tap for feedback
        _controller.forward(from: 0.0);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                widget.isLiked ? Icons.favorite : LucideIcons.heart,
                size: 20,
                color: widget.isLiked ? const Color(0xFFE91E63) : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${widget.likeCount} Suka',
              style: TextStyle(
                color: widget.isLiked ? const Color(0xFFE91E63) : Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Animated Button for Comment & Share
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color activeColor;

  const _AnimatedIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.activeColor,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _controller.forward(from: 0.0);
        widget.onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(widget.icon, size: 20, color: Colors.grey[600]),
            ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}