import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';
import '../services/firebase_storage_service.dart';
import '../../home/main_wrapper.dart';

// Import Tabs
import './tabs/community_feed_tab.dart';
import './tabs/community_trending_tab.dart';
import './tabs/community_groups_tab.dart';

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
  final FirebaseStorageService _firebaseService = FirebaseStorageService();
  final user = FirebaseAuth.instance.currentUser;
  final Color primaryBrown = const Color(0xFF5D4037);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    // Jika Mas punya widget CreateGroupSheet, aktifkan kode di bawah ini:
    /*
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateGroupSheet(
        firebaseService: _firebaseService,
        currentUser: user!,
        onGroupCreated: (newGroup) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text('Grup berhasil dibuat! 🎉'),
            autoCloseDuration: const Duration(seconds: 2),
          );
        },
      ),
    );
    */
    _showToast("Fitur buat grup akan segera hadir!", ToastificationType.info);
  }

  void _showLoginToast() {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      title: const Text('Silakan login untuk berinteraksi'),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  void _showToast(String msg, ToastificationType type) {
    toastification.show(
      context: context,
      type: type,
      title: Text(msg),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

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
                // TAB 2: TRENDING
                CommunityTrendingTab(),
                // TAB 3: GRUP
                CommunityGroupsTab(onShowCreateGroup: _showCreateGroupModal),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: _showCreatePostModal,
          backgroundColor: primaryBrown,
          elevation: 4,
          child: const Icon(LucideIcons.penTool, color: Colors.white),
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBrown, const Color(0xFF8D6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      // PERBAIKAN: Gunakan SafeArea agar tidak tertutup poni HP/Notch
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // TOMBOL KEMBALI
                  InkWell(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainWrapper(),
                        ),
                        (route) => false,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.arrowLeft,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Komunitas UMKM',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildHeaderIcon(
                    LucideIcons.messageCircle,
                    const ChatScreen(),
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderIcon(
                    LucideIcons.bell,
                    const NotificationScreen(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Cari diskusi, topik, atau anggota...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, Widget destination) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: primaryBrown,
        unselectedLabelColor: Colors.grey,
        indicatorColor: primaryBrown,
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(LucideIcons.home, size: 20), text: 'Beranda'),
          Tab(icon: Icon(LucideIcons.trendingUp, size: 20), text: 'Trending'),
          Tab(icon: Icon(LucideIcons.users, size: 20), text: 'Grup'),
        ],
      ),
    );
  }
}
