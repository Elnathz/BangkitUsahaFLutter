import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product_model.dart';

class MyStoreScreen extends StatelessWidget {
  const MyStoreScreen({super.key});

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddProductDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stok Toko Saya',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authProvider.userData?['storeName'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddProductDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Jual Barang'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Products List
            Expanded(
              child: productProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : productProvider.myProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Toko kosong. Mulai jual sesuatu!',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: productProvider.myProducts.length,
                      itemBuilder: (context, index) {
                        final product = productProvider.myProducts[index];
                        return _ProductCard(
                          product: product,
                          onDelete: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Hapus Barang'),
                                content: const Text(
                                  'Apakah Anda yakin ingin menghapus barang ini?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      context
                                          .read<ProductProvider>()
                                          .deleteProduct(product.id);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Barang dihapus'),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
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
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onDelete;

  const _ProductCard({required this.product, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image, color: Colors.grey[400], size: 32);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stok: ${product.stock}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${NumberFormat('#,###', 'id_ID').format(product.price)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProductDialog extends StatefulWidget {
  const _AddProductDialog();

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Harga wajib diisi')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final product = ProductModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      price: double.parse(_priceController.text),
      stock: int.tryParse(_stockController.text) ?? 0,
      category: _categoryController.text.isEmpty
          ? 'Umum'
          : _categoryController.text,
      description: '',
      image:
          'https://images.unsplash.com/photo-1595246140625-573b715d11dc?w=400',
      sellerId: authProvider.user?.uid ?? '',
      sellerName: authProvider.userData?['storeName'] ?? 'Penjual',
    );

    context.read<ProductProvider>().addProduct(product);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barang berhasil ditambahkan!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Jual Barang Baru',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang',
                  hintText: 'Contoh: Beras Merah 1kg',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Price and Stock
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Harga (Rp)',
                        hintText: '15000',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stok',
                        hintText: '10',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Category
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  hintText: 'Makanan / Kerajinan',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tayangkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
