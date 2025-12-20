import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import halaman-halaman
import '../account/profile_screen.dart';
import 'dashboard_screen.dart';
import '../finance/transactions_screen.dart';
import '../inventory/products_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  static int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

  // Warna Palet Profesional dari Gambar Anda
  final Color colVanDike = const Color(0xFF503C37); // Background Gelap
  final Color colTimberwolf = const Color(0xFFD9D1C9); // Highlight Terang
  final Color colSoftStone = const Color(0xFFB7B0A4); // Icon Mati

  // Daftar Halaman
  final List<Widget> _screens = [
    const DashboardScreen(), // 0: Beranda
    const TransactionsPage(), // 1: Keuangan
    const ProductsScreen(), // 2: Toko
    const ProfileScreen(), // 4: Akun
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gunakan Stack agar Navigasi bisa "Melayang" di atas konten
      body: Stack(
        children: [
          // 1. KONTEN HALAMAN (Di Lapis Bawah)
          // Kita kasih padding bawah agar konten paling bawah tidak tertutup navigasi
          Positioned.fill(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),

          // 2. CUSTOM FLOATING NAVIGATION BAR (Di Lapis Atas)
          Positioned(
            left: 20,
            right: 20,
            bottom: 24, // Jarak dari bawah layar (Melayang)
            child: Container(
              height: 70, // Tinggi Bar
              decoration: BoxDecoration(
                color: colVanDike, // Warna Background Cokelat Tua (#503C37)
                borderRadius: BorderRadius.circular(40), // Sudut sangat bulat
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(0, LucideIcons.home, "Beranda"),
                  _buildNavItem(1, LucideIcons.wallet, "Keuangan"),
                  _buildNavItem(2, LucideIcons.store, "Toko"),
                  _buildNavItem(3, LucideIcons.users, "Komunitas"),
                  _buildProfileItem(4), // Item khusus untuk Foto Profil
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk Item Navigasi Biasa
  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
            : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colTimberwolf
              : Colors.transparent, // Warna pill aktif (#D9D1C9)
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colVanDike
                  : colSoftStone, // Icon gelap jika aktif, abu jika mati
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colVanDike, // Teks warna gelap (#503C37) agar kontras
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget Khusus Item Profil (Dengan StreamBuilder Foto)
  Widget _buildProfileItem(int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: isSelected
            ? const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ) // Padding beda dikit biar muat foto
            : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colTimberwolf : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            // FOTO PROFIL DINAMIS
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String? imageUrl;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  imageUrl = data?['image'];
                }

                // Tampilan Foto / Icon User
                if (imageUrl != null && imageUrl.isNotEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colVanDike : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                  );
                } else {
                  return Icon(
                    LucideIcons.user,
                    color: isSelected ? colVanDike : colSoftStone,
                    size: 24,
                  );
                }
              },
            ),

            // LABEL "AKUN" (Hanya muncul jika dipilih)
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                "Akun",
                style: TextStyle(
                  color: colVanDike,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
