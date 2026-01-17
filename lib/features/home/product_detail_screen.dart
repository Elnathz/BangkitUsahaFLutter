import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
// removed unused import 'package:toastification/toastification.dart'
import '../inventory/checkout_screen.dart'; // Pastikan path relatifnya benar sesuai struktur folder
// ATAU gunakan path absolut jika bingung:
// import 'package:bangkit_usaha/features/inventory/checkout_screen.dart';
import '../../services/market_service.dart';
import '../chat/chat_detail_screen.dart';
import 'product_reviews_screen.dart';
import 'store_profile_screen.dart';
// --- IMPORT CHECKOUT SCREEN (duplicate removal) ---
// duplicate import removed

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required Map<String, dynamic> productData,
    required this.productId,
  }) : initialData = productData;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // --- STATE ADMIN & USER ---
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isAdmin = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  // 1. CEK APAKAH USER ADALAH ADMIN
  Future<void> _checkAdminStatus() async {
    if (currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists && doc.data()?['role'] == 'admin') {
        if (mounted) setState(() => _isAdmin = true);
      }
    } catch (e) {
      debugPrint("Gagal cek admin: $e");
    }
  }

  // 2. FUNGSI HAPUS PRODUK
  Future<void> _deleteProduct() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Produk Ini?"),
        content: const Text(
          "Produk akan dihapus permanen oleh Admin. Lanjutkan?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isDeleting = true);
              try {
                // Hapus Produk
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(widget.productId)
                    .delete();

                // Hapus Review Terkait
                var reviews = await FirebaseFirestore.instance
                    .collection('reviews')
                    .where('productId', isEqualTo: widget.productId)
                    .get();
                for (var doc in reviews.docs) {
                  await doc.reference.delete();
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Produk berhasil dihapus (Admin)"),
                    ),
                  );
                  Navigator.pop(context); // Kembali ke dashboard
                }
              } catch (e) {
                setState(() => _isDeleting = false);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Gagal hapus: $e")));
              }
            },
            child: const Text("Hapus Permanen"),
          ),
        ],
      ),
    );
  }

  // --- UI UTAMA ---
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> data;
        if (snapshot.hasData && snapshot.data!.exists) {
          data = snapshot.data!.data() as Map<String, dynamic>;
        } else {
          if (snapshot.connectionState == ConnectionState.active &&
              !snapshot.hasData) {
            return const SizedBox();
          }
          data = widget.initialData;
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

    String ownerUid = productData['uid'] ?? "";
    num rawPrice = productData['price'] ?? 0;
    int price = rawPrice.toInt();
    double rating = (productData['rating'] ?? 0).toDouble();
    int totalReviews = productData['totalReviews'] ?? 0;

    bool isOwner = ownerUid == currentUser?.uid;
    bool canDelete = _isAdmin || isOwner;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      // SAFE AREA DI BODY AGAR HEADER TIDAK TERTUTUP STATUS BAR
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. HEADER MANUAL (IKUT SCROLL) ---
                  Container(
                    color: isDark ? Colors.black : Colors.grey[100],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Tombol Back
                        IconButton(
                          icon: Icon(LucideIcons.arrowLeft, color: textColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        // Judul
                        Expanded(
                          child: Text(
                            "Detail Produk",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        // Tombol Delete
                        if (canDelete)
                          IconButton(
                            icon: _isDeleting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    LucideIcons.trash2,
                                    color: Colors.red,
                                  ),
                            tooltip: _isAdmin
                                ? "Hapus sbg Admin"
                                : "Hapus Produk",
                            onPressed: _isDeleting ? null : _deleteProduct,
                          ),
                      ],
                    ),
                  ),

                  // --- 2. GAMBAR PRODUK ---
                  GestureDetector(
                    onTap: () {
                      if (productData['image'] != null &&
                          productData['image'] != "") {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: EdgeInsets.zero,
                            child: Stack(
                              children: [
                                InteractiveViewer(
                                  child: CachedNetworkImage(
                                    imageUrl: productData['image'],
                                    // OPTIMASI RAM: Batasi tinggi gambar di memori
                                    memCacheHeight: 1024, 
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 40,
                                  right: 20,
                                  child: IconButton(
                                    icon: const Icon(
                                      LucideIcons.x,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    onPressed: () => Navigator.pop(ctx),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 350,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        image:
                            (productData['image'] != null &&
                                productData['image'] != "")
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  productData['image'],
                                ),
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
                  ),

                  // --- 3. INFO HARGA & RATING ---
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
                            color: Colors.green.shade600,
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
                            Text(
                              "|",
                              style: TextStyle(color: Colors.grey[400]),
                            ),
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
                            Text(
                              "|",
                              style: TextStyle(color: Colors.grey[400]),
                            ),
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

                  // --- 4. INFO TOKO ---
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
                            shopName =
                                data['storeName'] ??
                                data['name'] ??
                                "Toko Mitra";
                            shopImage = data['image'];
                            isOnline = true;
                          }
                        } else {
                          shopName = "Toko Tidak Dikenal";
                        }
                      }

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage:
                                        (shopImage != null && shopImage != "")
                                        ? CachedNetworkImageProvider(shopImage)
                                        : null,
                                    child:
                                        (shopImage == null || shopImage == "")
                                        ? Text(
                                            shopName.isNotEmpty
                                                ? shopName[0].toUpperCase()
                                                : "?",
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1976D2),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Name and Role
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shopName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            LucideIcons.store,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isOnline ? "Online" : "Offline",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Visit Button
                              InkWell(
                                onTap: () {
                                  if (ownerUid.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            StoreProfileScreen(
                                              sellerId: ownerUid,
                                              sellerName: shopName,
                                            ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Data toko tidak tersedia",
                                        ),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: const Text(
                                    "Kunjungi",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // --- 5. DESKRIPSI ---
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

                  // --- 6. ULASAN ---
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
                                      productId: widget.productId,
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
                              .where('productId', isEqualTo: widget.productId)
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

            // --- BOTTOM BAR (TETAP DI POSISI FIXED) ---
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                    IconButton(
                      icon: Column(
                        children: [
                          Icon(
                            LucideIcons.messageSquare,
                            size: 20,
                            color: primaryColor,
                          ),
                          const Text("Chat", style: TextStyle(fontSize: 9)),
                        ],
                      ),
                      onPressed: () async {
                        if (ownerUid.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Error: Data penjual tidak valid"),
                            ),
                          );
                          return;
                        }
                        if (currentUser != null &&
                            ownerUid == currentUser!.uid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Ini produk Anda sendiri"),
                            ),
                          );
                          return;
                        }
                        // Fetch user logic inline...
                        String targetName = "Toko";
                        String targetImage = "";
                        try {
                          final userSnap = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(ownerUid)
                              .get();
                          if (userSnap.exists) {
                            final userData =
                                userSnap.data() as Map<String, dynamic>;
                            targetName =
                                userData['storeName'] ??
                                userData['name'] ??
                                "Penjual";
                            targetImage =
                                userData['image'] ?? userData['imageUrl'] ?? "";
                          }
                        } catch (e) {
                          // ignore error
                        }
                        if (targetImage.isEmpty) {
                          targetImage = productData['ownerImage'] ?? "";
                        }

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                targetUid: ownerUid,
                                targetName: targetName,
                                targetImage: targetImage.isNotEmpty
                                    ? targetImage
                                    : 'https://via.placeholder.com/150',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () async {
                        try {
                          await MarketService().addToCart(
                            widget.productId,
                            productData['name'] ?? "Produk",
                            price,
                            productData['image'] ?? "",
                            sellerId: ownerUid,
                            sellerName:
                                productData['sellerName'] ??
                                productData['storeName'] ??
                                "Toko", // Ensure sellerName is passed
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Berhasil masuk keranjang!"),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Gagal: $e")),
                            );
                          }
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
                          const Text(
                            "Keranjang",
                            style: TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // LOGIKA BARU: BUKA DIALOG, TAPI DATA LENGKAP
                          _showBuyDialog(context, productData, price);
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
      ),
    );
  }

  // --- HELPER DIALOG BELI (DIPERBARUI DENGAN QTY & NOTES) ---
  void _showBuyDialog(
    BuildContext context,
    Map<String, dynamic> productData,
    int price,
  ) {
    // Local State for Dialog
    int qty = 1;
    final noteController = TextEditingController();
    int stock = productData['stock'] is int ? productData['stock'] : 0;
    final primaryColor = Theme.of(context).primaryColor;

    // Currency Format
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final String productName = productData['name'] ?? "Produk";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            int totalPrice = price * qty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                          image:
                              (productData['image'] != null &&
                                  productData['image'] != "")
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    productData['image'],
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currency.format(price),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Stok: $stock",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Jumlah Pembelian",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: qty > 1
                                  ? () => setStateSB(() => qty--)
                                  : null,
                              icon: const Icon(LucideIcons.minus, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Text(
                              "$qty",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              // Limit max qty to stock if needed, or sensible default
                              onPressed: (qty < stock)
                                  ? () => setStateSB(() => qty++)
                                  : null,
                              icon: const Icon(LucideIcons.plus, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Notes Field
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: "Catatan untuk penjual (Opsional)",
                      hintText:
                          "Contoh: Warna merah, ukuran L, packing aman...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),

                  // Summary & Action
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Harga",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              currency.format(totalPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx); // Close Modal

                            // 1. Prepare Item Data
                            final item = {
                              'productId': widget.productId,
                              'name': productName,
                              'price': price,
                              'qty': qty,
                              'image': productData['image'] ?? '',
                              'note': noteController.text
                                  .trim(), // Include Note
                              'sellerId': productData['uid'],
                              'sellerName': productData['sellerName'] ?? "Toko",
                            };

                            // 2. Navigate to Checkout
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutScreen(
                                  items: [item],
                                  totalPrice: totalPrice,
                                  // Fields below redundant if using item grouping logic but needed for constructor
                                  sellerId: productData['uid'] ?? "",
                                  sellerName:
                                      productData['sellerName'] ?? "Toko",
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            "Beli Sekarang",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
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
