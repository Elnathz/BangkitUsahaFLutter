import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Untuk cek current user
import 'package:toastification/toastification.dart';
import '../models/post.dart';
import '../services/firebase_storage_service.dart'; // Import Service

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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037)),
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
                    if (value == 'share') widget.onShare();
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

          // Content Image
          if (widget.post.image != null && widget.post.image!.isNotEmpty)
            Container(
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

          // Category Tag
          if (widget.post.category.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.brown[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.post.category,
                  style: TextStyle(
                    color: Colors.brown[700],
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
                _ActionButton(
                  icon: widget.post.isLiked ? Icons.favorite : LucideIcons.heart,
                  label: '${widget.post.likes} Suka',
                  color: widget.post.isLiked ? Colors.red : Colors.grey[600],
                  onTap: widget.onLike,
                ),
                _ActionButton(
                  icon: LucideIcons.messageCircle,
                  label: '${widget.post.comments} Komen',
                  onTap: widget.onComment,
                ),
                _ActionButton(
                  icon: LucideIcons.share2,
                  label: 'Bagikan',
                  onTap: widget.onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.grey[600],
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