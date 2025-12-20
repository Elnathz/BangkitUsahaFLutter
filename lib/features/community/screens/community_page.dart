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
  bool isCommentDialogOpen = false;
  Post? selectedPost;
  String newPostContent = '';
  String newPostCategory = 'Umum';
  String newComment = '';

  List<String> joinedGroups = ['1']; // User sudah join grup dengan id '1'

  // Mock data posts
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
    Post(
      id: '4',
      author: Author(
        name: 'Pak Ahmad',
        avatar:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
        businessName: 'Kopi Seduh Ahmad',
        verified: true,
      ),
      content:
          'Senang banget bisa ikut webinar digital marketing gratis dari komunitas ini. Ilmunya langsung bisa dipraktekkan dan omzet naik 25%! Thanks admin 🙌',
      category: 'Testimoni',
      likes: 189,
      comments: 56,
      shares: 23,
      timestamp: '2 hari lalu',
      isLiked: false,
      isBookmarked: false,
    ),
    Post(
      id: '5',
      author: Author(
        name: 'Ibu Fitri',
        businessName: 'Batik Fitri Collection',
        verified: false,
      ),
      content:
          'Ada yang punya pengalaman ekspor produk ke luar negeri? Share dong prosesnya gimana dan dokumen apa aja yang diperlukan. Pengen coba expand market nih 🌏',
      category: 'Tanya Jawab',
      likes: 67,
      comments: 41,
      shares: 12,
      timestamp: '3 hari lalu',
      isLiked: false,
      isBookmarked: false,
    ),
    Post(
      id: '6',
      author: Author(
        name: 'Admin Bangkit Usaha',
        avatar:
            'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=100',
        businessName: 'Bangkit Usaha',
        verified: true,
      ),
      content:
          '📢 WEBINAR GRATIS: "Strategi Digital Marketing untuk UMKM 2025" - Sabtu, 14 Des 2024, 19:00 WIB. Daftar sekarang, tempat terbatas! Link pendaftaran di komentar 👇',
      image:
          'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600',
      category: 'Event',
      likes: 342,
      comments: 87,
      shares: 156,
      timestamp: '5 jam lalu',
      isLiked: false,
      isBookmarked: false,
    ),
  ];

  // Trending topics
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
      icon: LucideIcons.trendingUp,
    ),
    TrendingTopic(
      id: '3',
      title: 'Digital Marketing UMKM',
      posts: 189,
      icon: LucideIcons.trendingUp,
    ),
    TrendingTopic(
      id: '4',
      title: 'Manajemen Keuangan',
      posts: 145,
      icon: LucideIcons.trendingUp,
    ),
  ];

  // Groups
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
      name: 'Fashion & Kerajinan Tangan',
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
    CommunityGroup(
      id: '4',
      name: 'Export & Import',
      members: 876,
      posts: 456,
      image:
          'https://images.unsplash.com/photo-1578575437130-527eed3abbec?w=200',
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

  // Mock comments
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
      Comment(
        id: '2',
        author: 'Ibu Fitri',
        content: 'Kue lapisnya enak banget! Saya juga pelanggan setia ❤️',
        timestamp: '30 menit lalu',
        likes: 8,
      ),
    ],
    '2': [
      Comment(
        id: '1',
        author: 'Ibu Dewi',
        avatar:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
        content:
            'Coba cek di Tokopedia Pak, banyak supplier packaging murah dan kualitas bagus',
        timestamp: '3 jam lalu',
        likes: 15,
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
    super.dispose();
  }

  // Filtered posts
  List<Post> get filteredPosts {
    return posts.where((post) {
      final matchesSearch =
          post.content.toLowerCase().contains(searchQuery.toLowerCase()) ||
          post.author.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory =
          selectedCategory == 'Semua' || post.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Handle actions
  void handleLikePost(String postId) {
    setState(() {
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = posts[index];
        final newLiked = !post.isLiked;
        posts[index] = post.copyWith(
          isLiked: newLiked,
          likes: newLiked ? post.likes + 1 : post.likes - 1,
        );
        _showToast(
          newLiked ? 'Postingan disukai ❤️' : 'Batal suka',
          ToastificationType.success,
        );
      }
    });
  }

  void handleBookmarkPost(String postId) {
    setState(() {
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = posts[index];
        final newBookmarked = !post.isBookmarked;
        posts[index] = post.copyWith(isBookmarked: newBookmarked);
        _showToast(
          newBookmarked ? 'Disimpan ke bookmark 🔖' : 'Dihapus dari bookmark',
          ToastificationType.success,
        );
      }
    });
  }

  void handleSharePost(String postId, String authorName) {
    _showToast(
      'Membagikan postingan dari $authorName',
      ToastificationType.success,
    );
  }

  void handleCommentClick(Post post) {
    setState(() {
      selectedPost = post;
    });
    _showCommentsDialog();
  }

  void handleCreatePost() {
    if (newPostContent.trim().isEmpty) {
      _showToast(
        'Konten postingan tidak boleh kosong',
        ToastificationType.error,
      );
      return;
    }

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: Author(
        name: 'Anda',
        businessName: 'Toko Makanan Ibu Sari',
        verified: true,
      ),
      content: newPostContent,
      category: newPostCategory,
      likes: 0,
      comments: 0,
      shares: 0,
      timestamp: 'Baru saja',
      isLiked: false,
      isBookmarked: false,
    );

    setState(() {
      posts.insert(0, newPost);
      isPostDialogOpen = false;
      newPostContent = '';
      newPostCategory = 'Umum';
    });

    _showToast('Postingan berhasil dibagikan! 🎉', ToastificationType.success);
  }

  void handleAddComment() {
    if (newComment.trim().isEmpty) return;
    _showToast('Komentar berhasil ditambahkan', ToastificationType.success);
    setState(() {
      newComment = '';
    });
  }

  void handleJoinGroupById(String groupId, String groupName) {
    if (!joinedGroups.contains(groupId)) {
      setState(() {
        joinedGroups.add(groupId);
      });
      _showToast(
        'Berhasil bergabung dengan grup $groupName! 🎉',
        ToastificationType.success,
      );
    }
  }

  void handleCategorySelect(String category) {
    setState(() {
      selectedCategory = category;
    });
    _showToast(
      category == 'Semua' ? 'Menampilkan semua kategori' : 'Filter: $category',
      ToastificationType.success,
    );
  }

  void _showToast(String message, ToastificationType type) {
    toastification.show(
      context: context,
      type: type,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 2),
      alignment: Alignment.topCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Tabs
          _buildTabBar(),

          // Content
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
    );
  }

  // Header
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
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
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isPostDialogOpen = true;
                  });
                  _showCreatePostDialog();
                },
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search
          TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari diskusi...',
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Tab Bar
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF4F46E5),
        unselectedLabelColor: const Color(0xFF6B7280),
        indicatorColor: const Color(0xFF4F46E5),
        tabs: const [
          Tab(icon: Icon(LucideIcons.messageCircle, size: 18), text: 'Feed'),
          Tab(icon: Icon(LucideIcons.trendingUp, size: 18), text: 'Trending'),
          Tab(icon: Icon(LucideIcons.users, size: 18), text: 'Grup'),
        ],
      ),
    );
  }

  // Feed Tab
  Widget _buildFeedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Categories
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((category) {
              final isSelected = selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    handleCategorySelect(category);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF4F46E5),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Posts
        ...filteredPosts.map((post) {
          return PostCard(
            post: post,
            onLike: () => handleLikePost(post.id),
            onComment: () => handleCommentClick(post),
            onShare: () => handleSharePost(post.id, post.author.name),
            onBookmark: () => handleBookmarkPost(post.id),
          );
        }),

        // Empty state
        if (filteredPosts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: const [
                  Icon(
                    LucideIcons.messageCircle,
                    size: 64,
                    color: Color(0xFFD1D5DB),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tidak ada postingan ditemukan',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Trending Tab
  Widget _buildTrendingTab() {
    // Sorting posts by likes untuk popular posts
    final popularPosts = posts.toList()
      ..sort((a, b) => b.likes.compareTo(a.likes));
    final topPosts = popularPosts.take(3).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '🔥 Topik Trending',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Trending topics
        ...trendingTopics.map((topic) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
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
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFED7AA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        topic.icon,
                        color: const Color(0xFFEA580C),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${topic.posts} diskusi',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      LucideIcons.trendingUp,
                      color: Color(0xFFEA580C),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        // Popular posts
        const Text(
          '⭐ Postingan Populer Minggu Ini',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Display top 3 popular posts
        ...topPosts.map((post) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF4F46E5),
                        backgroundImage: post.author.avatar != null
                            ? NetworkImage(post.author.avatar!)
                            : null,
                        child: post.author.avatar == null
                            ? Text(
                                post.author.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.author.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              post.author.businessName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.award,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '❤️ ${post.likes}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '💬 ${post.comments}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '🔗 ${post.shares}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // Groups Tab
  Widget _buildGroupsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '👥 Grup Populer',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        ...groups.map((group) {
          final isJoined = joinedGroups.contains(group.id);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      group.image,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '👥 ${group.members.toStringAsFixed(0)} anggota',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          '📝 ${group.posts} post',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isJoined)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CommunityGroupDetailPage(
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
                              icon: const Icon(LucideIcons.users, size: 16),
                              label: const Text('Lihat Grup'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    handleJoinGroupById(group.id, group.name);
                                  },
                                  child: const Text('Gabung'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CommunityGroupDetailPage(
                                              group: group,
                                              posts: posts,
                                              onLikePost: handleLikePost,
                                              onBookmarkPost:
                                                  handleBookmarkPost,
                                              onSharePost: handleSharePost,
                                              onCommentClick:
                                                  handleCommentClick,
                                              isJoined: isJoined,
                                              onJoinGroup: handleJoinGroupById,
                                            ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                  ),
                                  child: const Text('Lihat'),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        // Suggested groups
        const Text(
          '💡 Rekomendasi Grup',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bergabung dengan grup sesuai minat bisnis Anda untuk mendapat insight dan networking lebih baik',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      _showToast(
                        'Fitur akan segera tersedia',
                        ToastificationType.info,
                      );
                    },
                    child: const Text('Jelajahi Semua Grup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Create Post Dialog
  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => CreatePostDialog(
        onCreatePost: (post) {
          setState(() {
            posts.insert(0, post);
          });
          _showToast(
            'Postingan berhasil dibagikan! 🎉',
            ToastificationType.success,
          );
        },
      ),
    );
  }

  // Comments Dialog
  void _showCommentsDialog() {
    if (selectedPost == null) return;

    final postComments = comments[selectedPost!.id] ?? [];

    showDialog(
      context: context,
      builder: (context) => CommentsDialog(
        post: selectedPost!,
        comments: postComments,
        onAddComment: (commentText) {
          handleAddComment();
        },
      ),
    );
  }
}
