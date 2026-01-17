import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// --- IMPORT HALAMAN LAIN ---
import 'order_history_screen.dart';
import 'settings_screen.dart';
import '../notifications/notification_screen.dart';
import '../chat/chat_screen.dart';
import 'widgets/reviews_modal.dart';
import '../../services/market_service.dart';
import '../../map_picker_screen.dart';
import '../../services/notification_service.dart';

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
    // Sinkronisasi Token FCM agar notifikasi masuk ke akun yang benar
    NotificationService.syncFCMToken();
  }

  Future<void> _fetchUserData() async {
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .snapshots()
        .listen((docSnap) {
          if (!mounted) return;

          FirebaseFirestore.instance
              .collection('reviews')
              .where('shopId', isEqualTo: user!.uid)
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
                'name': data['storeName'] ?? user!.displayName ?? "Toko Saya",
                'owner': data['ownerName'] ?? user!.displayName ?? "Pemilik",
                'description': data['description'] ?? "",
                'address': data['address'] ?? "",
                'phone': data['phoneNumber'] ?? "",
                'email': data['email'] ?? user!.email ?? "",
                'openingHours': data['openingHours'] ?? "",
                'established': data['established'] ?? "",
                'image': data['image'] ?? user!.photoURL ?? "",
                'rating': (data['rating'] ?? 0).toDouble(),
                'totalReviews': data['totalReviews'] ?? 0,
                'totalSales': data['totalSales'] ?? 0,
                'responseRate': data['responseRate'] ?? 0,
                'storeLat': (data['storeLat'] as num?)?.toDouble(),
                'storeLng': (data['storeLng'] as num?)?.toDouble(),
              };
              isLoading = false;
            });
          } else {
            setState(() {
              businessProfile = {
                'name': user!.displayName ?? "Nama Toko Anda",
                'owner': user!.displayName ?? "Nama Pemilik",
                'description': "",
                'address': "",
                'phone': user!.phoneNumber ?? "",
                'email': user!.email ?? "",
                'openingHours': "",
                'established': "",
                'image': user!.photoURL ?? "",
                'rating': 0.0,
                'totalReviews': 0,
                'totalSales': 0,
                'responseRate': 0,
                'storeLat': null,
                'storeLng': null,
              };
              isLoading = false;
            });
          }
        });
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

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'image': downloadURL,
      }, SetOptions(merge: true));
      await user!.updatePhotoURL(downloadURL);
      _showToast("Foto berhasil diperbarui!", ToastificationType.success);
    } catch (e) {
      _showToast("Gagal upload: $e", ToastificationType.error);
    } finally {
      setState(() => isUploading = false);
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
        'ownerName': user!.displayName ?? "Pemilik",
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
              _addressController.text = address; // Gunakan alamat lengkap
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

    // Background gradient for the whole screen
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildOrderSection(context),
                  const SizedBox(height: 16),
                  _buildStatsSection(context),
                  const SizedBox(height: 16),
                  _buildBusinessInfoSection(context),
                  const SizedBox(height: 16),
                  _buildReviewsSection(context),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    String displayName = businessProfile['name'];
    // if (displayName.isEmpty) displayName = "Nama Toko Anda"; // Removed as we use businessProfile['name'] directly in specific place
    String image = businessProfile['image'];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                        backgroundImage:
                            (image != "" && image.startsWith("http"))
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
                      businessProfile['name'] ?? "Nama Toko",
                      style: const TextStyle(
                        fontSize: 22, // Slightly larger
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
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

              // Action Buttons
              Row(
                children: [
                  _buildActionButton(
                    context,
                    LucideIcons.bell,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    context,
                    LucideIcons.messageSquare,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    context,
                    LucideIcons.settings,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
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

  Widget _buildOrderSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: MarketService().getMyOrders(),
      builder: (context, snapshot) {
        int pending = 0;
        int packing = 0;
        int shipping = 0;
        int completed = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'];
            if (status == 'Menunggu') {
              pending++;
            } else if (status == 'Diproses')
              packing++; // Assuming 'Diproses' maps to Packed
            else if (status == 'Diantar')
              shipping++;
            else if (status == 'Selesai')
              completed++;
          }
        }

        return Container(
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Pesanan Saya",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrderHistoryScreen(),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            "Lihat Riwayat",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Used Wrap with spaceEvenly alignment to bring icons closer but still distributed
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Center(
                        child: _buildOrderIcon(
                          context,
                          "Menunggu",
                          pending,
                          LucideIcons.shoppingBag,
                          Colors.amber,
                          Colors.amber[50]!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: _buildOrderIcon(
                          context,
                          "Dikemas",
                          packing,
                          LucideIcons.package,
                          Colors.blue,
                          Colors.blue[50]!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: _buildOrderIcon(
                          context,
                          "Dikirim",
                          shipping,
                          LucideIcons.truck,
                          Colors.purple,
                          Colors.purple[50]!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: _buildOrderIcon(
                          context,
                          "Selesai",
                          completed,
                          LucideIcons.checkCircle,
                          Colors.green,
                          Colors.green[50]!,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderIcon(
    BuildContext context,
    String label,
    int count,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bgColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (count > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              "Penjualan",
              "${businessProfile['totalSales']}",
              LucideIcons.trendingUp,
              Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
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
            _buildStatCard(
              "Ulasan Toko",
              "${businessProfile['totalReviews']}",
              LucideIcons.messageCircle,
              Colors.purple,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              "Total Ulasan",
              "$totalAllInteractions",
              LucideIcons.users,
              Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        // Removed fixed height to prevent overflow
        padding: const EdgeInsets.all(12), // Reduced padding for compact screens
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

  Widget _buildBusinessInfoSection(BuildContext context) {
    return Container(
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
                Text(
                  "Informasi Bisnis",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
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
              _buildEditInput("Nama Toko", _nameController),
              const SizedBox(height: 12),
              _buildEditInput("Deskripsi", _descController, maxLines: 3),
              const SizedBox(height: 12),
              _buildEditInput(
                "Alamat",
                _addressController,
                icon: LucideIcons.mapPin,
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
              const SizedBox(height: 16),
              const Text(
                "Jam Operasional",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DAYS.map((day) {
                  final isSelected = selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (_) => _handleDayToggle(day),
                    selectedColor: const Color(0xFF2563EB).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF2563EB),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(true),
                      child: Text("Buka: ${openTime.format(context)}"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(false),
                      child: Text("Tutup: ${closeTime.format(context)}"),
                    ),
                  ),
                ],
              ),
            ] else ...[
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
              const SizedBox(height: 16),
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
                LucideIcons.calendar,
                "Berdiri Sejak",
                businessProfile['established'],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
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

  Widget _buildReviewsSection(BuildContext context) {
    return Container(
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Ulasan Toko",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => ReviewsModal(shopId: user!.uid),
                    );
                  },
                  child: Row(
                    children: [
                      const Text(
                        "Lihat Semua",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),

            // Scrollable Reviews List
            SizedBox(
              height: 300,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reviews')
                    .where('shopId', isEqualTo: user!.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "Belum ada ulasan",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      // Handle date formatting
                      String dateStr = "";
                      if (data['createdAt'] != null) {
                        final timestamp = data['createdAt'] as Timestamp;
                        final now = DateTime.now();
                        final diff = now.difference(timestamp.toDate());
                        if (diff.inDays > 0) {
                          dateStr = "${diff.inDays} hari lalu";
                        } else if (diff.inHours > 0) {
                          dateStr = "${diff.inHours} jam lalu";
                        } else {
                          dateStr = "${diff.inMinutes} menit lalu";
                        }
                      }

                      return _buildReviewItem(
                        data['userName'] ?? "Pengguna",
                        data['userAvatar'] ?? "",
                        (data['rating'] ?? 0).toInt(),
                        data['comment'] ?? "",
                        dateStr,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(
    String name,
    String avatarUrl,
    int rating,
    String comment,
    String date,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            backgroundImage: NetworkImage(avatarUrl),
            onBackgroundImageError: (_, __) {},
            child: const Icon(Icons.person, size: 16, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            "$rating",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "Ulasan Toko",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple[700],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  comment,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: Colors.grey[600])
            : null,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      readOnly: readOnly,
      onTap: onTap,
    );
  }
}
