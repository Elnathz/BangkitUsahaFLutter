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
            // HEADER + SEARCH BAR
            Stack(
              clipBehavior: Clip.none,
              children: [
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
                          // Foto Profil
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
                          // Nama User
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

                          // --- ICON BARIS (NOTIF, CHAT, CART) ---
                          Row(
                            children: [
                              // 1. Notifikasi (REALTIME BADGE)
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('notifications')
                                    .where('recipientId', isEqualTo: user?.uid)
                                    .where('isRead', isEqualTo: false)
                                    .limit(
                                      1,
                                    ) // Cukup cek ada 1 aja utk nyalain badge
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  bool hasUnreadNotif = false;
                                  if (snapshot.hasData &&
                                      snapshot.data!.docs.isNotEmpty) {
                                    hasUnreadNotif = true;
                                  }

                                  return _buildHeaderIcon(
                                    context,
                                    LucideIcons.bell,
                                    const NotificationScreen(),
                                    showBadge: hasUnreadNotif,
                                  );
                                },
                              ),
                              const SizedBox(width: 8),

                              // 2. Chat (SMART BADGE + SYSTEM NOTIFICATION)
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
                                          data['unread_count_${user?.uid}'] ??
                                          0;

                                      if (unreadCount > 0) {
                                        hasUnread = true;

                                        // --- LOGIKA NOTIFIKASI SYSTEM ---
                                        final Timestamp? lastTime =
                                            data['last_message_time'];
                                        if (lastTime != null) {
                                          final now = DateTime.now();
                                          final messageTime = lastTime.toDate();
                                          final diff = now
                                              .difference(messageTime)
                                              .inSeconds;

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
                                              print(
                                                "Gagal menampilkan notif: $e",
                                              );
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

                              // 3. Cart
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

                // SEARCH BAR
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: -25,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(LucideIcons.search, color: Colors.grey[400]),
                          const SizedBox(width: 12),
                          Text(
                            "Cari produk UMKM di sini...",
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
              ],
            ),

            const SizedBox(height: 40),

            // MARKETPLACE FEED (GRID PRODUK)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  StreamBuilder<QuerySnapshot>(
                    stream: MarketService().getAvailableProducts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allProducts = snapshot.data!.docs;

                      // --- LOGIKA FILTER ---
                      final otherShopProducts = allProducts.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final stock = data['stock'] ?? 0;
                        return stock > 0;
                      }).toList();

                      if (otherShopProducts.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.remove_shopping_cart,
                                  size: 40,
                                  color: Colors.grey[400],
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
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
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
                            child: _buildProductCard(
                              data,
                              cardColor,
                              textColor,
                              isDark,
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // SPACING BAWAH (Supaya tidak tertutup Nav Bar)
                  const SizedBox(height: 200),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          if (showBadge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF5D4037),
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    Map<String, dynamic> item,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    String image = (item['imageUrl'] != null && item['imageUrl'] != "")
        ? item['imageUrl']
        : (item['image'] != null && item['image'] != "")
        ? item['image']
        : "https://via.placeholder.com/150";

    String name = item['name'] ?? "Tanpa Nama";
    String category = item['category'] ?? "Umum";
    int price = (item['price'] ?? 0).toInt();
    int stock = (item['stock'] ?? 0).toInt();
    double rating = (item['rating'] ?? 0).toDouble();
    int totalReviews = item['totalReviews'] ?? 0;

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
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.star,
                          size: 10,
                          color: rating > 0 ? Colors.orange : Colors.grey[300],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "$rating",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "($totalReviews)",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Sisa: $stock",
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
