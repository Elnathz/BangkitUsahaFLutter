import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/trending_topic.dart';
import '../models/group.dart';
import '../widgets/post_card.dart';
import 'community_topic_detail_page.dart';
import 'community_group_detail_page.dart';
import '../widgets/create_post_dialog.dart';
import '../widgets/comments_dialog.dart';

// --- IMPORT CHAT & NOTIFIKASI (NAIK 2 LEVEL) ---
import '../../chat/chat_screen.dart';
import '../../notifications/notification_screen.dart';

class CommunityPage extends StatefulWidget {
  final VoidCallback onClose;

  const CommunityPage({Key? key, required this.onClose}) : super(key: key);

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';
  String selectedCategory = 'Semua';
  bool isPostDialogOpen = false;

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
  ];

  final List<String> categories = [
    'Semua',
    'Tips Bisnis',
    'Tanya Jawab',
    'Sharing Pengalaman',
    'Testimoni',
    'Event',
  ];
  final Map<String, List<Comment>> comments = {};

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

  List<Post> get filteredPosts => posts;
  void handleCategorySelect(String c) {
    setState(() => selectedCategory = c);
  }

  void handleLikePost(String id) {
    setState(() {
      var p = posts.firstWhere((e) => e.id == id);
      var idx = posts.indexOf(p);
      posts[idx] = p.copyWith(
        isLiked: !p.isLiked,
        likes: !p.isLiked ? p.likes + 1 : p.likes - 1,
      );
    });
  }

  void handleBookmarkPost(String id) {}
  void handleSharePost(String id, String name) {}
  void handleCommentClick(Post p) {
    _showCommentsDialog(p);
  }

  void handleJoinGroupById(String id, String name) {}
  void _showToast(String msg, ToastificationType type) {
    toastification.show(
      context: context,
      title: Text(msg),
      type: type,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (c) => CreatePostDialog(
        onCreatePost: (p) {
          setState(() => posts.insert(0, p));
        },
      ),
    );
  }

  void _showCommentsDialog(Post p) {
    showDialog(
      context: context,
      builder: (c) =>
          CommentsDialog(post: p, comments: [], onAddComment: (s) {}),
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
      // Cari bagian floatingActionButton di dalam Scaffold, ganti jadi ini:
      floatingActionButton: Padding(
        // Kita beri jarak 90 pixel dari bawah supaya naik ke atas Nav Bar
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: _showCreatePostDialog,
          backgroundColor: primaryBrown,
          child: const Icon(LucideIcons.penTool),
        ),
      ),
    );
  }

  // HEADER DENGAN TOMBOL CHAT & NOTIFIKASI
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
              // TOMBOL KANAN (Search, Chat, Notif)
              Row(
                children: [
                  _buildHeaderIcon(
                    context,
                    LucideIcons.search,
                    null,
                  ), // Search dummy
                  const SizedBox(width: 8),
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
        ],
      ),
    );
  }

  // *** Widget Helper untuk Tombol Header (Sama Persis) ***
  Widget _buildHeaderIcon(
    BuildContext context,
    IconData icon,
    Widget? destination,
  ) {
    return InkWell(
      onTap: destination != null
          ? () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => destination),
            )
          : () {},
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

  // TAB BAR COKLAT
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
        // 1. Header "Apa yang Anda pikirkan"
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFEFEBE9),
                child: Icon(LucideIcons.user, color: Colors.brown),
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
                onPressed: () {},
                icon: const Icon(LucideIcons.image, color: Colors.green),
              ),
            ],
          ),
        ),

        // 2. Kategori Chips
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

        // 3. List Postingan
        if (filteredPosts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text("Belum ada postingan")),
          )
        else
          ...filteredPosts.map((post) {
            return PostCard(
              post: post,
              onLike: () => handleLikePost(post.id),
              onComment: () => handleCommentClick(post),
              onShare: () => handleSharePost(post.id, post.author.name),
              onBookmark: () => handleBookmarkPost(post.id),
            );
          }),

        // --- TAMBAHAN: KOTAK KOSONG DI BAWAH (Seperti Dashboard) ---
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildTrendingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Spread operator (...) untuk mengeluarkan isi list trendingTopics
        ...trendingTopics.map(
          (topic) => Card(
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
              onTap: () {},
            ),
          ),
        ),

        // --- TAMBAHAN: KOTAK KOSONG DI BAWAH ---
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildGroupsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Spread operator (...) untuk mengeluarkan isi list groups
        ...groups.map(
          (group) => Card(
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
                    '${group.members} anggota • ${group.posts} postingan',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBrown,
                      ),
                      onPressed: () {},
                      child: const Text(
                        "Lihat Grup",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- TAMBAHAN: KOTAK KOSONG DI BAWAH ---
        const SizedBox(height: 120),
      ],
    );
  }
}
