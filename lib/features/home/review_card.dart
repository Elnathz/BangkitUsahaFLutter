import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// removed unused import 'package:lucide_icons/lucide_icons.dart'

class ReviewCard extends StatelessWidget {
  final String productId; // Wajib ada agar bisa update rating saat dihapus
  final String reviewId;
  final Map<String, dynamic> data;
  final String currentUserId;
  final bool isProductOwner;

  const ReviewCard({
    super.key,
    required this.productId, // Pastikan ini ada
    required this.reviewId,
    required this.data,
    required this.currentUserId,
    required this.isProductOwner,
  });

  // --- LOGIC HAPUS ULASAN (ROOT COLLECTION) ---
  void _deleteReview(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Ulasan?"),
        content: const Text("Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // 1. Hapus dokumen dari Root Collection 'reviews'
                await FirebaseFirestore.instance
                    .collection('reviews')
                    .doc(reviewId)
                    .delete();

                // 2. Hitung ulang rating produk (Penting!)
                await _recalculateProductRating(productId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ulasan berhasil dihapus")),
                  );
                }
              } catch (e) {
                debugPrint("Gagal hapus: $e");
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- LOGIC HITUNG ULANG RATING ---
  Future<void> _recalculateProductRating(String pid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('productId', isEqualTo: pid)
        .get();

    if (snapshot.docs.isEmpty) {
      // Jika ulasan habis, reset ke 0
      await FirebaseFirestore.instance.collection('products').doc(pid).update({
        'rating': 0.0,
        'totalReviews': 0,
      });
      return;
    }

    double totalStars = 0;
    for (var doc in snapshot.docs) {
      totalStars += (doc['rating'] as num).toDouble();
    }
    double avg = totalStars / snapshot.docs.length;

    await FirebaseFirestore.instance.collection('products').doc(pid).update({
      'rating': double.parse(avg.toStringAsFixed(1)),
      'totalReviews': snapshot.docs.length,
    });
  }

  // --- LOGIC EDIT ULASAN ---
  void _editReview(BuildContext context) {
    final editController = TextEditingController(text: data['comment']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Ulasan"),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('reviews') // Root Collection
                    .doc(reviewId)
                    .update({'comment': editController.text.trim()});
                Navigator.pop(ctx);
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // --- LOGIC BALAS ULASAN ---
  void _replyReview(BuildContext context) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Balas Ulasan"),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(hintText: "Tulis balasan..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.trim().isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .get();
                final userData = userDoc.data() as Map<String, dynamic>;

                await FirebaseFirestore.instance
                    .collection('reviews')
                    .doc(reviewId)
                    .collection('replies') // Sub-collection replies
                    .add({
                      'uid': user.uid,
                      'name':
                          userData['ownerName'] ?? userData['name'] ?? "User",
                      'image': userData['imageUrl'] ?? userData['image'] ?? "",
                      'text': replyController.text.trim(),
                      'timestamp': FieldValue.serverTimestamp(),
                      'isSeller': isProductOwner,
                    });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Kirim"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic Cek Kepemilikan (Support field 'userId' maupun 'uid')
    final bool isMyReview =
        (data['userId'] == currentUserId) || (data['uid'] == currentUserId);

    final timestamp =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage:
                      (data['userImage'] != null && data['userImage'] != "")
                      ? NetworkImage(data['userImage'])
                      : null,
                  child: (data['userImage'] == null || data['userImage'] == "")
                      ? const Icon(Icons.person, size: 12)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userName'] ?? "Anonim",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < (data['rating'] ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 12,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yy').format(timestamp),
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),

                // --- MENU TITIK TIGA (Hanya Muncul Jika Review Milik Sendiri) ---
                if (isMyReview)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 16),
                    onSelected: (v) => v == 'edit'
                        ? _editReview(context)
                        : _deleteReview(context),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text("Edit")),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          "Hapus",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(data['comment'] ?? "", style: const TextStyle(fontSize: 13)),

            // TOMBOL BALAS
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _replyReview(context),
              child: Text(
                "Balas",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // LIST BALASAN (Replies)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .doc(reviewId)
                  .collection('replies')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const SizedBox();
                return Container(
                  margin: const EdgeInsets.only(top: 8, left: 12),
                  padding: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey[300]!, width: 2),
                    ),
                  ),
                  child: Column(
                    children: snapshot.data!.docs.map((doc) {
                      final r = doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text(
                              "${r['name']}: ",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            if (r['isSeller'] == true)
                              Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                color: Colors.orange[100],
                                child: const Text(
                                  "Penjual",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                r['text'],
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
