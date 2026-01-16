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
  final String sellerId; // Optional if multi-seller
  final String sellerName; // Optional if multi-seller
  final bool isFromCart;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.totalPrice,
    this.sellerId = "",
    this.sellerName = "",
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

  // Helper to group items by seller
  Map<String, List<Map<String, dynamic>>> _groupItemsBySeller() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var item in widget.items) {
      String sId = item['sellerId'] ?? widget.sellerId;
      if (sId.isEmpty) sId = "unknown";
      
      if (!grouped.containsKey(sId)) {
        grouped[sId] = [];
      }
      grouped[sId]!.add(item);
    }
    return grouped;
  }

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

  int _computeTotalShipping(Map<String, List<Map<String, dynamic>>> groupedItems) {
    if (_userLocation == null) return 0;
    int total = 0;
    for (var entry in groupedItems.entries) {
      final sellerItems = entry.value;
      double storeLat = (sellerItems.first['storeLat'] ?? -6.200000).toDouble();
      double storeLng = (sellerItems.first['storeLng'] ?? 106.816666).toDouble();
      double distance = ShippingCalculator.calculateDistance(
        _userLocation!.latitude,
        _userLocation!.longitude,
        storeLat,
        storeLng,
      );
      total += ShippingCalculator.calculateShippingCost(distance);
    }
    return total;
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
      final groupedItems = _groupItemsBySeller();
      bool allSuccess = true;
      String errorMessage = "";

      // Create One Order per Seller
      for (var entry in groupedItems.entries) {
        String sId = entry.key;
        List<Map<String, dynamic>> sellerItems = entry.value;

        // Calculate subtotal for this seller
        int sellerTotal = 0;
        for (var i in sellerItems) {
          sellerTotal += ((i['price'] as num) * (i['qty'] as num)).toInt();
        }

        String sName = sellerItems.first['sellerName'] ?? widget.sellerName;
        if (sName.isEmpty) sName = "Toko";

        // Calculate shipping for this seller (based on first store coordinates)
        int sellerShipping = 0;
        if (_userLocation != null) {
          double storeLat = (sellerItems.first['storeLat'] ?? -6.200000).toDouble();
          double storeLng = (sellerItems.first['storeLng'] ?? 106.816666).toDouble();
          double distance = ShippingCalculator.calculateDistance(
            _userLocation!.latitude,
            _userLocation!.longitude,
            storeLat,
            storeLng,
          );
          sellerShipping = ShippingCalculator.calculateShippingCost(distance);
        }

        String result = await MarketService().createOrder(
          items: sellerItems,
          totalPrice: sellerTotal,
          sellerId: sId,
          sellerName: sName,
          deliveryAddress: _deliveryAddress,
          shippingCost: sellerShipping,
          deliveryLat: _userLocation?.latitude,
          deliveryLng: _userLocation?.longitude,
        );

        if (result != "SUCCESS") {
          allSuccess = false;
          errorMessage = result;
          break; // Stop if one fails
        }
      }

      if (allSuccess) {
        // If from cart, remove ALL purchased items
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
            description: const Text("Semua pesanan telah diteruskan ke penjual."),
            autoCloseDuration: const Duration(seconds: 3),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        throw Exception(errorMessage);
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
    final groupedItems = _groupItemsBySeller();

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
                  // ADDRESS
                  const Text("Alamat Pengiriman", style: TextStyle(fontWeight: FontWeight.bold)),
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
                          const Icon(LucideIcons.mapPin, color: Color(0xFF1565C0)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _deliveryAddress.isEmpty
                                ? const Text("Pilih Alamat Pengiriman...", style: TextStyle(color: Colors.grey))
                                : Text(_deliveryAddress, style: const TextStyle(color: Colors.black87)),
                          ),
                          const Icon(LucideIcons.chevronRight, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ITEMS GROUPED BY STORE
                  const Text("Rincian Pesanan", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  ...groupedItems.entries.map((entry) {
                    final items = entry.value;
                    final sellerName = items.first['sellerName'] ?? widget.sellerName;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Header inside Checkout
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.store, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text("Toko: $sellerName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        ),
                        ...items.map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                image: (item['image'] != null && item['image'] != "")
                                    ? DecorationImage(
                                        image: NetworkImage(item['image']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                            title: Text(item['name'] ?? "Produk"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${item['qty']} x ${currencyFormat.format(item['price'])}"),
                                if (item['note'] != null && item['note'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "Catatan: ${item['note']}",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    );
                  }),
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
                      const Text("Total (+Ongkir)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        currencyFormat.format(widget.totalPrice + _computeTotalShipping(groupedItems)),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                      ),
                      if (_computeTotalShipping(groupedItems) > 0)
                        Text(
                          "(Ongkir: ${currencyFormat.format(_computeTotalShipping(groupedItems))})",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _processOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Buat Pesanan", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
