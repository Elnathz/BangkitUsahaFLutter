import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  final String targetUid;
  final String targetName;
  final String targetImage;

  const ChatDetailScreen({
    super.key,
    required this.targetUid,
    required this.targetName,
    required this.targetImage,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  late String chatRoomId;

  @override
  void initState() {
    super.initState();
    // Generate ID Room yang konsisten
    chatRoomId = getChatRoomId(currentUser!.uid, widget.targetUid);

    // Reset Unread Count saat membuka chat
    resetUnreadCount();
  }

  String getChatRoomId(String user1, String user2) {
    if (user1.compareTo(user2) > 0) {
      return "${user2}_$user1";
    } else {
      return "${user1}_$user2";
    }
  }

  void resetUnreadCount() {
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .update({'unread_count_${currentUser!.uid}': 0})
        .catchError((e) {
          // Ignore error jika dokumen belum ada
        });
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String message = _messageController.text.trim();
    _messageController.clear();

    final timestamp = Timestamp.now();

    // 1. Simpan pesan ke sub-collection 'messages'
    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
          'senderId': currentUser!.uid,
          'text': message,
          'timestamp': timestamp,
          'isRead': false,
        });

    // 2. UPDATE/BUAT Dokumen 'chat_rooms' (Agar muncul di halaman depan)
    // Kita gunakan set(..., SetOptions(merge: true)) agar tidak menimpa data lain
    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .set({
          'participants': [currentUser!.uid, widget.targetUid],
          'last_message': message,
          'last_message_time': timestamp,
          // Increment unread count untuk lawan bicara
          'unread_count_${widget.targetUid}': FieldValue.increment(1),
          // Reset unread count untuk diri sendiri
          'unread_count_${currentUser!.uid}': 0,
        }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5), // Warna Background Chat WA
      appBar: AppBar(
        leadingWidth: 70,
        backgroundColor: const Color(0xFF075E54), // Hijau WA Gelap
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.arrowLeft, color: Colors.white),
              const SizedBox(width: 5),
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(widget.targetImage),
                backgroundColor: Colors.grey,
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.targetName,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // LIST PESAN
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Pesan baru di bawah
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUser!.uid;
                    final time = (data['timestamp'] as Timestamp).toDate();

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFFDCF8C6)
                              : Colors.white, // Hijau muda WA untuk user
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(10),
                            topRight: const Radius.circular(10),
                            bottomLeft: isMe
                                ? const Radius.circular(10)
                                : Radius.zero,
                            bottomRight: isMe
                                ? Radius.zero
                                : const Radius.circular(10),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              data['text'],
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm').format(time),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT FIELD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.transparent,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Ketik pesan...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF075E54),
                  child: IconButton(
                    icon: const Icon(
                      LucideIcons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
