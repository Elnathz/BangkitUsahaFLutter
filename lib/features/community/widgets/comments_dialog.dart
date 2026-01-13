import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk Timestamp
import 'package:lucide_icons/lucide_icons.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/firebase_storage_service.dart';

class CommentsDialog extends StatefulWidget {
  final Post post;

  const CommentsDialog({
    Key? key,
    required this.post,
    // Parameter lain tidak diperlukan lagi karena kita fetch sendiri di sini
    // required this.comments,
    // required this.onAddComment,
  }) : super(key: key);

  @override
  State<CommentsDialog> createState() => _CommentsDialogState();
}

class _CommentsDialogState extends State<CommentsDialog> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseStorageService _firebaseService = FirebaseStorageService();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    // Kirim ke Firebase
    await _firebaseService.addComment(widget.post.id, content);

    _commentController.clear();
    setState(() => _isSending = false);

    // Tutup keyboard
    FocusScope.of(context).unfocus();
  }

  // Helper untuk format waktu komentar
  String _formatTimestamp(String timestampStr) {
    // Karena model Comment kita string, tapi di fromMap kita olah.
    // Jika masih raw timestamp, logic-nya ada di Model.
    // Di sini kita anggap Model sudah memberikan string yang "human readable"
    // atau kita biarkan apa adanya.
    return timestampStr;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header Dialog
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Komentar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List Komentar (StreamBuilder)
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _firebaseService.getComments(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.messageSquare,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada komentar',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage:
                                (comment.avatar != null &&
                                    comment.avatar!.isNotEmpty)
                                ? NetworkImage(comment.avatar!)
                                : null,
                            child:
                                (comment.avatar == null ||
                                    comment.avatar!.isEmpty)
                                ? const Icon(
                                    LucideIcons.user,
                                    size: 18,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment.author,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      comment.timestamp,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.content,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
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

          const Divider(height: 1),

          // Input Field
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _sendComment,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.send, color: Color(0xFF1565C0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
