import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import halaman-halaman yang sudah ada
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
  final user = FirebaseAuth.instance.currentUser;

  // Daftar Halaman
  final List<Widget> _screens = [
    const DashboardScreen(), // 0: Beranda
    const TransactionsScreen(), // 1: Keuangan
    const ProductsScreen(), // 2: Toko (Produk)
    // 3: HALAMAN KOMUNITAS (Sementara pakai Placeholder dulu)
    const Scaffold(
      body: Center(
        child: Text(
          "Halaman Komunitas Segera Hadir!",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    ),

    const ProfileScreen(), // 4: Akun
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
          // 1. Beranda
          const NavigationDestination(
            icon: Icon(LucideIcons.home),
            label: 'Beranda',
          ),

          // 2. Keuangan
          const NavigationDestination(
            icon: Icon(LucideIcons.wallet),
            label: 'Keuangan',
          ),

          // 3. Toko
          const NavigationDestination(
            icon: Icon(LucideIcons.store),
            label: 'Toko',
          ),

          // 4. KOMUNITAS (BARU DITAMBAHKAN)
          const NavigationDestination(
            icon: Icon(LucideIcons.users), // Ikon orang banyak/grup
            label: 'Komunitas',
          ),

          // 5. Akun (Dengan Foto Profil Dinamis)
          NavigationDestination(
            label: 'Akun',
            icon: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final imageUrl = data?['image'];

                  if (imageUrl != null && imageUrl.toString().isNotEmpty) {
                    return CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: NetworkImage(imageUrl),
                    );
                  }
                }
                return const Icon(LucideIcons.user);
              },
            ),
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
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(imageUrl),
                      ),
                    );
                  }
                }
                return const Icon(LucideIcons.user, fill: 1.0);
              },
            ),
          ),
        ],
      ),
    );
  }
}
