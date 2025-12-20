import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';

import '../home/product_detail_screen.dart';
import '../chat/chat_detail_screen.dart';

class ShopProfileScreen extends StatefulWidget {
  final String shopId;

  const ShopProfileScreen({super.key, required this.shopId});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen>
    with SingleTickerProviderStateMixin {
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final currentUser = FirebaseAuth.instance.currentUser;

  // --- LOGIC: TAMBAH ULASAN KHUSUS TOKO ---
  void _showAddShopReviewDialog() {
    if (currentUser == null) return;
    if (currentUser!.uid == widget.shopId) {
      toastification.show(
        context: context,
        title: const Text("Anda tidak bisa mereview toko sendiri"),
        type: ToastificationType.warning,
      );
      return;
    }

    final commentCtrl = TextEditingController();
    double rating = 5.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text("Tulis Ulasan Toko"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Bagaimana pelayanan toko ini?"),
                  const SizedBox(height: 12),
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
                      hintText: "Contoh: Pelayanan ramah, respon cepat...",
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
                    await _submitShopReview(rating, commentCtrl.text);
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

  Future<void> _submitShopReview(double rating, String comment) async {
    try {
      // Simpan Ulasan (ProductId KOSONG "" = Tanda ini Ulasan Toko)
      await FirebaseFirestore.instance.collection('reviews').add({
        'productId': "",
        'shopId': widget.shopId,
        'userId': currentUser!.uid,
        'userName': currentUser!.displayName ?? "Pembeli",
        'userImage': currentUser!.photoURL ?? "",
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Hitung Ulang Rating
      await _recalculateShopRating();

      if (mounted)
        toastification.show(
          context: context,
          title: const Text("Ulasan toko terkirim!"),
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 3),
        );
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // --- LOGIC HITUNG YANG DIPERBAIKI ---
  Future<void> _recalculateShopRating() async {
    try {
      // 1. Ambil HANYA review yang productId-nya KOSONG ("")
      // Ini memastikan ulasan produk TIDAK ikut terhitung
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('shopId', isEqualTo: widget.shopId)
          .where('productId', isEqualTo: "")
          .get();

      // Jika belum ada review toko sama sekali
      if (snapshot.docs.isEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.shopId)
            .update({'rating': 0.0, 'totalReviews': 0});
        return;
      }

      double totalStars = 0;
      for (var doc in snapshot.docs) {
        totalStars += (doc['rating'] as num).toDouble();
      }
      double avg = totalStars / snapshot.docs.length;

      // 2. Update Data Toko (User) dengan Rating Murni Toko
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.shopId)
          .update({
            'rating': double.parse(avg.toStringAsFixed(1)),
            'totalReviews': snapshot.docs.length,
          });
    } catch (e) {
      debugPrint("Gagal hitung rating toko (Mungkin butuh Index): $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddShopReviewDialog,
        backgroundColor: Colors.orange,
        icon: const Icon(LucideIcons.star, color: Colors.white),
        label: const Text(
          "Beri Nilai Toko",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                backgroundColor: primaryColor,
                leading: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildShopHeader(primaryColor),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: TabBar(
                      labelColor: primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: primaryColor,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: "Produk"),
                        Tab(text: "Semua Ulasan"),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildProductGrid(cardColor, textColor, primaryColor),
              _buildReviewList(cardColor, textColor, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopHeader(Color primaryColor) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.shopId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container(color: primaryColor);

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return Container(color: primaryColor);

        String name = data['storeName'] ?? "Toko";
        String image = data['image'] ?? "";
        // Ini Rating yang diambil dari DB (akan berubah setelah recalculate berjalan)
        double rating = (data['rating'] ?? 0).toDouble();
        int totalReviews = data['totalReviews'] ?? 0;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryColor, const Color(0xFF503C37)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: (image.isNotEmpty)
                          ? NetworkImage(image)
                          : null,
                      child: (image.isEmpty)
                          ? Text(
                              name[0],
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.star,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$rating / 5.0",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "|  $totalReviews Ulasan Toko",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Online",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            targetUid: widget.shopId,
                            targetName: name,
                            targetImage: image,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.messageCircle, size: 16),
                    label: const Text("Chat"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductGrid(
    Color cardColor,
    Color textColor,
    Color primaryColor,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('uid', isEqualTo: widget.shopId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final products = snapshot.data!.docs;
        if (products.isEmpty)
          return Center(
            child: Text(
              "Toko ini belum memiliki produk.",
              style: TextStyle(color: Colors.grey[500]),
            ),
          );

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final data = products[index].data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(
                    productData: data,
                    productId: products[index].id,
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          color: Colors.grey[300],
                          image: (data['image'] != null && data['image'] != "")
                              ? DecorationImage(
                                  image: NetworkImage(data['image']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? "",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(data['price'] ?? 0),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.star,
                                size: 10,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                "${data['rating'] ?? 0}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewList(Color cardColor, Color textColor, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      // Tampilkan SEMUA ulasan di sini (Campuran), tapi diberi Label
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('shopId', isEqualTo: widget.shopId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final reviews = snapshot.data!.docs;
        if (reviews.isEmpty)
          return Center(
            child: Text(
              "Belum ada ulasan.",
              style: TextStyle(color: Colors.grey[500]),
            ),
          );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final data = reviews[index].data() as Map<String, dynamic>;
            String dateStr = "";
            if (data['createdAt'] != null)
              dateStr = DateFormat(
                'dd MMM yyyy',
              ).format((data['createdAt'] as Timestamp).toDate());

            bool isShopReview =
                (data['productId'] == null || data['productId'] == "");

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            (data['userImage'] != "" &&
                                data['userImage'] != null)
                            ? NetworkImage(data['userImage'])
                            : null,
                        child:
                            (data['userImage'] == "" ||
                                data['userImage'] == null)
                            ? const Icon(
                                LucideIcons.user,
                                size: 16,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['userName'] ?? "Pembeli",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: textColor,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              "${data['rating']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.star,
                              size: 12,
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isShopReview
                          ? Colors.purple.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isShopReview ? "Ulasan Toko" : "Ulasan Produk",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isShopReview ? Colors.purple : Colors.blue,
                      ),
                    ),
                  ),

                  Text(
                    data['comment'] ?? "",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
