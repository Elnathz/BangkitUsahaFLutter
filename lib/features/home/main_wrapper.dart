import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../account/profile_screen.dart'; // Import Profil yang sudah kita buat
import 'dashboard_screen.dart'; // Kita buat setelah ini
import '../finance/transactions_screen.dart'; // Kita buat setelah ini
import '../inventory/products_screen.dart'; // Kita buat setelah ini

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // Daftar Halaman
  final List<Widget> _screens = [
    const DashboardScreen(), // Index 0: Beranda
    const TransactionsScreen(), // Index 1: Keuangan
    const ProductsScreen(), // Index 2: Stok
    const ProfileScreen(), // Index 3: Akun (YANG SUDAH JADI)
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
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.home), label: 'Beranda'),
          NavigationDestination(
            icon: Icon(LucideIcons.wallet),
            label: 'Keuangan',
          ),
          NavigationDestination(icon: Icon(LucideIcons.package), label: 'Stok'),
          NavigationDestination(icon: Icon(LucideIcons.user), label: 'Akun'),
        ],
      ),
    );
  }
}
