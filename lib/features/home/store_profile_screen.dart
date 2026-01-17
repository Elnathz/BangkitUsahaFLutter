import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreProfileScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;

  const StoreProfileScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [_buildSliverAppBar()];
        },
        body: Column(
          children: [
            // Tab Bar ala Shopee
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1976D2),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF1976D2),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: "Produk"),
                  Tab(text: "Penilaian"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildProductTab(), _buildReviewsTab()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1976D2),
      flexibleSpace: FlexibleSpaceBar(
        background: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.sellerId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Container(color: Colors.grey[200]);

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final image = data?['image'] ?? '';
            final coverImage =
                data?['coverImage'] ?? ''; // Jika ada cover image
            final location = data?['address'] ?? 'Lokasi belum diatur';

            return Stack(
              fit: StackFit.expand,
              children: [
                // Background Image (Cover)
                coverImage.isNotEmpty
                    ? Image.network(coverImage, fit: BoxFit.cover)
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                          ),
                        ),
                      ),
                // Overlay Gelap
                Container(color: Colors.black.withOpacity(0.4)),

                // Info Toko
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      // Foto Profil Toko
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: image.isNotEmpty
                              ? NetworkImage(image)
                              : null,
                          backgroundColor: Colors.grey[300],
                          child: image.isEmpty
                              ? const Icon(
                                  LucideIcons.store,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.sellerName,
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
                                  LucideIcons.mapPin,
                                  color: Colors.white70,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _showLocationSheet(data),
                                    child: Text(
                                      location,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Stats Row
                            Row(
                              children: [
                                _buildStatBadge(LucideIcons.star, "4.8"),
                                const SizedBox(width: 8),
                                _buildStatBadge(
                                  LucideIcons.users,
                                  "1.2k Pengikut",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.yellow, size: 10),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  // --- TAB 1: PRODUK ---
  Widget _buildProductTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('uid', isEqualTo: widget.sellerId) // Ubah sellerId jadi uid
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("Belum ada produk", LucideIcons.package);
        }

        final products = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final data = products[index].data() as Map<String, dynamic>;
            return _buildProductCard(data);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                image: DecorationImage(
                  image: NetworkImage(
                    data['imageUrl'] ??
                        data['image'] ??
                        'https://via.placeholder.com/150',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Produk',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(data['price'] ?? 0),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM SHEET LOKASI ---
  void _showLocationSheet(Map<String, dynamic>? data) {
    // Cek apakah ada koordinat (latitude/longitude)
    double? lat = data?['latitude'];
    double? lng = data?['longitude'];

    // Default ke Monas jika tidak ada lokasi
    final LatLng position = (lat != null && lng != null)
        ? LatLng(lat, lng)
        : const LatLng(-6.175392, 106.827153);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: position,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('storeLocation'),
                      position: position,
                      infoWindow: InfoWindow(title: widget.sellerName),
                    ),
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(LucideIcons.mapPin, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data?['address'] ??
                            'Alamat lengkap belum diatur oleh penjual.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 2: PENILAIAN (Hanya Ulasan Toko) ---
  Widget _buildReviewsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('shopId', isEqualTo: widget.sellerId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter: Hanya ambil ulasan yang TIDAK punya productId (Ulasan Toko)
        final reviews =
            snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['productId'] == null || data['productId'] == "";
            }).toList() ??
            [];

        if (reviews.isEmpty) {
          return _buildEmptyState(
            "Belum ada ulasan toko",
            LucideIcons.messageSquare,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final data = reviews[index].data() as Map<String, dynamic>;

            // Format Tanggal
            String dateStr = "Baru saja";
            if (data['createdAt'] != null) {
              final date = (data['createdAt'] as Timestamp).toDate();
              dateStr = DateFormat('dd MMM yyyy').format(date);
            }

            return _buildReviewItem(
              data['userName'] ?? "Pengguna",
              (data['rating'] ?? 0).toInt(),
              data['comment'] ?? "",
              dateStr,
            );
          },
        );
      },
    );
  }

  Widget _buildReviewItem(String user, int stars, String comment, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey[300],
                child: Text(user[0], style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(
                user,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                date,
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star,
                size: 14,
                color: index < stars ? Colors.amber : Colors.grey[300],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(comment, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Logika Chat Penjual
              },
              icon: const Icon(LucideIcons.messageCircle, size: 18),
              label: const Text("Chat Penjual"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1976D2),
                side: const BorderSide(color: Color(0xFF1976D2)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showAddReviewDialog();
              },
              icon: const Icon(LucideIcons.star, size: 18),
              label: const Text("Beri Ulasan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Beri Ulasan Toko"),
        content: const TextField(
          decoration: InputDecoration(
            hintText: "Tulis pengalamanmu berbelanja di sini...",
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kirim"),
          ),
        ],
      ),
    );
  }
}
