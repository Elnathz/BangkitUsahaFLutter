import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/trending_topic.dart';
import '../models/group.dart';
import '../widgets/post_card.dart';
import 'community_topic_detail_page.dart';
import 'community_group_detail_page.dart';
import '../widgets/comments_dialog.dart';
import '../services/firebase_storage_service.dart';

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
  String selectedCategory = 'Semua';
  
  // State untuk kontrol UI
  bool isCreatePostDialogOpen = false;
  
  // Firebase Service
  final FirebaseStorageService _firebaseService = FirebaseStorageService();

  // Data Dummy (Bisa diganti dengan StreamBuilder/FutureBuilder ke Firebase)
  List<String> joinedGroups = ['1'];
  List<Post> posts = [
    Post(
      id: '1',
      author: Author(
        name: 'Ibu Sari',
        avatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
        businessName: 'Toko Kue Sari',
        verified: true,
      ),
      content: 'Alhamdulillah hari ini berhasil jual 50 box kue lapis! Tips dari saya: konsisten dengan kualitas dan pelayanan. Terima kasih untuk tips dari komunitas ini 🙏',
      image: 'https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?w=600',
      category: 'Sharing Pengalaman',
      likes: 128,
      comments: 24,
      shares: 8,
      timestamp: '2 jam lalu',
      isLiked: false,
      isBookmarked: false,
    ),
    // ... tambahkan data dummy lain jika perlu
  ];

  final List<CommunityGroup> groups = [
    CommunityGroup(
      id: '1',
      name: 'UMKM Makanan & Minuman',
      members: 2450,
      posts: 1234,
      image: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=200',
    ),
    CommunityGroup(
      id: '2',
      name: 'Fashion & Kerajinan',
      members: 1890,
      posts: 892,
      image: 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=200',
    ),
  ];

  final List<TrendingTopic> trendingTopics = [
    TrendingTopic(
      id: '1',
      title: 'Tips Meningkatkan Penjualan',
      posts: 234,
      icon: LucideIcons.trendingUp,
    ),
    TrendingTopic(
      id: '2',
      title: 'Packaging Ramah Lingkungan',
      posts: 156,
      icon: LucideIcons.package,
    ),
  ];

  final List<String> categories = [
    'Semua', 'Tips Bisnis', 'Tanya Jawab', 'Sharing Pengalaman', 'Testimoni', 'Event',
  ];

  // Theme Colors
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

  // --- LOGIC HELPERS ---

  List<Post> get filteredPosts {
    return posts.where((post) {
      final matchesSearch = searchQuery.isEmpty ||
          post.content.toLowerCase().contains(searchQuery.toLowerCase()) ||
          post.author.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory =
          selectedCategory == 'Semua' || post.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showToast(String msg, ToastificationType type) {
    toastification.show(
      context: context,
      title: Text(msg),
      type: type,
      autoCloseDuration: const Duration(seconds: 2),
      alignment: Alignment.topCenter,
    );
  }

  // --- MODAL HANDLERS ---

  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostSheet(
        firebaseService: _firebaseService,
        onPostCreated: (newPost) {
          setState(() {
            posts.insert(0, newPost);
          });
          _showToast('Postingan berhasil dibuat! 🎉', ToastificationType.success);
        },
      ),
    );
  }

  void _showCreateGroupModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateGroupSheet(
        onGroupCreated: (newGroup) {
          setState(() {
            groups.insert(0, newGroup);
            joinedGroups.add(newGroup.id);
          });
          _showToast('Grup berhasil dibuat! 🎉', ToastificationType.success);
        },
      ),
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
                _buildFeedTab(),
                _buildTrendingTab(),
                _buildGroupsTab(),
              ],
            ),
          ),
        ],
      ),
      // --- POSISI TOMBOL OPTIMAL ---
      // Bottom padding 120 aman karena Nav Bar tingginya ~94 (70 height + 24 margin)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: FloatingActionButton(
          onPressed: _showCreatePostModal,
          backgroundColor: primaryBrown,
          elevation: 4,
          child: const Icon(LucideIcons.penTool, color: Colors.white),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBrown, const Color(0xFF503C37)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Komunitas UMKM',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              _buildHeaderIcon(LucideIcons.messageCircle, const ChatScreen()),
              const SizedBox(width: 8),
              _buildHeaderIcon(LucideIcons.bell, const NotificationScreen()),
            ],
          ),
          const SizedBox(height: 16),
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
                prefixIcon: Icon(LucideIcons.search, color: Colors.grey[400], size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, Widget destination) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
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
        tabs: const [
          Tab(icon: Icon(LucideIcons.home, size: 20), text: 'Beranda'),
          Tab(icon: Icon(LucideIcons.trendingUp, size: 20), text: 'Trending'),
          Tab(icon: Icon(LucideIcons.users, size: 20), text: 'Grup'),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 0, bottom: 100),
      children: [
        // Create Post Trigger
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: InkWell(
            onTap: _showCreatePostModal,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.edit3, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Apa yang Anda pikirkan?', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
        
        // Categories
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (val) => setState(() => selectedCategory = category),
                    backgroundColor: Colors.white,
                    selectedColor: primaryBrown,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    checkmarkColor: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        const SizedBox(height: 8),

        // Posts List
        if (filteredPosts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: Text('Belum ada postingan')),
          )
        else
          ...filteredPosts.map((post) => Container(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            child: PostCard(
              post: post,
              onLike: () {},
              onComment: () {},
              onShare: () {},
              onBookmark: () {},
            ),
          )),
      ],
    );
  }

  Widget _buildTrendingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('🔥 Topik Trending', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...trendingTopics.map((topic) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
              child: Icon(topic.icon, color: Colors.deepOrange),
            ),
            title: Text(topic.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${topic.posts} diskusi'),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () {},
          ),
        )),
      ],
    );
  }

  Widget _buildGroupsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('👥 Grup Populer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _showCreateGroupModal,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Buat Grup'),
              style: TextButton.styleFrom(foregroundColor: primaryBrown),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...groups.map((group) {
          final isJoined = joinedGroups.contains(group.id);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(group.image, width: 50, height: 50, fit: BoxFit.cover),
              ),
              title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${group.members} anggota • ${group.posts} postingan'),
              trailing: isJoined 
                ? const Icon(LucideIcons.checkCircle, color: Colors.green)
                : OutlinedButton(
                    onPressed: () => setState(() => joinedGroups.add(group.id)),
                    child: const Text('Gabung'),
                  ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CommunityGroupDetailPage(
                    group: group,
                    posts: posts,
                    onLikePost: (id){},
                    onBookmarkPost: (id){},
                    onSharePost: (id, name){},
                    onCommentClick: (p){},
                    isJoined: isJoined,
                  )),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

// ============================================================================
// WIDGET TAMBAHAN (DIPISAH SUPAYA LEBIH RAPI & OPTIMAL)
// ============================================================================

/// 1. Widget Bottom Sheet untuk Membuat Postingan Baru
class CreatePostSheet extends StatefulWidget {
  final FirebaseStorageService firebaseService;
  final Function(Post) onPostCreated;

  const CreatePostSheet({
    Key? key,
    required this.firebaseService,
    required this.onPostCreated,
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
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _isUploading = true);

    // Simulasi atau Integrasi Firebase Service disini
    // ... (Gunakan widget.firebaseService untuk upload sebenarnya)
    
    await Future.delayed(const Duration(seconds: 1)); // Mock delay

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: Author(name: 'Anda', businessName: 'Bisnis Saya', verified: false),
      content: _contentController.text,
      category: _category,
      image: _imageFile?.path, // Note: In real app, this should be URL from Firebase
      likes: 0,
      comments: 0,
      shares: 0,
      timestamp: 'Baru saja',
      isLiked: false,
      isBookmarked: false,
    );

    widget.onPostCreated(newPost);
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
              const Text('Buat Post Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
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
                      hintText: 'Apa yang ingin Anda bagikan?',
                      border: InputBorder.none,
                    ),
                  ),
                  if (_imageFile != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb 
                            ? Image.network(_imageFile!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                            : Image.file(File(_imageFile!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 8, top: 8,
                          child: InkWell(
                            onTap: () => setState(() => _imageFile = null),
                            child: const CircleAvatar(backgroundColor: Colors.red, radius: 12, child: Icon(LucideIcons.x, size: 14, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          // Toolbar Bottom
          Row(
            children: [
              IconButton(onPressed: _pickImage, icon: const Icon(LucideIcons.image, color: Colors.green)),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                  items: ['Tips Bisnis', 'Tanya Jawab', 'Sharing Pengalaman', 'Promosi']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
                      .toList(),
                  onChanged: (val) => setState(() => _category = val!),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isUploading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037)),
                child: _isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Posting", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 2. Widget Bottom Sheet untuk Membuat Grup Baru (Clean & Validated)
class CreateGroupSheet extends StatefulWidget {
  final Function(CommunityGroup) onGroupCreated;

  const CreateGroupSheet({Key? key, required this.onGroupCreated}) : super(key: key);

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
    await Future.delayed(const Duration(seconds: 1)); // Mock Upload

    final newGroup = CommunityGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      members: 1,
      posts: 0,
      image: _imageFile?.path ?? 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200',
    );

    widget.onGroupCreated(newGroup);
    if (mounted) Navigator.pop(context);
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
                const Text('Buat Grup Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            
            // Image Picker Area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  image: _imageFile != null 
                    ? DecorationImage(
                        image: kIsWeb ? NetworkImage(_imageFile!.path) as ImageProvider : FileImage(File(_imageFile!.path)),
                        fit: BoxFit.cover
                      )
                    : null
                ),
                child: _imageFile == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.camera, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Upload Foto Sampul', style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  : null,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Buat Grup', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}