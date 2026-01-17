import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../account/settings_screen.dart';
import '../notifications/notification_screen.dart';
import '../chat/chat_screen.dart';
import '../../map_picker_screen.dart';
import '../../services/connectivity_service.dart';

const List<String> DAYS = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

class ShopProfileScreen extends StatefulWidget {
  final String? shopId; // Opsional: Jika null, berarti lihat profil sendiri

  const ShopProfileScreen({super.key, this.shopId});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;
  bool isUploading = false;

  // Cek apakah ini profil saya sendiri
  bool get isMyProfile => widget.shopId == null || widget.shopId == user?.uid;

  Map<String, dynamic> businessProfile = {
    'name': '',
    'owner': '',
    'description': '',
    'address': '',
    'phone': '',
    'email': '',
    'openingHours': '',
    'established': '',
    'image': '',
    'rating': 0.0,
    'totalReviews': 0,
    'totalSales': 0,
    'responseRate': 0,
  };

  int totalAllInteractions = 0;

  // Controllers
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  List<String> selectedDays = [];
  TimeOfDay openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay closeTime = const TimeOfDay(hour: 17, minute: 0);

  double? _storeLat;
  double? _storeLng;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final targetUid = isMyProfile ? user?.uid : widget.shopId;
    if (targetUid == null) return;

