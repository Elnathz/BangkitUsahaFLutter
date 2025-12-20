import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Untuk format Rupiah

// Import halaman notifikasi & chat (agar navigasi tetap jalan)
import '../notifications/notification_screen.dart';
import '../chat/chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Ambil user yang sedang login
  final user = FirebaseAuth.instance.currentUser;

  // Format Mata Uang
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

    final Color cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ============================================================
            // 1. HEADER + SEARCH BAR (STACK) - TETAP SAMA
            // ============================================================
            Stack(
              clipBehavior: Clip.none,
              children: [
                // BACKGROUND HEADER COKELAT
                Container(
                  height: 180,
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, const Color(0xFF503C37)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              image: const DecorationImage(
                                image: AssetImage(
                                  'assets/images/bangkitusaha.jpeg',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Bangkit Usaha",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user?.uid)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    String ownerName = "Pemilik";
                                    if (snapshot.hasData &&
                                        snapshot.data!.exists) {
                                      final data =
                                          snapshot.data!.data()
                                              as Map<String, dynamic>?;
                                      ownerName =
                                          data?['ownerName'] ??
                                          user?.displayName ??
                                          "Pemilik";
                                    }
                                    return Text(
                                      "Selamat datang, $ownerName! 👋",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _buildHeaderIcon(
                                context,
                                LucideIcons.bell,
                                const NotificationScreen(),
                              ),
                              const SizedBox(width: 8),
                              _buildHeaderIcon(
                                context,
                                LucideIcons.messageCircle,
                                const ChatScreen(),
                              ),
                              const SizedBox(width: 8),
                              _buildHeaderIcon(
                                context,
                                LucideIcons.shoppingCart,
                                null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // SEARCH BAR
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: -25,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Cari produk UMKM di sini...",
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.search,
                          color: Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ============================================================
            // 2. MARKETPLACE FEED (PRODUK DARI TOKO LAIN)
            // ============================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // JUDUL SEKSI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.shoppingBag,
                            size: 20,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Rekomendasi Untuk Anda",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Lihat Semua",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // STREAM BUILDER (REALTIME DATA)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        // Kita urutkan berdasarkan waktu update agar yang terbaru muncul duluan
                        .orderBy('updatedAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text("Error memuat produk: ${snapshot.error}"),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allProducts = snapshot.data!.docs;

                      // FILTER PENTING:
                      // Hanya ambil produk yang UID pembuatnya BUKAN UID saya
                      final otherShopProducts = allProducts.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['uid'] != user?.uid;
                      }).toList();

                      if (otherShopProducts.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.store,
                                  size: 48,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Belum ada produk dari toko lain.",
                                  style: TextStyle(color: Colors.grey[500]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: otherShopProducts.length,
                        itemBuilder: (context, index) {
                          final doc = otherShopProducts[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return _buildProductCard(
                            data,
                            cardColor,
                            textColor,
                            isDark,
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 100), // Space bawah
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET ICON HEADER
  Widget _buildHeaderIcon(
    BuildContext context,
    IconData icon,
    Widget? destination,
  ) {
    return InkWell(
      onTap: destination != null
          ? () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            )
          : () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // WIDGET KARTU PRODUK (DATA REALTIME)
  Widget _buildProductCard(
    Map<String, dynamic> item,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    // Ambil data, jika null pakai default
    String image = (item['image'] != null && item['image'] != "")
        ? item['image']
        : "https://via.placeholder.com/150"; // Fallback image
    String name = item['name'] ?? "Tanpa Nama";
    String category = item['category'] ?? "Umum";
    int price = item['price'] ?? 0;
    int stock = item['stock'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GAMBAR PRODUK
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: Colors.grey[300],
                    image: DecorationImage(
                      image: NetworkImage(image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Label Kategori (Pengganti Lokasi sementara)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // DETAIL PRODUK
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Karena kita belum menyimpan nama Toko di produk,
                // kita kosongkan dulu atau pakai tulisan "UMKM Lokal"
                Text(
                  "UMKM Mitra",
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  currencyFormat.format(price),
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
                      "5.0",
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "| Stok $stock",
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
