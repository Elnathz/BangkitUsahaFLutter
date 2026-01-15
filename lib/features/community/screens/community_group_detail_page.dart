import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/group.dart';
import '../models/post.dart';
import '../services/firebase_storage_service.dart';
import '../widgets/comments_dialog.dart';
import '../widgets/share_bottom_sheet.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../../../services/chat_service.dart';

class CommunityGroupDetailPage extends StatefulWidget {
  final CommunityGroup group;

  const CommunityGroupDetailPage({super.key, required this.group});

  @override
  State<CommunityGroupDetailPage> createState() =>
      _CommunityGroupDetailPageState();
}



class _CommunityGroupDetailPageState extends State<CommunityGroupDetailPage> {
  final FirebaseStorageService _firebaseService = FirebaseStorageService();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isJoined = false;
  bool isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkMembershipStatus();
    // Auto-fix negative post count if needed
    _firebaseService.fixNegativePostCount(widget.group.id);
  }

  Future<void> _checkMembershipStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      final status = await _firebaseService.hasJoinedGroup(
        widget.group.id,
        user.uid,
      );
      if (mounted) {
        setState(() {
          isJoined = status;
          isLoadingStatus = false;
        });
      }
    } else {
      if (mounted) setState(() => isLoadingStatus = false);
    }
  }

  Future<void> _handleJoinToggle() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showToast('Silakan login dahulu', ToastificationType.error);
      return;
    }

    setState(() => isLoadingStatus = true);

    if (isJoined) {
      await _firebaseService.leaveGroup(widget.group.id, user.uid);
      if (mounted) {
        setState(() {
          isJoined = false;
          isLoadingStatus = false;
        });
        _showToast('Anda keluar dari grup', ToastificationType.info);
      }
    } else {
      await _firebaseService.joinGroup(widget.group.id, user.uid);
      if (mounted) {
        setState(() {
          isJoined = true;
          isLoadingStatus = false;
        });
        _showToast('Berhasil bergabung! 🎉', ToastificationType.success);
      }
    }
  }

  void _handleLike(Post post) {
    if (_auth.currentUser == null) {
      _showToast('Silakan login dahulu', ToastificationType.error);
      return;
    }
    _firebaseService.toggleLike(post.id, post.isLiked);
    _showToast(post.isLiked ? 'Like dibatalkan' : 'Post disukai! ❤️', ToastificationType.success);
  }

  void _handleComment(Post post) {
    if (_auth.currentUser == null) {
      _showToast('Silakan login dahulu', ToastificationType.error);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsDialog(post: post),
    );
  }

  void _handleShare(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ShareBottomSheet(
        postUrl: 'https://bangkitumkm.app/post/${post.id}',
      ),
    );
  }

  void _handleBookmark() {
    _showToast('Post disimpan! 🔖', ToastificationType.success);
  }

  void _showToast(String msg, ToastificationType type) {
    toastification.show(
      context: context,
      type: type,
      title: Text(msg),
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  // --- SETTINGS MODAL (LEAVE GROUP) ---
  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.only(bottom: 15),
        width: double.infinity,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              if (isJoined)
                ListTile(
                  leading: const Icon(LucideIcons.logOut, color: Colors.red),
                  title: const Text('Keluar Grup', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context); // Close modal
                    _confirmLeaveGroup();
                  },
                )
              else
                ListTile(
                  leading: const Icon(LucideIcons.info, color: Colors.grey),
                  title: const Text('Belum bergabung dengan grup ini'),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLeaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Grup?'),
        content: const Text('Anda yakin ingin keluar dari grup ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _handleJoinToggle(); // Reuse existing logic
            },
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  // --- SHARE TO CHAT MODAL ---
  void _showShareToChatModal() {
    if (_auth.currentUser == null) {
      _showToast('Silakan login dahulu', ToastificationType.error);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareToChatSheet(
        groupName: widget.group.name,
        groupId: widget.group.id,
        currentUser: _auth.currentUser!,
      ),
    );
  }

  void _showCreateGroupPostModal() {
    if (_auth.currentUser == null) {
      _showToast('Silakan login dahulu', ToastificationType.error);
      return;
    }
    if (!isJoined) {
      _showToast('Gabung grup dulu untuk memposting', ToastificationType.warning);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePostModal(
        firebaseService: _firebaseService,
        group: widget.group,
        currentUser: _auth.currentUser!,
        onSuccess: () {
          _showToast('Post berhasil dibuat! 📝', ToastificationType.success);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('groups').doc(widget.group.id).snapshots(),
        builder: (context, groupSnapshot) {
          int memberCount = widget.group.members;
          int postCount = widget.group.posts;

          if (groupSnapshot.hasData && groupSnapshot.data!.exists) {
            final data = groupSnapshot.data!.data() as Map<String, dynamic>;
            memberCount = math.max(0, data['members'] ?? 0);
            postCount = math.max(0, data['posts'] ?? 0);
          }

          return CustomScrollView(
            slivers: [
              // ===== STICKY HEADER =====
              SliverAppBar(
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.white.withOpacity(0.95),
                surfaceTintColor: Colors.transparent,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF374151), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${NumberFormat.compact().format(memberCount)} Anggota • $postCount post',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.moreHorizontal, color: Color(0xFF374151), size: 20),
                      onPressed: _showSettingsModal,
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
              ),

              // ===== GROUP INFO CARD =====
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      children: [
                        // Cover Image with Gradient
                        Container(
                          height: 128,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF3B82F6),
                                Color(0xFF2563EB),
                                Color(0xFF4F46E5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              //覆盖图片
                              Opacity(
                                opacity: 0.3,
                                child: Image.network(
                                  widget.group.image,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(),
                                ),
                              ),
                              // Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Avatar & Info Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            children: [
                              // Avatar overlapping cover
                              Transform.translate(
                                offset: const Offset(0, -48),
                                child: Column(
                                  children: [
                                    // Avatar with Badge
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 96,
                                          height: 96,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.white, width: 4),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.15),
                                                blurRadius: 16,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.network(
                                              widget.group.image,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: const Color(0xFFDBEAFE),
                                                child: const Icon(
                                                  LucideIcons.users,
                                                  color: Color(0xFF2563EB),
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Verified/Joined Badge
                                        if (isJoined)
                                          Positioned(
                                            bottom: -4,
                                            right: -4,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 3),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF3B82F6).withOpacity(0.4),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                LucideIcons.check,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Group Name
                                    Text(
                                      widget.group.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                        color: Color(0xFF111827),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),

                                    // Stats Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildStat(
                                          icon: LucideIcons.users,
                                          value: NumberFormat.compact().format(memberCount),
                                          label: 'anggota',
                                        ),
                                        Container(
                                          width: 1,
                                          height: 24,
                                          margin: const EdgeInsets.symmetric(horizontal: 16),
                                          color: const Color(0xFFE5E7EB),
                                        ),
                                        _buildStat(
                                          icon: LucideIcons.messageCircle,
                                          value: postCount.toString(),
                                          label: 'post',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Action Buttons (offset to compensate for transform)
                              Transform.translate(
                                offset: const Offset(0, -32),
                                child: Row(
                                  children: isJoined
                                      ? [
                                          // Notification Button
                                          Expanded(
                                            child: _GradientButton(
                                              icon: LucideIcons.bell,
                                              label: 'Notifikasi',
                                              onTap: () => _showToast('Notifikasi grup diaktifkan! 🔔', ToastificationType.success),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Invite Button
                                          Expanded(
                                            child: _OutlinedButton(
                                              icon: LucideIcons.userPlus,
                                              label: 'Undang',
                                              onTap: _showShareToChatModal,
                                            ),
                                          ),
                                        ]
                                      : [
                                          // Join Button
                                          Expanded(
                                            child: _GradientButton(
                                              icon: LucideIcons.plus,
                                              label: 'Gabung Grup',
                                              isLoading: isLoadingStatus,
                                              onTap: _handleJoinToggle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Share Button
                                          Expanded(
                                            child: _OutlinedButton(
                                              icon: LucideIcons.share2,
                                              label: 'Bagikan',
                                              onTap: () => _showToast('Link grup disalin!', ToastificationType.success),
                                            ),
                                          ),
                                        ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ===== POSTS SECTION HEADER =====
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Postingan Terbaru',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$postCount Post',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ===== POSTS LIST =====
              StreamBuilder<List<Post>>(
                stream: _firebaseService.getPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final allPosts = snapshot.data ?? [];
                  final groupPosts = allPosts
                      .where((p) => p.groupId == widget.group.id)
                      .toList();

                  if (groupPosts.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.messageCircle,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada postingan di grup ini',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Jadilah yang pertama membuat postingan!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = groupPosts[index];
                        return _PostCard(
                          post: post,
                          onLike: () => _handleLike(post),
                          onComment: () => _handleComment(post),
                          onShare: () => _handleShare(post),
                          onBookmark: _handleBookmark,
                        );
                      },
                      childCount: groupPosts.length,
                    ),
                  );
                },
              ),

              // Bottom padding for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),

      // ===== FAB =====
      floatingActionButton: isJoined
          ? Tooltip(
              message: 'Buat Postingan',
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40, right: 15),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF4F46E5)], // blue-600 to indigo-600
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
                      onTap: _showCreateGroupPostModal,
                      borderRadius: BorderRadius.circular(30),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(LucideIcons.plus, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

// ===== GRADIENT BUTTON WIDGET =====
class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _GradientButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: isLoading
                  ? [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ]
                  : [
                      Icon(icon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===== OUTLINED BUTTON WIDGET =====
class _OutlinedButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlinedButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===== POST CARD WIDGET =====
class _PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onBookmark;

  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Row
            Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFDBEAFE),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (post.author.avatar != null && post.author.avatar!.isNotEmpty)
                        ? Image.network(
                            post.author.avatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                          )
                        : _buildAvatarFallback(),
                  ),
                ),
                const SizedBox(width: 12),
                // Author Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.author.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post.author.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.checkCircle,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        post.author.businessName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        post.timestamp,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                // More Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.moreHorizontal,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Category Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDBEAFE), Color(0xFFE0E7FF)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                post.category,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Content
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF374151),
              ),
            ),

            // Post Image - Tappable for fullscreen
            if (post.image != null && post.image!.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageViewer(
                        imageUrl: post.image!,
                        authorName: post.author.name,
                        likes: post.likes,
                        comments: post.comments,
                        shares: post.shares,
                        isLiked: post.isLiked,
                        onLikeToggled: (isLiked) => onLike(),
                        onCommentTap: onComment,
                      ),
                    ),
                  );
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 350),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      post.image!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
              ),
            ],

            // Divider before action buttons
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 1,
              color: const Color(0xFFE5E7EB),
            ),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: LucideIcons.heart,
                    label: 'Suka',
                    isActive: post.isLiked,
                    activeColor: const Color(0xFFEF4444),
                    onTap: onLike,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: LucideIcons.messageCircle,
                    label: 'Komentar',
                    onTap: onComment,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: LucideIcons.share2,
                    label: 'Bagikan',
                    onTap: onShare,
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onBookmark,
                    child: const Icon(
                      LucideIcons.bookmark,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFF2563EB),
      child: Center(
        child: Text(
          post.author.name.isNotEmpty ? post.author.name[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

// ===== ACTION BUTTON WIDGET =====
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? activeColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (activeColor ?? const Color(0xFF3B82F6))
        : const Color(0xFF6B7280);

    return Material(
      color: isActive
          ? (activeColor?.withOpacity(0.1) ?? const Color(0xFFEF4444).withOpacity(0.1))
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== CREATE POST MODAL =====
class _CreatePostModal extends StatefulWidget {
  final FirebaseStorageService firebaseService;
  final CommunityGroup group;
  final User currentUser;
  final VoidCallback onSuccess;

  const _CreatePostModal({
    required this.firebaseService,
    required this.group,
    required this.currentUser,
    required this.onSuccess,
  });

  @override
  State<_CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<_CreatePostModal> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String _selectedCategory = 'Tips Bisnis';
  bool _isUploading = false;

  final List<String> _categories = [
    'Tips Bisnis',
    'Pengalaman',
    'Pertanyaan',
    'Informasi',
  ];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;

    if (image != null) {
      // Check file size (max 5MB)
      final bytes = await image.length();
      if (bytes > 5 * 1024 * 1024) {
        _showToast('Ukuran file terlalu besar! Maksimal 5MB', ToastificationType.error);
        return;
      }
      setState(() => _imageFile = image);
      _showToast('Gambar berhasil diupload! 📷', ToastificationType.success);
    }
  }

  void _removeImage() {
    setState(() => _imageFile = null);
    _showToast('Gambar dihapus', ToastificationType.info);
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) return;

    if (!mounted) return;
    setState(() => _isUploading = true);

    String finalName = '';
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        finalName = data['ownerName'] ?? '';
      }
    } catch (e) {
      debugPrint("Error getting user: $e");
    }

    if (finalName.isEmpty) {
      finalName = widget.currentUser.displayName ?? '';
      if (finalName.isEmpty && widget.currentUser.email != null) {
        finalName = widget.currentUser.email!.split('@')[0];
      }
    }
    if (finalName.isEmpty) finalName = 'Anggota Grup';

    await widget.firebaseService.uploadImageAndSavePost(
      imageFile: _imageFile,
      userId: widget.currentUser.uid,
      userName: finalName,
      userAvatar: widget.currentUser.photoURL ?? '',
      businessName: 'Anggota Grup',
      content: _contentController.text,
      category: _selectedCategory,
      groupId: widget.group.id,
      groupName: widget.group.name,
      onProgress: (val) {},
    );

    widget.onSuccess();
    if (mounted) Navigator.pop(context);
  }

  void _showToast(String msg, ToastificationType type) {
    toastification.show(
      context: context,
      type: type,
      title: Text(msg),
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buat Postingan Baru',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Bagikan dengan anggota ${widget.group.name}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Selection
                  const Text(
                    'Pilih Kategori',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
                                  )
                                : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF374151),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Content Input
                  const Text(
                    'Tulis Postingan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Apa yang ingin Anda bagikan?\n\n• Bagikan tips sukses bisnis\n• Tanyakan hal yang ingin diketahui\n• Ceritakan pengalaman menarik',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        height: 1.5,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_contentController.text.length} karakter',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (_contentController.text.isNotEmpty)
                        const Text(
                          '✓ Siap diposting',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF10B981),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Image Upload
                  Row(
                    children: [
                      const Text(
                        'Tambah Gambar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(Opsional)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_imageFile != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
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
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.black.withOpacity(0.3),
                            ),
                            child: Center(
                              child: ElevatedButton.icon(
                                onPressed: _removeImage,
                                icon: const Icon(LucideIcons.x, size: 16),
                                label: const Text('Hapus Gambar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFF9FAFB),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.image,
                                size: 32,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Klik untuk upload gambar',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PNG, JPG hingga 5MB',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _contentController.text.trim().isEmpty || _isUploading
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Posting Sekarang',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}

class _ShareToChatSheet extends StatefulWidget {
  final String groupName;
  final String groupId;
  final User currentUser;

  const _ShareToChatSheet({
    required this.groupName,
    required this.groupId,
    required this.currentUser,
  });

  @override
  State<_ShareToChatSheet> createState() => _ShareToChatSheetState();
}

class _ShareToChatSheetState extends State<_ShareToChatSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSendInvite(String chatRoomId, String partnerName, String partnerId) async {
    // 1. Kirim pesan invite
    String inviteText = "Ayo gabung ke grup *${widget.groupName}*! 👥\n\nKlik di sini untuk melihat: https://bangkitumkm.app/group/${widget.groupId}";

    await _chatService.sendMessage(
      chatRoomId: chatRoomId,
      senderId: widget.currentUser.uid,
      receiverId: partnerId,
      text: inviteText,
    );

    // 2. Tutup Modal & Show Toast
    if (mounted) {
      Navigator.pop(context);
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: Text('Undangan dikirim ke $partnerName! 📨'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Kirim Undangan ke...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Cari chat...",
                prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Chat List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .where('participants', arrayContains: widget.currentUser.uid)
                  .orderBy('last_message_time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "Belum ada chat aktif",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final chatRoom = snapshot.data!.docs[index];
                    final data = chatRoom.data() as Map<String, dynamic>;

                    // Find Partner ID
                    final List participants = data['participants'] ?? [];
                    final String partnerId = participants.firstWhere(
                      (id) => id != widget.currentUser.uid,
                      orElse: () => '',
                    );

                    if (partnerId.isEmpty) return const SizedBox.shrink();

                    return _InviteChatTile(
                      chatRoomId: chatRoom.id,
                      partnerId: partnerId,
                      searchQuery: _searchQuery,
                      onTap: (name) => _handleSendInvite(chatRoom.id, name, partnerId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteChatTile extends StatelessWidget {
  final String chatRoomId;
  final String partnerId;
  final String searchQuery;
  final Function(String) onTap;

  const _InviteChatTile({
    required this.chatRoomId,
    required this.partnerId,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(partnerId).snapshots(),
      builder: (context, snapshot) {
        String name = "Pengguna";
        String image = "";

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          name = userData['storeName'] ?? userData['name'] ?? "Pengguna";
          image = userData['imageUrl'] ?? userData['image'] ?? "";
        }

        if (searchQuery.isNotEmpty && !name.toLowerCase().contains(searchQuery)) {
          return const SizedBox.shrink();
        }

        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty ? const Icon(LucideIcons.user, size: 20) : null,
          ),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Kirim",
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          onTap: () => onTap(name),
        );
      },
    );
  }
}
