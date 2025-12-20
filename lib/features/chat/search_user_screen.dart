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
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Cari Mitra / Toko",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Cari nama toko atau pemilik...",
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(LucideIcons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // LIST USER
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text("Terjadi kesalahan"));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uid = doc.id;

                  // Jangan tampilkan diri sendiri
                  if (uid == currentUser?.uid) return false;

                  // Filter Search
                  final storeName = (data['storeName'] ?? '')
                      .toString()
                      .toLowerCase();
                  final ownerName = (data['ownerName'] ?? '')
                      .toString()
                      .toLowerCase();
                  return storeName.contains(_searchQuery) ||
                      ownerName.contains(_searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      "Tidak ditemukan user.",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data() as Map<String, dynamic>;
                    final targetUid = users[index].id;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            (data['image'] != null && data['image'] != "")
                            ? NetworkImage(data['image'])
                            : null,
                        child: (data['image'] == null || data['image'] == "")
                            ? const Icon(LucideIcons.user, color: Colors.grey)
                            : null,
                      ),
                      title: Text(
                        data['storeName'] ?? "Toko Tanpa Nama",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        data['ownerName'] ?? "Pemilik",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Icon(
                        LucideIcons.messageCircle,
                        color: primaryColor,
                      ),
                      onTap: () {
                        // Buka Ruang Chat
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              targetUid: targetUid,
                              targetName: data['storeName'] ?? "Toko",
                              targetImage: data['image'],
                            ),
                          ),
                        );
                      },
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
