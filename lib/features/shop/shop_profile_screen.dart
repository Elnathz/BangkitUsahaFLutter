import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../home/product_detail_screen.dart'; // Agar bisa klik produk di etalase toko
import '../chat/chat_detail_screen.dart'; // Agar bisa chat penjual

class ShopProfileScreen extends StatefulWidget {
  final String shopId; // UID Penjual

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // DefaultTabController untuk mengatur Tab Produk & Ulasan
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
                        Tab(text: "Ulasan"),
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

  // --- 1. HEADER TOKO (FOTO, NAMA, RATING, CHAT) ---
  Widget _buildShopHeader(Color primaryColor) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.shopId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container(color: primaryColor);

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return Container(color: primaryColor);

        String name = data['storeName'] ?? "Toko";
        String image = data['image'] ?? "";
        double rating = (data['rating'] ?? 0).toDouble();
        int totalReviews = data['totalReviews'] ?? 0;
        int totalSales = data['totalSales'] ?? 0;
        String joinedDate = "";
        if (data['createdAt'] != null) {
          // Jika ada data tanggal gabung
          // joinedDate = ...
        }

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
                  // FOTO PROFIL
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

                  // INFO TOKO
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
                              "|  $totalReviews Ulasan",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Online 10 menit lalu",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // TOMBOL CHAT
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
              const SizedBox(height: 20),

              // STATISTIK KECIL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    "Produk",
                    "Memuat...",
                  ), // Nanti diisi stream count
                  Container(height: 20, width: 1, color: Colors.white24),
                  _buildStatItem("Penilaian", "$rating"),
                  Container(height: 20, width: 1, color: Colors.white24),
                  _buildStatItem("Performa Chat", "98%"),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  // --- 2. TAB PRODUK (GRID) ---
  Widget _buildProductGrid(
    Color cardColor,
    Color textColor,
    Color primaryColor,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('uid', isEqualTo: widget.shopId) // Ambil produk toko ini saja
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final products = snapshot.data!.docs;

        if (products.isEmpty) {
          return Center(
            child: Text(
              "Toko ini belum memiliki produk.",
              style: TextStyle(color: Colors.grey[500]),
            ),
          );
        }

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
            final id = products[index].id;

            // Reuse Card Design
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailScreen(productData: data, productId: id),
                  ),
                );
              },
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

  // --- 3. TAB ULASAN TOKO (LIST) ---
  Widget _buildReviewList(Color cardColor, Color textColor, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      // Ambil review yang ditujukan untuk SHOP ID ini
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('shopId', isEqualTo: widget.shopId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Perlu Index Database (shopId + createdAt)",
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final reviews = snapshot.data!.docs;
        if (reviews.isEmpty) {
          return Center(
            child: Text(
              "Belum ada ulasan untuk toko ini.",
              style: TextStyle(color: Colors.grey[500]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final data = reviews[index].data() as Map<String, dynamic>;
            String dateStr = "";
            if (data['createdAt'] != null) {
              dateStr = DateFormat(
                'dd MMM yyyy',
              ).format((data['createdAt'] as Timestamp).toDate());
            }

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
                            (data['userImage'] != null &&
                                data['userImage'] != "")
                            ? NetworkImage(data['userImage'])
                            : null,
                        child:
                            (data['userImage'] == null ||
                                data['userImage'] == "")
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
