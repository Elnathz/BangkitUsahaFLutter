import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';

import '../../models/group.dart';
import '../community_group_detail_page.dart';
import '../../services/firebase_storage_service.dart'; // Import Service

class CommunityGroupsTab extends StatefulWidget {
  final VoidCallback onShowCreateGroup;

  const CommunityGroupsTab({
    super.key,
    required this.onShowCreateGroup,
  });

  @override
  State<CommunityGroupsTab> createState() => CommunityGroupsTabState();
}

class CommunityGroupsTabState extends State<CommunityGroupsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('groups')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final docs = snapshot.data?.docs ?? [];

        final groups = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return CommunityGroup(
            id: doc.id,
            name: data['name'] ?? 'Tanpa Nama',
            members: data['members'] ?? 0,
            posts: data['posts'] ?? 0,
            image: data['image'] ?? 'https://via.placeholder.com/150',
          );
        }).toList();

        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.users, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text("Belum ada grup. Buat sekarang!",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: widget.onShowCreateGroup,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D4037)),
                  child: const Text("Buat Grup Baru",
                      style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: groups.length + 1, // +1 untuk Header Row
          itemBuilder: (context, index) {
            if (index == 0) {
              // Header Row
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '👥 Grup Populer',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: widget.onShowCreateGroup,
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Buat Grup'),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF5D4037)),
                    ),
                  ],
                ),
              );
            }

            final group = groups[index - 1];
            // Menggunakan Widget Terpisah agar setiap item bisa cek status join sendiri
            return GroupListItem(group: group);
          },
        );
      },
    );
  }
}

// --- WIDGET ITEM GRUP PINTAR (Smart List Item) ---
class GroupListItem extends StatefulWidget {
  final CommunityGroup group;

  const GroupListItem({super.key, required this.group});

  @override
  State<GroupListItem> createState() => _GroupListItemState();
}

class _GroupListItemState extends State<GroupListItem> {
  final FirebaseStorageService _service = FirebaseStorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool isJoined = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      final status = await _service.hasJoinedGroup(widget.group.id, user.uid);
      if (mounted) {
        setState(() {
          isJoined = status;
          isLoading = false;
        });
      }
    }
  }

  void _handleJoin() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);
    
    // Panggil Service Join
    await _service.joinGroup(widget.group.id, user.uid);

    if (mounted) {
      setState(() {
        isJoined = true;
        isLoading = false;
      });
      
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Berhasil bergabung!'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            widget.group.image,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) =>
                Container(width: 50, height: 50, color: Colors.grey[300]),
          ),
        ),
        title: Text(widget.group.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${widget.group.members} anggota • ${widget.group.posts} postingan'),
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : isJoined
                ? const Icon(LucideIcons.checkCircle, color: Colors.green)
                : OutlinedButton(
                    onPressed: _handleJoin,
                    child: const Text('Gabung'),
                  ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CommunityGroupDetailPage(group: widget.group)),
          ).then((_) {
            // Refresh status saat kembali dari detail page
            _checkStatus();
          });
        },
      ),
    );
  }
}