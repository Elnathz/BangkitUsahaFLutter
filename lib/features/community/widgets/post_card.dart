import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onBookmark;

  const PostCard({
    Key? key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onBookmark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Definisi warna tema lokal untuk card ini
    final primaryBrown = const Color(0xFF5D4037);
    final accentGold = const Color(0xFF8D6E63);

    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Jarak antar post ala FB
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 4,
          ), // Separator tebal
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Avatar + Nama + Opsi)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: accentGold,
                  backgroundImage: post.author.avatar != null
                      ? NetworkImage(post.author.avatar!)
                      : null,
                  child: post.author.avatar == null
                      ? Text(
                          post.author.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.author.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          if (post.author.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.checkCircle,
                              size: 14,
                              color: Colors.blue, // Verified tetap biru umum
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '${post.author.businessName} • ${post.timestamp}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (post.category.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            const Text(
                              "•",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.brown[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                post.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: primaryBrown,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.moreHorizontal,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              post.content,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1F2937),
                height: 1.4,
              ),
            ),
          ),

          // Image (Full Width ala Facebook)
          if (post.image != null)
            Image.network(
              post.image!,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

          // Stats (Like count etc)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5D4037), // Coklat icon like
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.thumbsUp,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.likes}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${post.comments} komentar',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${post.shares} dibagikan',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Action Buttons (Like, Comment, Share)
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: post.isLiked
                      ? LucideIcons.thumbsUp
                      : LucideIcons.thumbsUp,
                  label: 'Suka',
                  color: post.isLiked ? primaryBrown : Colors.grey[600]!,
                  onTap: onLike,
                  isActive: post.isLiked,
                ),
              ),
              Expanded(
                child: _ActionButton(
                  icon: LucideIcons.messageCircle,
                  label: 'Komentar',
                  color: Colors.grey[600]!,
                  onTap: onComment,
                ),
              ),
              Expanded(
                child: _ActionButton(
                  icon: LucideIcons.share2,
                  label: 'Bagikan',
                  color: Colors.grey[600]!,
                  onTap: onShare,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
