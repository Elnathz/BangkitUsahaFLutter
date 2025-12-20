import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = FirebaseAuth.instance.currentUser;

  // State untuk Filter Kategori
  String _selectedCategory = "Semua";

  // Format Mata Uang
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Data Dummy Pesanan
  final List<Map<String, dynamic>> orders = [
    {
      "id": "ORD-001",
      "customer": "Budi Santoso",
      "status": "Menunggu",
      "items": [
        {"name": "Keripik Singkong", "qty": 3, "price": 25000},
        {"name": "Sambal Matah", "qty": 1, "price": 35000},
      ],
      "total": 110000,
      "payment": "Transfer",
    },
    {
      "id": "ORD-002",
      "customer": "Siti Aminah",
      "status": "Diproses",
      "items": [
        {"name": "Kue Lapis Legit", "qty": 1, "price": 150000},
      ],
      "total": 150000,
      "payment": "COD",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  // --- LOGIC PRODUK (CRUD & REORDER) ---

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
                debugPrint("Upload Error: $e");
              }
            }

            return AlertDialog(
              title: Text(isEdit ? "Edit Produk" : "Tambah Produk Baru"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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

                          // Pastikan kategori tidak kosong agar filter berfungsi
                          String category = categoryCtrl.text.trim();
                          if (category.isEmpty) category = "Umum";

                          final data = {
                            'name': nameCtrl.text,
                            'price': int.tryParse(priceCtrl.text) ?? 0,
                            'stock': int.tryParse(stockCtrl.text) ?? 0,
                            'category': category,
                            'description': descCtrl.text,
                            'image': imageUrl ?? '',
                            'uid': user?.uid,
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
    await FirebaseFirestore.instance.collection('products').doc(id).delete();
    toastification.show(
      context: context,
      title: const Text("Produk dihapus"),
      type: ToastificationType.error,
      autoCloseDuration: const Duration(seconds: 3),
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
                onPressed: () => _showProductDialog(),
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
                    const Text(
                      "Manajemen Toko",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
                            _buildSummaryCard(
                              "Pesanan",
                              "${orders.length}",
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

  // --- TAB 1: LIST PRODUK + FILTER KATEGORI ---
  Widget _buildProductList(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color primaryColor,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('uid', isEqualTo: user?.uid)
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final allDocs = snapshot.data!.docs;

        // 1. Ambil Daftar Kategori Unik
        Set<String> categories = {"Semua"};
        for (var doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['category'] != null && data['category'] != "") {
            categories.add(data['category']);
          }
        }
        final categoryList = categories.toList();

        // 2. Filter Produk Sesuai Pilihan
        final filteredDocs = _selectedCategory == "Semua"
            ? allDocs
            : allDocs
                  .where((doc) => doc['category'] == _selectedCategory)
                  .toList();

        return Column(
          children: [
            // --- BAGIAN FILTER KATEGORI (CHIPS) ---
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

            // --- BAGIAN LIST PRODUK ---
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
                  // Jika "Semua", pakai ReorderableListView (Bisa Drag & Drop)
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
                  // Jika Filter Aktif, pakai ListView biasa (Tidak Bisa Drag & Drop)
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

  // WIDGET ITEM PRODUK (Dipisah agar rapi)
  Widget _buildProductItem(
    DocumentSnapshot doc,
    Color cardColor,
    Color textColor,
    Color primaryColor,
    bool isReorderable,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final id = doc.id;

    return Card(
      key: ValueKey(id),
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
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
        title: Text(
          data['name'],
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(data['price']),
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
                Text(
                  "Stok: ${data['stock']}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.edit2, size: 18, color: Colors.grey),
              onPressed: () => _showProductDialog(product: doc),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
              onPressed: () => _deleteProduct(id),
            ),
            // Icon Grip hanya muncul jika mode "Semua"
            if (isReorderable)
              const Icon(LucideIcons.gripVertical, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: PESANAN ---
  Widget _buildOrdersTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color primaryColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...orders.map((order) {
            Color statusColor = order['status'] == 'Menunggu'
                ? Colors.orange
                : (order['status'] == 'Selesai' ? Colors.green : Colors.blue);
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
                        order['id'],
                        style: TextStyle(
                          fontSize: 16,
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
                          order['status'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order['customer'],
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const Divider(height: 24),
                  ...order['items']
                      .map<Widget>(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${item['qty']}x ${item['name']}",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "Rp ${item['price']}",
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            currencyFormat.format(order['total']),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.eye,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            LucideIcons.messageCircle,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 120),
        ],
      ),
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
