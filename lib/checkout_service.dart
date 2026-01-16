import '../shipping_calculator.dart';

class CheckoutService {
  /// Mengelompokkan item keranjang berdasarkan Toko dan menghitung ongkir per Toko.
  ///
  /// [cartItems]: List barang di keranjang. Harus punya key: 'storeId', 'storeLat', 'storeLng', 'price', 'quantity'.
  /// [userLat], [userLng]: Koordinat alamat pembeli (dari Maps).
  static List<Map<String, dynamic>> prepareOrders({
    required List<Map<String, dynamic>> cartItems,
    required double userLat,
    required double userLng,
  }) {
    // 1. Grouping item berdasarkan storeId
    Map<String, List<Map<String, dynamic>>> groupedItems = {};
    Map<String, Map<String, dynamic>> storeDetails = {};

    for (var item in cartItems) {
      String storeId = item['storeId'];

      // Simpan item ke dalam list milik storeId tersebut
      if (!groupedItems.containsKey(storeId)) {
        groupedItems[storeId] = [];
        // Cache detail toko untuk perhitungan nanti
        storeDetails[storeId] = {
          'storeName': item['storeName'],
          'storeLat':
              item['storeLat'], // Pastikan data produk punya koordinat toko
          'storeLng': item['storeLng'],
        };
      }
      groupedItems[storeId]!.add(item);
    }

    List<Map<String, dynamic>> finalOrders = [];

    // 2. Hitung Ongkir dan Total per Toko
    groupedItems.forEach((storeId, items) {
      var store = storeDetails[storeId]!;

      // Hitung Jarak
      double distance = ShippingCalculator.calculateDistance(
        userLat,
        userLng,
        store['storeLat'],
        store['storeLng'],
      );

      // Hitung Ongkir (1000/km, min 1000)
      int shippingCost = ShippingCalculator.calculateShippingCost(distance);

      // Hitung Subtotal Barang
      double itemsSubtotal = items.fold(
        0,
        (sum, item) => sum + (item['price'] * item['quantity']),
      );

      // Buat Struktur Order Final
      finalOrders.add({
        'storeId': storeId,
        'storeName': store['storeName'],
        'items': items, // List barang dalam satu order ini
        'shippingCost': shippingCost,
        'totalPrice': itemsSubtotal + shippingCost,
        'distanceKm': distance,
      });
    });

    return finalOrders;
  }
}
