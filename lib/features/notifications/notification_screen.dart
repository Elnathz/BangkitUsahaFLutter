import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    // PERBAIKAN: Tambahkan '!' di belakang Colors.grey[900]
    final Color cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    // Data Dummy
    final List<Map<String, dynamic>> notifications = [
      {
        "title": "Pesanan Baru",
        "body":
            "Anda menerima pesanan baru dari Budi Santoso senilai Rp 75.000",
        "time": "5 menit lalu",
        "type": "order",
        "isRead": false,
      },
      {
        "title": "Pesan Baru",
        "body": "Siti Aminah mengirim pesan: \"Apakah produk ready stock?\"",
        "time": "15 menit lalu",
        "type": "chat",
        "isRead": false,
      },
      {
        "title": "Pengingat Catatan Keuangan",
        "body":
            "Jangan lupa catat transaksi hari ini untuk laporan yang akurat",
        "time": "1 jam lalu",
        "type": "alert",
        "isRead": false,
      },
      {
        "title": "Pencapaian Penjualan",
        "body": "Selamat! Penjualan minggu ini naik 12.5% dari minggu lalu",
        "time": "Kemarin",
        "type": "success",
        "isRead": true,
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Notifikasi",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "3 baru",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          return _buildNotificationCard(
            item,
            cardColor,
            textColor,
            primaryColor,
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> item,
    Color cardColor,
    Color textColor,
    Color primaryColor,
  ) {
    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (item['type']) {
      case 'order':
        icon = LucideIcons.shoppingBag;
        iconBg = Colors.blue.withOpacity(0.1);
        iconColor = Colors.blue;
        break;
      case 'chat':
        icon = LucideIcons.messageCircle;
        iconBg = Colors.purple.withOpacity(0.1);
        iconColor = Colors.purple;
        break;
      case 'alert':
        icon = LucideIcons.alertCircle;
        iconBg = Colors.orange.withOpacity(0.1);
        iconColor = Colors.orange;
        break;
      case 'success':
        icon = LucideIcons.trendingUp;
        iconBg = Colors.green.withOpacity(0.1);
        iconColor = Colors.green;
        break;
      default:
        icon = LucideIcons.bell;
        iconBg = Colors.grey.withOpacity(0.1);
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    if (!item['isRead'])
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['body'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['time'],
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
