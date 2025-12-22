import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- IMPORT BARU ---
import '../../services/market_service.dart'; // Import Service Logic
// -------------------

import '../chat/chat_detail_screen.dart';
import 'product_reviews_screen.dart';
import '../shop/shop_profile_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> initialData;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required Map<String, dynamic> productData,
    required this.productId,
  }) : initialData = productData;

  Map<String, dynamic> get productData => initialData;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> data;
        if (snapshot.hasData && snapshot.data!.exists) {
          data = snapshot.data!.data() as Map<String, dynamic>;
        } else {
          data = initialData;
        }
        return _buildContent(context, data);
      },
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> productData) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Ambil UID Pemilik Toko
    String ownerUid = productData['uid'] ?? "";

    num rawPrice = productData['price'] ?? 0;
    int price = rawPrice.toInt();
    double rating = (productData['rating'] ?? 0).toDouble();
    int totalReviews = productData['totalReviews'] ?? 0;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. GAMBAR PRODUK
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 350,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        image:
                            (productData['image'] != null &&
                                productData['image'] != "")
                            ? DecorationImage(
                                image: NetworkImage(productData['image']),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {},
                              )
                            : null,
                      ),
                      child:
                          (productData['image'] == null ||
                              productData['image'] == "")
                          ? Icon(
                              LucideIcons.image,
                              size: 64,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                    Positioned(
                      top: 40,
                      left: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black26,
                        child: IconButton(
                          icon: const Icon(
                            LucideIcons.arrowLeft,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),

                // 2. INFO HARGA & RATING
                Container(
                  color: cardColor,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyFormat.format(price),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        productData['name'] ?? "Tanpa Nama",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.star,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$rating",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text("|", style: TextStyle(color: Colors.grey[400])),
                          const SizedBox(width: 8),
                          Text(
                            "($totalReviews Ulasan)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text("|", style: TextStyle(color: Colors.grey[400])),
                          const SizedBox(width: 8),
                          Text(
                            "Stok: ${productData['stock'] ?? 0}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. INFO TOKO
                FutureBuilder<DocumentSnapshot>(
                  future: ownerUid.isNotEmpty
                      ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(ownerUid)
                            .get()
                      : null,
                  builder: (context, snapshot) {
                    String shopName = "Memuat...";
                    String? shopImage;
                    bool isOnline = false;

                    if (ownerUid.isEmpty) {
                      shopName = "Info Toko Tidak Tersedia";
                    } else if (snapshot.connectionState ==
                        ConnectionState.done) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        if (data != null) {
                          shopName = data['storeName'] ?? "Toko Mitra";
                          shopImage = data['image'];
                          isOnline = true;
                        }
                      } else {
                        shopName = "Toko Tidak Dikenal";
                      }
                    }

                    return Container(
                      color: cardColor,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage:
                                (shopImage != null && shopImage != "")
                                ? NetworkImage(shopImage!)
                                : null,
                            backgroundColor: Colors.grey[200],
                            child: (shopImage == null || shopImage == "")
                                ? Text(
                                    shopName.isNotEmpty &&
                                            shopName != "Memuat..."
                                        ? shopName[0]
                                        : "?",
                                    style: TextStyle(color: primaryColor),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shopName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  isOnline
                                      ? "Aktif"
                                      : (ownerUid.isEmpty ? "-" : "..."),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOnline
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              if (ownerUid.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ShopProfileScreen(shopId: ownerUid),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Data toko tidak tersedia untuk produk ini",
                                    ),
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryColor),
                              foregroundColor: primaryColor,
                            ),
                            child: const Text("Kunjungi"),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // 4. DESKRIPSI
                Container(
                  color: cardColor,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Deskripsi Produk",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        productData['description'] ?? "Tidak ada deskripsi.",
                        style: TextStyle(
                          height: 1.5,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. ULASAN
                Container(
                  color: cardColor,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Penilaian Produk",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductReviewsScreen(
                                    productId: productId,
                                    productData: productData,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              "Lihat Semua",
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reviews')
                            .where('productId', isEqualTo: productId)
                            .orderBy('createdAt', descending: true)
                            .limit(2)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Text(
                              "Belum ada ulasan.",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }
                          return Column(
                            children: snapshot.data!.docs.map<Widget>((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return _buildReviewItem(
                                data['userName'] ?? "User",
                                data['comment'] ?? "",
                                (data['rating'] as num).toInt(),
                                isDark,
                                textColor,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- BOTTOM BAR (DIPERBARUI) ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // TOMBOL CHAT (TETAP)
                  IconButton(
                    icon: Column(
                      children: [
                        Icon(
                          LucideIcons.messageCircle,
                          size: 20,
                          color: primaryColor,
                        ),
                        const Text("Chat", style: TextStyle(fontSize: 9)),
                      ],
                    ),
                    onPressed: () async {
                      if (ownerUid.isEmpty) return;
                      String targetName = "Toko";
                      try {
                        final userSnap = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(ownerUid)
                            .get();
                        if (userSnap.exists)
                          targetName =
                              (userSnap.data() as Map)['storeName'] ?? "Toko";
                      } catch (e) {
                        /* ignore */
                      }
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              // HAPUS 'widget.' DI SINI
                              targetUid: productData['uid'],

                              // HAPUS 'widget.' DI SINI JUGA
                              targetName: productData['ownerName'] ?? 'Penjual',

                              // DAN DI SINI
                              targetImage:
                                  (productData['ownerImage'] != null &&
                                      productData['ownerImage'] != '')
                                  ? productData['ownerImage']
                                  : 'https://via.placeholder.com/150',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 16),

                  // TOMBOL KERANJANG (DIBERIKAN FUNGSI)
                  InkWell(
                    onTap: () async {
                      try {
                        await MarketService().addToCart(
                          productId,
                          productData['name'] ?? "Produk",
                          price,
                          productData['image'] ?? "",
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Berhasil masuk keranjang!"),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.shoppingCart,
                          size: 20,
                          color: primaryColor,
                        ),
                        const Text("Keranjang", style: TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // TOMBOL BELI SEKARANG (DIBERIKAN FUNGSI)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Tampilkan Dialog Konfirmasi
                        _showBuyDialog(
                          context,
                          productData['name'] ?? "Produk",
                          price,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Beli Sekarang",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER UNTUK DIALOG BELI ---
  void _showBuyDialog(BuildContext context, String productName, int price) {
    // Format rupiah helper
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Pembelian"),
        content: Text(
          "Apakah Anda yakin ingin membeli '$productName' seharga ${currency.format(price)}?",
        ),
        actions: [
          TextButton(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Bayar"),
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog

              // PANGGIL SERVICE TRANSAKSI
              String result = await MarketService().processPayment(
                productId,
                1,
              );

              if (result == "SUCCESS") {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text("Pembelian Berhasil! Barang akan dikirim."),
                  ),
                );
                // Opsional: Kembali ke halaman sebelumnya
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text("Gagal: $result"),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(
    String name,
    String comment,
    int stars,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey[300],
                child: Text(name[0], style: const TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 8),
              Text(name, style: TextStyle(fontSize: 12, color: textColor)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                LucideIcons.star,
                size: 12,
                color: index < stars ? Colors.orange : Colors.grey[300],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            comment,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
