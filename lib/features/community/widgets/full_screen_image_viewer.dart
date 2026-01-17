import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'share_bottom_sheet.dart';

/// Full-screen Twitter-like image viewer
class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String authorName;
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked;
  final Function(bool isLiked)? onLikeToggled;
  final VoidCallback? onCommentTap;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.authorName,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
    this.onLikeToggled,
    this.onCommentTap,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late int _likes;
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _likes = widget.likes;
    _isLiked = widget.isLiked;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Image (Centered & Zoomable)
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(LucideIcons.imageOff, color: Colors.white54, size: 64),
                ),
              ),
            ),
          ),

          // Top Bar (Close button + Menu)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close Button
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x, color: Colors.white, size: 24),
                      ),
                    ),
                    // More Options
                    InkWell(
                      onTap: () {
                        // Show options menu
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.moreHorizontal, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Bar (Like, Comment, Share counts)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9), // Semi-transparent black bg
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Rata kiri ke kanan
                  children: [
                    _buildActionItem(
                      icon: _isLiked ? LucideIcons.heart : LucideIcons.heart,
                      color: _isLiked ? Colors.pink : Colors.white,
                      label: '$_likes Suka',
                      onTap: () {
                         setState(() {
                           _isLiked = !_isLiked;
                           if (_isLiked) {
                             _likes++;
                           } else {
                             _likes--;
                           }
                         });
                         // Notify parent about like change
                         widget.onLikeToggled?.call(_isLiked);
                      }
                    ),
                    _buildActionItem(
                      icon: LucideIcons.messageCircle,
                      label: '${widget.comments} Komen',
                      onTap: () {
                         // Call parent's comment handler or show comment sheet
                         if (widget.onCommentTap != null) {
                           widget.onCommentTap!();
                         } else {
                           // Default: Show simple comment sheet
                           _showCommentSheet();
                         }
                      }
                    ),
                    _buildActionItem(
                      icon: LucideIcons.share2,
                      label: 'Bagikan',
                      onTap: () {
                         _showShareSheet();
                      }
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Komentar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Tulis komentar...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(LucideIcons.send, color: Colors.blue),
                  onPressed: () {
                    // TODO: Implement comment submission
                    Navigator.pop(context);
                  },
                ),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ShareBottomSheet(
        postUrl: 'https://bangkitbmkm.app/post/${widget.imageUrl.hashCode}',
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color == Colors.pink ? Colors.pink : Colors.white, // Match text color to icon? Or keep white? Usually white or grey.
                // Ref image had Pink text "1 Suka"
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
