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
  int _selectedIndex = 0;
  final user =
      FirebaseAuth.instance.currentUser; // Ambil user yang sedang login

  // Daftar Halaman
  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const ProductsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(LucideIcons.home),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(LucideIcons.wallet),
            label: 'Keuangan',
          ),
          const NavigationDestination(
            icon: Icon(LucideIcons.package),
            label: 'Stok',
          ),

          // --- BAGIAN INI YANG DIUBAH (ICON PROFIL DINAMIS) ---
          NavigationDestination(
            label: 'Akun',
            // Gunakan StreamBuilder agar update realtime saat foto berubah
            icon: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                // 1. Jika Data User ada & field 'image' tidak kosong
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final imageUrl = data?['image'];

                  if (imageUrl != null && imageUrl.toString().isNotEmpty) {
                    return CircleAvatar(
                      radius: 12, // Ukuran kecil pas untuk navbar
                      backgroundColor: Colors.grey[300],
                      backgroundImage: NetworkImage(imageUrl),
                    );
                  }
                }

                // 2. Jika belum ada foto, tampilkan Icon User biasa
                return const Icon(LucideIcons.user);
              },
            ),
            // Agar saat diklik (selected) fotonya tetap ada tapi ada border/highlight otomatis dari navbar
            selectedIcon: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final imageUrl = data?['image'];

                  if (imageUrl != null && imageUrl.toString().isNotEmpty) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ), // Tambah border biar kelihatan aktif
                      ),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(imageUrl),
                      ),
                    );
                  }
                }
                return const Icon(
                  LucideIcons.user,
                  fill: 1.0,
                ); // Icon user terisi jika selected
              },
            ),
          ),

          // ----------------------------------------------------
        ],
      ),
    );
  }
}
