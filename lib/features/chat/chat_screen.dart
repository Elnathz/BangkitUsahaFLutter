import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor; // Warna Cokelat Kita
    final textColor = isDark ? Colors.white : Colors.black87;

    // Data Dummy sesuai gambar referensi
    final List<Map<String, dynamic>> chats = [
      {
        "name": "Budi Santoso",
        "message": "Terima kasih, produknya sudah sampai",
        "time": "10:30",
        "unread": 0,
        "isOnline": true,
        "avatar": null, // Nanti pakai inisial
      },
      {
        "name": "Siti Aminah",
        "message": "Apakah produk ready stock?",
        "time": "09:15",
        "unread": 2, // Badge pesan
        "isOnline": false,
        "avatar": "https://via.placeholder.com/150",
      },
      {
        "name": "Ahmad Yani",
        "message": "Oke, saya transfer sekarang",
        "time": "Kemarin",
        "unread": 0,
        "isOnline": false,
        "avatar": null,
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Chat",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari chat...",
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: Colors.grey[400],
                  size: 20,
                ),
                fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const Divider(height: 1),

          // LIST CHAT
          Expanded(
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _buildChatTile(chat, textColor, primaryColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(
    Map<String, dynamic> chat,
    Color textColor,
    Color primaryColor,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[300],
            backgroundImage: chat['avatar'] != null
                ? NetworkImage(chat['avatar'])
                : null,
            child: chat['avatar'] == null
                ? Text(
                    chat['name'][0],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  )
                : null,
          ),
          // Indikator Online (Hijau)
          if (chat['isOnline'])
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            chat['name'],
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          Text(
            chat['time'],
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                chat['message'],
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Badge Unread (Warna Cokelat Primary biar serasi tema)
            if (chat['unread'] > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "${chat['unread']}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
      onTap: () {}, // Nanti masuk ke detail chat
    );
  }
}
