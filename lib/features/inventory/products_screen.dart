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

            return AlertDialog(
              title: Text(isEdit ? "Edit Produk" : "Tambah Produk Baru"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // INPUT GAMBAR
                    GestureDetector(
                      onTap: isUploading ? null : handleImageUpload,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          image: imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: isUploading
                            ? const Center(child: CircularProgressIndicator())
                            : (imageUrl == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          LucideIcons.camera,
                                          color: Colors.grey,
                                        ),
                                        Text(
                                          "Upload Foto",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    )
                                  : null),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // FORM INPUT
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Nama Produk",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Harga (Rp)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Stok",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: "Kategori (Misal: Makanan)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Deskripsi Produk",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: isUploading
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
                  child: Text(isEdit ? "Simpan Perubahan" : "Tambah Produk"),
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      floatingActionButton: _tabController.index == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: FloatingActionButton.extended(
                onPressed: () => _checkStoreProfileBeforeAdd(),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                icon: const Icon(LucideIcons.plus),
                label: const Text("Tambah Produk"),
                elevation: 4,
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, const Color(0xFF503C37)],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
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
                          "Manajemen Toko",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            _buildHeaderIcon(
                              context,
                              LucideIcons.messageCircle,
                              const ChatScreen(),
                            ),
                            const SizedBox(width: 8),
                            _buildHeaderIcon(
                              context,
                              LucideIcons.bell,
                              const NotificationScreen(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .where('uid', isEqualTo: user?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.hasData
                            ? snapshot.data!.docs.length
                            : 0;
                        return Row(
                          children: [
                            _buildSummaryCard(
                              "Total Produk",
                              "$count",
                              LucideIcons.package,
                              Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            // Summary Pesanan
                            _buildSummaryCard(
                              "Pesanan",
                              "...",
                              LucideIcons.shoppingBag,
                              Colors.blue,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: primaryColor,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: "Produk Saya"),
                    Tab(text: "Pesanan Masuk"),
                  ],
                ),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
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
                      onReorder: (oldIndex, newIndex) =>
                          _onReorder(allDocs, oldIndex, newIndex),
                      itemBuilder: (context, index) {
                        return _buildProductItem(
                          filteredDocs[index],
                          cardColor,
                          textColor,
                          primaryColor,
                          true,
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

  Widget _buildProductItem(
    DocumentSnapshot doc,
    Color cardColor,
    Color textColor,
    Color primaryColor,
    bool isReorderable,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final id = doc.id;

    // --- INDIKATOR STOK HABIS ---
    int stock = (data['stock'] ?? 0).toInt();
    bool isOutOfStock = stock <= 0;

    return Card(
      key: ValueKey(id),
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        // BAGIAN GAMBAR + OVERLAY "HABIS"
        leading: Stack(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: (data['image'] != null && data['image'] != '')
                    ? DecorationImage(
                        image: NetworkImage(data['image']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (data['image'] == null || data['image'] == '')
                  ? const Icon(LucideIcons.image, color: Colors.grey)
                  : null,
            ),
            // OVERLAY JIKA HABIS
            if (isOutOfStock)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Habis",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          data['name'] ?? "Produk",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(data['price'] ?? 0),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    data['category'] ?? 'Umum',
                    style: const TextStyle(fontSize: 10, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                // INDIKATOR STOK WARNA MERAH JIKA HABIS
                Text(
                  isOutOfStock ? "Stok: 0 (Habis)" : "Stok: $stock",
                  style: TextStyle(
                    fontSize: 12,
                    color: isOutOfStock ? Colors.red : Colors.grey[600],
                    fontWeight: isOutOfStock
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                LucideIcons.messageSquare,
                size: 18,
                color: Colors.blue,
              ),
              tooltip: "Lihat Ulasan",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductReviewsScreen(productId: id, productData: data),
                  ),
                );
              },
            ),
            // TOMBOL EDIT (UTK NAMBAH STOK)
            IconButton(
              icon: const Icon(LucideIcons.edit2, size: 18, color: Colors.grey),
              tooltip: "Edit & Restock",
              onPressed: () => _showProductDialog(product: doc),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
              onPressed: () => _deleteProduct(id),
            ),
            if (isReorderable)
              const Icon(LucideIcons.gripVertical, color: Colors.grey),
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
          return const Center(child: CircularProgressIndicator());

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.clipboardList,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                const Text("Belum ada pesanan masuk."),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Menunggu';
            final List items = (data['items'] as List?) ?? [];

            Color statusColor;
            if (status == 'Menunggu')
              statusColor = Colors.orange;
            else if (status == 'Diproses')
              statusColor = Colors.blue;
            else if (status == 'Diantar')
              statusColor = Colors.purple;
            else
              statusColor = Colors.green;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
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
                        data['orderId'] ?? "ORD-???",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Pembeli: ${data['buyerName'] ?? 'Pembeli'}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  Text(
                    "Alamat: ${data['address'] ?? '-'}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const Divider(height: 24),

                  // LIST ITEMS
                  ...items.map((item) {
                    if (item == null) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${item['qty'] ?? 1}x ${item['name'] ?? 'Produk'}",
                            style: TextStyle(color: textColor, fontSize: 13),
                          ),
                          Text(
                            currencyFormat.format(item['price'] ?? 0),
                            style: TextStyle(color: textColor, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(height: 24),

                  // FOOTER & ACTION BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total: ${currencyFormat.format(data['totalPrice'] ?? 0)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (status == 'Menunggu')
                        ElevatedButton(
                          onPressed: () => MarketService().updateOrderStatus(
                            doc.id,
                            'Diproses',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            "Terima Pesanan",
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        )
                      else if (status == 'Diproses')
                        ElevatedButton(
                          onPressed: () => MarketService().updateOrderStatus(
                            doc.id,
                            'Diantar',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            "Kirim Barang",
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        )
                      else if (status == 'Diantar')
                        const Text(
                          "Menunggu diterima...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
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
  final TabBar _tabBar;
  final Color _bgColor;
  _SliverAppBarDelegate(this._tabBar, this._bgColor);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(color: _bgColor, child: _tabBar);
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
