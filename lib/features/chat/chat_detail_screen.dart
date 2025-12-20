import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  final String targetUid;
  final String targetName;
  final String? targetImage;

  const ChatDetailScreen({
    super.key,
    required this.targetUid,
    required this.targetName,
    this.targetImage,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  late String chatId;

  @override
  void initState() {
    super.initState();
    // Membuat Chat ID unik gabungan UID (agar A->B dan B->A masuk room yang sama)
    final List<String> ids = [currentUser!.uid, widget.targetUid];
    ids.sort(); // Urutkan biar konsisten
    chatId = ids.join("_");
  }

  void _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty) return;

    final msg = _msgCtrl.text.trim();
    _msgCtrl.clear();

    final timestamp = FieldValue.serverTimestamp();

    // 1. Simpan Pesan di Sub-collection
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': currentUser!.uid,
          'text': msg,
          'createdAt': timestamp,
        });

    // 2. Update Metadata Chat (Untuk ditampilkan di List Chat Terluar)
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [currentUser!.uid, widget.targetUid],
      'lastMessage': msg,
      'lastTime': timestamp,
      // Kita simpan info user biar gampang load di list
      'users': {
        currentUser!.uid: true, // Marker participant
        widget.targetUid: true,
      },
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  (widget.targetImage != null && widget.targetImage != "")
                  ? NetworkImage(widget.targetImage!)
                  : null,
              backgroundColor: Colors.grey[300],
              child: (widget.targetImage == null || widget.targetImage == "")
                  ? const Icon(LucideIcons.user, size: 16, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.targetName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // DAFTAR PESAN
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      "Mulai percakapan dengan ${widget.targetName}",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true, // Pesan terbaru di bawah
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUser!.uid;

                    return _buildMessageBubble(
                      data['text'],
                      isMe,
                      data['createdAt'],
                      primaryColor,
                      isDark,
                    );
                  },
                );
              },
            ),
          ),

          // INPUT AREA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Tulis pesan...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    backgroundColor: primaryColor,
                    radius: 22,
                    child: const Icon(
                      LucideIcons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    String msg,
    bool isMe,
    Timestamp? timestamp,
    Color primaryColor,
    bool isDark,
  ) {
    // Format Jam
    String timeStr = "";
    if (timestamp != null) {
      timeStr = DateFormat('HH:mm').format(timestamp.toDate());
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe
              ? primaryColor
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.end, // Agar jam ada di kanan bawah bubble
          children: [
            Text(
              msg,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
