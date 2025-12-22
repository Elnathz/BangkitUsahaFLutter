import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';

// --- IMPORT WIDGET REVIEW CARD YANG BARU ---
// (Sesuaikan path ini dengan lokasi Anda menyimpan review_card.dart)
import '../home/review_card.dart';
// ------------------------------------------

class ProductReviewsScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const ProductReviewsScreen({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // --- LOGIC: KIRIM ULASAN ---
  void _showAddReviewDialog() {
    final commentCtrl = TextEditingController();
    double rating = 5.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text("Tulis Ulasan Produk"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Berikan bintang untuk produk ini:"),
                  const SizedBox(height: 12),
                  // Input Bintang Manual
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () => setStateSB(() => rating = index + 1.0),
                        icon: Icon(
                          LucideIcons.star,
                          color: index < rating
                              ? Colors.orange
                              : Colors.grey[300],
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Bagaimana kualitas produk ini?",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (commentCtrl.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    await _submitReview(rating, commentCtrl.text);
                  },
                  child: const Text("Kirim"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitReview(double rating, String comment) async {
    try {
      final shopId = widget.productData['uid'];

      await FirebaseFirestore.instance.collection('reviews').add({
        'productId': widget.productId,
        'shopId': shopId,
        'userId': user!.uid,
        'userName': user!.displayName ?? "Pembeli",
        'userImage': user!.photoURL ?? "",
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update Rating PRODUK
      await _recalculateProductRating(widget.productId);

      if (mounted) {
        toastification.show(
          context: context,
          title: const Text("Ulasan produk berhasil dikirim!"),
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint("Error submit review: $e");
    }
  }

  Future<void> _recalculateProductRating(String productId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .get();
    if (snapshot.docs.isEmpty) return;

    double totalStars = 0;
    for (var doc in snapshot.docs) {
      totalStars += (doc['rating'] as num).toDouble();
    }
    double avg = totalStars / snapshot.docs.length;

    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .update({
          'rating': double.parse(avg.toStringAsFixed(1)),
          'totalReviews': snapshot.docs.length,
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final primaryColor = theme.primaryColor;

    // Cek apakah user yang login adalah pemilik produk (untuk fitur balasan)
    bool isProductOwner = widget.productData['uid'] == user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ulasan Produk",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('productId', isEqualTo: widget.productId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Perlu Index Database (Cek Console)",
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviews = snapshot.data!.docs;

          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.messageSquare,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada ulasan untuk produk ini.",
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            // ... di dalam ListView.builder ...
            itemBuilder: (context, index) {
              final doc = reviews[index];
              final data = doc.data() as Map<String, dynamic>;

              return ReviewCard(
                // --- TAMBAHKAN BARIS INI ---
                productId: widget.productId,

                // ---------------------------
                reviewId: doc.id,
                data: data,
                currentUserId: user?.uid ?? "",
                isProductOwner: isProductOwner,
              );
            },
            // ...
          );
        },
      ),
      // Tombol Tulis Ulasan (Hanya muncul jika BUKAN pemilik produk)
      floatingActionButton: !isProductOwner
          ? FloatingActionButton.extended(
              onPressed: _showAddReviewDialog,
              backgroundColor: primaryColor,
              icon: const Icon(LucideIcons.edit3, color: Colors.white),
              label: const Text(
                "Tulis Ulasan",
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
