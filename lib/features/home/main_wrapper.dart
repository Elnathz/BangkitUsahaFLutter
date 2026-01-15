import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Import Pages
import '../account/profile_screen.dart';
import 'dashboard_screen.dart';
import '../finance/screens/transactions_screen.dart';
import '../community/screens/community_page.dart';
import '../inventory/products_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // Handle Community Page Navigation
  void _handleCommunityClose() {
    setState(() {
      _selectedIndex = 0; // Back to Dashboard
    });
  }

  // Get Current Screen based on selected index
  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const TransactionsScreen();
      case 2:
        return const ProductsScreen();
      case 3:
        return CommunityPage(onClose: _handleCommunityClose);
      case 4:
        return const ProfileScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFE5E7EB), // gray-200
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.home, "Beranda"),
                _buildNavItem(1, LucideIcons.wallet, "Keuangan"),
                _buildNavItem(2, LucideIcons.store, "Toko"),
                _buildNavItem(3, LucideIcons.users, "Komunitas"),
                _buildNavItem(4, LucideIcons.user, "Akun"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigation Item Widget - Simple TSX Style
  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF2563EB) // blue-600
                  : const Color(0xFF6B7280), // gray-500
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
