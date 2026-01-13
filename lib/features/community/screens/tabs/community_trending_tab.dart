import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/trending_topic.dart';
import '../community_topic_detail_page.dart';

class CommunityTrendingTab extends StatelessWidget {
  CommunityTrendingTab({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Mengambil data dari collection 'trending', diurutkan berdasarkan 'count' (terbanyak)
      stream: _firestore
          .collection('trending')
          .orderBy('count', descending: true)
          .limit(20) // Batasi 20 teratas
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.trendingUp, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  "Belum ada topik trending.\nAyo buat postingan dengan #hashtag!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '🔥 Trending Saat Ini',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final topic = TrendingTopic.fromFirestore(data, doc.id);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${docs.indexOf(doc) + 1}", // Ranking 1, 2, 3...
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  title: Text(
                    topic.title, // Contoh: #Bisnis
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${topic.posts} diskusi'),
                  trailing: const Icon(
                    LucideIcons.chevronRight,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    // Ketika diklik, arahkan ke halaman detail topic
                    // (Halaman ini akan menampilkan post yang mengandung hashtag tsb)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommunityTopicDetailPage(topic: topic),
                      ),
                    );
                  },
                ),
              );
            }).toList(),

            // Tambahan padding bawah agar tidak ketutup navbar/fab jika ada
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }
}
