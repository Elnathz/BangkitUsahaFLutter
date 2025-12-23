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
// Tambahkan ini di paling atas file community_page.dart
import '../../home/main_wrapper.dart';

// Import Tabs
import './tabs/community_feed_tab.dart';
import './tabs/community_trending_tab.dart';
import './tabs/community_groups_tab.dart'; // Pastikan import ini benar

// Import Chat & Notification
import '../../chat/chat_screen.dart';
import '../../notifications/notification_screen.dart';

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

  // HAPUS INI (Tidak lagi diperlukan)
  // final GlobalKey<_CommunityGroupsTabState> _groupsTabKey = GlobalKey();

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateGroupSheet(
        firebaseService: _firebaseService,
        currentUser: user!,
        onGroupCreated: (newGroup) {
          // UPDATE: Tidak perlu update state manual lagi.
          // Karena data sudah tersimpan di Firebase,
          // StreamBuilder di CommunityGroupsTab akan otomatis mendeteksi perubahan.

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
                // PERBAIKAN: Panggil tanpa GlobalKey
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

  // --- WIDGET HELPER SAMA SEPERTI SEBELUMNYA ---
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBrown, const Color(0xFF8D6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              // --- UPDATE TOMBOL KEMBALI DI SINI ---
              // GANTI IconButton LAMA DENGAN INI:
              InkWell(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainWrapper()),
                    (route) => false,
                  );
                },
                borderRadius: BorderRadius.circular(8), // Radius untuk efek riak air (splash)
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), // Background transparan
                    borderRadius: BorderRadius.circular(8), // Radius kotak
                  ),
                  child: const Icon(LucideIcons.arrowLeft,
                      color: Colors.white, size: 20),
                ),
              ),

              // -------------------------------------
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Komunitas UMKM',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildHeaderIcon(LucideIcons.messageCircle, const ChatScreen()),
              const SizedBox(width: 8),
              _buildHeaderIcon(LucideIcons.bell, const NotificationScreen()),
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

// ... CLASS CreatePostSheet dan CreateGroupSheet tetap ada di bawah sini ...
// (Biarkan kode sheet yang sudah kita perbaiki sebelumnya di sini)
// PASTIKAN CreateGroupSheet menggunakan XFile dan upload ke Firebase seperti yang sudah kita perbaiki.
class CreatePostSheet extends StatefulWidget {
  final FirebaseStorageService firebaseService;
  final User currentUser;
  final VoidCallback onSuccess;

  const CreatePostSheet({
    Key? key,
    required this.firebaseService,
    required this.currentUser,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final TextEditingController _contentController = TextEditingController();
  String _category = 'Tips Bisnis';
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imageFile = image);
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty && _imageFile == null) return;

    setState(() => _isUploading = true);

    String finalName = '';
    String businessName = 'UMKM Member';

    try {
      // 1. AMBIL DATA DARI FIRESTORE
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        // --- PERBAIKAN: HANYA AMBIL OWNERNAME ---
        finalName = data['ownerName'] ?? '';
      }
    } catch (e) {
      print("Gagal ambil data user: $e");
    }

    // 2. FALLBACK (Jaga-jaga jika ownerName di database kosong)
    if (finalName.isEmpty) {
      finalName = widget.currentUser.displayName ?? '';
      if (finalName.isEmpty && widget.currentUser.email != null) {
        finalName = widget.currentUser.email!.split('@')[0];
      }
    }

    if (finalName.isEmpty) {
      finalName = 'Pengguna Tanpa Nama';
    }

    // 3. UPLOAD
    await widget.firebaseService.uploadImageAndSavePost(
      imageFile: _imageFile,
      userId: widget.currentUser.uid,
      userName: finalName, // Sekarang menggunakan ownerName
      userAvatar: widget.currentUser.photoURL ?? '',
      businessName: businessName,
      content: _contentController.text,
      category: _category,
      onProgress: (val) {},
    );

    widget.onSuccess();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Buat Post Baru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _contentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Apa yang ingin Anda bagikan kepada komunitas?',
                      border: InputBorder.none,
                    ),
                  ),
                  if (_imageFile != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(
                                  _imageFile!.path,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_imageFile!.path),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: InkWell(
                            onTap: () => setState(() => _imageFile = null),
                            child: const CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 12,
                              child: Icon(
                                LucideIcons.x,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _pickImage,
                icon: const Icon(LucideIcons.image, color: Colors.green),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  items:
                      [
                            'Tips Bisnis',
                            'Tanya Jawab',
                            'Sharing Pengalaman',
                            'Promosi',
                            'Lainnya',
                          ]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _category = val!),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isUploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D4037),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text(
                        "Posting",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreateGroupSheet extends StatefulWidget {
  final Function(CommunityGroup) onGroupCreated;
  final FirebaseStorageService firebaseService;
  final User currentUser;

  const CreateGroupSheet({
    Key? key,
    required this.onGroupCreated,
    required this.firebaseService,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imageFile = image);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? groupId = await widget.firebaseService.createGroup(
      imageFile: _imageFile,
      name: _nameController.text,
      description: _descController.text,
      creatorId: widget.currentUser.uid,
    );

    if (groupId != null) {
      final newGroup = CommunityGroup(
        id: groupId,
        name: _nameController.text,
        members: 1,
        posts: 0,
        image:
            _imageFile?.path ??
            'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200',
      );

      widget.onGroupCreated(newGroup);
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Buat Grup Baru',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _imageFile == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.camera,
                            size: 40,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Upload Foto Sampul',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                            : Image.file(
                                File(_imageFile!.path),
                                fit: BoxFit.cover,
                              ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Grup',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.users),
              ),
              validator: (v) => v!.isEmpty ? 'Nama grup harus diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Deskripsi / Topik',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) => v!.isEmpty ? 'Deskripsi harus diisi' : null,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D4037),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Buat Grup',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
