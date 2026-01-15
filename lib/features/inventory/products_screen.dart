import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart';
import '../../services/market_service.dart';

// IMPORT HALAMAN LAIN
import '../home/product_reviews_screen.dart';
import '../shop/shop_profile_screen.dart';
import '../chat/chat_screen.dart';
import '../notifications/notification_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = FirebaseAuth.instance.currentUser;

  String _selectedCategory = "Semua";
  String _selectedOrderStatus = "Semua"; // Order status filter
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  // --- LOGIC: CEK PROFIL TOKO ---
  Future<void> _checkStoreProfileBeforeAdd() async {
    if (user == null) return;
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (!docSnap.exists) {
        _showWarningDialog("Data user tidak ditemukan.");
        return;
      }

      final data = docSnap.data() as Map<String, dynamic>;
      final String? storeName = data['storeName'];
      final String? address = data['address'];

      if (storeName == null ||
          storeName.trim().isEmpty ||
          address == null ||
          address.trim().isEmpty) {
        _showWarningDialog(
          "Profil Toko Belum Lengkap.\n\nAnda harus mengisi Nama Toko dan Alamat sebelum bisa menjual produk.",
          showEditButton: true,
        );
      } else {
        _showProductDialog();
      }
    } catch (e) {
      debugPrint("Error check store: $e");
    }
  }

  void _showWarningDialog(String message, {bool showEditButton = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Perhatian"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("Nanti Saja"),
            onPressed: () => Navigator.pop(context),
          ),
          if (showEditButton)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text(
                "Lengkapi Sekarang",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopProfileScreen(shopId: user!.uid),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- LOGIC PRODUK (CRUD) ---
  Future<void> _showProductDialog({DocumentSnapshot? product}) async {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: isEdit ? product['name'] : '');
    final priceCtrl = TextEditingController(
      text: isEdit ? product['price'].toString() : '',
    );
    final stockCtrl = TextEditingController(
      text: isEdit ? product['stock'].toString() : '',
    );
    final categoryCtrl = TextEditingController(
      text: isEdit ? product['category'] : '',
    );
    final descCtrl = TextEditingController(
      text: isEdit ? product['description'] : '',
    );
    String? imageUrl = isEdit ? product['image'] : null;
    bool isUploading = false;

    final blueColor = const Color(0xFF1976D2);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            Future<void> handleImageUpload() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (image == null) return;

              setStateSB(() => isUploading = true);
              try {
                final ref = FirebaseStorage.instance.ref().child(
                  'product_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
                );
                final data = await image.readAsBytes();
                await ref.putData(
                  data,
                  SettableMetadata(contentType: 'image/jpeg'),
                );
                final url = await ref.getDownloadURL();
                setStateSB(() {
                  imageUrl = url;
                  isUploading = false;
                });
              } catch (e) {
                setStateSB(() => isUploading = false);
              }
            }

            InputDecoration styledInputDecoration(String label) {
              return InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: blueColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: blueColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              isEdit ? LucideIcons.edit2 : LucideIcons.packagePlus,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? "Edit Produk" : "Tambah Produk Baru",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEdit ? "Perbarui detail produk Anda" : "Masukkan detail produk baru Anda",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(LucideIcons.x, size: 18, color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Image Upload Area
                            GestureDetector(
                              onTap: isUploading ? null : handleImageUpload,
                              child: Container(
                                height: 140,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                  image: imageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(imageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: isUploading
                                    ? Center(child: CircularProgressIndicator(color: blueColor))
                                    : (imageUrl == null
                                          ? Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: blueColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(LucideIcons.camera, color: blueColor, size: 28),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  "Upload Foto",
                                                  style: TextStyle(
                                                    color: blueColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : null),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Product Name
                            TextField(
                              controller: nameCtrl,
                              decoration: styledInputDecoration("Nama Produk"),
                            ),
                            const SizedBox(height: 14),
                            
                            // Price and Stock Row
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: priceCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: styledInputDecoration("Harga (Rp)"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: stockCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: styledInputDecoration("Stok"),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            
                            // Category Dropdown with Add Custom Option
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: ['Makanan', 'Minuman', 'Snack', 'Kue', 'Kerajinan', 'Lainnya'].contains(categoryCtrl.text) 
                                        ? categoryCtrl.text 
                                        : (categoryCtrl.text.isEmpty ? null : 'Lainnya'),
                                    decoration: styledInputDecoration("Kategori"),
                                    items: ['Makanan', 'Minuman', 'Snack', 'Kue', 'Kerajinan', 'Lainnya'].map((cat) {
                                      return DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value == 'Lainnya') {
                                        // Show custom category dialog
                                        showDialog(
                                          context: context,
                                          builder: (ctx) {
                                            final customCatCtrl = TextEditingController();
                                            return AlertDialog(
                                              title: const Text("Tambah Kategori Baru"),
                                              content: TextField(
                                                controller: customCatCtrl,
                                                decoration: const InputDecoration(
                                                  hintText: "Nama kategori baru",
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: const Text("Batal"),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    if (customCatCtrl.text.isNotEmpty) {
                                                      setStateSB(() {
                                                        categoryCtrl.text = customCatCtrl.text;
                                                      });
                                                    }
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: const Text("Tambah"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      } else {
                                        setStateSB(() {
                                          categoryCtrl.text = value ?? '';
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    // Show custom category dialog
                                    showDialog(
                                      context: context,
                                      builder: (ctx) {
                                        final customCatCtrl = TextEditingController();
                                        return AlertDialog(
                                          title: const Text("Tambah Kategori Baru"),
                                          content: TextField(
                                            controller: customCatCtrl,
                                            decoration: const InputDecoration(
                                              hintText: "Nama kategori baru",
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text("Batal"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                if (customCatCtrl.text.isNotEmpty) {
                                                  setStateSB(() {
                                                    categoryCtrl.text = customCatCtrl.text;
                                                  });
                                                }
                                                Navigator.pop(ctx);
                                              },
                                              child: const Text("Tambah"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1976D2).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.3)),
                                    ),
                                    child: const Icon(LucideIcons.plus, color: Color(0xFF1976D2), size: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            
                            // Description
                            TextField(
                              controller: descCtrl,
                              maxLines: 3,
                              decoration: styledInputDecoration("Deskripsi Produk"),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Action Buttons
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: Text(
                                "Batal",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isUploading
                                      ? [Colors.grey.shade400, Colors.grey.shade500]
                                      : [const Color(0xFF1976D2), const Color(0xFF0D47A1)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isUploading
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: blueColor.withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: isUploading
                                      ? null
                                      : () async {
                                          if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty)
                                            return;

                                          String category = categoryCtrl.text.trim();
                                          if (category.isEmpty) category = "Umum";

                                          // Ambil data toko untuk disimpan di produk
                                          String sellerName = "Toko";
                                          String sellerImage = "";
                                          try {
                                            final userDoc = await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user!.uid)
                                                .get();
                                            if (userDoc.exists) {
                                              sellerName =
                                                  userDoc['storeName'] ??
                                                  userDoc['name'] ??
                                                  "Toko";
                                              sellerImage = userDoc['image'] ?? "";
                                            }
                                          } catch (e) {}

                                          final data = {
                                            'name': nameCtrl.text,
                                            'price': int.tryParse(priceCtrl.text) ?? 0,
                                            'stock': int.tryParse(stockCtrl.text) ?? 0,
                                            'category': category,
                                            'description': descCtrl.text,
                                            'image': imageUrl ?? '',
                                            'uid': user?.uid,
                                            'sellerName': sellerName,
                                            'sellerImage': sellerImage,
                                            'updatedAt': FieldValue.serverTimestamp(),
                                          };

                                          if (isEdit) {
                                            await FirebaseFirestore.instance
                                                .collection('products')
                                                .doc(product.id)
                                                .update(data);
                                          } else {
                                            data['order'] =
                                                DateTime.now().millisecondsSinceEpoch;
                                            data['rating'] = 0.0;
                                            data['totalReviews'] = 0;
                                            data['sold'] = 0;
                                            data['createdAt'] = FieldValue.serverTimestamp();

                                            await FirebaseFirestore.instance
                                                .collection('products')
                                                .add(data);
                                          }

                                          Navigator.pop(context);
                                          toastification.show(
                                            context: context,
                                            title: Text(
                                              isEdit ? "Produk Diupdate!" : "Produk Ditambah!",
                                            ),
                                            type: ToastificationType.success,
                                            autoCloseDuration: const Duration(seconds: 3),
                                          );
                                        },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isEdit ? LucideIcons.save : LucideIcons.plus,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isEdit ? "Simpan Perubahan" : "Tambah Produk",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
            );
          },
        );
      },
    );
  }

  Future<void> _deleteProduct(String id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Produk?"),
        content: const Text("Produk akan dihapus permanen."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(id)
                  .delete();
              if (mounted) {
                toastification.show(
                  context: context,
                  title: const Text("Produk dihapus"),
                  type: ToastificationType.error,
                  autoCloseDuration: const Duration(seconds: 3),
                );
              }
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  Future<void> _onReorder(
    List<DocumentSnapshot> docs,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = docs.removeAt(oldIndex);
    docs.insert(newIndex, item);

    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < docs.length; i++) {
      batch.update(docs[i].reference, {'order': i});
    }
    await batch.commit();
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await MarketService().updateOrderStatus(orderId, status);
      if (mounted) {
        toastification.show(
          context: context,
          title: Text("Status: $status"),
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          title: Text("Gagal update status: $e"),
          type: ToastificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // FAB: Tambah Produk - Premium design with plus icon
      floatingActionButton: _tabController.index == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1976D2).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _checkStoreProfileBeforeAdd(),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(LucideIcons.plus, color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Text(
                            "Tambah Produk",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1976D2), // Blue-600
                      Color(0xFF0D47A1), // Blue-900
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER TOKO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Toko Saya",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Row(
                          children: [
                            _buildHeaderIcon(
                              context,
                              LucideIcons.bell,
                              const NotificationScreen(),
                            ),
                            const SizedBox(width: 8),
                            _buildHeaderIcon(
                              context,
                              LucideIcons.messageSquare,
                              const ChatScreen(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // TSX-style Stats Cards
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .where('uid', isEqualTo: user?.uid)
                          .snapshots(),
                      builder: (context, productSnapshot) {
                        final productCount = productSnapshot.hasData
                            ? productSnapshot.data!.docs.length
                            : 0;
                        
                        return StreamBuilder<QuerySnapshot>(
                          stream: MarketService().getIncomingOrders(),
                          builder: (context, orderSnapshot) {
                            int pendingCount = 0;
                            Set<String> customers = {};
                            
                            if (orderSnapshot.hasData) {
                              for (var doc in orderSnapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                if (data['status'] == 'Menunggu') pendingCount++;
                                if (data['buyerName'] != null) {
                                  customers.add(data['buyerName']);
                                }
                              }
                            }
                            
                            return Row(
                              children: [
                                // Pesanan Baru
                                _buildTSXStatsCard(
                                  "Pesanan Baru",
                                  "$pendingCount",
                                  LucideIcons.shoppingBag,
                                  const Color(0xFFFB923C), // orange-400
                                  const Color(0xFFF97316), // orange-500
                                ),
                                const SizedBox(width: 10),
                                // Total Produk
                                _buildTSXStatsCard(
                                  "Total Produk",
                                  "$productCount",
                                  LucideIcons.package,
                                  const Color(0xFF60A5FA), // blue-400
                                  const Color(0xFF3B82F6), // blue-500
                                ),
                                const SizedBox(width: 10),
                                // Pelanggan
                                _buildTSXStatsCard(
                                  "Pelanggan",
                                  "${customers.length}",
                                  LucideIcons.users,
                                  const Color(0xFF34D399), // emerald-400
                                  const Color(0xFF10B981), // emerald-500
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                _buildCustomTabBar(primaryColor),
                cardColor,
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductList(isDark, cardColor, textColor, primaryColor),
            _buildOrdersTab(isDark, cardColor, textColor, primaryColor),
          ],
        ),
      ),
    );
  }

  // --- CUSTOM TAB BAR WITH COUNTS ---
  Widget _buildCustomTabBar(Color primaryColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: MarketService().getUserProducts(),
      builder: (context, productSnapshot) {
        int productCount = productSnapshot.hasData ? productSnapshot.data!.docs.length : 0;
        
        return StreamBuilder<QuerySnapshot>(
          stream: MarketService().getIncomingOrders(),
          builder: (context, orderSnapshot) {
            int orderCount = orderSnapshot.hasData ? orderSnapshot.data!.docs.length : 0;
            
            return TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              tabs: [
                Tab(text: "Produk Saya ($productCount)"),
                Tab(text: "Pesanan Masuk ($orderCount)"),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderIcon(
    BuildContext context,
    IconData icon,
    Widget destination,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
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

  // --- TAB 1: LIST PRODUK ---
  Widget _buildProductList(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color primaryColor,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: MarketService().getUserProducts(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final allDocs = snapshot.data!.docs;

        Set<String> categories = {"Semua"};
        for (var doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['category'] != null && data['category'] != "") {
            categories.add(data['category']);
          }
        }
        final categoryList = categories.toList();

        final filteredDocs = _selectedCategory == "Semua"
            ? allDocs
            : allDocs
                  .where((doc) => doc['category'] == _selectedCategory)
                  .toList();

        return Column(
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categoryList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categoryList[index];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? primaryColor : Colors.grey[600],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  );
                },
              ),
            ),

            Expanded(
              child: filteredDocs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.packageOpen,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Tidak ada produk di kategori '$_selectedCategory'",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : _selectedCategory == "Semua"
                  ? ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
                      itemCount: filteredDocs.length,
                      buildDefaultDragHandles: false,
                      onReorder: (oldIndex, newIndex) =>
                          _onReorder(allDocs, oldIndex, newIndex),
                      itemBuilder: (context, index) {
                        return _buildProductItem(
                          filteredDocs[index],
                          cardColor,
                          textColor,
                          primaryColor,
                          true,
                          index,
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        return _buildProductItem(
                          filteredDocs[index],
                          cardColor,
                          textColor,
                          primaryColor,
                          false,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // --- HELPER: Category Color ---
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return Colors.purple;
      case 'minuman':
        return Colors.blue;
      case 'kue':
        return Colors.pink;
      case 'kerajinan':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildProductItem(
    DocumentSnapshot doc,
    Color cardColor,
    Color textColor,
    Color primaryColor,
    bool isReorderable, [
    int index = 0,
  ]) {
    final data = doc.data() as Map<String, dynamic>;
    final id = doc.id;

    // --- INDICATOR STOK ---
    int stock = (data['stock'] ?? 0).toInt();
    bool isOutOfStock = stock <= 0;
    bool isLowStock = stock < 10 && !isOutOfStock;
    String category = data['category'] ?? 'Umum';
    Color catColor = _getCategoryColor(category);

    return Container(
      key: ValueKey(id),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GAMBAR KIRI
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      ),
                    ],
                    image: (data['image'] != null && data['image'] != '')
                        ? DecorationImage(
                            image: NetworkImage(data['image']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (data['image'] == null || data['image'] == '')
                      ? Icon(LucideIcons.image, color: Colors.grey[400], size: 32)
                      : null,
                ),
                if (isLowStock)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Stok Sedikit",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (isOutOfStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Habis",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // KONTEN KANAN
            Expanded(
              child: SizedBox(
                height: 100, // Match image height
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? "Produk",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    catColor.withOpacity(0.1),
                                    catColor.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: catColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons Row (Right)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _showProductDialog(product: doc),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(LucideIcons.edit2, size: 16, color: Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _deleteProduct(id),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                            ),
                          ),
                          if (isReorderable) ...[
                            const SizedBox(width: 8),
                            ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(LucideIcons.gripVertical, size: 16, color: Colors.grey[500]),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  
                  // Description
                  if (data['description'] != null && data['description'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        data['description'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Footer: Price and Stock (Always at bottom)
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormat.format(data['price'] ?? 0),
                        style: const TextStyle(
                          color: Color(0xFF10B981), // Emerald-600
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(LucideIcons.package, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            "Stok: ",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            "$stock",
                            style: TextStyle(
                              fontSize: 12, 
                              color: isLowStock || isOutOfStock ? Colors.red : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: PESANAN MASUK ---
  Widget _buildOrdersTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color primaryColor,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: MarketService().getIncomingOrders(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator(
            color: Color(0xFF1976D2),
          ));

        final allDocs = snapshot.data!.docs;
        
        // Count orders by status
        int allCount = allDocs.length;
        int pendingCount = 0;
        int processingCount = 0;
        int completedCount = 0;
        
        for (var doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Menunggu';
          if (status == 'Menunggu') pendingCount++;
          else if (status == 'Diproses') processingCount++;
          else if (status == 'Selesai' || status == 'Diantar') completedCount++;
        }
        
        // Filter orders based on selected status
        final filteredDocs = _selectedOrderStatus == "Semua"
            ? allDocs
            : allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'Menunggu';
                if (_selectedOrderStatus == "Baru") return status == "Menunggu";
                if (_selectedOrderStatus == "Proses") return status == "Diproses";
                if (_selectedOrderStatus == "Selesai") return status == "Selesai" || status == "Diantar";
                return true;
              }).toList();

        return Column(
          children: [
            // Order Status Tabs
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                   colors: [Colors.grey.shade50, const Color(0xFFFAFAFA)], // Warm neutral grey
                ),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildExpandedStatusTab("Semua", allCount, Colors.grey)), // Grey
                    Expanded(child: _buildExpandedStatusTab("Baru", pendingCount, const Color(0xFFF97316))), // Orange
                    Expanded(child: _buildExpandedStatusTab("Proses", processingCount, const Color(0xFF1976D2))), // Blue
                    Expanded(child: _buildExpandedStatusTab("Selesai", completedCount, const Color(0xFF10B981))), // Emerald
                  ],
                ),
              ),
            ),
            
            // Orders List
            Expanded(
              child: filteredDocs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.clipboardList,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedOrderStatus == "Semua" 
                                ? "Belum ada pesanan masuk."
                                : "Tidak ada pesanan $_selectedOrderStatus",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index] as DocumentSnapshot;
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? 'Menunggu';
                        final List items = (data['items'] as List?) ?? [];

                        // Get status info
                        Color statusColor;
                        IconData statusIcon;
                        String statusLabel;
                        
                        if (status == 'Menunggu') {
                          statusColor = Colors.orange;
                          statusIcon = LucideIcons.clock;
                          statusLabel = "Menunggu";
                        } else if (status == 'Diproses') {
                          statusColor = Colors.blue;
                          statusIcon = LucideIcons.package;
                          statusLabel = "Diproses";
                        } else if (status == 'Diantar') {
                          statusColor = Colors.purple;
                          statusIcon = LucideIcons.truck;
                          statusLabel = "Diantar";
                        } else {
                          statusColor = Colors.green;
                          statusIcon = LucideIcons.checkCircle;
                          statusLabel = "Selesai";
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                const Color(0xFFF8F7FF), // Very subtle purple tint
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.15), width: 1), // Purple accent
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // HEADER
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [const Color(0xFF1976D2).withOpacity(0.1), const Color(0xFF1976D2).withOpacity(0.18)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(LucideIcons.shoppingBag, color: Color(0xFF1976D2), size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['orderId'] ?? "ORD-???",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(LucideIcons.user, size: 12, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  data['buyerName'] ?? 'Pembeli',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: statusColor.withOpacity(0.1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(statusIcon, size: 14, color: statusColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            statusLabel,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // ITEMS
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: items.map<Widget>((item) {
                                      int qty = item['quantity'] ?? 1;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEEEEEE),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      "${qty}x",
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      item['name'] ?? 'Item',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              currencyFormat.format((item['price'] ?? 0) * qty),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // FOOTER
                                Divider(height: 1, color: Colors.grey[200]),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Total Pembayaran",
                                          style: TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          currencyFormat.format(data['totalPrice'] ?? 0),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: const Color(0xFFBDBDBD)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            (data['paymentMethod'] ?? 'Transfer') == 'cod' ? 'COD' : 'Transfer',
                                            style: const TextStyle(fontSize: 10, color: Colors.black),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        // ACTION BUTTONS BASED ON STATUS
                                        if (status == 'Menunggu') ...[
                                          OutlinedButton.icon(
                                            icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                                            label: const Text("Tolak", style: TextStyle(color: Colors.red)),
                                            onPressed: () => _updateOrderStatus(doc.id, "Ditolak"),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: Colors.grey.shade300),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            icon: const Icon(LucideIcons.checkCircle, size: 16, color: Colors.white),
                                            label: const Text("Terima", style: TextStyle(color: Colors.white)),
                                            onPressed: () => _updateOrderStatus(doc.id, "Diproses"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF1976D2),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              elevation: 0,
                                            ),
                                          ),
                                        ] else if (status == 'Diproses') ...[
                                          ElevatedButton.icon(
                                            icon: const Icon(LucideIcons.truck, size: 16, color: Colors.white),
                                            label: const Text("Kirim", style: TextStyle(color: Colors.white)),
                                            onPressed: () => _updateOrderStatus(doc.id, "Diantar"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.purple,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              elevation: 0,
                                            ),
                                          ),
                                        ] else if (status == 'Diantar') ...[
                                          ElevatedButton.icon(
                                            icon: const Icon(LucideIcons.check, size: 16, color: Colors.white),
                                            label: const Text("Selesai", style: TextStyle(color: Colors.white)),
                                            onPressed: () => _updateOrderStatus(doc.id, "Selesai"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              elevation: 0,
                                            ),
                                          ),
                                        ] else ...[
                                          // Completed or other
                                          OutlinedButton.icon(
                                            icon: const Icon(LucideIcons.eye, size: 16, color: Colors.purple),
                                            label: const Text("Detail", style: TextStyle(color: Colors.purple)),
                                            onPressed: () {}, // Detail action
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.purple),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // --- WIDGET: EXPANDED STATUS TAB ---
  Widget _buildExpandedStatusTab(String title, int count, Color color) {
    bool isSelected = _selectedOrderStatus == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOrderStatus = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withOpacity(0.8),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: STATS CARD (TSX STYLE) ---
  Widget _buildTSXStatsCard(
    String title,
    String value,
    IconData icon,
    Color gradientStart,
    Color gradientEnd,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gradientStart, gradientEnd],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradientEnd.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget _child;
  final Color _bgColor;
  _SliverAppBarDelegate(this._child, this._bgColor);
  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(color: _bgColor, child: _child);
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => true;
}
