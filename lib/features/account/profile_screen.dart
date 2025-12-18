import 'dart:typed_data'; // PENTING: Untuk support Web (Chrome)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';

// Konstanta Hari
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

  // State UI
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;
  bool isUploading = false;

  // Data Utama
  Map<String, dynamic> businessProfile = {
    'name': 'Memuat...',
    'owner': '',
    'category': '-',
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

  // Controllers
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  // State Khusus Jadwal
  List<String> selectedDays = [];
  TimeOfDay openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay closeTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 1. FETCH DATA
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

  // 2. LOGIKA UPLOAD FOTO
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

  // 3. PARSE SCHEDULE
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

  // 4. SAVE DATA
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

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // === HEADER BARU (PASTI BISA DIKLIK) ===
            // Menggunakan SizedBox tinggi untuk menampung stack
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    height: 160,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF9333EA)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 110, // Posisi foto (160 - radius 50 = 110)
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.grey[200],
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
                                        ? businessProfile['name'][0]
                                              .toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: isUploading
                                ? null
                                : _handleImageUpload, // Tombol Kamera
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      LucideIcons.camera,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tidak perlu SizedBox(height: 60) lagi karena sudah dihandle di atas

            // INFO
            Text(
              businessProfile['name'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.user, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  businessProfile['owner'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Chip(label: Text(businessProfile['category'])),
            const SizedBox(height: 24),

            // STATS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatCard(
                    "Penjualan",
                    "${businessProfile['totalSales']}",
                    LucideIcons.award,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    "Rating",
                    "${businessProfile['rating']}",
                    LucideIcons.star,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    "Ulasan",
                    "${businessProfile['totalReviews']}",
                    LucideIcons.messageSquare,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    "Respon",
                    "${businessProfile['responseRate']}%",
                    LucideIcons.messageCircle,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Informasi Bisnis",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                                      color: Colors.red[50],
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
                                foregroundColor: Colors.blue[600],
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
                      placeholder: "Contoh: Toko kami menyediakan...",
                    ),
                    const SizedBox(height: 12),
                    _buildEditInput(
                      "Alamat",
                      _addressController,
                      icon: LucideIcons.mapPin,
                    ),
                    const SizedBox(height: 12),
                    _buildEditInput(
                      "Telepon",
                      _phoneController,
                      icon: LucideIcons.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildEditInput(
                      "Email",
                      _emailController,
                      icon: LucideIcons.mail,
                    ),
                    const SizedBox(height: 12),
                    _buildEditInput(
                      "Berdiri Sejak",
                      _yearController,
                      icon: LucideIcons.store,
                    ),

                    const SizedBox(height: 20),
                    // Jadwal UI Asli Anda
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Atur Jam Operasional",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
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
                                        ? Colors.blue[50]
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    day.substring(0, 3),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected
                                          ? Colors.blue[700]
                                          : Colors.grey[600],
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
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Preview: ${_generateScheduleString().isEmpty ? 'Belum diatur' : _generateScheduleString()}",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _buildDescriptionView(),
                    const SizedBox(height: 20),
                    _buildInfoRow(
                      LucideIcons.mapPin,
                      "Alamat",
                      businessProfile['address'],
                    ),
                    _buildInfoRow(
                      LucideIcons.phone,
                      "Telepon",
                      businessProfile['phone'],
                    ),
                    _buildInfoRow(
                      LucideIcons.mail,
                      "Email",
                      businessProfile['email'],
                    ),
                    _buildInfoRow(
                      LucideIcons.clock,
                      "Jam Operasional",
                      businessProfile['openingHours'],
                    ),
                    _buildInfoRow(
                      LucideIcons.store,
                      "Berdiri Sejak",
                      businessProfile['established'],
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Ulasan Pelanggan",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Lihat Semua",
                        style: TextStyle(color: Colors.blue[600], fontSize: 12),
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
                            color: Colors.grey[100],
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
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    LucideIcons.settings,
                    "Pengaturan",
                    () =>
                        _showToast("Menu Pengaturan", ToastificationType.info),
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    LucideIcons.logOut,
                    "Keluar Aplikasi",
                    _handleLogout,
                    isDanger: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: Colors.blue[600]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            Text(
              value == "0" ? "-" : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionView() {
    bool isEmpty =
        businessProfile['description'] == null ||
        businessProfile['description'].isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        isEmpty
            ? "Deskripsi toko belum diisi."
            : businessProfile['description'],
        style: TextStyle(
          fontSize: 13,
          color: isEmpty ? Colors.grey[400] : Colors.grey[700],
          fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                Text(
                  value.isEmpty ? "-" : value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        prefixIcon: icon != null
            ? Icon(icon, size: 16, color: Colors.grey)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildTimePickerButton(String label, TimeOfDay time, bool isOpenTime) {
    return InkWell(
      onTap: () => _selectTime(isOpenTime),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDanger ? Colors.red[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDanger ? Colors.red : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDanger ? Colors.red : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
