import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // Fungsi untuk menandai notifikasi sudah dibaca
  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint("Gagal update status baca: $e");
    }
  }

  // Fungsi untuk mendapatkan icon berdasarkan tipe notifikasi
  IconData _getIcon(String type) {
    switch (type) {
      case 'order_incoming':
        return LucideIcons.packagePlus; // Pesanan Masuk
      case 'order_update':
        return LucideIcons.truck; // Status Pengiriman
      case 'stock_empty':
        return LucideIcons.alertTriangle; // Stok Habis
      case 'wallet':
        return LucideIcons.wallet; // Uang Masuk
      default:
        return LucideIcons.bell;
    }
  }

  // Fungsi untuk mendapatkan warna icon
  Color _getIconColor(String type) {
    switch (type) {
      case 'order_incoming':
        return Colors.blue;
      case 'order_update':
        return Colors.green;
      case 'stock_empty':
        return Colors.red;
      case 'wallet':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    return DateFormat('dd MMM HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Notifikasi")),
        body: const Center(child: Text("Silakan login terlebih dahulu.")),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Notifikasi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: user!.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.bellOff, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada notifikasi",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isRead = data['isRead'] ?? false;
              final String type = data['type'] ?? 'general';

              return InkWell(
                onTap: () {
                  // 1. Tandai sudah dibaca (Titik merah dashboard hilang)
                  if (!isRead) {
                    _markAsRead(doc.id);
                  }

                  // 2. (Opsional) Navigasi ke detail jika diperlukan
                  // Misal: Navigator.push(...) ke halaman Detail Order
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead
                        ? (isDark ? const Color(0xFF112240) : Colors.white)
                        : (isDark
                              ? const Color(0xFF1A3050)
                              : const Color(0xFFF0F7FF)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRead
                          ? Colors.grey.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Bulat
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getIconColor(type).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(type),
                          color: _getIconColor(type),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Konten Teks
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['title'] ?? "Notifikasi Baru",
                                    style: TextStyle(
                                      fontWeight: isRead
                                          ? FontWeight.w600
                                          : FontWeight.bold,
                                      fontSize: 14,
                                      color: isRead
                                          ? (isDark
                                                ? Colors.white70
                                                : Colors.black87)
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['body'] ?? "",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(data['createdAt']),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
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
      ),
    );
  }
}
