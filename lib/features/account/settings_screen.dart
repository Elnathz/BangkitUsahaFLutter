import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF1565C0).withOpacity(0.2)
        : Colors.white; // Wadah biru gelap transparan di dark mode
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = const Color(0xFF1565C0); // Warna Biru Utama

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Pengaturan",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tampilan",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeManager.themeMode,
                    builder: (context, mode, _) {
                      return SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            mode == ThemeMode.dark
                                ? LucideIcons.moon
                                : LucideIcons.sun,
                            size: 20,
                            color: primaryColor,
                          ),
                        ),
                        title: Text(
                          "Mode Gelap",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        subtitle: Text(
                          mode == ThemeMode.dark ? "Aktif" : "Nonaktif",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        value: mode == ThemeMode.dark,
                        activeColor: primaryColor, // Switch jadi biru
                        onChanged: (val) {
                          ThemeManager.toggleTheme(val);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              "Akun",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.logOut,
                    size: 20,
                    color: Colors.red,
                  ),
                ),
                title: const Text(
                  "Keluar Aplikasi",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: () => _handleLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
