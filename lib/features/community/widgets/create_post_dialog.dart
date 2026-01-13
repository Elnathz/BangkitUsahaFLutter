import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_storage_service.dart';

class CreatePostSheet extends StatefulWidget {
  final FirebaseStorageService firebaseService;
  final User currentUser;
  final VoidCallback onSuccess;

  const CreatePostSheet({
    super.key,
    required this.firebaseService,
    required this.currentUser,
    required this.onSuccess,
  });

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final TextEditingController _contentController = TextEditingController();
  String _category = 'Tips Bisnis';
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  final List<String> categories = [
    'Tips Bisnis',
    'Tanya Jawab',
    'Sharing Pengalaman',
    'Promosi',
    'Lainnya',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Kompresi gambar
      );
      if (image != null) {
        setState(() => _imageFile = image);
      }
    } catch (e) {
      debugPrint("Gagal ambil gambar: $e");
    }
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty && _imageFile == null) return;

    setState(() => _isUploading = true);

    String finalName = '';
    String businessName = 'UMKM Member';

    try {
      // 1. Ambil Nama Lengkap/Toko dari Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        // Prioritaskan Nama Toko/Owner
        finalName =
            data['storeName'] ?? data['ownerName'] ?? data['userName'] ?? '';
      }
    } catch (e) {
      debugPrint("Gagal ambil data user: $e");
    }

    // Fallback nama jika kosong
    if (finalName.isEmpty) {
      finalName = widget.currentUser.displayName ?? 'Pengguna';
    }

    // 2. Upload & Simpan Post
    await widget.firebaseService.uploadImageAndSavePost(
      imageFile: _imageFile,
      userId: widget.currentUser.uid,
      userName: finalName,
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
    // Agar dialog tidak tertutup keyboard
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        // Tinggi dinamis maksimal 90% layar
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Penting agar tidak full height
          children: [
            // HEADER
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

            // SCROLLABLE CONTENT
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input Text
                    TextField(
                      controller: _contentController,
                      maxLines: 5,
                      minLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Apa yang ingin Anda bagikan kepada komunitas?',
                        border: InputBorder.none,
                      ),
                    ),

                    // Image Preview
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

            const SizedBox(height: 10),
            const Divider(),

            // FOOTER ACTIONS
            Row(
              children: [
                // Tombol Upload Gambar
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(
                    LucideIcons.image,
                    color: const Color(0xFF1565C0),
                  ),
                  tooltip: "Tambah Foto",
                ),

                // Dropdown Kategori
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    isExpanded: true, // Agar teks tidak overflow
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    items: categories
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

                // Tombol Kirim
                ElevatedButton(
                  onPressed: _isUploading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
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
      ),
    );
  }
}
