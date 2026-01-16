import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import '../../services/market_service.dart';
import '../../map_picker_screen.dart';
import '../../shipping_calculator.dart';

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
  String _deliveryAddress = "";
  LatLng? _userLocation;
  int _shippingCost = 0;
  bool _isLoading = false;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Navigasi ke Halaman Pilih Alamat
  Future<void> _pickAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          onLocationPicked: (LatLng location, String address) {
            setState(() {
              _userLocation = location;
              _deliveryAddress = address; // Gunakan alamat lengkap dari Maps
              _calculateShipping();
            });
          },
        ),
      ),
    );
  }

  void _calculateShipping() {
    if (_userLocation == null || widget.items.isEmpty) return;

    // Ambil koordinat toko dari item pertama (asumsi satu toko per checkout)
    // Pastikan data item memiliki 'storeLat' dan 'storeLng'
    double storeLat = (widget.items.first['storeLat'] ?? -6.200000).toDouble();
    double storeLng = (widget.items.first['storeLng'] ?? 106.816666).toDouble();

    double distance = ShippingCalculator.calculateDistance(
      _userLocation!.latitude,
      _userLocation!.longitude,
      storeLat,
      storeLng,
    );

    setState(() {
      _shippingCost = ShippingCalculator.calculateShippingCost(distance);
    });
  }

  Future<void> _processOrder() async {
    if (_deliveryAddress.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text("Alamat Kosong"),
        description: const Text("Harap masukkan alamat pengiriman."),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Panggil Service untuk Buat Order
      String result = await MarketService().createOrder(
        items: widget.items,
        totalPrice: widget.totalPrice,
        sellerId: widget.sellerId,
        sellerName: widget.sellerName,
        deliveryAddress: _deliveryAddress,
        shippingCost: _shippingCost, // Kirim ongkir ke backend
        deliveryLat: _userLocation?.latitude,
        deliveryLng: _userLocation?.longitude,
      );

      if (result == "SUCCESS") {
        // Jika dari keranjang, hapus item yang dibeli
        if (widget.isFromCart) {
          for (var item in widget.items) {
            await MarketService().removeFromCart(item['productId']);
          }
        }

        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text("Pesanan Berhasil!"),
            description: const Text("Pesanan diteruskan ke penjual."),
            autoCloseDuration: const Duration(seconds: 3),
          );
          // Kembali ke Dashboard (Hapus semua route sampai home)
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        throw Exception(result);
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text("Gagal"),
          description: Text("Error: $e"),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BAGIAN ALAMAT
                  const Text(
                    "Alamat Pengiriman",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickAddress,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            color: Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _deliveryAddress.isEmpty
                                ? const Text(
                                    "Pilih Alamat Pengiriman...",
                                    style: TextStyle(color: Colors.grey),
                                  )
                                : Text(
                                    _deliveryAddress,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // BAGIAN ITEM
                  const Text(
                    "Rincian Pesanan",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...widget.items
                      .map(
                        (item) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                image:
                                    (item['image'] != null &&
                                        item['image'] != "")
                                    ? DecorationImage(
                                        image: NetworkImage(item['image']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                            title: Text(item['name'] ?? "Produk"),
                            subtitle: Text(
                              "${item['qty']} x ${currencyFormat.format(item['price'])}",
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),

          // BOTTOM BAR
          Container(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Total (+Ongkir)",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        currencyFormat.format(
                          widget.totalPrice + _shippingCost,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      if (_shippingCost > 0)
                        Text(
                          "(Ongkir: ${currencyFormat.format(_shippingCost)})",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _processOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Buat Pesanan",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
