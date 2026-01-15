import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

import '../services/firebase_storage_service.dart';

class CreateGroupModal extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  const CreateGroupModal({
    super.key,
    required this.onClose,
    required this.onSuccess,
  });

  @override
  State<CreateGroupModal> createState() => _CreateGroupModalState();
}

class _CreateGroupModalState extends State<CreateGroupModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseStorageService _firebaseService = FirebaseStorageService();
  final ImagePicker _picker = ImagePicker();

  XFile? _uploadedImage;
  String _selectedCategory = 'Kuliner';
  bool _isCreating = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'kuliner', 'name': 'Kuliner', 'icon': '🍜', 'colors': [const Color(0xFFFB923C), const Color(0xFFEF4444)]},
    {'id': 'fashion', 'name': 'Fashion', 'icon': '👕', 'colors': [const Color(0xFFF472B6), const Color(0xFFA855F7)]},
    {'id': 'teknologi', 'name': 'Teknologi', 'icon': '💻', 'colors': [const Color(0xFF60A5FA), const Color(0xFF22D3EE)]},
    {'id': 'kerajinan', 'name': 'Kerajinan', 'icon': '🎨', 'colors': [const Color(0xFF4ADE80), const Color(0xFF10B981)]},
    {'id': 'pertanian', 'name': 'Pertanian', 'icon': '🌾', 'colors': [const Color(0xFFA3E635), const Color(0xFF16A34A)]},
    {'id': 'jasa', 'name': 'Jasa', 'icon': '🔧', 'colors': [const Color(0xFFFBBF24), const Color(0xFFF97316)]},
  ];

  bool get _isFormValid =>
      _nameController.text.trim().length >= 3 &&
      _descriptionController.text.trim().isNotEmpty &&
      _uploadedImage != null;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      // Check file size (max 5MB)
      final bytes = await image.length();
      if (bytes > 5 * 1024 * 1024) {
        _showToast('Ukuran file terlalu besar! Maksimal 5MB', ToastificationType.error);
        return;
      }

      if (mounted) {
        setState(() => _uploadedImage = image);
        _showToast('Foto grup berhasil diupload! 📷', ToastificationType.success);
      }
    } catch (e) {
      _showToast('Gagal mengambil gambar', ToastificationType.error);
    }
  }

  void _removeImage() {
    setState(() => _uploadedImage = null);
    _showToast('Foto grup dihapus', ToastificationType.info);
  }

  Future<void> _handleSubmit() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showToast('Nama grup harus diisi!', ToastificationType.error);
      return;
    }

    if (_nameController.text.trim().length < 3) {
      _showToast('Nama grup minimal 3 karakter!', ToastificationType.error);
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showToast('Deskripsi grup harus diisi!', ToastificationType.error);
      return;
    }

    if (_uploadedImage == null) {
      _showToast('Foto grup harus diupload!', ToastificationType.error);
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Get current user ID
      final userId = _firebaseService.getCurrentUserId();
      if (userId == null) {
        _showToast('Silakan login terlebih dahulu', ToastificationType.error);
        setState(() => _isCreating = false);
        return;
      }

      // Create group using firebase service
      final groupId = await _firebaseService.createGroup(
        imageFile: _uploadedImage,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        creatorId: userId,
      );

      if (groupId != null) {
        _showToast('Grup berhasil dibuat! 🎉', ToastificationType.success);
        widget.onSuccess();
        widget.onClose();
      } else {
        _showToast('Gagal membuat grup', ToastificationType.error);
      }
    } catch (e) {
      _showToast('Error: $e', ToastificationType.error);
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
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
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle indicator
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ===== HEADER =====
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.users, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buat Grup Baru',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Buat komunitas untuk berdiskusi dengan sesama UMKM',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(LucideIcons.x, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ===== CONTENT =====
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== FOTO GRUP =====
                  _buildSectionLabel(
                    icon: LucideIcons.image,
                    label: 'Foto Grup',
                    required: true,
                  ),
                  const SizedBox(height: 12),

                  if (_uploadedImage != null)
                    _buildImagePreview()
                  else
                    _buildImageUploader(),

                  const SizedBox(height: 24),

                  // ===== NAMA GRUP =====
                  _buildSectionLabel(
                    icon: LucideIcons.users,
                    label: 'Nama Grup',
                    required: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: 'Contoh: UMKM Makanan & Minuman Jakarta',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_nameController.text.length}/50 karakter',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      if (_nameController.text.length >= 3)
                        const Row(
                          children: [
                            Icon(LucideIcons.checkCircle, size: 14, color: Color(0xFF16A34A)),
                            SizedBox(width: 4),
                            Text(
                              'Nama grup valid',
                              style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ===== KATEGORI GRUP =====
                  _buildSectionLabel(
                    icon: LucideIcons.tag,
                    label: 'Kategori Grup',
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat['name'];

                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat['name']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: cat['colors'] as List<Color>,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: (cat['colors'] as List<Color>)[0].withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                cat['icon'] as String,
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cat['name'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ===== DESKRIPSI GRUP =====
                  _buildSectionLabel(
                    icon: LucideIcons.fileText,
                    label: 'Deskripsi Grup',
                    required: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: 'Ceritakan tentang grup ini...\n\n• Tujuan grup\n• Siapa yang cocok bergabung\n• Topik diskusi',
                      hintStyle: TextStyle(color: Colors.grey.shade400, height: 1.5),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_descriptionController.text.length}/200 karakter',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      if (_descriptionController.text.length > 20)
                        const Row(
                          children: [
                            Icon(LucideIcons.checkCircle, size: 14, color: Color(0xFF16A34A)),
                            SizedBox(width: 4),
                            Text(
                              'Deskripsi lengkap',
                              style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ===== TIPS BOX =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.users, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tips Membuat Grup',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• Pilih nama yang jelas dan mudah diingat\n'
                                '• Gunakan foto yang menarik dan relevan\n'
                                '• Tulis deskripsi yang informatif\n'
                                '• Pilih kategori yang sesuai',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== FORM VALIDATION WARNING =====
                  if (!_isFormValid)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE047), width: 2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('⚠️', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'Lengkapi semua field yang wajib diisi (*)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF854D0E),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ===== ACTION BUTTONS =====
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClose,
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
                      gradient: _isFormValid
                          ? const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
                            )
                          : null,
                      color: _isFormValid ? null : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isFormValid
                          ? [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: (_isFormValid && !_isCreating) ? _handleSubmit : null,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.plus, size: 20),
                      label: const Text('Buat Grup Sekarang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.transparent,
                        disabledForegroundColor: Colors.grey.shade500,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
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

  Widget _buildSectionLabel({
    required IconData icon,
    required String label,
    bool required = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF111827),
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
      ),
      child: Row(
        children: [
          // Preview Image
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? Image.network(
                          _uploadedImage!.path,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_uploadedImage!.path),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              // Success badge
              Positioned(
                bottom: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.check, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foto berhasil diupload!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Foto ini akan menjadi identitas grup Anda',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(LucideIcons.x, size: 16),
                  label: const Text('Ganti Foto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFECACA), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploader() {
    return GestureDetector(
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
            // Icon with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDBEAFE), Color(0xFFE0E7FF)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.upload, size: 36, color: Color(0xFF2563EB)),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '+',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload Foto Grup',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Klik untuk memilih foto dari galeri',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PNG, JPG atau JPEG • Maksimal 5MB',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.image, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Pilih Foto',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
