import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import '../../services/market_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  final bool isSellerMode;
  const OrderHistoryScreen({super.key, this.isSellerMode = false});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
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
    // Inisialisasi 4 Tab
    _tabController = TabController(length: 4, vsync: this);
  }

  // --- LOGIC KONFIRMASI TERIMA BARANG ---
  Future<void> _confirmOrderReceived(String orderId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pesanan Diterima?"),
        content: const Text(
          "Pastikan barang sudah diterima dengan baik.\n\n"
          "Setelah dikonfirmasi, dana akan diteruskan ke Penjual dan transaksi dianggap Selesai.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog
              try {
                // Update status jadi 'Selesai' (Uang masuk ke penjual)
                await MarketService().updateOrderStatus(orderId, 'Selesai');

                if (mounted) {
                  toastification.show(
                    context: context,
                    title: const Text("Transaksi Selesai!"),
                    description: const Text("Terima kasih telah berbelanja."),
                    type: ToastificationType.success,
                    autoCloseDuration: const Duration(seconds: 3),
                  );
                }
              } catch (e) {
                toastification.show(
                  context: context,
                  title: Text("Gagal: $e"),
                  type: ToastificationType.error,
                );
              }
            },
            child: const Text(
              "Ya, Terima Barang",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC PENJUAL: UPDATE STATUS ---
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await MarketService().updateOrderStatus(orderId, newStatus);
      if (mounted) {
        String msg = "";
        if (newStatus == 'Diproses') msg = "Pesanan diproses";
        if (newStatus == 'Diantar') msg = "Pesanan dikirim";

        toastification.show(
          context: context,
          title: Text(msg),
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      toastification.show(
        context: context,
        title: Text("Gagal: $e"),
        type: ToastificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(widget.isSellerMode ? "Pesanan Masuk" : "Pesanan Saya"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          isScrollable: true, // Agar tab bisa digeser di HP kecil
          tabs: const [
            Tab(text: "Menunggu"),
            Tab(text: "Dikemas"), // Status: Diproses
            Tab(text: "Dikirim"), // Status: Diantar
            Tab(text: "Selesai"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList("Menunggu"),
          _buildOrderList("Diproses"), // Mapping: Dikemas -> Diproses
          _buildOrderList("Diantar"), // Mapping: Dikirim -> Diantar
          _buildOrderList("Selesai"),
        ],
      ),
    );
  }

  Widget _buildOrderList(String statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: widget.isSellerMode
          ? MarketService().getIncomingOrders()
          : MarketService().getMyOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // --- FILTER CLIENT-SIDE ---
        // Kita filter data di sini agar tidak perlu membuat 4 index berbeda di Firestore
        final allOrders = snapshot.data!.docs;
        final filteredOrders = allOrders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Menunggu';
          return status == statusFilter;
        }).toList();

        if (filteredOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.shoppingBag,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  "Tidak ada pesanan di status ini",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final doc = filteredOrders[index];
            final data = doc.data() as Map<String, dynamic>;
            // Anti-Crash untuk items
            final items = (data['items'] as List?) ?? [];

            return _buildOrderCard(doc.id, data, items);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(
    String orderId,
    Map<String, dynamic> data,
    List items,
  ) {
    final primaryColor = const Color(0xFF1565C0);
    final status = data['status'] ?? 'Menunggu';
    final isSeller = widget.isSellerMode;
    final int totalPrice = (data['totalPrice'] ?? 0).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: Nama Toko & Status
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isSeller ? LucideIcons.user : LucideIcons.store,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSeller
                          ? (data['buyerName'] ?? "Pembeli")
                          : (data['sellerName'] ?? "Toko"),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // AUTO-CANCEL DEADLINE WARNING (for "Menunggu" and "Diproses" status)
          if ((status == 'Menunggu' || status == 'Diproses') && 
              (data['createdAt'] != null || data['updatedAt'] != null))
            Builder(builder: (context) {
              // Menunggu uses createdAt (3 days), Diproses uses updatedAt (7 days)
              final bool isMenunggu = status == 'Menunggu';
              final int deadlineDays = isMenunggu ? 3 : 7;
              
              final DateTime baseTime;
              if (isMenunggu && data['createdAt'] != null) {
                baseTime = (data['createdAt'] as Timestamp).toDate();
              } else if (data['updatedAt'] != null) {
                baseTime = (data['updatedAt'] as Timestamp).toDate();
              } else {
                return const SizedBox();
              }
              
              final deadline = baseTime.add(Duration(days: deadlineDays));
              final now = DateTime.now();
              final remaining = deadline.difference(now);
              
              // Calculate remaining time
              final days = remaining.inDays;
              final hours = remaining.inHours % 24;
              final minutes = remaining.inMinutes % 60;
              
              // Determine urgency color
              final isUrgent = remaining.inHours < 24;
              final isExpired = remaining.isNegative;
              
              // Color scheme based on urgency
              final Color bgColor;
              final Color borderColor;
              final Color textColor;
              final Color badgeColor;
              
              if (isExpired) {
                bgColor = Colors.red.shade50;
                borderColor = Colors.red.shade200;
                textColor = Colors.red.shade700;
                badgeColor = Colors.red;
              } else if (isUrgent) {
                bgColor = Colors.orange.shade50;
                borderColor = Colors.orange.shade200;
                textColor = Colors.orange.shade700;
                badgeColor = Colors.orange;
              } else {
                bgColor = Colors.amber.shade50;
                borderColor = Colors.amber.shade200;
                textColor = Colors.amber.shade800;
                badgeColor = Colors.amber.shade700;
              }
              
              String timeText;
              if (isExpired) {
                timeText = "Akan segera dibatalkan";
              } else if (days > 0) {
                timeText = "$days hari $hours jam lagi";
              } else if (hours > 0) {
                timeText = "$hours jam $minutes menit lagi";
              } else {
                timeText = "$minutes menit lagi";
              }
              
              // Different messages based on status
              final String statusMessage;
              if (isMenunggu) {
                statusMessage = isSeller 
                    ? "Segera proses pesanan ini"
                    : "Menunggu konfirmasi penjual";
              } else {
                statusMessage = isSeller 
                    ? "Segera kirim pesanan ini"
                    : "Menunggu pengiriman dari penjual";
              }
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      isMenunggu ? LucideIcons.clock : LucideIcons.package,
                      size: 16,
                      color: textColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusMessage,
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "Batas waktu: $timeText",
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUrgent && !isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "⚠️ Urgent",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          
          const Divider(height: 1),

          // LIST BARANG (Preview 1 Barang Utama + Info sisa)
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      image:
                          (items[0]['image'] != null && items[0]['image'] != "")
                          ? DecorationImage(
                              image: NetworkImage(items[0]['image']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child:
                        (items[0]['image'] == null || items[0]['image'] == "")
                        ? const Icon(LucideIcons.image, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[0]['name'] ?? "Produk",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${items[0]['qty']} barang x ${currencyFormat.format(items[0]['price'])}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (items.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "+ ${items.length - 1} produk lainnya",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // FOOTER: Total Harga & Tombol Aksi
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Total Pesanan",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      currencyFormat.format(totalPrice),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                // TOMBOL AKSI BERDASARKAN STATUS
                if (!isSeller && status == 'Diantar')
                  ElevatedButton(
                    onPressed: () => _confirmOrderReceived(orderId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Pesanan Diterima"),
                  )
                else if (!isSeller && status == 'Selesai')
                  OutlinedButton(
                    onPressed: () {
                      // Logic beri ulasan bisa diarahkan ke halaman detail produk
                      // Untuk sementara tampilkan toast saja
                      toastification.show(
                        context: context,
                        title: const Text("Terima kasih!"),
                        autoCloseDuration: const Duration(seconds: 2),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor),
                      foregroundColor: primaryColor,
                    ),
                    child: const Text("Beri Ulasan"),
                  )
                // --- TOMBOL AKSI PENJUAL ---
                else if (isSeller && status == 'Menunggu')
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus(orderId, 'Diproses'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Proses Pesanan"),
                  )
                else if (isSeller && status == 'Diproses')
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus(orderId, 'Diantar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Kirim Barang"),
                  )
                else if (isSeller && status == 'Diantar')
                  const Text(
                    "Menunggu Konfirmasi",
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  )
                else
                  // Status Menunggu/Diproses tidak ada tombol aksi
                  const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
