import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

// Pastikan import ChatDetailScreen benar
import '../chat/chat_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Notifikasi",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Ambil chat room dimana user terlibat
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('participants', arrayContains: currentUser?.uid)
            .orderBy('last_message_time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          // FILTER MANUAL: Hanya ambil yang unread_count_SAYA > 0
          final unreadChats = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final int myUnread = data['unread_count_${currentUser?.uid}'] ?? 0;
            return myUnread > 0;
          }).toList();

          if (unreadChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.bellOff, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "Tidak ada notifikasi baru",
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: unreadChats.length,
            itemBuilder: (context, index) {
              final chatRoom = unreadChats[index];
              final data = chatRoom.data() as Map<String, dynamic>;

              // Cari ID lawan bicara
              final List participants = data['participants'] ?? [];
              final String otherUid = participants.firstWhere(
                (id) => id != currentUser?.uid,
                orElse: () => 'unknown',
              );

              final lastMessage = data['last_message'] ?? 'Pesan baru';
              final timestamp = (data['last_message_time'] as Timestamp)
                  .toDate();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUid)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox();

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  final String name =
                      userData?['ownerName'] ?? userData?['name'] ?? 'Pengguna';

                  // Setup Gambar
                  String avatarUrl = 'https://via.placeholder.com/150';
                  if (userData != null) {
                    if (userData['imageUrl'] != null &&
                        userData['imageUrl'] != '') {
                      avatarUrl = userData['imageUrl'];
                    } else if (userData['image'] != null &&
                        userData['image'] != '') {
                      avatarUrl = userData['image'];
                    }
                  }

                  return Container(
                    color: Colors
                        .blue[50], // Highlight warna biru muda karena belum dibaca
                    child: ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(avatarUrl),
                          ),
                          const Positioned(
                            right: 0,
                            bottom: 0,
                            child: Icon(
                              LucideIcons.messageCircle,
                              size: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      title: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87),
                          children: [
                            const TextSpan(text: "Pesan baru dari "),
                            TextSpan(
                              text: name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ), // Sedikit tebal
                      ),
                      trailing: Text(
                        DateFormat('HH:mm').format(timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              targetUid: otherUid,
                              targetName: name,
                              targetImage: avatarUrl,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
