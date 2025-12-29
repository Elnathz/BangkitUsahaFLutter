import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import '../../services/market_service.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int totalPrice;
  final String sellerId;
  final String sellerName;
  final bool isFromCart;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.totalPrice,
    required this.sellerId,
    required this.sellerName,
    this.isFromCart = false,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Future<void> _processCheckout() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon isi alamat pengiriman")),
      );
      return;
    }

    setState(() => _isLoading = true);

    String result = await MarketService().createOrder(
      items: widget.items,
      totalPrice: widget.totalPrice,
      sellerId: widget.sellerId,
      sellerName: widget.sellerName,
      deliveryAddress: _addressController.text,
    );

    if (result == "SUCCESS") {
      if (widget.isFromCart) {
        try {
          for (var item in widget.items) {
            if (item['productId'] != null) {
              await MarketService().removeFromCart(item['productId']);
            }
          }
        } catch (e) {
          print("Gagal bersihkan keranjang: $e");
        }
      }

      setState(() => _isLoading = false);

      if (mounted) {
        toastification.show(
          context: context,
          title: const Text("Pesanan Berhasil Dibuat!"),
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 3),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: $result")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ALAMAT
            const Text(
              "Alamat Pengiriman",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Masukkan alamat lengkap...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 24),

            // ITEM LIST
            const Text(
              "Rincian Pesanan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: widget.items.map((item) {
                  // --- SAFETY DATA EXTRACTION (PENTING!) ---
                  // Kita paksa semua data menjadi String atau Int yang valid
                  // .toString() mengubah null menjadi "null" (teks),
                  // lalu ?? memastikan kita punya nilai default.

                  String safeName = (item['name'] ?? "Produk").toString();
                  String safeImage = (item['image'] ?? "").toString();

                  // Parsing angka dengan aman
                  int safePrice = 0;
                  int safeQty = 1;
                  try {
                    safePrice = int.parse(item['price'].toString());
                  } catch (_) {}

                  try {
                    safeQty = int.parse(item['qty'].toString());
                  } catch (_) {}

                  int subtotal = safePrice * safeQty;
                  // ------------------------------------------

                  return ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                        image: (safeImage.isNotEmpty && safeImage != "null")
                            ? DecorationImage(
                                image: NetworkImage(safeImage),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {},
                              )
                            : null,
                      ),
                      child: (safeImage.isEmpty || safeImage == "null")
                          ? const Icon(
                              LucideIcons.image,
                              size: 24,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    title: Text(
                      safeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      "$safeQty x ${currencyFormat.format(safePrice)}",
                    ),
                    trailing: Text(
                      currencyFormat.format(subtotal),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // METODE PEMBAYARAN
            const Text(
              "Metode Pembayaran",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: const [
                  Icon(LucideIcons.wallet, color: Colors.blue),
                  SizedBox(width: 12),
                  Text(
                    "Transfer Bank / COD (Manual)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Pembayaran",
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  currencyFormat.format(widget.totalPrice),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _processCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text(
                      "Buat Pesanan",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
