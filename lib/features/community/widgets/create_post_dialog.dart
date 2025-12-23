import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post.dart';

/// Create Post Dialog - Backward Compatible Version
/// Supports both old callback style and new Firebase integration
class CreatePostDialog extends StatefulWidget {
  final Function(Post)? onCreatePost;
  final String? groupId;
  final String? groupName;

  const CreatePostDialog({
    Key? key,
    this.onCreatePost,
    this.groupId,
    this.groupName,
  }) : super(key: key);

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String newPostCategory = 'Tips Bisnis';
  XFile? pickedImageFile;
  bool isUploading = false;
  String? errorMessage;

  final List<String> categories = [
    'Tips Bisnis',
    'Pertanyaan',
    'Pengalaman',
    'Promosi',
    'Diskusi',
    'Lainnya',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
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
        // Validate file size
        final bytes = await image.readAsBytes();
        final sizeInMB = bytes.length / (1024 * 1024);

        if (sizeInMB > 5) {
          _showToast(
            'Ukuran file terlalu besar! Maksimal 5MB\nUkuran: ${sizeInMB.toStringAsFixed(2)} MB',
            ToastificationType.error,
          );
          return;
        }

        setState(() {
          pickedImageFile = image;
          errorMessage = null;
        });

        _showToast('Gambar siap diupload! 📷', ToastificationType.success);
      }
    } catch (e) {
      _showToast('Gagal memilih gambar: $e', ToastificationType.error);
    }
  }

  void _handleCreatePost() {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      setState(() {
        errorMessage = 'Konten post tidak boleh kosong!';
      });
      return;
    }

    // Create mock post object
    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: Author(
        name: 'Anda',
        avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Anda',
        businessName: 'Usaha Anda',
        verified: false,
      ),
      content: content,
      image: pickedImageFile?.path, // Local path for preview
      category: newPostCategory,
      likes: 0,
      comments: 0,
      shares: 0,
      timestamp: 'Baru saja',
      isLiked: false,
      isBookmarked: false,
    );

    // Callback
    if (widget.onCreatePost != null) {
      widget.onCreatePost!(newPost);
    }

    // Close dialog
    Navigator.of(context).pop();
  }

  void _showToast(String message, ToastificationType type) {
    toastification.show(
      context: context,
      type: type,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content TextField
                    TextField(
                      controller: _contentController,
                      maxLines: 5,
                      enabled: !isUploading,
                      decoration: InputDecoration(
                        hintText: 'Tulis post Anda...',
                        border: const OutlineInputBorder(),
                        errorText: errorMessage,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: newPostCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: isUploading
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  newPostCategory = value;
                                });
                              }
                            },
                    ),

                    const SizedBox(height: 16),

                    // Image Upload Section
                    _buildImageSection(),

                    // Error Message
                    if (errorMessage != null && !isUploading)
                      _buildErrorMessage(),
                  ],
                ),
              ),
            ),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Buat Post Baru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (!isUploading)
            IconButton(
              icon: const Icon(LucideIcons.x),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    if (pickedImageFile != null) {
      // Show image preview
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(
                    pickedImageFile!.path,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.red[100],
                        child: const Center(
                          child: Text('Error loading image'),
                        ),
                      );
                    },
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
      );
    } else {
      // Show upload area
      return GestureDetector(
        onTap: isUploading ? null : _handlePickImage,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFD1D5DB),
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.image, size: 48, color: Color(0xFF9CA3AF)),
                SizedBox(height: 8),
                Text(
                  'Klik untuk upload gambar',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                SizedBox(height: 4),
                Text(
                  'Maksimal 5MB',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Text(
          'Error: $errorMessage',
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isUploading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: (_contentController.text.trim().isEmpty || isUploading)
                ? null
                : _handleCreatePost,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Kirim Post'),
          ),
        ],
      ),
    );
  }
}