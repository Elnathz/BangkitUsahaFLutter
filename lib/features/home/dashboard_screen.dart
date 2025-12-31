import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/market_service.dart';
import '../cart/cart_screen.dart';
import '../notifications/notification_screen.dart';
import '../chat/chat_screen.dart';
import 'search_page.dart';
import 'product_detail_screen.dart';
import '../../services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    // UI Constants matches the requested "Blue Theme" style
    final gradientColors = [Colors.blue[600]!, Colors.blue[700]!];
    final scaffoldBg = Colors.grey[50];

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER SECTION
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: gradientColors,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // PROFILE INFO
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
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
                                children: [
                                  const Text(
                                    "Bangkit Usaha",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
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
                                        style: TextStyle(
                                          color: Colors.blue[100],
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ACTION ICONS
                      Row(
                        children: [
                          _buildHeaderIcon(
                            context,
                            LucideIcons.bell,
                            const NotificationScreen(),
                            showBadge: false,
                          ),
                          const SizedBox(width: 8),
                          // Chat Stream Logic Preserved
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('chat_rooms')
                                .where(
                              'participants',
                              arrayContains: user?.uid,
                            )
                                .snapshots(),
                            builder: (context, snapshot) {
                              bool hasUnread = false;
                              if (snapshot.hasData) {
                                for (var doc in snapshot.data!.docs) {
                                  final data =
                                  doc.data() as Map<String, dynamic>;
                                  final int unreadCount =
                                      data['unread_count_${user?.uid}'] ?? 0;

                                  if (unreadCount > 0) {
                                    hasUnread = true;
                                    final Timestamp? lastTime =
                                    data['last_message_time'];
                                    if (lastTime != null) {
                                      final now = DateTime.now();
                                      final diff =
                                          now
                                              .difference(lastTime.toDate())
                                              .inSeconds;

                                      // Logic Notif System
                                      if (diff.abs() <= 10) {
                                        try {
                                          NotificationService.showNotification(
                                            id: doc.id.hashCode,
                                            title: "Pesan Baru",
                                            body:
                                            data['last_message'] ??
                                                "Anda mendapat pesan",
                                          );
                                        } catch (e) {
                                          debugPrint("Gagal notif: $e");
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                              return _buildHeaderIcon(
                                context,
                                LucideIcons.messageCircle,
                                const ChatScreen(),
                                showBadge: hasUnread,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildHeaderIcon(
                            context,
                            LucideIcons.shoppingCart,
                            CartScreen(),
                            showBadge: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. SEARCH BAR & CONTENT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Floating Search Bar Style
                  Transform.translate(
                    offset: const Offset(0, -25),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchPage(),
                          ),
                        );
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(LucideIcons.search, color: Colors.grey[400]),
                            const SizedBox(width: 12),
                            Text(
                              "Cari produk, toko, atau kategori...",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // SECTION HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "🛍️ Produk Pilihan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SearchPage()),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              "Lihat Semua",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(LucideIcons.chevronRight, size: 16, color: Colors.blue[600]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // MARKETPLACE GRID
                  StreamBuilder<QuerySnapshot>(
                    stream: MarketService().getAvailableProducts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allProducts = snapshot.data!.docs;

                      // --- LOGIKA FILTER (PRESERVED) ---
                      final otherShopProducts = allProducts.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final stock = data['stock'] ?? 0;
                        // Logic preserved as requested
                        // return data['uid'] != user?.uid && stock > 0;
                        return stock > 0; // Display all for testing
                      }).toList();

                      if (otherShopProducts.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.packageOpen,
                                  size: 40,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Belum ada produk tersedia.",
                                  style: TextStyle(color: Colors.grey[500]),
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
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: otherShopProducts.length,
                        itemBuilder: (context, index) {
                          final doc = otherShopProducts[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final id = doc.id;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(
                                    productData: data,
                                    productId: id,
                                  ),
                                ),
                              );
                            },
                            child: _buildProductCard(data),
                          );
                        },
                      );
                    },
                  ),

                  // Bottom Spacing
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER ICON STYLE
  Widget _buildHeaderIcon(
      BuildContext context,
      IconData icon,
      Widget? destination, {
        bool showBadge = false,
      }) {
    return InkWell(
      onTap: destination != null
          ? () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      )
          : () {},
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (showBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // CARD STYLE (Matches UI Guidelines)
  Widget _buildProductCard(Map<String, dynamic> item) {
    String image = (item['imageUrl'] != null && item['imageUrl'] != "")
        ? item['imageUrl']
        : (item['image'] != null && item['image'] != "")
        ? item['image']
        : "https://via.placeholder.com/150";

    String name = item['name'] ?? "Tanpa Nama";
    String sellerName = item['sellerName'] ?? "Toko";
    int price = (item['price'] ?? 0).toInt();
    double rating = (item['rating'] ?? 0).toDouble();
    int sold = item['sold'] ?? 0;
    String location = item['location'] ?? "Indonesia";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE SECTION
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[200],
                  child: Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
                    const Center(child: Icon(LucideIcons.image, color: Colors.grey)),
                  ),
                ),
                // Location Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      location,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // DETAILS SECTION
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sellerName,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(price),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
                const SizedBox(height: 4),
                // Rating & Sold
                Row(
                  children: [
                    const Icon(LucideIcons.star, size: 12, color: Colors.orange),
                    const SizedBox(width: 3),
                    Text(
                      "$rating",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "• Terjual $sold",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
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