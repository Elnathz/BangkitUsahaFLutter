import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../services/market_service.dart';
import '../inventory/checkout_screen.dart'; // Import Halaman Checkout

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Keranjang Saya"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: MarketService().getUserCart(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var items = snapshot.data!.docs;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.shoppingCart,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Keranjang masih kosong",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              // 1. DATA DARI KERANJANG (Aman karena sudah ada di Stream)
              var cartData = items[index].data() as Map<String, dynamic>;
              String productId = cartData['productId'] ?? "";

              // FutureBuilder untuk ambil data Penjual (uid) dari Produk
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .get(),
                builder: (context, productSnapshot) {
                  // Jika loading atau error, tampilkan card kosong dulu/loading
                  if (!productSnapshot.hasData) return const SizedBox();

                  // Cek apakah dokumen produk masih ada di database?
                  if (!productSnapshot.data!.exists) {
                    return const SizedBox(); // Produk mungkin sudah dihapus
                  }

                  // 2. DATA DARI PRODUK (POSISI RAWAN ERROR)
                  // Kita gunakan '?' dan '?? ""' untuk mencegah crash jika field hilang
                  var productData =
                      productSnapshot.data!.data() as Map<String, dynamic>?;

                  if (productData == null) return const SizedBox();

                  // --- PROTEKSI GANDA DI SINI ---
                  String sellerId =
                      productData['uid'] ??
                      ""; // Kalau null, jadi string kosong
                  String sellerName = productData['sellerName'] ?? "Toko";
                  // ------------------------------

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          image:
                              (cartData['image'] != null &&
                                  cartData['image'] != '')
                              ? DecorationImage(
                                  image: NetworkImage(cartData['image']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child:
                            (cartData['image'] == null ||
                                cartData['image'] == '')
                            ? const Icon(LucideIcons.image, color: Colors.grey)
                            : null,
                      ),
                      title: Text(
                        cartData['name'] ?? "Produk",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currencyFormat.format(cartData['price'] ?? 0)),
                          Text("Qty: ${cartData['qty'] ?? 1}"),
                        ],
                      ),
                      trailing: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tombol Hapus Item
                            IconButton(
                              icon: const Icon(
                                LucideIcons.trash2,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () {
                                MarketService().removeFromCart(productId);
                              },
                            ),
                            // Tombol Checkout
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              child: const Text("Beli"),
                              onPressed: () {
                                // --- PROTEKSI SAAT KLIK BELI ---
                                String safeProductId = productId;
                                String safeName = cartData['name'] ?? 'Produk';
                                // Gunakan .toInt() agar aman jika data dari Firestore berupa double
                                int safePrice = (cartData['price'] ?? 0)
                                    .toInt();
                                int safeQty = (cartData['qty'] ?? 1).toInt();

                                // Cek image di cart, kalau null cek di product, kalau null pakai string kosong
                                String safeImage =
                                    (cartData['image'] ??
                                            productData['image'] ??
                                            "")
                                        as String;

                                final item = {
                                  'productId': safeProductId,
                                  'name': safeName,
                                  'price': safePrice,
                                  'qty': safeQty,
                                  'image': safeImage,
                                  'storeLat': productData['storeLat'],
                                  'storeLng': productData['storeLng'],
                                };

                                // HITUNG TOTAL
                                int total = safePrice * safeQty;

                                // KE HALAMAN CHECKOUT
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutScreen(
                                      items: [item],
                                      totalPrice: total,
                                      sellerId:
                                          sellerId, // Ini sudah aman (?? "")
                                      sellerName:
                                          sellerName, // Ini sudah aman (?? "Toko")
                                      isFromCart: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
