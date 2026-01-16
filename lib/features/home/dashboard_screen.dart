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
import '../account/order_history_screen.dart';

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

  // Pagination state
  final ScrollController _scrollController = ScrollController();
  int _displayedProductCount = 999; // Show all products initially
  bool _isLoadingMore = false;
  int _totalAvailableProducts = 0; // Track total available products

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if we're near the bottom (within 300 pixels)
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 300) {
      // Only load more if there are more products to show
      if (_displayedProductCount < _totalAvailableProducts) {
        _loadMoreProducts();
      }
    }
  }

  void _loadMoreProducts() {
    if (!_isLoadingMore && _displayedProductCount < _totalAvailableProducts) {
      setState(() {
        _isLoadingMore = true;
      });
      // Simulate loading delay for smooth UX
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _displayedProductCount += 6; // Load 6 more products
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF112240) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      // Background gradient
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF5F3FF),
                    const Color(0xFFEEF2FF),
                  ],
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              // HEADER dengan SEARCH BAR terintegrasi
              Container(
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1976D2),
                      Color(0xFF0D47A1),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Search Bar
                    Expanded(
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
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.search,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Cari produk...",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Icons Row
                    Row(
                      children: [
                        // Toko (KHUSUS PENJUAL)
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user?.uid)
                              .snapshots(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.hasData &&
                                userSnapshot.data!.exists) {
                              final userData =
                                  userSnapshot.data!.data()
                                      as Map<String, dynamic>;
                              if (userData['role'] == 'seller') {
                                return StreamBuilder<QuerySnapshot>(
                                  stream: MarketService()
                                      .getIncomingOrders(),
                                  builder: (context, orderSnapshot) {
                                    int incomingCount = 0;
                                    if (orderSnapshot.hasData) {
                                      incomingCount = orderSnapshot
                                          .data!
                                          .docs
                                          .where((doc) {
                                            final status =
                                                (doc.data()
                                                    as Map<
                                                      String,
                                                      dynamic
                                                    >)['status'];
                                            return status != 'Selesai' &&
                                                status != 'Dibatalkan';
                                          })
                                          .length;
                                    }
                                    return Row(
                                      children: [
                                        _buildHeaderIconNew(
                                          context,
                                          LucideIcons.store,
                                          const OrderHistoryScreen(
                                            isSellerMode: true,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                            return const SizedBox();
                          },
                        ),
                        // Notifikasi
                        _buildHeaderIconNew(
                          context,
                          LucideIcons.bell,
                          const NotificationScreen(),
                        ),
                        const SizedBox(width: 8),
                        // Chat
                        _buildHeaderIconNew(
                          context,
                          LucideIcons.messageSquare,
                          const ChatScreen(),
                        ),
                        const SizedBox(width: 8),
                        // Cart
                        _buildHeaderIconNew(
                          context,
                          LucideIcons.shoppingCart,
                          CartScreen(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // MARKETPLACE FEED (GRID PRODUK)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header "Produk Pilihan"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Icon background putih dengan warna biru
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.shoppingBag,
                                size: 24,
                                color: Color(0xFF1976D2), // Blue (sama dengan header)
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Title dan Subtitle dalam Column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Produk UMKM",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Produk terbaik dari UMKM Indonesia",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
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

                        final otherShopProducts = allProducts.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final stock = data['stock'] ?? 0;
                          return stock > 0;
                        }).toList();

                        // Update total available products for pagination
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_totalAvailableProducts != otherShopProducts.length) {
                            setState(() {
                              _totalAvailableProducts = otherShopProducts.length;
                            });
                          }
                        });

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

                        // Calculate displayed count
                        final displayCount = _displayedProductCount < otherShopProducts.length 
                            ? _displayedProductCount 
                            : otherShopProducts.length;
                        final hasMore = displayCount < otherShopProducts.length;

                        return Column(
                          children: [
                            GridView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.65,
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
                            ),
                            // Loading indicator
                            if (_isLoadingMore || hasMore)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: _isLoadingMore
                                    ? const CircularProgressIndicator()
                                    : Text(
                                        'Scroll untuk memuat lebih banyak...',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                              ),
                          ],
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
      ),
    );
  }

  Widget _buildHeaderIcon(
    BuildContext context,
    IconData icon,
    Widget? destination, {
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: destination != null
          ? () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            )
          : () {},
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (showBadge || badgeCount > 0)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444), // Red-500
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconNew(
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildSearchBarIcon(
    BuildContext context,
    IconData icon,
    Widget? destination, {
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: destination != null
          ? () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            )
          : () {},
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4F46E5), size: 18),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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
    String getValidImage() {
      if (item['imageUrl'] != null && item['imageUrl'] != "")
        return item['imageUrl'];
      if (item['image'] != null && item['image'] != "") return item['image'];
      return "https://via.placeholder.com/150";
    }

    String image = getValidImage();
    String name = item['name'] ?? "Tanpa Nama";
    String category = item['category'] ?? "Umum";
    int price = (item['price'] ?? 0).toInt();
    int stock = (item['stock'] ?? 0).toInt();
    double rating = (item['rating'] ?? 0).toDouble();
    int totalSold = item['totalSold'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFF3F4F6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Container
          Expanded(
            child: Stack(
              children: [
                // Product Image
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[200]!,
                        Colors.grey[300]!,
                      ],
                    ),
                    image: DecorationImage(
                      image: NetworkImage(image),
                      fit: BoxFit.cover,
                    ),
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
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "📍 $category",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Product Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seller with verified icon
                Row(
                  children: [
                    Icon(
                      LucideIcons.checkCircle,
                      size: 12,
                      color: const Color(0xFF10B981), // Emerald-500
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "UMKM Mitra",
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Product Name
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Price
                Text(
                  currencyFormat.format(price),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981), // Green
                  ),
                ),
                const SizedBox(height: 6),
                // Rating & Sold
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: const Color(0xFFF59E0B), // Amber-500
                    ),
                    const SizedBox(width: 2),
                    Text(
                      "$rating",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "• Terjual $totalSold",
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
