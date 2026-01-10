import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'chat_detail_screen.dart';
import 'search_user_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Pesan",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [],
      ),

      // TOMBOL HIJAU DI BAWAH (FAB)
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

      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                hintText: "Cari chat...",
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // CHAT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                // 2. Error
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
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
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // 4. List Chat
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final chatRoom = snapshot.data!.docs[index];
                    final data = chatRoom.data() as Map<String, dynamic>;

                    // Cari ID Lawan Bicara
                    final List participants = data['participants'] ?? [];
                    final String partnerId = participants.firstWhere(
                      (id) => id != currentUser?.uid,
                      orElse: () => '',
                    );

                    if (partnerId.isEmpty) return const SizedBox();

                    // Panggil Widget Tile Khusus (Supaya kodingan rapi)
                    return _ChatListTile(
                      partnerId: partnerId,
                      lastMessage: data['last_message'] ?? '',
                      lastTime: data['last_message_time'] as Timestamp?,
                      unreadCount: data['unread_count_${currentUser?.uid}'] ?? 0,
                      searchQuery: _searchQuery,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET TILE: MENGAMBIL DATA USER (NAMA & FOTO) ---
class _ChatListTile extends StatelessWidget {
  final String partnerId;
  final String lastMessage;
  final Timestamp? lastTime;
  final int unreadCount;
  final String searchQuery;

  const _ChatListTile({
    required this.partnerId,
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
    this.searchQuery = "",
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      // Kita pakai StreamBuilder untuk User juga, biar kalau dia ganti foto profil
      // di HP kita langsung berubah realtime.
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(partnerId)
          .snapshots(),
      builder: (context, snapshot) {
        String name = "Pengguna";
        String image = "";

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          // Cek berbagai kemungkinan nama field di database
          name = userData['storeName'] ?? userData['name'] ?? "Pengguna";
          // Cek berbagai kemungkinan nama field gambar
          image = userData['imageUrl'] ?? userData['image'] ?? "";
        }

        // FILTER: Hide if name doesn't match search query
        if (searchQuery.isNotEmpty &&
            !name.toLowerCase().contains(searchQuery)) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(
                      targetUid: partnerId,
                      targetName: name,
                      targetImage: image,
                    ),
                  ),
                );
              },
              // FOTO PROFIL + ONLINE INDICATOR
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        (image.isNotEmpty) ? NetworkImage(image) : null,
                    child: (image.isEmpty)
                        ? const Icon(LucideIcons.user, color: Colors.grey)
                        : null,
                  ),
                  // Green Dot Indicator
                  Positioned(
                    right: 0,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366), // Green for Online
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // NAMA USER & WAKTU
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (lastTime != null)
                    Text(
                      _formatWhatsAppTime(lastTime!.toDate()),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: unreadCount > 0
                            ? Colors.blue // Blue for active
                            : Colors.grey,
                        fontWeight: unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              // PESAN TERAKHIR & BADGE UNREAD
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: unreadCount > 0
                              ? Colors.black87
                              : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: unreadCount > 0
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          color: Colors.blue, // Blue Badge
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount.toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, indent: 72), // Divider with indentation
          ],
        );
      },
    );
  }

  // Helper Format Waktu
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
