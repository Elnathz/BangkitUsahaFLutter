import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
// import 'package:intl/intl.dart'; // Date removed
import '../services/firebase_storage_service.dart';
import 'edit_photo_screen.dart';

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
  String? _selectedLocation;
  // DateTime? _selectedDate; // Removed

  final List<String> categories = [
    'Tips Bisnis',
    'Tanya Jawab',
    'Sharing Pengalaman',
    'Promosi',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null && mounted) {
        setState(() => _imageFile = image);
      }
    } catch (e) {
      debugPrint("Gagal ambil gambar: $e");
    }
  }

  // Future<void> _pickDate() async { ... } // Removed

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _showLocationError('Location services are disabled.');
          return;
        }

        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            _showLocationError('Location permissions are denied');
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          _showLocationError('Location permissions are permanently denied.');
          return;
        }

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Getting location...")),
        );

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String loc = "${place.subLocality ?? ''} ${place.locality ?? ''}";
          if (loc.trim().isEmpty) {
             loc = "${place.administrativeArea ?? 'Unknown Location'}";
          }
          if (mounted) {
            setState(() => _selectedLocation = loc.trim());
          }
        }
    } catch (e) {
      debugPrint("Error getting location: $e");
      // Fallback to manual picker if GPS fails
      _pickLocationManual(); 
    }
  }
  
  void _showLocationError(String msg) {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickLocationManual() async {
     String? manualLoc = await showDialog<String>(
       context: context,
       builder: (context) {
         TextEditingController locCtrl = TextEditingController();
         return AlertDialog(
           title: const Text("Pick Location"),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               TextField(
                 controller: locCtrl,
                 decoration: const InputDecoration(
                    hintText: "Search city or place...",
                    prefixIcon: Icon(LucideIcons.search),
                 ),
               ),
               const SizedBox(height: 10),
               // Dummy suggestions
               ListTile(
                  leading: const Icon(LucideIcons.mapPin),
                  title: const Text("Jakarta, Indonesia"),
                  onTap: () => Navigator.pop(context, "Jakarta, Indonesia"),
               ),
               ListTile(
                  leading: const Icon(LucideIcons.mapPin),
                  title: const Text("Surabaya, Indonesia"),
                  onTap: () => Navigator.pop(context, "Surabaya, Indonesia"),
               ),
             ],
           ),
           actions: [
             TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
             ElevatedButton(
                onPressed: () => Navigator.pop(context, locCtrl.text),
                child: const Text("Select"),
             ),
           ],
         );
       }
     );
     
     if (manualLoc != null && manualLoc.isNotEmpty && mounted) {
        setState(() => _selectedLocation = manualLoc);
     }
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty && _imageFile == null) return;

    if (!mounted) return;
    
    setState(() => _isUploading = true);

    String finalName = '';
    String businessName = 'UMKM Member';

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        finalName =
            data['storeName'] ?? data['ownerName'] ?? data['userName'] ?? '';
      }
    } catch (e) {
      debugPrint("Gagal ambil data user: $e");
    }

    if (finalName.isEmpty) {
      finalName = widget.currentUser.displayName ?? 'Pengguna';
    }
    
    // Append meta info
    String finalContent = _contentController.text;
    if (_selectedLocation != null) {
       finalContent += "\n📍 $_selectedLocation";
    }

    await widget.firebaseService.uploadImageAndSavePost(
      imageFile: _imageFile,
      userId: widget.currentUser.uid,
      userName: finalName,
      userAvatar: widget.currentUser.photoURL ?? '',
      businessName: businessName,
      content: finalContent,
      category: _category,
      onProgress: (val) {},
    );

    widget.onSuccess();
    if (mounted) Navigator.pop(context);
  }

  Color _getIndicatorColor(int remaining) {
    if (remaining <= 0) return Colors.red;
    if (remaining <= 20) return Colors.orange;
    return const Color(0xFF1DA1F2);
  }

  @override
  Widget build(BuildContext context) {
    final int textLength = _contentController.text.length;
    final int maxLength = 280;
    final int remaining = maxLength - textLength;
    final double progress = (textLength / maxLength).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Twitter-like Header
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Cancel button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    
                    // Category Dropdown (Moved here)
                    Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _category,
                            style: const TextStyle(
                              color: Color(0xFF1DA1F2),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            dropdownColor: Colors.white,
                            icon: const Icon(
                              LucideIcons.chevronDown,
                              color: Color(0xFF1DA1F2),
                              size: 16,
                            ),
                            items: categories
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _category = val!),
                          ),
                        ),
                      ),
                      
                    // Post button
                    ElevatedButton(
                      onPressed: (_isUploading ||
                              (_contentController.text.trim().isEmpty &&
                                  _imageFile == null) ||
                              remaining < 0)
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DA1F2), // Twitter Blue
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Post',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // Main content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Avatar
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: widget.currentUser.photoURL != null
                          ? NetworkImage(widget.currentUser.photoURL!)
                          : null,
                      child: widget.currentUser.photoURL == null
                          ? const Icon(LucideIcons.user, color: Colors.grey, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Content area
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          // Text input
                          TextField(
                            controller: _contentController,
                            autofocus: true,
                            maxLines: null,
                            maxLength: maxLength, // Adds limit behavior
                            buildCounter: (
                              context, {
                              required currentLength,
                              required isFocused,
                              required maxLength,
                            }) => null, // Hide default counter
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText: "What's happening?",
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 18,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (text) => setState(() {}),
                          ),
                          
                          // Optional Location Indicator
                          if (_selectedLocation != null)
                             Padding(
                               padding: const EdgeInsets.only(bottom: 8),
                               child: Row(
                                 children: [
                                   const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF1DA1F2)),
                                   const SizedBox(width: 4),
                                   Text(_selectedLocation!, style: const TextStyle(color: Color(0xFF1DA1F2), fontSize: 13)),
                                   const SizedBox(width: 4),
                                   // Remove X
                                   InkWell(
                                     onTap: () => setState(() => _selectedLocation = null),
                                     child: const Icon(LucideIcons.x, size: 14, color: Colors.grey),
                                   )
                                 ],
                               ),
                             ),

                          // Image Preview
                          if (_imageFile != null) ...[
                            const SizedBox(height: 16),
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final editedFile = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditPhotoScreen(imageFile: _imageFile!),
                                      ),
                                    );
                                    if (editedFile != null && editedFile is XFile) {
                                       setState(() => _imageFile = editedFile);
                                    }
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxHeight: 300, 
                                      ),
                                      width: double.infinity,
                                      child: _buildImagePreview(),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: InkWell(
                                    onTap: () => setState(() => _imageFile = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.75),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LucideIcons.x,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom toolbar with media buttons
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Reordered Toolbar: Image, Location (Picker)
                      _buildMediaButton(LucideIcons.image, _pickImage),
                      _buildMediaButton(LucideIcons.mapPin, () {
                        // Show simple dialog to choose Auto or Manual
                        showModalBottomSheet(
                          context: context, 
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(LucideIcons.navigation),
                                  title: const Text("Current Location (GPS)"),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _getLocation();
                                  }
                                ),
                                ListTile(
                                  leading: const Icon(LucideIcons.search),
                                  title: const Text("Pick Manually"),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _pickLocationManual();
                                  }
                                ),
                              ],
                            ),
                          )
                        );
                      }),
                      
                      const Spacer(),

                      // Character Counter Indicator
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(_getIndicatorColor(remaining)),
                                strokeWidth: 3,
                              ),
                            ),
                            if (remaining <= 20)
                              Text(
                                '$remaining',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getIndicatorColor(remaining),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Category Removed from toolbar (moved to top)
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: const Color(0xFF1DA1F2),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile == null) return const SizedBox.shrink();
    
    if (kIsWeb) {
      // safe check for path
      if (_imageFile!.path.isEmpty) {
         // It's likely from bytes (XFile.fromData)
         return FutureBuilder<Uint8List>(
           future: _imageFile!.readAsBytes(),
           builder: (ctx, snapshot) {
             if (snapshot.hasData) {
               return Image.memory(
                 snapshot.data!,
                 fit: BoxFit.cover,
                 width: double.infinity,
               );
             }
             return const Center(child: CircularProgressIndicator());
           },
         );
      }
      return Image.network(
        _imageFile!.path,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    
    return Image.file(
      File(_imageFile!.path),
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }
}
