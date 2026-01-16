import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GroupedOrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const GroupedOrderCard({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Ambil data dari map
    final String storeName = orderData['storeName'] ?? 'Toko';
    final List<dynamic> items = orderData['items'] ?? [];
    final int shippingCost = orderData['shippingCost'] ?? 0;
    final double totalPrice = orderData['totalPrice']?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Nama Toko
            Row(
              children: [
                const Icon(Icons.store, size: 20),
                const SizedBox(width: 8),
                Text(
                  storeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),

            // List Barang
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    // Foto Produk (Placeholder jika null)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: item['imageUrl'] != null
                            ? DecorationImage(
                                image: NetworkImage(item['imageUrl']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: item['imageUrl'] == null
                          ? const Icon(Icons.image, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Nama Produk & Jumlah
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['productName'] ?? 'Produk',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${item['quantity']}x',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // Harga Produk (Bagian Kanan)
                    Text(
                      currencyFormat.format(item['price']),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 8),

            // Ongkos Kirim
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Ongkos Kirim",
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  currencyFormat.format(shippingCost),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const Divider(),

            // Total (Paling Bawah)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Pesanan",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
