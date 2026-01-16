import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added
import '../../services/market_service.dart';
import '../chat/chat_detail_screen.dart'; // Added

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

  // --- LOGIC PEMBELI: BATALKAN PESANAN ---
  // Common cancellation reasons from e-commerce (matching reference image)
  static const List<String> _cancellationReasons = [
    'Salah pilih produk/varian',
    'Salah alamat pengiriman',
    'Pemesanan duplikat',
    'Berubah pikiran',
    'Menemukan harga lebih murah',
    'Salah metode pembayaran',
    'Lainnya',
  ];

  Future<void> _showCancelOrderDialog(String orderId, Map<String, dynamic> data) async {
    // Check if order is within 2 minutes (instant cancel allowed)
    final createdAt = data['createdAt'] as Timestamp?;
    final bool canInstantCancel;
    
    if (createdAt != null) {
      final orderTime = createdAt.toDate();
      final now = DateTime.now();
      final difference = now.difference(orderTime);
      canInstantCancel = difference.inMinutes < 2;
    } else {
      canInstantCancel = false;
    }

    String? selectedReason;
    String customReason = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red Header (matching reference)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Batalkan Pesanan",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Order #${orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}",
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(LucideIcons.x, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Warning Banner (pink/red for needs approval, green for instant)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: canInstantCancel ? Colors.green.shade50 : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.alertCircle,
                      size: 18,
                      color: canInstantCancel ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            canInstantCancel ? "Pembatalan Langsung" : "Butuh Persetujuan Penjual",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: canInstantCancel ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            canInstantCancel
                                ? "Pesanan dapat langsung dibatalkan tanpa persetujuan"
                                : "Pembatalan akan dikirim ke penjual untuk disetujui. Proses bisa memakan waktu 1-2 hari kerja.",
                            style: TextStyle(
                              fontSize: 11,
                              color: canInstantCancel ? Colors.green.shade600 : Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Reason Label
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      "Alasan Pembatalan",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(" *", style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              
              // Radio Options (Boxed style matching reference)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _cancellationReasons.map((reason) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedReason == reason 
                              ? const Color(0xFF2563EB)
                              : Colors.grey.shade300,
                          width: selectedReason == reason ? 2 : 1,
                        ),
                      ),
                      child: RadioListTile<String>(
                        title: Text(reason, style: TextStyle(
                          fontSize: 14,
                          fontWeight: selectedReason == reason ? FontWeight.w500 : FontWeight.normal,
                        )),
                        value: reason,
                        groupValue: selectedReason,
                        activeColor: const Color(0xFF2563EB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        dense: true,
                        onChanged: (value) {
                          setDialogState(() => selectedReason = value);
                        },
                      ),
                    )).toList(),
                  ),
                ),
              ),
              
              // Custom reason input for Lainnya
              if (selectedReason == 'Lainnya')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Tulis alasan pembatalan...",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 2,
                    onChanged: (value) => customReason = value,
                  ),
                ),
              
              // Bottom Buttons (Batal / Kirim Permintaan)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Batal"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedReason == null
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                final reason = selectedReason == 'Lainnya'
                                    ? (customReason.isNotEmpty ? customReason : 'Lainnya')
                                    : selectedReason!;
                                
                                if (canInstantCancel) {
                                  await _cancelOrderInstant(orderId, reason);
                                } else {
                                  await _requestCancelOrder(orderId, reason, data);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          canInstantCancel ? "Batalkan" : "Kirim Permintaan",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Instant cancel (within 2 minutes)
  Future<void> _cancelOrderInstant(String orderId, String reason) async {
    try {
      await MarketService().cancelOrderByBuyer(orderId, reason, needsApproval: false);
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text("Pesanan Dibatalkan"),
          description: const Text("Pesanan berhasil dibatalkan."),
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
  }

  // Request cancellation (after 2 minutes, needs seller approval)
  Future<void> _requestCancelOrder(String orderId, String reason, Map<String, dynamic> data) async {
    try {
      await MarketService().cancelOrderByBuyer(orderId, reason, needsApproval: true);
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text("Pengajuan Pembatalan Terkirim"),
          description: const Text("Menunggu persetujuan penjual."),
          type: ToastificationType.info,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light blue-gray background
      body: Column(
        children: [
          // Gradient Header (TSX Style)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.isSellerMode ? "Pesanan Masuk" : "Pesanan Saya",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Tab Bar (TSX Style with icons and badges)
          Container(
            color: Colors.white,
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.isSellerMode
                  ? MarketService().getIncomingOrders()
                  : MarketService().getMyOrders(),
              builder: (context, snapshot) {
                // Count orders per status
                int menungguCount = 0, diprosesCount = 0, diantarCount = 0, selesaiCount = 0;
                
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    switch (data['status']) {
                      case 'Menunggu': menungguCount++; break;
                      case 'Diproses': diprosesCount++; break;
                      case 'Diantar': diantarCount++; break;
                      case 'Selesai': selesaiCount++; break;
                    }
                  }
                }
                
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildIconTab(0, LucideIcons.clock, "Menunggu", menungguCount),
                      _buildIconTab(1, LucideIcons.package, "Dikemas", diprosesCount),
                      _buildIconTab(2, LucideIcons.truck, "Dikirim", diantarCount),
                      _buildIconTab(3, LucideIcons.checkCircle2, "Selesai", selesaiCount),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList("Menunggu"),
                _buildOrderList("Diproses"),
                _buildOrderList("Diantar"),
                _buildOrderList("Selesai"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconTab(int index, IconData icon, String label, int count) {
    final isSelected = _tabController.index == index;
    const primaryColor = Color(0xFF2563EB);
    
    return Expanded(
      child: InkWell(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? primaryColor : Colors.grey.shade600,
                  ),
                  if (count > 0)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? primaryColor : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
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
    final status = data['status'] ?? 'Menunggu';
    final isSeller = widget.isSellerMode;
    final int totalPrice = (data['totalPrice'] ?? 0).toInt();
    // Calculate if all items are reviewed
    bool allReviewed = items.every((item) => item['reviewed'] == true);

    // Status Configuration (matching reference)
    late final Color themeColor;
    late final Color lightBg;
    late final Color textColor;
    late final IconData statusIcon;

    switch (status) {
      case 'Menunggu':
        themeColor = Colors.amber.shade600;
        lightBg = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
        statusIcon = LucideIcons.clock;
        break;
      case 'Diproses': // "Dikemas" in reference
        themeColor = Colors.blue.shade600;
        lightBg = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        statusIcon = LucideIcons.package;
        break;
      case 'Diantar': // "Dikirim" in reference
        themeColor = Colors.purple.shade600;
        lightBg = Colors.purple.shade50;
        textColor = Colors.purple.shade800;
        statusIcon = LucideIcons.truck;
        break;
      case 'Selesai':
        themeColor = Colors.green.shade600;
        lightBg = Colors.green.shade50;
        textColor = Colors.green.shade800;
        statusIcon = LucideIcons.checkCircle2;
        break;
      case 'Dibatalkan':
        themeColor = Colors.red.shade600;
        lightBg = Colors.red.shade50;
        textColor = Colors.red.shade800;
        statusIcon = LucideIcons.xCircle;
        break;
      default:
        themeColor = Colors.grey;
        lightBg = Colors.grey.shade50;
        textColor = Colors.grey.shade800;
        statusIcon = LucideIcons.helpCircle;
    }

    // Auto-cancel deadline calculation
    String? deadlineText;
    bool isUrgent = false;

    if ((status == 'Menunggu' || status == 'Diproses') &&
        (data['createdAt'] != null || data['updatedAt'] != null)) {
      final isMenunggu = status == 'Menunggu';
      final int deadlineDays = isMenunggu ? 3 : 7;
      final DateTime baseTime = isMenunggu
          ? (data['createdAt'] as Timestamp).toDate()
          : ((data['updatedAt'] as Timestamp?)?.toDate() ??
              (data['createdAt'] as Timestamp).toDate());

      final deadline = baseTime.add(Duration(days: deadlineDays));
      final remaining = deadline.difference(DateTime.now());

      if (!remaining.isNegative) {
        final days = remaining.inDays;
        final hours = remaining.inHours % 24;
        deadlineText =
            days > 0 ? "$days hari $hours jam lagi" : "$hours jam lagi";
        isUrgent = remaining.inHours < 24;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(color: Colors.grey.shade200), // border-gray-100
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4, // shadow-md
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === HEADER ===
          // bg-gradient-to-r from-gray-50 to-blue-50
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade50, Colors.blue.shade50],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // Store Icon
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade500, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSeller ? LucideIcons.user : LucideIcons.store,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                // Store/Buyer Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSeller
                            ? (data['buyerName'] ?? "Pembeli")
                            : (data['sellerName'] ?? "Toko"),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF111827), // text-gray-900
                        ), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "#${orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: lightBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: textColor),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // === INFO BOXES ===
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              children: [
                // Cancel Pending Warning (Highest Priority)
                if (data['cancelRequested'] == true && !isSeller)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade50, Colors.amber.shade50],
                      ),
                      border: Border.all(color: Colors.orange.shade300, width: 2), // border-2
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade500,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.alertCircle, size: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Menunggu konfirmasi penjual",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(LucideIcons.clock, size: 12, color: Colors.orange.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getRelativeDeadline(data), // Dynamic Deadline
                                    style: const TextStyle(fontSize: 10, color: Color(0xFFC2410C)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                // Seller Cancel Request Incoming
                if (data['cancelRequested'] == true && isSeller)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.alertTriangle, size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Pembeli mengajukan pembatalan",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 12, 
                                color: Colors.red.shade900
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Tracking & Estimate for 'Diantar' (Dikirim)
                if (status == 'Diantar') ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                           children: [
                              Icon(LucideIcons.mapPin, size: 16, color: Colors.purple.shade700),
                              const SizedBox(width: 8),
                              Text("No. Resi", style: TextStyle(fontSize: 11, color: Colors.purple.shade700)),
                           ],
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          "JNE123456789", // Mock
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple.shade900),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.truck, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                              children: [
                                TextSpan(text: "Estimasi: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: "Tiba ${_getDeliveryEstimation(data)}"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // General Deadline Warning
                if (deadlineText != null && data['cancelRequested'] != true && status != 'Dibatalkan' && status != 'Selesai' && status != 'Diantar')
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade50, Colors.orange.shade50],
                      ),
                      border: Border.all(color: Colors.amber.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade500,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.alertCircle, size: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSeller 
                                    ? (status == 'Menunggu' ? "Segera proses pesanan" : "Segera kirim paket")
                                    : (status == 'Menunggu' ? "Menunggu konfirmasi penjual" : "Menunggu pengiriman"),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(LucideIcons.clock, size: 12, color: Colors.amber.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    status == 'Diproses' 
                                        ? "Batas kirim: ${_getProcessingDeadline(data)}"
                                        : "Batas waktu: $deadlineText",
                                    style: TextStyle(fontSize: 10, color: Colors.amber.shade700),
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
            ),
          ),
          

          
          // === ITEMS LIST ===
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image with Badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 64, height: 64, // w-16 h-16
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                              image: (item['image'] != null && item['image'] != "")
                                  ? DecorationImage(
                                      image: NetworkImage(item['image']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (item['image'] == null || item['image'] == "")
                                ? const Icon(LucideIcons.image, color: Colors.grey)
                                : null,
                          ),
                          // Qty Badge (top right)
                          Positioned(
                            top: -6, right: -6,
                            child: Container(
                              width: 20, height: 20, // w-5 h-5
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "${item['qty'] ?? 1}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              item['name'] ?? "Produk",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13, // text-sm
                                color: Color(0xFF111827), // text-gray-900
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${item['qty'] ?? 1}x barang",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(((item['price'] ?? 0) * (item['qty'] ?? 1)).toInt()),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          
          // Summary text
          if (items.length > 0)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 8),
              child: Text(
                "${items.fold<int>(0, (sum, item) => sum + ((item['qty'] ?? 1) as int))} barang total • ${items.length} jenis produk",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),

          // === FOOTER ===
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade50, Colors.blue.shade50],
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                // Total Price Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Pesanan",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      currencyFormat.format(totalPrice),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
                
                // === ACTION BUTTONS ===

                  
                  if (status != 'Dibatalkan') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // --- LEFT BUTTON ---
                      if (!isSeller) ...[
                        if (status == 'Menunggu')
                          Expanded(
                            child: (data['cancelRequested'] == true) 
                             ? ElevatedButton.icon( 
                                  onPressed: null,
                                  icon: const Icon(LucideIcons.clock, size: 14),
                                  label: const Text("Menunggu Persetujuan", style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade300,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                               )
                             : Container( // Ajukan Batal
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [Colors.red.shade500, Colors.red.shade600]),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showCancelOrderDialog(orderId, data),
                                    icon: const Icon(LucideIcons.alertCircle, size: 14, color: Colors.white),
                                    label: const Text("Ajukan Batal", style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                               ),
                          )
                        else if (status == 'Diantar')
                          Expanded( // Lacak Paket
                            child: OutlinedButton.icon(
                              onPressed: () => _showTrackingDialog("JNE123456789"),
                              icon: const Icon(LucideIcons.truck, size: 14),
                              label: const Text("Lacak Paket", style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.blue.shade600),
                                foregroundColor: Colors.blue.shade600,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          )
                        else if (status == 'Selesai')
                          Expanded( // Pesan Lagi
                            child: OutlinedButton(
                              onPressed: () => _handleReorder(items),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                foregroundColor: Colors.grey.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Pesan Lagi", style: TextStyle(fontSize: 12)),
                            ),
                          ),
                      ] else ...[  
                        // SELLER LEFT BUTTONS
                        if (data['cancelRequested'] == true)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _handleCancelRequest(orderId, false),
                              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), foregroundColor: Colors.grey.shade700, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: const Text("Tolak", style: TextStyle(fontSize: 12)),
                            ),
                          )
                      ],

                      // --- RIGHT BUTTON (Review / Hubungi / Terima) ---
                      // Only show if NOT (Selesai AND allReviewed AND !isSeller)
                      // Because if Selesai & allReviewed (and buyer), we only want Pesan Lagi (which is already expanded above)
                      // If Selesai & !allReviewed (and buyer), we show Review button.
                      if (!(status == 'Selesai' && !isSeller && allReviewed)) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: (status == 'Selesai' && !isSeller)
                                    ? [Colors.orange.shade500, Colors.orange.shade600] // Orange for Review
                                    : (isSeller && data['cancelRequested'] == true) 
                                        ? [Colors.red.shade500, Colors.red.shade600] // Red for Seller Approve Cancel
                                        : (status == 'Diantar' && !isSeller)
                                           ? [Colors.green.shade600, Colors.green.shade700] // Green for Receive
                                           : [Colors.blue.shade600, Colors.blue.shade700], // Blue for others
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: (status == 'Selesai' && !isSeller) ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                                  blurRadius: 4, offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (isSeller) {
                                  if (data['cancelRequested'] == true) _handleCancelRequest(orderId, true);
                                  else if (status == 'Menunggu') _updateOrderStatus(orderId, 'Diproses');
                                  else if (status == 'Diproses') _updateOrderStatus(orderId, 'Diantar');
                                  else if (status == 'Diantar') toastification.show(context: context, title: const Text("Menunggu konfirmasi Buyer"));
                                } else {
                                  // Buyer Actions
                                  if (status == 'Menunggu' || status == 'Diproses') {
                                    _navigateToChat(data); // Hubungi
                                  } else if (status == 'Diantar') {
                                    _confirmOrderReceived(orderId);
                                  } else if (status == 'Selesai') {
                                    _handleReviewAction(items, data['shopId'] ?? data['sellerId'] ?? "", orderId);
                                  }
                                }
                              },
                              icon: Icon(
                                  (status == 'Selesai' && !isSeller) ? LucideIcons.star :
                                  (status == 'Diantar' && !isSeller) ? LucideIcons.check :
                                  (isSeller && data['cancelRequested'] == true) ? LucideIcons.check :
                                  LucideIcons.messageSquare, // Default icon
                                  size: 14, color: Colors.white
                              ),
                              label: Text(
                                isSeller 
                                    ? (data['cancelRequested'] == true ? "Setuju Batal" : 
                                       status == 'Menunggu' ? "Proses Pesanan" : 
                                       status == 'Diproses' ? "Kirim Barang" : "Hubungi Buyer")
                                    : (status == 'Diantar' ? "Terima" : 
                                       status == 'Selesai' ? "Beri Ulasan" :
                                       "Hubungi"), 
                                style: const TextStyle(fontSize: 11)
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Handle seller approve/reject cancellation request
  Future<void> _handleCancelRequest(String orderId, bool approve) async {
    try {
      await MarketService().handleCancelRequest(orderId, approve);
      if (mounted) {
        toastification.show(
          context: context,
          title: Text(approve ? "Pembatalan Disetujui" : "Pembatalan Ditolak"),
          type: approve ? ToastificationType.success : ToastificationType.info,
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

  // --- NEW ACTIONS HELPER METHODS ---

  void _navigateToChat(Map<String, dynamic> data) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final isSeller = widget.isSellerMode;
    // If I am seller, target is buyer. If I am buyer, target is seller.
    final String targetUid = isSeller ? (data['buyerId'] ?? "") : (data['sellerId'] ?? data['shopId'] ?? "");
    final String targetName = isSeller ? (data['buyerName'] ?? "Pembeli") : (data['sellerName'] ?? data['shopName'] ?? "Toko");
    final String targetImage = isSeller ? (data['buyerImage'] ?? "") : (data['sellerImage'] ?? data['shopImage'] ?? "");

    if (targetUid.isEmpty) {
       toastification.show(context: context, title: const Text("Data user tidak valid"), type: ToastificationType.error);
       return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          targetUid: targetUid,
          targetName: targetName,
          targetImage: targetImage,
        ),
      ),
    );
  }

  void _showTrackingDialog(String resi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.truck, color: Colors.blue),
            const SizedBox(width: 8),
            const Text("Lacak Paket"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("No. Resi:", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            SelectableText(
              resi,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // Mock Timeline
            _buildTimelineItem("Paket sedang diantar ke alamat tujuan", "Sedang Berjalan", true),
            _buildTimelineItem("Paket keluar dari hub Jakarta", "Kemarin, 14:00", false),
            _buildTimelineItem("Penjual telah mengirim paket", "Kemarin, 10:00", false),
          ],
        ),
        actions: [
        ],
      ),
    );
  }

  // Handle Re-order (Pesan Lagi)
  Future<void> _handleReorder(List<dynamic> items) async {
    try {
      await MarketService().reorderItems(items);
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text("Berhasil Ditambahkan"),
          description: const Text("Item telah dimasukkan ke keranjang."),
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 3),
        );
        // Optional: Navigate to Cart
        // Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
            context: context, 
            title: Text("Gagal: $e"), 
            type: ToastificationType.error
        );
      }
    }
  }

  // Handle Review Action (Beri Ulasan)
  void _handleReviewAction(List<dynamic> items, String shopId, String orderId) {
    if (items.isEmpty) return;

    // Filter out already reviewed items
    final unreviewedItems = items.where((item) => item['reviewed'] != true).toList();
    
    if (unreviewedItems.isEmpty) {
       toastification.show(context: context, title: const Text("Semua produk sudah diulas"));
       return;
    }

    if (unreviewedItems.length == 1) {
      // Direct Review
      _showReviewDialog(unreviewedItems[0], shopId, orderId);
    } else {
      // Select Product to Review
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Pilih Produk untuk Diulas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ...unreviewedItems.map((item) => ListTile(
                  leading: Container(
                     width: 48, height: 48,
                     decoration: BoxDecoration(
                       color: Colors.grey[200], borderRadius: BorderRadius.circular(8),
                       image: (item['image'] != null && item['image'] != "")
                           ? DecorationImage(image: NetworkImage(item['image']), fit: BoxFit.cover)
                           : null
                     ),
                  ),
                  title: Text(item['name'] ?? "Produk", maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReviewDialog(item, shopId, orderId);
                  },
                )),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    }
  }

  // Show Review Dialog Form
  void _showReviewDialog(Map<String, dynamic> item, String shopId, String orderId) {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text("Beri Ulasan"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item['name'] ?? "Produk", style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  
                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () => setStateSB(() => rating = index + 1.0),
                        icon: Icon(
                          index < rating ? LucideIcons.star : LucideIcons.star,
                          color: index < rating ? Colors.orange : Colors.grey[300],
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: "Tulis ulasan Anda...",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    // Submit
                    String res = await MarketService().submitReview(
                      productId: item['productId'],
                      shopId: shopId,
                      rating: rating,
                      comment: commentController.text,
                      images: [],
                      orderId: orderId, // Passed orderId
                    );
                    
                    if (mounted) {
                      if (res == "SUCCESS") {
                        toastification.show(
                          context: context, 
                          title: const Text("Ulasan Terkirim!"), 
                          description: const Text("Terima kasih atas ulasan Anda."),
                          type: ToastificationType.success
                        );
                      } else {
                        toastification.show(
                          context: context, 
                          title: const Text("Gagal kirim ulasan"), 
                          description: Text(res),
                          type: ToastificationType.error
                        );
                      }
                    }
                  },
                  child: const Text("Kirim"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildTimelineItem(String title, String time, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 2, height: 30, color: Colors.grey.shade200),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRelativeDeadline(Map<String, dynamic> data) {
    // Default deadline: 2 days (48 hours) from creation or cancel request
    // If 'cancelRequested' is true, base it on 'cancelRequestedAt' (if exists) or 'updatedAt'
    
    Timestamp? baseTimeTz;
    if (data['cancelRequested'] == true && data['cancelRequestedAt'] != null) {
      baseTimeTz = data['cancelRequestedAt'] as Timestamp;
    } else {
      baseTimeTz = data['createdAt'] as Timestamp?;
    }

    if (baseTimeTz == null) return "Batas waktu: Segera";

    final baseTime = baseTimeTz.toDate();
    final deadline = baseTime.add(const Duration(hours: 48)); // 2 Days deadline
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return "Batas waktu: Terlewat";
    }

    if (difference.inHours > 24) {
      int days = difference.inDays;
      int hours = difference.inHours % 24;
      return "Batas waktu: $days hari $hours jam lagi";
    } else if (difference.inHours > 0) {
      return "Batas waktu: ${difference.inHours} jam lagi";
    } else {
      return "Batas waktu: ${difference.inMinutes} menit lagi";
    }
  }

  // Helper for "Diproses" (Processing) Deadline - 3 Days
  String _getProcessingDeadline(Map<String, dynamic> data) {
    Timestamp? baseTimeTz = data['updatedAt'] as Timestamp? ?? data['createdAt'] as Timestamp?;
    if (baseTimeTz == null) return "Segera";

    final baseTime = baseTimeTz.toDate();
    final deadline = baseTime.add(const Duration(days: 3)); 
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) return "Terlewat";

    if (difference.inHours > 24) {
      return "${difference.inDays} hari lagi";
    } else {
      return "${difference.inHours} jam lagi";
    }
  }

  // Helper for "Dikirim" (Delivery) Estimation - 4 Days from shipping
  String _getDeliveryEstimation(Map<String, dynamic> data) {
    Timestamp? baseTimeTz = data['updatedAt'] as Timestamp? ?? data['createdAt'] as Timestamp?;
    if (baseTimeTz == null) return "Segera";

    final baseTime = baseTimeTz.toDate();
    final arrival = baseTime.add(const Duration(days: 4)); 
    
    return DateFormat("d MMM yyyy", "id_ID").format(arrival);
  }
}
