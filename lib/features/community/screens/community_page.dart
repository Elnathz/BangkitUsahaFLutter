import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_storage_service.dart';

// Import Tabs
import './tabs/community_feed_tab.dart';
import './tabs/community_groups_tab.dart';

// Import Widgets
import '../widgets/create_group_modal.dart';

// Import Chat & Notification
import '../../chat/chat_screen.dart';
import '../../notifications/notification_screen.dart';
import '../widgets/create_post_dialog.dart';

class CommunityPage extends StatefulWidget {
  final VoidCallback onClose;

  const CommunityPage({super.key, required this.onClose});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';
  bool _showSearch = false; // Toggle search bar visibility
  final FirebaseStorageService _firebaseService = FirebaseStorageService();
  final user = FirebaseAuth.instance.currentUser;
  final Color primaryBrown = Colors.black;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Listen to tab changes to rebuild custom tabs
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- MODAL HANDLERS ---
  void _showCreatePostModal() {
    if (user == null) {
      _showLoginToast();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostSheet(
        firebaseService: _firebaseService,
        currentUser: user!,
        onSuccess: () {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text('Postingan berhasil dibuat! 🎉'),
            autoCloseDuration: const Duration(seconds: 2),
          );
        },
      ),
    );
  }

  void _showCreateGroupModal() {
    if (user == null) {
      _showLoginToast();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateGroupModal(
        onClose: () => Navigator.pop(context),
        onSuccess: () {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text('Grup berhasil dibuat! 🎉'),
            autoCloseDuration: const Duration(seconds: 2),
          );
        },
      ),
    );
  }

  void _showLoginToast() {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      title: const Text('Silakan login untuk berinteraksi'),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  // _showToast removed (not referenced)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      resizeToAvoidBottomInset:
          false, // PENTING: Mencegah layout rusak saat keyboard muncul
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: BERANDA (FEED)
                CommunityFeedTab(
                  firebaseService: _firebaseService,
                  searchQuery: searchQuery,
                  onShowCreatePost: _showCreatePostModal,
                ),
                // TAB 2: GRUP
                CommunityGroupsTab(onShowCreateGroup: _showCreateGroupModal),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Tooltip(
        message: 'Buat Postingan',
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100, right: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showCreatePostModal,
                borderRadius: BorderRadius.circular(30),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(LucideIcons.plus, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar: Title + Action Icons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Komunitas',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Changed to white
                        ),
                      ),
                      Row(
                        children: [
                          // Search Toggle Button
                          _buildActionIcon(
                            icon: LucideIcons.search,
                            onTap: () =>
                                setState(() => _showSearch = !_showSearch),
                            color: Colors.white, // Explicit white color
                          ),
                          const SizedBox(width: 8),
                          // Notifications Button with Badge
                          _buildActionIcon(
                            icon: LucideIcons.bell,
                            showBadge: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationScreen(),
                              ),
                            ),
                            color: Colors.white, // Explicit white color
                          ),
                          const SizedBox(width: 8),
                          // Messages Button
                          _buildActionIcon(
                            icon: LucideIcons.messageSquare,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChatScreen(),
                              ),
                            ),
                            color: Colors.white, // Explicit white color
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search Bar (Toggleable)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: _showSearch ? 60 : 0,
                  child: _showSearch
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              autofocus: true,
                              onChanged: (val) =>
                                  setState(() => searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Cari di Komunitas...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(
                                  LucideIcons.search,
                                  color: Colors.grey[500],
                                  size: 20,
                                ),
                                suffixIcon: searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          LucideIcons.x,
                                          size: 18,
                                          color: Colors.grey[500],
                                        ),
                                        onPressed: () =>
                                            setState(() => searchQuery = ''),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    bool showBadge = false,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: color ?? Colors.white, size: 20),
            if (showBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCustomTab(
              index: 0,
              icon: LucideIcons.messageCircle,
              label: 'Feed',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCustomTab(
              index: 1,
              icon: LucideIcons.users,
              label: 'Grup',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isActive = _tabController.index == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? const Color(0xFF1976D2) : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF1976D2) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
