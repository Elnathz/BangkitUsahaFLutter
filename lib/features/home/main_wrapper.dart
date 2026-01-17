import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toastification/toastification.dart';

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

class _MainWrapperState extends State<MainWrapper>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

  // PageController for smooth page transitions
  late PageController _pageController;

  // Horizontal drag tracking for edge swipe
  double _dragStartX = 0;
  double _dragDelta = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _checkSecurityRequirement(); // Cek apakah user wajib buat password
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- LOGIK BLOKIR AKUN TANPA PASSWORD ---
  Future<void> _checkSecurityRequirement() async {
    // Tunggu frame selesai dirender agar bisa menampilkan dialog
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (user != null) {
        // Cek provider login
        bool isPhoneLogin = user!.providerData.any((p) => p.providerId == 'phone');
        // Cek apakah sudah punya password (provider 'password')
        // Catatan: user.providerData mungkin tidak langsung update, tapi ini cara standar cek link credential
        bool hasPassword = user!.providerData.any((p) => p.providerId == 'password');

        // Jika login HP dan belum ada password, paksa buat password
        if (isPhoneLogin && !hasPassword) {
          _showForcePasswordDialog();
        }
      }
    });
  }

  void _showForcePasswordDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool isObscure = true;

    showDialog(
      context: context,
      barrierDismissible: false, // TIDAK BISA DITUTUP (BLOKIR)
      builder: (ctx) => PopScope(
        canPop: false, // Tombol back tidak berfungsi
        child: StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Keamanan Diperlukan"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.shieldAlert, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  "Anda login menggunakan Nomor Telepon. Demi keamanan dan kemudahan akses berikutnya, Anda WAJIB membuat kata sandi sekarang.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: isObscure,
                  decoration: InputDecoration(
                    labelText: "Kata Sandi Baru",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(isObscure ? LucideIcons.eye : LucideIcons.eyeOff),
                      onPressed: () => setState(() => isObscure = !isObscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: isObscure,
                  decoration: const InputDecoration(
                    labelText: "Konfirmasi Kata Sandi",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  if (passwordController.text.length < 6) {
                    return; // Validasi sederhana
                  }
                  if (passwordController.text != confirmController.text) {
                    return;
                  }

                  try {
                    // Buat email dummy dari no HP agar bisa dipasangkan dengan password
                    if (user?.email == null && user?.phoneNumber != null) {
                      String dummyEmail = "${user!.phoneNumber!.replaceAll('+', '')}@bangkit.usaha";
                      await user?.updateEmail(dummyEmail);
                    }
                    
                    await user?.updatePassword(passwordController.text);
                    
                    if (context.mounted) {
                      Navigator.pop(ctx); // Tutup dialog jika sukses
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Kata sandi berhasil dibuat!")),
                      );
                    }
                  } catch (e) {
                    // Handle error
                  }
                },
                child: const Text("Simpan & Lanjutkan"),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Handle Community Page Navigation
  void _handleCommunityClose() {
    _animateToPage(0); // Back to Dashboard with animation
  }

  // Animate to specific page with smooth curve
  void _animateToPage(int index) {
    if (index < 0) index = 0;
    if (index > 4) index = 4;
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  // Handle page changes from swipe
  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  // Handle horizontal drag start - detect edge swipe
  void _onHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragDelta = 0;
    _isDragging = true;
  }

  // Handle horizontal drag update
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    _dragDelta = details.globalPosition.dx - _dragStartX;
  }

  // Handle horizontal drag end - navigate if swipe is significant
  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    // Minimum swipe distance (75 pixels) and velocity for navigation
    final velocity = details.primaryVelocity ?? 0;

    if (_dragDelta.abs() > 75 || velocity.abs() > 500) {
      if (_dragDelta > 0 || velocity > 500) {
        // Swipe right -> go to previous page
        if (_selectedIndex > 0) {
          _animateToPage(_selectedIndex - 1);
        }
      } else if (_dragDelta < 0 || velocity < -500) {
        // Swipe left -> go to next page
        if (_selectedIndex < 4) {
          _animateToPage(_selectedIndex + 1);
        }
      }
    }

    _dragDelta = 0;
  }

  // Build pages list
  List<Widget> _buildPages() {
    return [
      const DashboardScreen(),
      const TransactionsScreen(),
      const ProductsScreen(),
      CommunityPage(onClose: _handleCommunityClose),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Stack untuk Floating Navigation
      body: Stack(
        children: [
          // 1. CONTENT LAYER - PageView for smooth swipe navigation
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable default to use custom gesture
              children: _buildPages(),
            ),
          ),

          // 3. EDGE SWIPE ZONES - Transparent gesture areas for navigation
          // Left edge swipe zone
          Positioned(
            left: 0,
            top: 0,
            bottom: 100, // Above nav bar
            width: 60, // Edge zone width
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
            ),
          ),
          // Right edge swipe zone
          Positioned(
            right: 0,
            top: 0,
            bottom: 100,
            width: 60,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
            ),
          ),
          // Top swipe zone (header area)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120, // Header + status bar area
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
            ),
          ),

          // 2. FLOATING LIQUID GLASS NAVIGATION BAR
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    // Liquid Glass Effect - Multi-layer gradient
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.10),
                        Colors.white.withOpacity(0.05),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    // Glass border effect
                    border: Border.all(
                      width: 1.5,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    // Subtle shadow for depth
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: -5,
                        offset: const Offset(0, 10),
                      ),
                      // Inner glow effect
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: -2,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
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
            ),
          ),
        ],
      ),
    );
  }

  // Navigation Item Widget - Liquid Glass Style
  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _animateToPage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
            : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Selected item - subtle glass highlight
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.35),
                    Colors.white.withOpacity(0.15),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.4), width: 1)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF1976D2) // Blue when selected
                  : Colors.grey[600],
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Profile Item with Dynamic Photo - Liquid Glass Style
  Widget _buildProfileItem(int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _animateToPage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.35),
                    Colors.white.withOpacity(0.15),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.4), width: 1)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dynamic Profile Photo
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String? imageUrl;
                String displayName = user?.displayName ?? "User";

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  imageUrl = data?['image'];
                  if (data?['name'] != null && data!['name'].toString().isNotEmpty) {
                    displayName = data['name'];
                  } else if (data?['storeName'] != null && data!['storeName'].toString().isNotEmpty) {
                    displayName = data['storeName'];
                  }
                }

                // Display Photo or User Icon
                if (imageUrl != null && imageUrl.isNotEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1976D2)
                            : Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(imageUrl),
                      backgroundColor: Colors.grey[300],
                    ),
                  );
                } else {
                  return Icon(
                    LucideIcons.user,
                    color: isSelected
                        ? const Color(0xFF1976D2)
                        : Colors.grey[600],
                    size: 22,
                  );
                }
              },
            ),

            // "Akun" Label (Only when selected)
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Text(
                "Akun",
                style: TextStyle(
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