    // 1. Ambil Data Profil
    FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .snapshots()
        .listen((docSnap) {
          if (!mounted) return;

          // 2. Hitung Total Semua Ulasan
          FirebaseFirestore.instance
              .collection('reviews')
              .where('shopId', isEqualTo: targetUid)
              .count()
              .get()
              .then((countSnap) {
                if (mounted) {
                  setState(() => totalAllInteractions = countSnap.count ?? 0);
                }
              });

          if (docSnap.exists) {
            final data = docSnap.data()!;
            setState(() {
              businessProfile = {
                'name': data['storeName'] ?? data['name'] ?? "Toko",
                'owner': data['ownerName'] ?? data['name'] ?? "Pemilik",
                'description': data['description'] ?? "",
                'address': data['address'] ?? "",
                'phone': data['phoneNumber'] ?? "",
                'email': data['email'] ?? "",
                'openingHours': data['openingHours'] ?? "",
                'established': data['established'] ?? "",
                'image': data['image'] ?? data['imageUrl'] ?? "",
                'rating': (data['rating'] ?? 0).toDouble(),
                'totalReviews': data['totalReviews'] ?? 0,
                'totalSales': data['totalSales'] ?? 0,
                'responseRate': data['responseRate'] ?? 0,
              };
              isLoading = false;
            });
          } else {
            setState(() => isLoading = false);
          }
        });
  }

  Future<void> _handleImageUpload() async {
    if (!isMyProfile) return; // Hanya pemilik yang bisa upload

    if (!ConnectivityService().hasConnection) {
      _showToast("Perlu koneksi internet untuk ganti foto", ToastificationType.warning);
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40, // KOMPRESI GAMBAR: Turunkan kualitas ke 40%
    );
    if (image == null) return;

    setState(() => isUploading = true);
    _showToast("Mengunggah foto...", ToastificationType.info);

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_photos/${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      Uint8List imageData = await image.readAsBytes();
      await storageRef.putData(
        imageData,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadURL = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'image': downloadURL,
      }, SetOptions(merge: true));

      await user!.updatePhotoURL(downloadURL);
      _showToast("Foto berhasil diperbarui!", ToastificationType.success);
    } catch (e) {
      _showToast("Gagal upload: $e", ToastificationType.error);
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  // --- LOGIC JADWAL (Sama seperti sebelumnya) ---
  void _parseSchedule(String scheduleString) {
    if (scheduleString.isEmpty) return;
    try {
      final parts = scheduleString.split(': ');
      if (parts.length == 2) {
        final daysPart = parts[0];
        List<String> loadedDays = [];
        if (daysPart == "Setiap Hari") {
          loadedDays = List.from(DAYS);
        } else {
          loadedDays = daysPart
              .split(RegExp(r', | - '))
              .where((d) => DAYS.contains(d))
              .toList();
          if (daysPart.contains(" - ")) {
            final range = daysPart.split(" - ");
            if (range.length == 2) {
              int start = DAYS.indexOf(range[0]);
              int end = DAYS.indexOf(range[1]);
              if (start != -1 && end != -1) {
                loadedDays = DAYS.sublist(start, end + 1);
              }
            }
          }
        }
        final timesPart = parts[1].split(' - ');
        if (timesPart.length == 2) {
          setState(() {
            selectedDays = loadedDays;
            openTime = _stringToTime(timesPart[0]);
            closeTime = _stringToTime(timesPart[1]);
          });
        }
      }
    } catch (e) {
      debugPrint("Schedule parse error");
    }
  }

  TimeOfDay _stringToTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _generateScheduleString() {
    if (selectedDays.isEmpty) return "";
    final openStr =
        "${openTime.hour.toString().padLeft(2, '0')}:${openTime.minute.toString().padLeft(2, '0')}";
    final closeStr =
        "${closeTime.hour.toString().padLeft(2, '0')}:${closeTime.minute.toString().padLeft(2, '0')}";
    List<String> sortedDays = List.from(selectedDays);
    sortedDays.sort((a, b) => DAYS.indexOf(a).compareTo(DAYS.indexOf(b)));

    String dayStr;
    if (sortedDays.length == 7) {
      dayStr = "Setiap Hari";
    } else {
      List<List<String>> groups = [];
      if (sortedDays.isNotEmpty) {
        List<String> currentGroup = [sortedDays[0]];
        for (int i = 1; i < sortedDays.length; i++) {
          int prevIndex = DAYS.indexOf(sortedDays[i - 1]);
          int currIndex = DAYS.indexOf(sortedDays[i]);
          if (currIndex == prevIndex + 1) {
            currentGroup.add(sortedDays[i]);
          } else {
            groups.add(currentGroup);
            currentGroup = [sortedDays[i]];
          }
        }
        groups.add(currentGroup);
      }
      List<String> groupStrings = groups.map((group) {
        if (group.length >= 3) return "${group.first} - ${group.last}";
        return group.join(', ');
      }).toList();
      dayStr = groupStrings.join(', ');
    }
    return "$dayStr: $openStr - $closeStr";
  }

  void _toggleEdit() {
    if (!isEditing) {
      _nameController.text = businessProfile['name'];
      _descController.text = businessProfile['description'];
      _addressController.text = businessProfile['address'];
      _phoneController.text = businessProfile['phone'];
      _emailController.text = businessProfile['email'];
      _yearController.text = businessProfile['established'];
      _parseSchedule(businessProfile['openingHours']);
      _storeLat = businessProfile['storeLat'];
      _storeLng = businessProfile['storeLng'];
    }
    setState(() => isEditing = !isEditing);
  }

  Future<void> _handleSave() async {
    setState(() => isSaving = true);
    try {
      final scheduleString = _generateScheduleString();
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'storeName': _nameController.text,
        'description': _descController.text,
        'address': _addressController.text,
        'phoneNumber': _phoneController.text,
        'email': _emailController.text,
        'established': _yearController.text,
        'openingHours': scheduleString,
        'storeLat': _storeLat,
        'storeLng': _storeLng,
      }, SetOptions(merge: true));

      setState(() {
        isEditing = false;
        isSaving = false;
      });
      _showToast("Profil berhasil disimpan!", ToastificationType.success);
    } catch (e) {
      setState(() => isSaving = false);
      _showToast("Gagal menyimpan: $e", ToastificationType.error);
    }
  }

  void _handleDayToggle(String day) {
    setState(() {
      if (selectedDays.contains(day)) {
        selectedDays.remove(day);
      } else {
        selectedDays.add(day);
      }
      selectedDays.sort((a, b) => DAYS.indexOf(a).compareTo(DAYS.indexOf(b)));
    });
  }

  Future<void> _selectTime(bool isOpenTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpenTime ? openTime : closeTime,
    );
    if (picked != null) {
      setState(() => isOpenTime ? openTime = picked : closeTime = picked);
    }
  }

  void _showToast(String msg, ToastificationType type) {
    toastification.show(
      context: context,
      title: Text(msg),
      type: type,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  Future<void> _pickLocation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLocation: (_storeLat != null && _storeLng != null)
              ? LatLng(_storeLat!, _storeLng!)
              : const LatLng(-6.200000, 106.816666),
          onLocationPicked: (LatLng loc, String address) {
            setState(() {
              _storeLat = loc.latitude;
              _storeLng = loc.longitude;
              _addressController.text = address;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF6D4C41).withOpacity(0.2)
        : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white70 : Colors.grey[600]!;
    final primaryColor = theme.primaryColor;

    String displayName = businessProfile['name'];
    if (displayName.isEmpty) displayName = "Toko Tanpa Nama";
    String image = businessProfile['image'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                     Color(0xFF1976D2),
                     Color(0xFF0D47A1),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    children: [
                       // Back Button for Visitor
                       if (!isMyProfile)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_back, color: Colors.white),
                              ),
                            ),
                          ),
                        ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Back Button for Owner (styled like settings button)
                          if (isMyProfile)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          // Avatar with Badge
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: (image != "" && image.startsWith("http"))
                                        ? NetworkImage(image)
                                        : null,
                                    child: (image == "" || !image.startsWith("http"))
                                        ? Text(
                                            displayName.isNotEmpty
                                                ? displayName[0].toUpperCase()
                                                : "?",
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1976D2),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              if (isMyProfile)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _handleImageUpload,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981), // Emerald
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: isUploading
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              LucideIcons.camera,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          
                          // Name and Role
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  businessProfile['description'].isNotEmpty 
                                      ? businessProfile['description'] 
                                      : "Deskripsi toko belum diisi",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        LucideIcons.store,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        businessProfile['owner'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
            
                          // Action Buttons (Settings Only)
                          if (isMyProfile)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: InkWell(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: const Icon(LucideIcons.settings, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. STATS GRID (2x2 Layout like profile_screen.dart)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStatCardNew(
                        "Penjualan",
                        "${businessProfile['totalSales']}",
                        LucideIcons.trendingUp,
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCardNew(
                        "Rating Toko",
                        "${businessProfile['rating']}",
                        LucideIcons.star,
                        Colors.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatCardNew(
                        "Ulasan Toko",
                        "${businessProfile['totalReviews']}",
                        LucideIcons.messageCircle,
                        Colors.purple,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCardNew(
                        "Total Ulasan",
                        "$totalAllInteractions",
                        LucideIcons.users,
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. INFORMASI BISNIS (matching profile_screen.dart style)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Informasi Bisnis",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        // Tombol Edit hanya jika profil sendiri
                        if (isMyProfile)
                          isEditing
                              ? Row(
                                  children: [
                                    InkWell(
                                      onTap: _toggleEdit,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          LucideIcons.x,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: isSaving ? null : _handleSave,
                                      icon: isSaving
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              LucideIcons.save,
                                              size: 14,
                                            ),
                                      label: const Text(
                                        "Simpan",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : TextButton.icon(
                                  onPressed: _toggleEdit,
                                  icon: const Icon(LucideIcons.edit2, size: 14),
                                  label: const Text("Edit"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF2563EB),
                                  ),
                                ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  if (isEditing) ...[
                    // FORM EDIT
                    _buildEditInput(
                      "Nama Toko",
                      _nameController,
                      textColor: textColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildEditInput(
                      "Deskripsi",
                      _descController,
                      maxLines: 3,
                      textColor: textColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildEditInput(
                      "Alamat",
                      _addressController,
                      icon: LucideIcons.mapPin,
                      textColor: textColor,
                      isDark: isDark,
                      readOnly: true,
                      onTap: _pickLocation,
                      suffixIcon: IconButton(
                        icon: const Icon(LucideIcons.map),
                        onPressed: _pickLocation,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildEditInput(
                      "Telepon",
                      _phoneController,
                      icon: LucideIcons.phone,
                      textColor: textColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildEditInput(
                      "Email",
                      _emailController,
                      icon: LucideIcons.mail,
                      textColor: textColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildEditInput(
                      "Berdiri Sejak",
                      _yearController,
                      icon: LucideIcons.store,
                      textColor: textColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.brown[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.transparent
                              : Colors.brown[100]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 16,
                                color: labelColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Atur Jam Operasional",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: labelColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: DAYS.map((day) {
                              final isSelected = selectedDays.contains(day);
                              return InkWell(
                                onTap: () => _handleDayToggle(day),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor.withOpacity(0.1)
                                        : (isDark
                                              ? Colors.black26
                                              : Colors.white),
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryColor
                                          : (isDark
                                                ? Colors.transparent
                                                : Colors.grey[300]!),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    day.substring(0, 3),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected
                                          ? primaryColor
                                          : labelColor,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimePickerButton(
                                  "Buka",
                                  openTime,
                                  true,
                                  isDark,
                                  primaryColor,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text("-"),
                              ),
                              Expanded(
                                child: _buildTimePickerButton(
                                  "Tutup",
                                  closeTime,
                                  false,
                                  isDark,
                                  primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Preview: ${_generateScheduleString().isEmpty ? 'Belum diatur' : _generateScheduleString()}",
                            style: TextStyle(
                              fontSize: 11,
                              color: labelColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // VIEW MODE
                    _buildDescriptionView(isDark),
                    const SizedBox(height: 20),
                    _buildInfoRow(
                      LucideIcons.mapPin,
                      "Alamat",
                      businessProfile['address'],
                      textColor,
                      labelColor,
                    ),
                    _buildInfoRow(
                      LucideIcons.phone,
                      "Telepon",
                      businessProfile['phone'],
                      textColor,
                      labelColor,
                    ),
                    _buildInfoRow(
                      LucideIcons.mail,
                      "Email",
                      businessProfile['email'],
                      textColor,
                      labelColor,
                    ),
                    _buildInfoRow(
                      LucideIcons.clock,
                      "Jam Operasional",
                      businessProfile['openingHours'],
                      textColor,
                      labelColor,
                    ),
                    _buildInfoRow(
                      LucideIcons.store,
                      "Berdiri Sejak",
                      businessProfile['established'],
                      textColor,
                      labelColor,
                    ),
                  ],
                ],
              ),
            ),
          ),

            const SizedBox(height: 16),

            // 4. LIST ULASAN (Realtime)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ulasan Toko",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "Terbaru",
                        style: TextStyle(color: primaryColor, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('shopId', isEqualTo: widget.shopId ?? user?.uid)
                        .orderBy('createdAt', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black26
                                      : Colors.brown[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.star,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Belum ada ulasan toko.",
                                style: TextStyle(
                                  color: labelColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          bool isShopReview =
                              (data['productId'] == null ||
                              data['productId'] == "");

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.user,
                                      size: 12,
                                      color: labelColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      data['userName'] ?? "Pembeli",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: textColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      LucideIcons.star,
                                      size: 12,
                                      color: Colors.orange,
                                    ),
                                    Text(
                                      " ${data['rating']}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: isShopReview
                                        ? Colors.purple.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isShopReview
                                        ? "Ulasan Toko"
                                        : "Ulasan Produk",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isShopReview
                                          ? Colors.purple
                                          : Colors.blue,
                                    ),
                                  ),
                                ),
                                Text(
                                  data['comment'] ?? "",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: labelColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildHeaderIcon(
    BuildContext context,
    IconData icon,
    Widget destination,
  ) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // --- WIDGET STAT CARD YANG SUDAH DIPERBAIKI ---
  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color bg,
    Color text,
    Color iconColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 4),
            // PERBAIKAN: Gunakan FittedBox agar teks panjang tidak error
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value == "0" ? "-" : value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: text,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW STAT CARD MATCHING PROFILE_SCREEN.DART ---
  Widget _buildStatCardNew(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6, left: 4),
          child: Text(
            "Nama Toko dan Deskripsi",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                businessProfile['name'] ?? "",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                businessProfile['description'].isNotEmpty
                    ? businessProfile['description']
                    : "Deskripsi toko belum diisi",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color text,
    Color labelColor,
  ) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditInput(
    String label,
    TextEditingController controller, {
    IconData? icon,
    int maxLines = 1,
    String? placeholder,
    required Color textColor,
    required bool isDark,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(fontSize: 13, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
        prefixIcon: icon != null
            ? Icon(icon, size: 16, color: Colors.grey)
            : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildTimePickerButton(
    String label,
    TimeOfDay time,
    bool isOpenTime,
    bool isDark,
    Color activeColor,
  ) {
    return InkWell(
      onTap: () => _selectTime(isOpenTime),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isDark ? Colors.white10 : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
            Text(
              "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : activeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
