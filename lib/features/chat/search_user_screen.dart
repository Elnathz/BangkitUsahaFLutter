import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'chat_detail_screen.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final currentUser = FirebaseAuth.instance.currentUser;

  // Helper untuk membuat ID Chat Room yang konsisten (misal: "A_B" selalu urut abjad)
  String getChatRoomId(String user1, String user2) {
    if (user1.compareTo(user2) > 0) {
      return "${user2}_$user1";
    } else {
      return "${user1}_$user2";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        // TOMBOL BACK DI KIRI ATAS
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.black87),
          decoration: const InputDecoration(
            hintText: "Cari kontak...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val.toLowerCase();
            });
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          // 1. Filter User (Hapus diri sendiri & sesuaikan search)
          final users = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String name = (data['ownerName'] ?? data['name'] ?? '')
                .toString()
                .toLowerCase();
            final bool isSelf = doc.id == currentUser?.uid;
            final bool matchesSearch = name.contains(_searchQuery);

            return !isSelf && matchesSearch;
          }).toList();

          if (users.isEmpty) {
            return const Center(child: Text("Kontak tidak ditemukan"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final data = userDoc.data() as Map<String, dynamic>;

              final String name =
                  data['ownerName'] ?? data['name'] ?? 'Tanpa Nama';

              String avatarUrl = 'https://via.placeholder.com/150';
              if (data['imageUrl'] != null && data['imageUrl'] != '') {
                avatarUrl = data['imageUrl'];
              } else if (data['image'] != null && data['image'] != '') {
                avatarUrl = data['image'];
              }

              // ID Room unik untuk pasangan user ini
              final chatRoomId = getChatRoomId(currentUser!.uid, userDoc.id);

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(avatarUrl),
                  backgroundColor: Colors.grey[200],
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                // GANTI EMAIL DENGAN STATUS PESAN TERAKHIR
                subtitle: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chat_rooms')
                      .doc(chatRoomId)
                      .snapshots(),
                  builder: (context, chatSnapshot) {
                    if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
                      final chatData =
                          chatSnapshot.data!.data() as Map<String, dynamic>;
                      final lastMsg =
                          chatData['last_message'] ?? 'Belum ada pesan';
                      return Text(
                        lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600]),
                      );
                    } else {
                      return const Text(
                        "Belum ada pesan",
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                  },
                ),

                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        targetUid: userDoc.id,
                        targetName: name,
                        targetImage: avatarUrl,
                      ),
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
