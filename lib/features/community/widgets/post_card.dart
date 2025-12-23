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
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: User Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (post.author.avatar != null && post.author.avatar!.isNotEmpty)
                      ? NetworkImage(post.author.avatar!)
                      : null,
                  child: (post.author.avatar == null || post.author.avatar!.isEmpty)
                      ? const Icon(LucideIcons.user, color: Colors.grey)
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
                              fontSize: 14,
                            ),
                          ),
                          if (post.author.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                color: Colors.blue, size: 14),
                          ],
                        ],
                      ),
                      Text(
                        '${post.author.businessName} • ${post.timestamp}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.moreHorizontal, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Content Text
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                post.content,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),

          // Content Image
          if (post.image != null && post.image!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 400),
              child: Image.network(
                post.image!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(LucideIcons.imageOff, color: Colors.grey)),
                ),
              ),
            ),

          // Category & Group Tag (Optional)
          if (post.category.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.brown[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  post.category,
                  style: TextStyle(
                    color: Colors.brown[700],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  icon: post.isLiked ? Icons.favorite : LucideIcons.heart,
                  label: '${post.likes} Suka',
                  color: post.isLiked ? Colors.red : Colors.grey[600],
                  onTap: onLike,
                ),
                _ActionButton(
                  icon: LucideIcons.messageCircle,
                  label: '${post.comments} Komen',
                  onTap: onComment,
                ),
                _ActionButton(
                  icon: LucideIcons.share2,
                  label: 'Bagikan',
                  onTap: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}