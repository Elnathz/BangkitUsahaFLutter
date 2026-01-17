import 'dart:math';

class ShippingCalculator {
  static const int pricePerKm = 1000;
  static const int minShippingCost = 1000;

  // Menghitung jarak antara dua koordinat (dalam Kilometer) menggunakan Haversine Formula
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // Menghitung biaya ongkir berdasarkan jarak
  static int calculateShippingCost(double distanceInKm) {
    // Pembulatan jarak ke atas (misal 1.2 km jadi 2 km) agar adil bagi kurir
    // Atau gunakan round() jika ingin pembulatan biasa.
    // Di sini kita gunakan ceil() untuk pembulatan ke atas per km.
    int distance = distanceInKm.ceil();
    int cost = distance * pricePerKm;
    return cost < minShippingCost ? minShippingCost : cost;
  }
}