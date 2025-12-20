import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';

import 'settings_screen.dart';

const List<String> DAYS = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;
  bool isUploading = false;

  Map<String, dynamic> businessProfile = {
    'name': 'Memuat...',
    'owner': '',
    'description': '',
    'address': '',
    'phone': '',
    'email': '',
    'openingHours': '',
    'established': '',
    'image': '',
    'rating': 0,
    'totalReviews': 0,
    'totalSales': 0,
    'responseRate': 0,
  };

  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  List<String> selectedDays = [];
  TimeOfDay openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay closeTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user == null) return;
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (docSnap.exists) {
        final data = docSnap.data()!;
        setState(() {
          businessProfile = {
            'name': data['storeName'] ?? user!.displayName ?? "Toko Saya",
            'owner': data['ownerName'] ?? user!.displayName ?? "Pemilik",
            'category': data['category'] ?? "Umum",
            'description': data['description'] ?? "",
            'address': data['address'] ?? "",
            'phone': data['phoneNumber'] ?? "",
            'email': data['email'] ?? user!.email ?? "",
            'openingHours': data['openingHours'] ?? "",
            'established': data['established'] ?? "",
            'image': data['image'] ?? user!.photoURL ?? "",
            'rating': data['rating'] ?? 0,
            'totalReviews': data['totalReviews'] ?? 0,
            'totalSales': data['totalSales'] ?? 0,
            'responseRate': data['responseRate'] ?? 0,
          };
        });
      } else {
        setState(() {
          businessProfile['name'] = user!.displayName ?? "Toko Baru";
          businessProfile['owner'] = user!.displayName ?? "Pemilik";
          businessProfile['email'] = user!.email ?? "";
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleImageUpload() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => isUploading = true);
    _showToast("Mengunggah foto...", ToastificationType.info);

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_photos/${user!.uid}',
      );
      Uint8List imageData = await image.readAsBytes();
      await storageRef.putData(
        imageData,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadURL = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'image': downloadURL});
      await user!.updatePhotoURL(downloadURL);

      setState(() {
        businessProfile['image'] = downloadURL;
        isUploading = false;
      });

      _showToast("Foto berhasil diperbarui!", ToastificationType.success);
    } catch (e) {
      setState(() => isUploading = false);
      _showToast("Gagal upload: $e", ToastificationType.error);
    }
  }

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
      debugPrint("Reset jadwal parsing error");
    }
  }

  TimeOfDay _stringToTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _handleSave() async {
    setState(() => isSaving = true);
    try {
      final scheduleString = _generateScheduleString();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
            'description': _descController.text,
            'address': _addressController.text,
            'phoneNumber': _phoneController.text,
            'email': _emailController.text,
            'established': _yearController.text,
            'openingHours': scheduleString,
          });

      setState(() {
        businessProfile['description'] = _descController.text;
        businessProfile['address'] = _addressController.text;
        businessProfile['phone'] = _phoneController.text;
        businessProfile['email'] = _emailController.text;
        businessProfile['established'] = _yearController.text;
        businessProfile['openingHours'] = scheduleString;
        isEditing = false;
        isSaving = false;
      });

      _showToast("Informasi bisnis disimpan!", ToastificationType.success);
    } catch (e) {
      setState(() => isSaving = false);
      _showToast("Gagal menyimpan.", ToastificationType.error);
    }
  }

  void _toggleEdit() {
    if (!isEditing) {
      _descController.text = businessProfile['description'];
      _addressController.text = businessProfile['address'];
      _phoneController.text = businessProfile['phone'];
      _emailController.text = businessProfile['email'];
      _yearController.text = businessProfile['established'];
      _parseSchedule(businessProfile['openingHours']);
    }
    setState(() => isEditing = !isEditing);
  }

  void _handleDayToggle(String day) {
    setState(() {
      if (selectedDays.contains(day))
        selectedDays.remove(day);
      else
        selectedDays.add(day);
      selectedDays.sort((a, b) => DAYS.indexOf(a).compareTo(DAYS.indexOf(b)));
    });
  }

  Future<void> _selectTime(bool isOpenTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpenTime ? openTime : closeTime,
    );
    if (picked != null)
      setState(() => isOpenTime ? openTime = picked : closeTime = picked);
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

  void _showToast(String msg, ToastificationType type) {
    toastification.show(
      context: context,
      title: Text(msg),
      type: type,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color cardColor = isDark
        ? const Color(0xFF6D4C41).withOpacity(0.2)
        : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color labelColor = isDark ? Colors.white70 : Colors.grey[600]!;
    final Color primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ============================================================
            // HEADER BARU: PROFIL DI DALAM (PROFESSIONAL LOOK)
            // ============================================================
            Container(
              padding: const EdgeInsets.only(
                top: 50,
                bottom: 24,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    const Color(0xFF503C37), // Cokelat Lebih Gelap (Van Dike)
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 1. FOTO PROFIL (KIRI)
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2), // Border putih tipis
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 32, // Ukuran Foto sedang
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              (businessProfile['image'] != "" &&
                                  businessProfile['image'] != null)
                              ? NetworkImage(businessProfile['image'])
                              : null,
                          child:
                              (businessProfile['image'] == "" ||
                                  businessProfile['image'] == null)
                              ? Text(
                                  businessProfile['name'].isNotEmpty
                                      ? businessProfile['name'][0].toUpperCase()
                                      : "?",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // Ikon Kamera Kecil untuk Edit
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: isUploading ? null : _handleImageUpload,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryColor, width: 1),
                            ),
                            child: isUploading
                                ? SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryColor,
                                    ),
                                  )
                                : Icon(
                                    LucideIcons.camera,
                                    size: 12,
                                    color: primaryColor,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // 2. NAMA TOKO & PEMILIK (TENGAH)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessProfile['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Teks Putih di atas Cokelat
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.user,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              businessProfile['owner'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Akun Bisnis",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. ICON NOTIF & CHAT (KANAN ATAS)
                  Row(
                    children: [
                      _buildHeaderIcon(
                        LucideIcons.bell,
                        () => _showToast(
                          "Notifikasi kosong",
                          ToastificationType.info,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderIcon(
                        LucideIcons.messageCircle,
                        () => _showToast(
                          "Belum ada pesan",
                          ToastificationType.info,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ============================================================
            const SizedBox(height: 24),

            // STATS GRID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatCard(
                    "Penjualan",
                    "${businessProfile['totalSales']}",
                    LucideIcons.award,
                    cardColor,
                    textColor,
                    primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    "Rating",
                    "${businessProfile['rating']}",
                    LucideIcons.star,
                    cardColor,
                    textColor,
                    primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    "Ulasan",
                    "${businessProfile['totalReviews']}",
                    LucideIcons.messageSquare,
                    cardColor,
                    textColor,
                    primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    "Respon",
                    "${businessProfile['responseRate']}%",
                    LucideIcons.messageCircle,
                    cardColor,
                    textColor,
                    primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CARD INFORMASI
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Informasi Bisnis",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
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
                                      : const Icon(LucideIcons.save, size: 14),
                                  label: const Text(
                                    "Simpan",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
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
                                foregroundColor: primaryColor,
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (isEditing) ...[
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
            const SizedBox(height: 16),

            // REVIEWS
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
                        "Ulasan Pelanggan",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "Lihat Semua",
                        style: TextStyle(color: primaryColor, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.brown[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.star,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Belum ada ulasan.",
                          style: TextStyle(color: labelColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // MENU PENGATURAN
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.settings,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
                title: Text(
                  "Pengaturan",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  // Widget Icon Header Transparan
  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15), // Background transparan
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

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
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            Text(
              value == "0" ? "-" : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: text,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionView(bool isDark) {
    bool isEmpty =
        businessProfile['description'] == null ||
        businessProfile['description'].isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.brown[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.brown[100]!,
        ),
      ),
      child: Text(
        isEmpty
            ? "Deskripsi toko belum diisi."
            : businessProfile['description'],
        style: TextStyle(
          fontSize: 13,
          color: isEmpty
              ? Colors.grey[400]
              : (isDark ? Colors.grey[300] : Colors.black87),
          fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color text,
    Color labelColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: labelColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
                Text(
                  value.isEmpty ? "-" : value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: text,
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
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(fontSize: 13, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
        hintStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: icon != null
            ? Icon(icon, size: 16, color: Colors.grey)
            : null,
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
