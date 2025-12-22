import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'chat_detail_screen.dart';
import 'search_user_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // FITUR: TOMBOL BACK KIRI ATAS
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pesan",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        // FITUR: SEARCH DI ATAS DIHAPUS (Kosongkan actions)
        actions: [],
      ),

      // TOMBOL HIJAU DI BAWAH (FAB) UNTUK CARI KONTAK/CHAT BARU
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchUserScreen()),
          );
        },
        backgroundColor: const Color(0xFF25D366), // Hijau WA
        child: const Icon(LucideIcons.messageSquare, color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        // QUERY INI MEMBUTUHKAN INDEX DI FIREBASE CONSOLE
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('participants', arrayContains: currentUser?.uid)
            .orderBy('last_message_time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. CEK ERROR (BIASANYA KARENA INDEX BELUM DIBUAT)
          if (snapshot.hasError) {
            // Cetak link error ke console agar bisa diklik
            debugPrint("⚠️ ERROR FIREBASE: ${snapshot.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Chat tidak muncul karena Index belum dibuat.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Lihat 'Debug Console' di VS Code, cari link yang dimulai dengan 'https://console.firebase...', lalu klik link tersebut untuk membuat Index secara otomatis.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Kosong
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.messageSquare,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada percakapan",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Ketuk tombol hijau di bawah untuk mulai chat",
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          // 4. Ada Data (List Chat)
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final chatRoom = snapshot.data!.docs[index];
              final data = chatRoom.data() as Map<String, dynamic>;

              final List participants = data['participants'] ?? [];
              final String otherUid = participants.firstWhere(
                (id) => id != currentUser?.uid,
                orElse: () => 'unknown',
              );

              // Ambil Data User Lawan Bicara
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUid)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox();

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;

                  // Handle Nama & Foto
                  final String name =
                      userData?['ownerName'] ?? userData?['name'] ?? 'Pengguna';
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

                  final lastMessage = data['last_message'] ?? '';
                  final timestamp =
                      (data['last_message_time'] as Timestamp?)?.toDate() ??
                      DateTime.now();
                  final int unreadCount =
                      data['unread_count_${currentUser?.uid}'] ?? 0;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
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
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(avatarUrl),
                      backgroundColor: Colors.grey[200],
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unreadCount > 0
                              ? Colors.black87
                              : Colors.grey[600],
                          fontWeight: unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatWhatsAppTime(timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: unreadCount > 0
                                ? const Color(0xFF25D366)
                                : Colors.grey,
                            fontWeight: unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
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

  String _formatWhatsAppTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (dateToCheck == today) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (dateToCheck == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('dd/MM/yy').format(timestamp);
    }
  }
}
