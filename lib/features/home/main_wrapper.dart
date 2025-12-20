import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import Pages
import '../account/profile_screen.dart';
import 'dashboard_screen.dart';
import '../finance/transactions_screen.dart';
import '../community/screens/community_page.dart';
import '../inventory/products_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

  // Professional Color Palette
  final Color colVanDike = const Color(0xFF503C37);      // Dark Background
  final Color colTimberwolf = const Color(0xFFD9D1C9);   // Light Highlight
  final Color colSoftStone = const Color(0xFFB7B0A4);    // Inactive Icon

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
        return const TransactionsPage();
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
      // Stack untuk Floating Navigation
      body: Stack(
        children: [
          // 1. CONTENT LAYER
          Positioned.fill(
            child: _getCurrentScreen(),
          ),

          // 2. FLOATING NAVIGATION BAR
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: colVanDike,
                borderRadius: BorderRadius.circular(40),
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
                  _buildProfileItem(4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation Item Widget
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
          color: isSelected ? colTimberwolf : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colVanDike : colSoftStone,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
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

  // Profile Item with Dynamic Photo
  Widget _buildProfileItem(int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colTimberwolf : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            // Dynamic Profile Photo
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

                // Display Photo or User Icon
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
                      backgroundColor: colSoftStone,
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

            // "Akun" Label (Only when selected)
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