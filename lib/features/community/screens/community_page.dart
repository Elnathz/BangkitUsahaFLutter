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
  bool isCreatePostDialogOpen = false;
  bool isEditMode = false;
  Post? editingPost;

  // Firebase Service
  final FirebaseStorageService _firebaseService = FirebaseStorageService();

  // Create/Edit Post State
  String postContent = '';
  String postCategory = 'Tips Bisnis';
  XFile? pickedImageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _postController = TextEditingController();

  // Create Group State
  bool isCreateGroupDialogOpen = false;
  String groupName = '';
  String groupDescription = '';
  XFile? groupImageFile;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescController = TextEditingController();

  // Upload State
  bool isUploading = false;
  double uploadProgress = 0.0;

  // Theme Colors
  final Color primaryBrown = const Color(0xFF5D4037);
  final Color secondaryBrown = const Color(0xFF8D6E63);
  final Color accentOrange = const Color(0xFFD84315);

  List<String> joinedGroups = ['1'];
  List<Post> posts = [
    Post(
      id: '1',
      author: Author(
        name: 'Ibu Sari',
        avatar:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
        businessName: 'Toko Kue Sari',
        verified: true,
      ),
      content:
          'Alhamdulillah hari ini berhasil jual 50 box kue lapis! Tips dari saya: konsisten dengan kualitas dan pelayanan. Terima kasih untuk tips dari komunitas ini 🙏',
      image:
          'https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?w=600',
      category: 'Sharing Pengalaman',
      likes: 128,
      comments: 24,
      shares: 8,
      timestamp: '2 jam lalu',
      isLiked: false,
      isBookmarked: false,
    ),
    Post(
      id: '2',
      author: Author(
        name: 'Pak Budi',
        avatar:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
        businessName: 'Keripik Nusantara',
        verified: true,
      ),
      content:
          'Mau tanya dong, untuk packaging produk makanan yang menarik tapi harganya terjangkau dimana ya? Mohon sarannya teman-teman 🙏',
      category: 'Tanya Jawab',
      likes: 45,
      comments: 32,
      shares: 5,
      timestamp: '4 jam lalu',
      isLiked: false,
      isBookmarked: true,
    ),
    Post(
      id: '3',
      author: Author(
        name: 'Ibu Dewi',
        avatar:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
        businessName: 'Sambal Dewi',
        verified: false,
      ),
      content:
          'Tips foto produk: gunakan cahaya alami dari jendela, background polos putih/kayu, dan foto dari berbagai sudut. Hasilnya langsung meningkat penjualan 40%! 📸✨',
      image:
          'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=600',
      category: 'Tips Bisnis',
      likes: 256,
      comments: 48,
      shares: 67,
      timestamp: '1 hari lalu',
      isLiked: true,
      isBookmarked: true,
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
    TrendingTopic(
      id: '3',
      title: 'Digital Marketing UMKM',
      posts: 189,
      icon: LucideIcons.monitor,
    ),
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
      image:
          'https://images.unsplash.com/photo-1445205170230-053b83016050?w=200',
    ),
    CommunityGroup(
      id: '3',
      name: 'Digital Marketing UMKM',
      members: 3120,
      posts: 2341,
      image:
          'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=200',
    ),
  ];

  final List<String> categories = [
    'Semua',
    'Tips Bisnis',
    'Tanya Jawab',
    'Sharing Pengalaman',
    'Testimoni',
    'Event',
  ];

  final Map<String, List<Comment>> comments = {
    '1': [
      Comment(
        id: '1',
        author: 'Pak Budi',
        avatar:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
        content: 'Mantap Bu Sari! Konsistensi memang kunci sukses ya 👍',
        timestamp: '1 jam lalu',
        likes: 12,
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    _groupNameController.dispose();
    _groupDescController.dispose();
    super.dispose();
  }

  // Filtered posts with search and category
  List<Post> get filteredPosts {
    return posts.where((post) {
      final matchesSearch = searchQuery.isEmpty ||
          post.content.toLowerCase().contains(searchQuery.toLowerCase()) ||
          post.author.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          post.author.businessName
              .toLowerCase()
              .contains(searchQuery.toLowerCase());

      final matchesCategory =
          selectedCategory == 'Semua' || post.category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void handleCategorySelect(String c) {
    setState(() {
      selectedCategory = c;
    });
    _showToast(
      c == 'Semua' ? 'Menampilkan semua kategori' : 'Filter: $c',
      ToastificationType.info,
    );
  }

  void handleLikePost(String id) {
    setState(() {
      final index = posts.indexWhere((e) => e.id == id);
      if (index != -1) {
        final p = posts[index];
        posts[index] = p.copyWith(
          isLiked: !p.isLiked,
          likes: !p.isLiked ? p.likes + 1 : p.likes - 1,
        );
      }
    });
  }

  void handleBookmarkPost(String id) {
    setState(() {
      final index = posts.indexWhere((e) => e.id == id);
      if (index != -1) {
        final p = posts[index];
        posts[index] = p.copyWith(isBookmarked: !p.isBookmarked);
        _showToast(
          !p.isBookmarked ? 'Disimpan ke bookmark 🔖' : 'Dihapus dari bookmark',
          ToastificationType.success,
        );
      }
    });
  }

  void handleSharePost(String id, String name) {
    _showToast('Membagikan postingan dari $name', ToastificationType.success);
  }

  void handleCommentClick(Post p) {
    _showCommentsDialog(p);
  }

  void handleJoinGroupById(String id, String name) {
    if (!joinedGroups.contains(id)) {
      setState(() {
        joinedGroups.add(id);
      });
      _showToast(
        'Berhasil bergabung dengan grup $name! 🎉',
        ToastificationType.success,
      );
    }
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

  void _showCommentsDialog(Post p) {
    final postComments = comments[p.id] ?? [];
    showDialog(
      context: context,
      builder: (c) => CommentsDialog(
        post: p,
        comments: postComments,
        onAddComment: (s) {
          _showToast(
              'Komentar berhasil ditambahkan! 💬', ToastificationType.success);
        },
      ),
    );
  }

  // ========== CRUD OPERATIONS ==========

  void _showCreatePostDialog() {
    setState(() {
      isEditMode = false;
      editingPost = null;
      postContent = '';
      postCategory = 'Tips Bisnis';
      pickedImageFile = null;
      _postController.clear();
      isCreatePostDialogOpen = true;
    });
  }

  void _showCreateGroupDialog() {
    setState(() {
      groupName = '';
      groupDescription = '';
      groupImageFile = null;
      _groupNameController.clear();
      _groupDescController.clear();
      isCreateGroupDialogOpen = true;
    });
  }

  void _showEditPostDialog(Post post) {
    setState(() {
      isEditMode = true;
      editingPost = post;
      postContent = post.content;
      postCategory = post.category;
      _postController.text = post.content;
      pickedImageFile = null;
      isCreatePostDialogOpen = true;
    });
  }

  void _handleDeletePost(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Postingan'),
        content: const Text('Apakah Anda yakin ingin menghapus postingan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                posts.removeWhere((p) => p.id == post.id);
              });
              Navigator.pop(context);
              _showToast(
                  'Postingan berhasil dihapus! 🗑️', ToastificationType.success);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final sizeInMB = bytes.length / (1024 * 1024);

        if (sizeInMB > 5) {
          _showToast(
            'Ukuran file terlalu besar! Maksimal 5MB (${sizeInMB.toStringAsFixed(2)} MB)',
            ToastificationType.error,
          );
          return;
        }

        setState(() {
          pickedImageFile = image;
        });

        _showToast('Gambar berhasil dipilih! 📷', ToastificationType.success);
      }
    } catch (e) {
      _showToast('Gagal memilih gambar: $e', ToastificationType.error);
    }
  }

  Future<void> _handleSubmitPost() async {
    if (postContent.trim().isEmpty) {
      _showToast(
          'Konten post tidak boleh kosong!', ToastificationType.error);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showToast(
          'Anda harus login terlebih dahulu!', ToastificationType.error);
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    try {
      if (isEditMode && editingPost != null) {
        // UPDATE existing post
        final index = posts.indexWhere((p) => p.id == editingPost!.id);
        if (index != -1) {
          setState(() {
            posts[index] = editingPost!.copyWith(
              content: postContent,
              category: postCategory,
            );
          });
          _showToast(
              'Postingan berhasil diupdate! ✏️', ToastificationType.success);
        }
      } else {
        // CREATE new post with Firebase upload
        String? postId;
        String? imageUrl;

        if (pickedImageFile != null) {
          postId = await _firebaseService.uploadImageAndSavePost(
            imageFile: pickedImageFile!,
            userId: user.uid,
            userName: user.displayName ?? 'User',
            userAvatar: user.photoURL ??
                'https://api.dicebear.com/7.x/avataaars/svg?seed=${user.uid}',
            businessName: 'Toko Saya',
            content: postContent,
            category: postCategory,
            groupId: 'general',
            groupName: 'Komunitas Umum',
            onProgress: (progress) {
              setState(() {
                uploadProgress = progress;
              });
            },
          );
        } else {
          postId = await _firebaseService.savePost(
            userId: user.uid,
            userName: user.displayName ?? 'User',
            userAvatar: user.photoURL ??
                'https://api.dicebear.com/7.x/avataaars/svg?seed=${user.uid}',
            businessName: 'Toko Saya',
            content: postContent,
            category: postCategory,
            groupId: 'general',
            groupName: 'Komunitas Umum',
          );
        }

        if (postId != null) {
          final newPost = Post(
            id: postId,
            author: Author(
              name: user.displayName ?? 'User',
              avatar: user.photoURL ??
                  'https://api.dicebear.com/7.x/avataaars/svg?seed=${user.uid}',
              businessName: 'Toko Saya',
              verified: false,
            ),
            content: postContent,
            image: imageUrl,
            category: postCategory,
            likes: 0,
            comments: 0,
            shares: 0,
            timestamp: 'Baru saja',
            isLiked: false,
            isBookmarked: false,
          );

          setState(() {
            posts.insert(0, newPost);
          });

          _showToast(
              'Postingan berhasil dibuat! 🎉', ToastificationType.success);
        }
      }

      setState(() {
        postContent = '';
        pickedImageFile = null;
        isCreatePostDialogOpen = false;
        isUploading = false;
        uploadProgress = 0.0;
        isEditMode = false;
        editingPost = null;
      });
      _postController.clear();
    } catch (e) {
      _showToast('Gagal menyimpan post: $e', ToastificationType.error);
      setState(() {
        isUploading = false;
        uploadProgress = 0.0;
      });
    }
  }

  void _showPostOptions(Post post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.edit, color: Color(0xFF2563EB)),
              title: const Text('Edit Postingan'),
              onTap: () {
                Navigator.pop(context);
                _showEditPostDialog(post);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Colors.red),
              title: const Text('Hapus Postingan',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleDeletePost(post);
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  // ========== GROUP CRUD OPERATIONS ==========

  Future<void> _handlePickGroupImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final sizeInMB = bytes.length / (1024 * 1024);

        if (sizeInMB > 5) {
          _showToast(
            'Ukuran file terlalu besar! Maksimal 5MB (${sizeInMB.toStringAsFixed(2)} MB)',
            ToastificationType.error,
          );
          return;
        }

        setState(() {
          groupImageFile = image;
        });

        _showToast('Gambar grup berhasil dipilih! 📷', ToastificationType.success);
      }
    } catch (e) {
      _showToast('Gagal memilih gambar: $e', ToastificationType.error);
    }
  }

  Future<void> _handleSubmitGroup() async {
    if (groupName.trim().isEmpty) {
      _showToast('Nama grup tidak boleh kosong!', ToastificationType.error);
      return;
    }

    if (groupDescription.trim().isEmpty) {
      _showToast('Deskripsi grup tidak boleh kosong!', ToastificationType.error);
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    try {
      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          uploadProgress = i / 100;
        });
      }

      // Create new group
      final newGroup = CommunityGroup(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: groupName,
        members: 1,
        posts: 0,
        image: groupImageFile != null
            ? 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200'
            : 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200',
      );

      setState(() {
        groups.insert(0, newGroup);
        joinedGroups.add(newGroup.id);
      });

      _showToast('Grup berhasil dibuat! 🎉', ToastificationType.success);

      setState(() {
        groupName = '';
        groupDescription = '';
        groupImageFile = null;
        isCreateGroupDialogOpen = false;
        isUploading = false;
        uploadProgress = 0.0;
      });
      _groupNameController.clear();
      _groupDescController.clear();
    } catch (e) {
      _showToast('Gagal membuat grup: $e', ToastificationType.error);
      setState(() {
        isUploading = false;
        uploadProgress = 0.0;
      });
    }
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
      floatingActionButton: !isCreatePostDialogOpen
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: FloatingActionButton(
                onPressed: _showCreatePostDialog,
                backgroundColor: primaryBrown,
                child: const Icon(LucideIcons.penTool, color: Colors.white),
              ),
            )
          : null,
      bottomSheet:
          isCreatePostDialogOpen ? _buildCreatePostBottomSheet() : null,
    );
  }

  // HEADER WITH SEARCH, CHAT & NOTIFICATION
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
                icon: const Icon(
                  LucideIcons.arrowLeft,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
                ),
              ),
              Row(
                children: [
                  _buildHeaderIcon(
                    context,
                    LucideIcons.messageCircle,
                    const ChatScreen(),
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderIcon(
                    context,
                    LucideIcons.bell,
                    const NotificationScreen(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari diskusi, topik, atau anggota...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: Colors.grey[400],
                  size: 20,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          color: Colors.grey[400],
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(
    BuildContext context,
    IconData icon,
    Widget? destination, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ??
          (destination != null
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => destination),
                  )
              : null),
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
      padding: const EdgeInsets.only(top: 0),
      children: [
        // 1. Create Post Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEFEBE9),
                backgroundImage: FirebaseAuth.instance.currentUser?.photoURL !=
                        null
                    ? NetworkImage(
                        FirebaseAuth.instance.currentUser!.photoURL!)
                    : null,
                child: FirebaseAuth.instance.currentUser?.photoURL == null
                    ? const Icon(LucideIcons.user, color: Colors.brown)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _showCreatePostDialog,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Text(
                      'Apa yang Anda pikirkan?',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showCreatePostDialog,
                icon: const Icon(LucideIcons.image, color: Colors.green),
              ),
            ],
          ),
        ),

        // 2. Category Chips
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
                    onSelected: (val) => handleCategorySelect(category),
                    backgroundColor: Colors.white,
                    selectedColor: primaryBrown,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected ? primaryBrown : Colors.grey[300]!,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 3. Posts List
        if (filteredPosts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(48),
            child: Center(
              child: Column(
                children: [
                  Icon(LucideIcons.search, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    searchQuery.isNotEmpty
                        ? 'Tidak ada postingan ditemukan untuk "$searchQuery"'
                        : 'Belum ada postingan',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredPosts.map((post) {
            // Check if post is from current user
            final isMyPost = post.author.name == 'Anda' ||
                post.author.name ==
                    (FirebaseAuth.instance.currentUser?.displayName ?? '');

            return Column(
              children: [
                Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      // Post Header with 3-dot menu
                      if (isMyPost)
                        Padding(
                          padding: const EdgeInsets.only(right: 8, top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.moreVertical,
                                    size: 20),
                                onPressed: () => _showPostOptions(post),
                              ),
                            ],
                          ),
                        ),
                      PostCard(
                        post: post,
                        onLike: () => handleLikePost(post.id),
                        onComment: () => handleCommentClick(post),
                        onShare: () =>
                            handleSharePost(post.id, post.author.name),
                        onBookmark: () => handleBookmarkPost(post.id),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),

        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildTrendingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '🔥 Topik Trending',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...trendingTopics.map(
          (topic) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(topic.icon, color: Colors.deepOrange),
              ),
              title: Text(
                topic.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${topic.posts} diskusi'),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityTopicDetailPage(
                      topic: topic,
                      posts: posts,
                      onLikePost: handleLikePost,
                      onBookmarkPost: handleBookmarkPost,
                      onSharePost: handleSharePost,
                      onCommentClick: handleCommentClick,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildGroupsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header with "Create Group" button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '👥 Grup Populer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _showCreateGroupDialog,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Buat Grup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...groups.map((group) {
          final isJoined = joinedGroups.contains(group.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      group.image,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    group.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${group.members.toStringAsFixed(0)} anggota • ${group.posts} postingan',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      if (!isJoined)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              handleJoinGroupById(group.id, group.name);
                            },
                            icon: const Icon(LucideIcons.userPlus, size: 16),
                            label: const Text('Gabung'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryBrown,
                              side: BorderSide(color: primaryBrown),
                            ),
                          ),
                        ),
                      if (!isJoined) const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBrown,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommunityGroupDetailPage(
                                  group: group,
                                  posts: posts,
                                  onLikePost: handleLikePost,
                                  onBookmarkPost: handleBookmarkPost,
                                  onSharePost: handleSharePost,
                                  onCommentClick: handleCommentClick,
                                  isJoined: isJoined,
                                  onJoinGroup: handleJoinGroupById,
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            isJoined ? LucideIcons.users : LucideIcons.eye,
                            size: 16,
                          ),
                          label: Text(isJoined ? 'Lihat Grup' : 'Lihat'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildCreatePostBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEditMode ? '✏️ Edit Postingan' : '✨ Buat Post Baru',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: isUploading
                      ? null
                      : () {
                          setState(() {
                            isCreatePostDialogOpen = false;
                            pickedImageFile = null;
                            postContent = '';
                            _postController.clear();
                            isEditMode = false;
                            editingPost = null;
                          });
                        },
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Field
                  TextField(
                    controller: _postController,
                    maxLines: 5,
                    enabled: !isUploading,
                    decoration: InputDecoration(
                      hintText: 'Apa yang ingin Anda bagikan?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      setState(() {
                        postContent = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: postCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Tips Bisnis', child: Text('Tips Bisnis')),
                      DropdownMenuItem(
                          value: 'Tanya Jawab', child: Text('Tanya Jawab')),
                      DropdownMenuItem(
                          value: 'Sharing Pengalaman',
                          child: Text('Sharing Pengalaman')),
                      DropdownMenuItem(
                          value: 'Testimoni', child: Text('Testimoni')),
                      DropdownMenuItem(value: 'Event', child: Text('Event')),
                    ],
                    onChanged: isUploading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                postCategory = value;
                              });
                            }
                          },
                  ),

                  const SizedBox(height: 16),

                  // Image Upload Section
                  if (pickedImageFile == null)
                    GestureDetector(
                      onTap: isUploading ? null : _handlePickImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFD1D5DB),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.image,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Klik untuk upload gambar',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Maksimal 5MB',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(
                                  pickedImageFile!.path,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(pickedImageFile!.path),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        if (!isUploading)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  pickedImageFile = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.x,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                  // Upload Progress
                  if (isUploading && uploadProgress > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Uploading: ${(uploadProgress * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: uploadProgress,
                            backgroundColor: Colors.grey[200],
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primaryBrown),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (postContent.trim().isEmpty || isUploading)
                    ? null
                    : _handleSubmitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBrown,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditMode ? '✏️ Update Post' : '🚀 Kirim Post',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}